"""Agent-independent development checks. No vault or model access."""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
from urllib.parse import unquote, urlsplit
import zipfile

ROOT = Path(__file__).resolve().parent.parent
MARKER = "# managed-by: organon-plugin install-git-hooks.sh"


def run(*args, cwd=None, capture=False):
    """Run argv in the selected worktree; raise on nonzero exit.

    Capture stdout only when requested; all other output stays visible to the caller."""
    return subprocess.run(args, cwd=cwd or ROOT, check=True, text=True,
                          stdout=subprocess.PIPE if capture else None).stdout


def git(*args, cwd=None):
    """Return stripped Git output for this worktree; propagate command failures."""
    return run("git", *args, cwd=cwd, capture=True).strip()


def data(path):
    """Read repository-relative JSON policy; malformed or missing inputs fail closed."""
    return json.loads((ROOT / path).read_text())


def require(condition, message):
    """Raise a CLI policy failure with actionable text when an invariant is false."""
    if not condition:
        raise ValueError(message)


def source_files():
    # Include new development files before the first commit; skip ignored artifacts.
    """Return existing tracked and nonignored untracked files, including symlinks.

    Using Git instead of a filesystem walk excludes environments and local artifacts
    while allowing checks before the first commit. This does not select package inputs."""
    names = run("git", "ls-files", "--cached", "--others", "--exclude-standard", "-z", capture=True)
    return sorted({ROOT / p for p in names.split("\0") if p and (ROOT / p).is_file()})


def specs():
    """Validate portable skills, connector tool declarations and both manifest paths.

    The Claude manifest must remain a symlink to the canonical root manifest.
    Validator executables come from the locked project environment, never a skip path."""
    run("bash", str(ROOT / "scripts/check-agent-tools.sh"))
    for skill in sorted((ROOT / "skills").iterdir()):
        if (skill / "SKILL.md").is_file():
            run("skills-ref", "validate", str(skill))
    run("check-jsonschema", "--schemafile", str(ROOT / "config/plugin.schema.json"), str(ROOT / "plugin.json"))
    require((ROOT / ".claude-plugin/plugin.json").is_symlink(), "Claude manifest must remain a symlink")
    require((ROOT / ".claude-plugin/plugin.json").resolve() == ROOT / "plugin.json", "Wrong manifest target")


def links():
    """Check explicit relative Markdown targets in current source files.

    Parse Markdown so examples are ignored. Vault wikilinks, URL/fragment-only links
    and heading existence are outside this structural check; prose needs review."""
    from markdown_it import MarkdownIt
    parser = MarkdownIt()
    errors = []
    for path in source_files():
        if path.suffix != ".md":
            continue
        # Markdown parser ignores fenced/inline examples and supports reference links.
        for token in parser.parse(path.read_text()):
            for child in token.children or []:
                target = child.attrGet("href") if child.type == "link_open" else child.attrGet("src") if child.type == "image" else None
                if not target or target.startswith(("#", "[")) or urlsplit(target).scheme:
                    continue
                dest = unquote(urlsplit(target).path)
                if dest and not (path.parent / dest).exists():
                    errors.append(f"{path.relative_to(ROOT)}: missing link {target}")
    require(not errors, "\n".join(errors))
    print("links: passed (explicit relative targets; excludes vault links and anchors)")


def inventory():
    """Check current README skill/command coverage and its latest release version.

    Ignore historical changelog inventory when checking currently shipped entries."""
    readme = (ROOT / "README.md").read_text().split("## Changes since", 1)[0]
    for skill in (ROOT / "skills").glob("*/SKILL.md"):
        require(f"**{skill.parent.name}**" in readme, f"README missing skill {skill.parent.name}")
    for command in (ROOT / "commands").glob("*.md"):
        require(command.stem in readme, f"README missing command {command.stem}")
    headings = re.findall(r"^### v(\d+\.\d+\.\d+)", (ROOT / "README.md").read_text(), re.M)
    require(headings and max(headings, key=lambda v: tuple(map(int, v.split('.')))) == data("plugin.json")["version"], "README release version differs from manifest")
    print("inventory: passed")


def protected(base):
    """Compare current protected files with base, enforcing pin/exception policy.

    Union base and current inventories so deleting a policy entry cannot exempt a
    changed reference. Exceptions authorize exact bytes, never a wildcard. A resync
    token permits selected editor operations only and always blocks this gate.
    A changed pin records a refresh workflow; it does not prove upstream equivalence."""
    config = data("config/protected-references.json")
    pin = (ROOT / "kepano-version.txt").read_text().strip()
    require(re.fullmatch(r"kepano/obsidian-skills@[0-9a-f]{40}", pin), "Malformed Kepano pin")
    require(not (ROOT / ".organon-resync-token").exists(), "Remove .organon-resync-token before checking/committing")
    # Include paths protected by the base revision so removing an entry is not a bypass.
    old_paths = set(config["paths"])
    try:
        old_config = subprocess.run(["git", "show", f"{base}:config/protected-references.json"], cwd=ROOT, text=True, capture_output=True, check=True).stdout
        old_paths.update(json.loads(old_config)["paths"])
    except subprocess.CalledProcessError:
        pass  # Initial migration from the old hardcoded inventory.
    changed = set(git("diff", "--name-only", base, "--").splitlines())
    old_pin = git("show", f"{base}:kepano-version.txt")
    for name in sorted(old_paths & changed):
        if old_pin != pin:
            continue
        path = ROOT / name
        digest = hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None
        approved = any(e.get("path") == name and e.get("sha256") == digest and e.get("reason", "").strip() for e in config["exceptions"])
        require(approved, f"Protected reference changed without pin refresh or recorded maintainer exception: {name}")
    print("protected references: passed (workflow policy, not upstream content equivalence)")


def lint(fix=False):
    """Check shell style, ShellCheck warnings and Git whitespace; fix only on opt-in.

    format uses shfmt -w explicitly. Normal checks and lifecycle hooks never rewrite
    files behind the agent. The shell file selection is shared with Stop feedback."""
    files = shell_files()
    run("shfmt", "-i", "4", "-ci", "-w" if fix else "-d", *files)
    if not fix:
        run("shellcheck", "-x", "--severity=warning", *files)
        run("git", "diff", "--check")


def tokens(update=False):
    """Compare modeled main/total content tokens with the tracked scenario baseline.

    Both inline and delegated profiles have a 5% aggregate regression limit. Updating
    the baseline is an explicit reviewed operation, not a way to repair a failed gate.
    These estimates are content-size comparisons, not measured API usage or billing."""
    spec = importlib.util.spec_from_file_location("token_harness", ROOT / "scripts/token-harness.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    result = {"model_version": 2, "tokenizer": "cl100k_base", "tiktoken": "0.14.0", "profiles": {}}
    for profile in ("inline", "delegated"):
        rows = [module.session_costs(s, {}, profile=profile) for s in module.SESSIONS]
        result["profiles"][profile] = {r["id"]: {"main": r["post_tokens"], "total": r["post_tokens"] + r["subagent_tokens"]} for r in rows}
    baseline_path = ROOT / "tests/token-baseline.json"
    if update:
        baseline_path.parent.mkdir(parents=True, exist_ok=True)
        baseline_path.write_text(json.dumps(result, indent=2) + "\n")
        print("token baseline updated; review separately from content changes")
        return
    baseline = json.loads(baseline_path.read_text())
    require(all(result[k] == baseline[k] for k in ("model_version", "tokenizer", "tiktoken")), "Token methodology changed; review baseline")
    for profile, rows in result["profiles"].items():
        require(rows.keys() == baseline["profiles"][profile].keys(), "Token scenarios changed; review baseline")
        for metric in ("main", "total"):
            before = sum(r[metric] for r in baseline["profiles"][profile].values())
            after = sum(r[metric] for r in rows.values())
            print(f"tokens {profile}/{metric}: {before} -> {after} ({(after / before - 1):+.1%})")
            require(after <= before * 1.05, f"Token regression exceeds 5%: {profile}/{metric}")


def package_paths():
    # Ignore local artifacts even when they live inside a shipped directory.
    """Expand the runtime allowlist, retaining only nonignored source files.

    Selection, path validation and archive verification are separate steps so callers
    can inspect the contract without creating an archive. Source symlinks are retained."""
    sources = set(source_files())
    paths = []
    for name in data("config/package-files.json"):
        path = ROOT / name
        require(path.exists(), f"Package input missing: {name}")
        paths.extend(p for p in ([path] if path.is_file() else path.rglob('*')) if p in sources and '.DS_Store' not in p.parts and '__pycache__' not in p.parts)
    return sorted(paths)


def package_check():
    """Validate runtime selection, external symlinks and the audit-command invariant.

    Only listed payloads ship; development configuration and out-of-repo targets fail."""
    paths = package_paths()
    for path in paths:
        require(not any(p in path.relative_to(ROOT).parts for p in ('.claude', '.codex', '.agents', '.git')), f"Development config in package: {path}")
        require(path.resolve().is_relative_to(ROOT.resolve()), f"External symlink: {path}")
    require(any(p == ROOT / 'commands/organon-memory-audit.md' for p in paths), "Missing runtime command")
    print(f"package contract: {len(paths)} runtime files; no development configuration")


def package(packager, output):
    # Delegate zip creation to pa-toolkit; only select this plugin's payload here.
    """Stage the runtime contract, delegate ZIP creation and verify exact file names.

    packager selects pa-toolkit package.sh explicitly. Temporary staging is cleaned
    on success or failure; only a verified archive is copied to output. Preserve the
    source manifest symlink, and never package the development checkout directly."""
    package_check()
    script = Path(packager).expanduser().resolve()
    require(script.is_file(), "Pass --packager pointing to pa-toolkit's package.sh")
    with tempfile.TemporaryDirectory(prefix="organon-package-") as temp:
        stage = Path(temp)
        for path in package_paths():
            target = stage / path.relative_to(ROOT)
            target.parent.mkdir(parents=True, exist_ok=True)
            if path.is_symlink():
                target.symlink_to(os.readlink(path))
            else:
                shutil.copy2(path, target)
        run("bash", str(script), str(stage))
        archives = list(stage.glob('*.plugin'))
        require(len(archives) == 1, "Expected exactly one pa-toolkit archive")
        expected = {p.relative_to(ROOT).as_posix() for p in package_paths()}
        with zipfile.ZipFile(archives[0]) as archive:
            actual = {n.removeprefix('./') for n in archive.namelist() if not n.endswith('/')}
            require(actual == expected, f"Archive differs from contract: {actual ^ expected}")
        dest = Path(output).expanduser().resolve()
        dest.mkdir(parents=True, exist_ok=True)
        shutil.copy2(archives[0], dest / archives[0].name)
        print(dest / archives[0].name)


def check(base, skip_tests=False):
    """Run the common required gates in order; stop at the first failure.

    Used by agents, isolated staged checks and both CI operating systems. Full release
    archive creation is a separate package/driver step, not implied by package_check.
    skip_tests is an internal option; normal CLI checks always run infrastructure tests."""
    doctor()
    specs()
    lint()
    links()
    inventory()
    protected(base)
    tokens()
    package_check()
    if not skip_tests:
        run(sys.executable, "-m", "unittest", "discover", "-s", "tests", "-v")


def check_staged():
    """Validate exactly the Git index, not unstaged edits that could hide a defect.

    Export the index into a disposable repository, compare it with committed HEAD,
    and invoke the same check command there. Strip inherited GIT_* variables so Git
    cannot resolve back to the original checkout. Never change its branch or index."""
    require(git("branch", "--show-current") not in ("", "main"), "Commit from a named feature branch, not main/detached HEAD")
    require(not (ROOT / '.organon-resync-token').exists(), "Remove .organon-resync-token before commit")
    # Export the index, never the working tree: partial staging must not hide failures.
    with tempfile.TemporaryDirectory(prefix="organon-index-") as temp:
        run("git", "checkout-index", "--all", "--prefix", temp + os.sep)
        # Isolated repository makes diff policies compare the staged snapshot to HEAD.
        env = {k: v for k, v in os.environ.items() if not k.startswith('GIT_')}
        def isolated(*args):
            subprocess.run(args, cwd=temp, env=env, check=True)
        isolated("git", "init", "-q")
        isolated("git", "fetch", "-q", str(ROOT), "HEAD")
        isolated("git", "reset", "--quiet", "--mixed", "FETCH_HEAD")
        isolated(str(Path(temp) / "scripts/dev"), "check", "--base", "HEAD")


def install_hooks(uninstall=False):
    # Honor core.hooksPath and Git's common metadata directory for linked worktrees.
    """Install/remove only the marked staged-check launcher at Git’s resolved path.

    Linked worktrees may share this file; the launcher resolves the active worktree
    when executed. Refuse unmanaged hooks rather than replacing someone else’s checks."""
    path = Path(git("rev-parse", "--path-format=absolute", "--git-path", "hooks/pre-commit"))
    if path.exists():
        require(MARKER in path.read_text(), f"Preserving unmanaged hook: {path}; merge manually")
    if uninstall:
        if path.exists():
            path.unlink()
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text('#!/usr/bin/env bash\n' + MARKER + '\nset -euo pipefail\nroot="$(git rev-parse --show-toplevel)"\nif [[ ! -x "$root/scripts/dev" ]]; then\n    echo "Shared checks missing in this worktree; update the branch before committing." >&2\n    exit 1\nfi\nexec "$root/scripts/dev" check-staged\n')
    path.chmod(0o755)
    print(f"Installed {path}; shared by worktrees using this hooks path")


def hook_paths(payload):
    """Resolve every native patch header or Claude file path against payload cwd.

    Include move destinations as well as sources: protecting only the source
    would permit overwriting a protected destination. Resolve dot segments and
    symlinks before consulting the one repository inventory. Unsupported shapes
    or paths outside this repository raise; arbitrary shell text is never parsed.
    """
    require(isinstance(payload, dict), 'Hook payload must be an object')
    inputs = payload.get('tool_input', {})
    require(isinstance(inputs, dict), 'Unsupported tool_input shape')
    if payload.get('tool_name') == 'apply_patch':
        command = inputs.get('command')
        require(isinstance(command, str) and command.startswith('*** Begin Patch'), 'Malformed apply_patch payload')
        names = re.findall(r'^\*\*\* (?:Add File|Update File|Delete File|Move to): (.+)$', command, re.M)
        require(names, 'Patch has no supported file headers')
    elif inputs.get('file_path'):
        names = [inputs['file_path']]
    else:
        raise ValueError('Unsupported edit payload; Git/CI remain authoritative')
    cwd = Path(payload.get('cwd', str(ROOT)))
    require(cwd.is_absolute(), 'Hook cwd must be absolute')
    paths = []
    for name in names:
        require(isinstance(name, str) and name.strip(), 'Invalid edit path')
        path = Path(name)
        path = (path if path.is_absolute() else cwd / path).resolve()
        # Outside-root writes cannot be checked against this repository inventory.
        require(path.is_relative_to(ROOT.resolve()), 'Edit path outside repository: ' + str(path))
        paths.append(path)
    return paths


def hook(event):
    """Adapt one lifecycle event to common policy and bounded client-compatible output.

    start emits advisory branch context. edit raises on protected paths unless each
    path has a scoped token entry. format and stop produce advisory JSON without
    changing files; repeated Stop events do not request another continuation. Native
    patch and Claude file payloads normalize through hook_paths. Git/CI cover other
    editing paths, including shell writes, which these matchers do not intercept."""
    if event == 'start':
        if git('branch', '--show-current') == 'main':
            print('Development policy: create a feature branch/worktree before committing; see AGENTS.md.')
        return
    payload = json.load(sys.stdin)
    require(isinstance(payload, dict), 'Hook payload must be an object')
    if event == 'stop':
        if payload.get('stop_hook_active'):
            return
        # Advisory JSON feedback: never force another Stop cycle or modify files.
        if not shell_files():
            print('{}')
            return
        output = subprocess.run(['shfmt', '-i', '4', '-ci', '-d', *shell_files()], cwd=ROOT,
                                text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        shell = subprocess.run(['shellcheck', '-x', '--severity=warning', *shell_files()], cwd=ROOT,
                               text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        message = (output.stdout + shell.stdout)[-4000:]
        status = message or ('failed without diagnostic output' if output.returncode or shell.returncode else 'passed')
        print(json.dumps({'systemMessage': 'Shared lint (advisory; files unchanged): ' + status}))
        return
    feedback = []
    paths = hook_paths(payload)
    for path in paths:
        rel = path.relative_to(ROOT.resolve()).as_posix()
        if event == 'format':
            if path.suffix == '.sh' and path.is_file():
                result = subprocess.run(['shfmt', '-i', '4', '-ci', '-d', str(path)], text=True,
                                        stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
                if result.returncode:
                    feedback.append('Formatting required (advisory only; file unchanged). Run scripts/dev format explicitly.\n' + result.stdout[-3500:])
            continue
        if rel in data('config/protected-references.json')['paths']:
            token = ROOT / '.organon-resync-token'
            allowed = token.exists() and rel in [l.strip() for l in token.read_text().splitlines() if not l.lstrip().startswith('#')]
            require(allowed, f'Protected reference: {rel}; follow docs/refreshing-kepano.md')

    if feedback:
        print(json.dumps({'hookSpecificOutput': {'hookEventName': 'PostToolUse',
                          'additionalContext': '\n'.join(feedback)[-4000:]}}))


def shell_files():
    """Select repository shell sources, including the extensionless scripts/dev."""
    return [str(p) for p in source_files() if p.suffix == '.sh' or p == ROOT / 'scripts/dev']


def parse_version(output):
    """Normalize the first major.minor[.patch] tuple from required-tool output.

    Support Git vendor suffixes, shfmt prefixes, jq and Info-ZIP banners. Unknown
    formats raise instead of being assumed supported; fixtures pin the expected forms."""
    match = re.search(r'(\d+)\.(\d+)(?:\.(\d+))?', output)
    require(match, 'Cannot parse tool version: ' + output[:160])
    return tuple(int(x or 0) for x in match.groups())


def doctor():
    """Report required executable versions and verify the managed project interpreter.

    The launcher can use Python 3.9+, while uv selects Python 3.11+ for locked checks.
    Do not reject a usable managed environment based on Apple’s older system Python.
    Missing tools, unsupported versions and blocked uv access fail with a remedy."""
    require(sys.version_info >= (3, 9), 'Launcher Python 3.9+ required; use a supported python3 on PATH')
    policy = data('config/toolchain.json')
    failures = []
    for name, rule in policy.items():
        found = shutil.which(name)
        if not found:
            print(f'{name}: MISSING')
            failures.append(f'Install {name} >= {rule["minimum"]}')
            continue
        result = subprocess.run([found, rule['flag']], text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        try:
            version = parse_version(result.stdout)
            minimum = tuple(int(n) for n in rule['minimum'].split('.'))
            print(f'{name}: {".".join(map(str, version))} ({found})')
            require(result.returncode == 0 and version >= minimum, f'{name} >= {rule["minimum"]} required; upgrade the detected installation')
        except ValueError as error:
            failures.append(str(error))
    print(f'Launcher Python: {sys.version.split()[0]} ({sys.executable}); project Python is checked separately')
    try:
        result = run('uv', 'run', '--locked', '--project', str(ROOT), 'python', '-c',
                     'import sys; print(sys.version.split()[0]); sys.exit(sys.version_info < (3, 11))', capture=True)
        print('Managed project Python: ' + result.strip())
    except (OSError, subprocess.CalledProcessError):
        failures.append('Managed Python unavailable: run uv sync --locked with approved network/cache access; see docs/development.md')
    require(not failures, '; '.join(failures))
    path = Path(git('rev-parse', '--path-format=absolute', '--git-path', 'hooks/pre-commit'))
    print(f'pre-commit: {path} ({"current launcher" if path.exists() and "check-staged" in path.read_text() else "missing or outdated"})')


def main():
    """Dispatch the shared CLI and preserve each consumer’s failure/output contract.

    Required commands fail nonzero. Stop errors become explicit advisory JSON, with
    no recursive continuation. Do not print a generic success suffix after hook JSON.
    Release-check requires a clean tree, full gates and an actual verified archive;
    only upstream freshness remains advisory. Session launching lives in scripts/dev."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=['doctor', 'specs', 'links', 'inventory', 'tokens', 'baseline', 'check', 'check-staged', 'format', 'install-hooks', 'hook', 'worktree', 'package-check', 'package', 'release-check'])
    parser.add_argument('extra', nargs='*')
    parser.add_argument('--base', default='HEAD')
    parser.add_argument('--staged', action='store_true')
    parser.add_argument('--uninstall', action='store_true')
    parser.add_argument('--packager')
    parser.add_argument('--output', default='dist')
    args = parser.parse_args()
    command = args.command
    if command == 'doctor': doctor()
    elif command == 'specs': specs()
    elif command == 'links': links()
    elif command == 'inventory': inventory()
    elif command == 'tokens': tokens()
    elif command == 'baseline': tokens(update=True)
    elif command == 'format': lint(fix=True)
    elif command == 'check-staged' or (command == 'check' and args.staged): check_staged()
    elif command == 'check': check(args.base)
    elif command == 'install-hooks': install_hooks(args.uninstall)
    elif command == 'hook':
        try:
            hook(args.extra[0])
        except (ValueError, OSError, subprocess.CalledProcessError) as error:
            if args.extra[0] != 'stop':
                raise
            print(json.dumps({'systemMessage': 'Shared lint unavailable: ' + str(error)[:1000]}))
    elif command == 'worktree':
        require(len(args.extra) == 2, 'Usage: scripts/dev worktree <branch> <destination>')
        require(re.match(r'^(feat|fix|chore|perf|docs)/', args.extra[0]), 'Use a documented branch prefix')
        run('git', 'worktree', 'add', '-b', args.extra[0], str(Path(args.extra[1]).expanduser()), 'main')
    elif command == 'package-check': package_check()
    elif command == 'package':
        require(bool(args.packager), '--packager is required; see docs/release.md')
        package(args.packager, args.output)
    elif command == 'release-check':
        require(not git('status', '--porcelain'), 'Release requires a clean working tree')
        check(args.base)
        rc = subprocess.run(['bash', str(ROOT / 'scripts/kepano-check-upstream.sh')]).returncode
        if rc: print(f'ADVISORY: upstream freshness unavailable/outdated (exit {rc})')
        require(bool(args.packager), '--packager is required for archive verification')
        with tempfile.TemporaryDirectory(prefix='organon-release-check-') as temp:
            package(args.packager, temp)
    if command != 'hook':
        print(f'{command}: passed')


if __name__ == '__main__':
    try:
        main()
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        print(f'ERROR: {error}', file=sys.stderr)
        sys.exit(2 if len(sys.argv) > 1 and sys.argv[1] == 'hook' else 1)
