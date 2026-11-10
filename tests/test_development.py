"""Tests use disposable Git repositories, never a vault or the real Git index."""
import contextlib
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location('dev', Path(__file__).resolve().parents[1] / 'scripts/dev.py')
dev = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(dev)


class RepositoryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='organon-test-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / 'repo'
        self.root.mkdir()
        self.original_root = dev.ROOT
        dev.ROOT = self.root
        self.addCleanup(setattr, dev, 'ROOT', self.original_root)
        self.git('init', '-q', '-b', 'main')
        self.git('config', 'user.email', 'test@example.invalid')
        self.git('config', 'user.name', 'Test')
        self.write('kepano-version.txt', 'kepano/obsidian-skills@' + 'a' * 40 + '\n')
        self.write('config/protected-references.json', json.dumps({'paths': ['protected.md'], 'exceptions': []}))
        self.write('protected.md', 'original')
        self.commit()
        self.git('switch', '-q', '-c', 'chore/test')

    def git(self, *args):
        return subprocess.check_output(['git', *args], cwd=self.root, text=True).strip()

    def write(self, name, content):
        p = self.root / name
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(content)
        return p

    def commit(self):
        self.git('add', '.')
        self.git('-c', 'core.hooksPath=/dev/null', 'commit', '-qm', 'fixture')

    def test_protected_requires_pin_change(self):
        self.write('protected.md', 'changed')
        with self.assertRaisesRegex(ValueError, 'Protected reference'):
            dev.protected('HEAD')
        self.write('kepano-version.txt', 'kepano/obsidian-skills@' + 'b' * 40)
        dev.protected('HEAD')

    def test_inventory_removal_does_not_bypass_protection(self):
        self.write('config/protected-references.json', json.dumps({'paths': [], 'exceptions': []}))
        self.write('protected.md', 'changed')
        with self.assertRaises(ValueError):
            dev.protected('HEAD')

    def test_exception_matches_exact_bytes(self):
        self.write('protected.md', 'approved')
        self.write('config/protected-references.json', json.dumps({'paths': ['protected.md'], 'exceptions': [{'path': 'protected.md', 'sha256': hashlib.sha256(b'approved').hexdigest(), 'reason': 'Maintainer approved adaptation'}]}))
        dev.protected('HEAD')
        self.write('protected.md', 'different')
        with self.assertRaises(ValueError):
            dev.protected('HEAD')

    def test_resync_token_never_allows_commit(self):
        self.write('.organon-resync-token', 'protected.md')
        with self.assertRaisesRegex(ValueError, 'resync-token'):
            dev.protected('HEAD')

    def test_malformed_pin_fails(self):
        self.write('kepano-version.txt', 'kepano/obsidian-skills@garbage')
        with self.assertRaisesRegex(ValueError, 'Malformed'):
            dev.protected('HEAD')

    def test_unmanaged_hook_preserved(self):
        hook = self.write('.git/hooks/pre-commit', '#!/bin/sh\necho custom\n')
        with self.assertRaisesRegex(ValueError, 'unmanaged'):
            dev.install_hooks()
        self.assertIn('custom', hook.read_text())

    def test_worktree_hook_resolves_shared_location_and_current_root(self):
        other = Path(self.temp.name) / 'linked worktree'
        self.git('worktree', 'add', '-q', '-b', 'chore/linked', str(other))
        # Fixture command records which worktree the launcher selected.
        for root in (self.root, other):
            script = root / 'scripts/dev'
            script.parent.mkdir(exist_ok=True)
            script.write_text('#!/bin/sh\nprintf "%s" "$PWD"\n')
            script.chmod(0o755)
        dev.ROOT = other
        dev.install_hooks()
        hook = self.root / '.git/hooks/pre-commit'
        result = subprocess.check_output([str(hook)], cwd=other, text=True)
        self.assertEqual(Path(result).resolve(), other.resolve())
        self.assertIn(dev.MARKER, hook.read_text())

    def test_custom_hook_path(self):
        self.git('config', 'core.hooksPath', '.custom-hooks')
        dev.install_hooks()
        self.assertTrue((self.root / '.custom-hooks/pre-commit').exists())

    def test_staged_snapshot_ignores_working_tree_fix(self):
        # The staged checker deliberately fails on the staged fixture. The working
        # tree replacement succeeds: testing it instead would mask the failure.
        script = self.write('scripts/dev', '#!/bin/sh\nexit 17\n')
        script.chmod(0o755)
        self.git('add', 'scripts/dev')
        self.write('scripts/dev', '#!/bin/sh\nexit 0\n')
        with self.assertRaises(subprocess.CalledProcessError) as caught:
            dev.check_staged()
        self.assertEqual(caught.exception.returncode, 17)
        self.assertEqual(script.read_text(), '#!/bin/sh\nexit 0\n')
        self.assertIn('exit 17', self.git('show', ':scripts/dev'))

    def test_staged_main_refused(self):
        self.git('switch', '-q', 'main')
        with self.assertRaisesRegex(ValueError, 'main'):
            dev.check_staged()

    def test_links_parse_reference_links_skip_code(self):
        self.write('notes.md', '[ok][ref]\n\n[ref]: protected.md\n\n`[fake](missing.md)`\n\n```md\n[example](absent.md)\n```\n')
        dev.links()
        self.write('notes.md', '[bad][ref]\n\n[ref]: missing.md\n')
        with self.assertRaisesRegex(ValueError, 'missing link'):
            dev.links()

    def test_edit_adapter_normalizes_paths_and_token(self):
        with patch('sys.stdin', io.StringIO(json.dumps({'tool_input': {'file_path': './sub/../protected.md'}}))):
            with self.assertRaisesRegex(ValueError, 'Protected reference'):
                dev.hook('edit')
        self.write('.organon-resync-token', '# scoped\nprotected.md\n')
        with patch('sys.stdin', io.StringIO(json.dumps({'tool_input': {'file_path': str(self.root / 'protected.md')}}))):
            dev.hook('edit')

    def patch_payload(self, text, cwd=None):
        return {'tool_name': 'apply_patch', 'tool_input': {'command': text}, 'cwd': str(cwd or self.root)}

    def test_native_patch_multiple_paths_and_move_destination(self):
        payload = self.patch_payload('*** Begin Patch\n*** Update File: ordinary.md\n*** Move to: protected.md\n@@\n-a\n+b\n*** End Patch')
        with patch('sys.stdin', io.StringIO(json.dumps(payload))):
            with self.assertRaisesRegex(ValueError, 'Protected reference'):
                dev.hook('edit')
        self.assertEqual(len(dev.hook_paths(payload)), 2)

    def test_native_patch_subdirectory_absolute_and_delete(self):
        (self.root / 'sub').mkdir()
        for name in ('../protected.md', str(self.root / 'protected.md')):
            payload = self.patch_payload('*** Begin Patch\n*** Delete File: ' + name + '\n*** End Patch', self.root / 'sub')
            with patch('sys.stdin', io.StringIO(json.dumps(payload))):
                with self.assertRaisesRegex(ValueError, 'Protected reference'):
                    dev.hook('edit')

    def test_native_patch_scoped_token_does_not_allow_other_path(self):
        self.write('.organon-resync-token', 'ordinary.md\n')
        payload = self.patch_payload('*** Begin Patch\n*** Add File: protected.md\n+x\n*** End Patch')
        with patch('sys.stdin', io.StringIO(json.dumps(payload))):
            with self.assertRaisesRegex(ValueError, 'Protected reference'):
                dev.hook('edit')
        self.write('.organon-resync-token', 'protected.md\n')
        with patch('sys.stdin', io.StringIO(json.dumps(payload))):
            dev.hook('edit')

    def test_malformed_unsupported_and_outside_paths_fail(self):
        for payload in ([], {'tool_input': []}, {'tool_name': 'Bash', 'tool_input': {'command': 'echo x'}},
                        self.patch_payload('bad'), self.patch_payload('*** Begin Patch\n*** Add File: /tmp/outside\n+x\n*** End Patch')):
            with self.subTest(payload=payload), self.assertRaises(ValueError):
                dev.hook_paths(payload)

    def test_stop_does_not_recurse(self):
        with patch('sys.stdin', io.StringIO('{"stop_hook_active":true}')), patch.object(dev, 'source_files') as files:
            dev.hook('stop')
            files.assert_not_called()

    def test_version_outputs(self):
        for output, expected in [('git version 2.54.0 (Apple Git)', (2,54,0)), ('shfmt v3.6.0', (3,6,0)),
                                 ('ShellCheck - shell analysis\nversion: 0.9.0', (0,9,0)), ('jq-1.6', (1,6,0)),
                                 ('Copyright 1990-2008\nThis is Zip 3.0 (July)', (3,0,0))]:
            self.assertEqual(dev.parse_version(output), expected)
        with self.assertRaises(ValueError):
            dev.parse_version('unrecognized')

    def test_doctor_required_tools_missing_old_and_supported(self):
        self.write('config/toolchain.json', json.dumps({'shfmt': {'minimum': '3.6.0', 'flag': '--version'}}))
        for found, version, success in [(None, '3.6.0', False), ('/tool/shfmt', '3.5.0', False), ('/tool/shfmt', 'v3.6.0', True)]:
            with patch.object(dev.shutil, 'which', return_value=found), patch.object(dev.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, version)), patch.object(dev, 'run', return_value='3.12.0'), patch.object(dev, 'git', return_value=str(self.root / '.git/hooks/pre-commit')):
                if success:
                    dev.doctor()
                else:
                    with self.assertRaises(ValueError):
                        dev.doctor()

    def test_session_launcher_resolves_root_from_subdirectory(self):
        import shutil
        launcher = self.root / 'scripts/dev'
        launcher.parent.mkdir(exist_ok=True)
        shutil.copy2(self.original_root / 'scripts/dev', launcher)
        fake_bin = self.root / 'fake-bin'
        fake_bin.mkdir()
        client = fake_bin / 'codex'
        client.write_text('#!/bin/sh\nprintf "%s\\n" "$PWD" "$@"\n')
        client.chmod(0o755)
        env = dict(os.environ, PATH=str(fake_bin) + os.pathsep + os.environ['PATH'])
        result = subprocess.check_output([str(launcher), 'session', 'codex', '--example', 'argument with spaces'], cwd=launcher.parent, env=env, text=True)
        lines = result.splitlines()
        self.assertEqual(Path(lines[0]).resolve(), self.root.resolve())
        self.assertEqual(lines[1:], ['--example', 'argument with spaces'])

    def test_package_rejects_development_config(self):
        self.write('.codex/hooks.json', '{}')
        self.write('config/package-files.json', json.dumps(['.codex']))
        with self.assertRaisesRegex(ValueError, 'Development config'):
            dev.package_check()

    def test_package_excludes_ignored_files(self):
        self.write('.gitignore', '*.bak\n')
        self.write('skills/example/SKILL.md', 'runtime')
        self.write('skills/example/private.bak', 'local-only')
        self.write('config/package-files.json', json.dumps(['skills']))
        self.assertEqual([p.name for p in dev.package_paths()], ['SKILL.md'])

    def test_package_rejects_external_symlink(self):
        outside = Path(self.temp.name) / 'outside'
        outside.write_text('private')
        (self.root / 'leak').symlink_to(outside)
        self.write('config/package-files.json', json.dumps(['leak']))
        with self.assertRaisesRegex(ValueError, 'External symlink'):
            dev.package_check()


if __name__ == '__main__':
    unittest.main()
