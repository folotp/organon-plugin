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
    return subprocess.run(args, cwd=cwd or ROOT, check=True, text=True,
                          stdout=subprocess.PIPE if capture else None).stdout


def git(*args, cwd=None):
    return run("git", *args, cwd=cwd, capture=True).strip()


def data(path):
    return json.loads((ROOT / path).read_text())


def require(condition, message):
    if not condition:
        raise ValueError(message)


def source_files():
    # Include new development files before the first commit; skip ignored artifacts.
    names = run("git", "ls-files", "--cached", "--others", "--exclude-standard", "-z", capture=True)
    return sorted({ROOT / p for p in names.split("\0") if p and (ROOT / p).is_file()})


def specs():
    run("bash", str(ROOT / "scripts/check-agent-tools.sh"))
    for skill in sorted((ROOT / "skills").iterdir()):
        if (skill / "SKILL.md").is_file():
            run("skills-ref", "validate", str(skill))
    run("check-jsonschema", "--schemafile", str(ROOT / "config/plugin.schema.json"), str(ROOT / "plugin.json"))
    require((ROOT / ".claude-plugin/plugin.json").is_symlink(), "Claude manifest must remain a symlink")
    require((ROOT / ".claude-plugin/plugin.json").resolve() == ROOT / "plugin.json", "Wrong manifest target")


def links():
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
    readme = (ROOT / "README.md").read_text().split("## Changes since", 1)[0]
    for skill in (ROOT / "skills").glob("*/SKILL.md"):
        require(f"**{skill.parent.name}**" in readme, f"README missing skill {skill.parent.name}")
    for command in (ROOT / "commands").glob("*.md"):
        require(command.stem in readme, f"README missing command {command.stem}")
    headings = re.findall(r"^### v(\d+\.\d+\.\d+)", (ROOT / "README.md").read_text(), re.M)
    require(headings and max(headings, key=lambda v: tuple(map(int, v.split('.')))) == data("plugin.json")["version"], "README release version differs from manifest")
    print("inventory: passed")


def protected(base):
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
    files = [str(p) for p in source_files() if p.suffix == ".sh" or p == ROOT / "scripts/dev"]
    run("shfmt", "-i", "4", "-ci", "-w" if fix else "-d", *files)
    if not fix:
        run("shellcheck", "-x", "--severity=warning", *files)
        run("git", "diff", "--check")


def tokens(update=False):
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
    sources = set(source_files())
    paths = []
    for name in data("config/package-files.json"):
        path = ROOT / name
        require(path.exists(), f"Package input missing: {name}")
        paths.extend(p for p in ([path] if path.is_file() else path.rglob('*')) if p in sources and '.DS_Store' not in p.parts and '__pycache__' not in p.parts)
    return sorted(paths)


def package_check():
    paths = package_paths()
    for path in paths:
        require(not any(p in path.relative_to(ROOT).parts for p in ('.claude', '.codex', '.agents', '.git')), f"Development config in package: {path}")
        require(path.resolve().is_relative_to(ROOT.resolve()), f"External symlink: {path}")
    require(any(p == ROOT / 'commands/organon-memory-audit.md' for p in paths), "Missing runtime command")
    print(f"package contract: {len(paths)} runtime files; no development configuration")


def package(packager, output):
    # Delegate zip creation to pa-toolkit; only select this plugin's payload here.
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


def hook(event):
    if event == 'start':
        if git('branch', '--show-current') == 'main':
            print('Development policy: create a feature branch/worktree before committing; see AGENTS.md.')
        return
    payload = json.load(sys.stdin)
    if event in ('edit', 'format'):
        name = payload.get('tool_input', {}).get('file_path')
        if not name:
            return  # Tool adapters do not substitute for Git/CI validation.
        path = Path(name)
        path = (path if path.is_absolute() else ROOT / path).resolve()
        if not path.is_relative_to(ROOT.resolve()):
            return
        rel = path.relative_to(ROOT.resolve()).as_posix()
        if event == 'format':
            if path.suffix == '.sh' and path.is_file():
                run('shfmt', '-i', '4', '-ci', '-d', str(path))
            return
        if rel in data('config/protected-references.json')['paths']:
            token = ROOT / '.organon-resync-token'
            allowed = token.exists() and rel in [l.strip() for l in token.read_text().splitlines() if not l.lstrip().startswith('#')]
            require(allowed, f'Protected reference: {rel}; follow docs/refreshing-kepano.md')
    elif event == 'stop':
        lint()


def doctor():
    missing = []
    for name in ('git', 'python3', 'uv', 'jq', 'shfmt', 'shellcheck', 'zip'):
        found = shutil.which(name)
        print(f'{name}: {found or "MISSING"}')
        if not found:
            missing.append(name)
    path = Path(git('rev-parse', '--path-format=absolute', '--git-path', 'hooks/pre-commit'))
    print(f'pre-commit: {path} ({"current launcher" if path.exists() and "check-staged" in path.read_text() else "missing or outdated"})')
    print('Vault/MCP and agent CLIs: optional; not needed by shared checks.')
    require(not missing, 'Missing required development tools: ' + ', '.join(missing))


def main():
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
    elif command == 'hook': hook(args.extra[0])
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
    print(f'{command}: passed')


if __name__ == '__main__':
    try:
        main()
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        print(f'ERROR: {error}', file=sys.stderr)
        sys.exit(2 if len(sys.argv) > 1 and sys.argv[1] == 'hook' else 1)
