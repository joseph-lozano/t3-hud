#!/usr/bin/env python3
"""Create a uniquely owned fixture and app bundle; never modify real T3 state."""
import datetime
import json
import pathlib
import plistlib
import shutil
import subprocess
import sys
import time
import urllib.request
import uuid

repo = pathlib.Path(__file__).resolve().parents[2]

def command(*args, **kwargs):
    return subprocess.run(args, check=True, **kwargs)

def process_identity(pid):
    result = subprocess.run(['ps', '-p', str(pid), '-o', 'lstart=,command='], capture_output=True, text=True)
    return result.stdout.strip() if result.returncode == 0 else None

def owned(path):
    path = pathlib.Path(path).resolve()
    if path.parent != repo / '.verification':
        raise SystemExit('Refusing a path outside the verification directory')
    record = json.loads((path / 'owner.json').read_text())
    if record['run'] != path.name:
        raise SystemExit('Run identity mismatch')
    return path, record

action = sys.argv[1]
if action == 'start':
    source = repo / 'dist/T3 HUD.app'
    if not source.exists():
        raise SystemExit('Run ./scripts/build first')
    run_id = datetime.datetime.now().strftime('%Y%m%d-%H%M%S-') + uuid.uuid4().hex[:8]
    root = repo / '.verification' / run_id
    root.mkdir(parents=True)
    app = root / 'T3 HUD Check.app'
    shutil.copytree(source, app)
    bundle = 'local.t3hud.verify.' + run_id
    info_path = app / 'Contents/Info.plist'
    info = plistlib.loads(info_path.read_bytes()); info['CFBundleIdentifier'] = bundle
    info['CFBundleName'] = 'T3 HUD Check'; info['CFBundleDisplayName'] = 'T3 HUD Check'
    info_path.write_bytes(plistlib.dumps(info))
    command('codesign', '--force', '--sign', '-', str(app), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    log = (root / 'fixture.log').open('w')
    fixture = subprocess.Popen([sys.executable, str(repo / 'Tests/UI/fixture.py'), str(root)], stdout=log, stderr=log, start_new_session=True)
    owner = {'run': run_id, 'bundle': bundle, 'app': str(app), 'fixture_pid': fixture.pid, 'fixture_identity': process_identity(fixture.pid)}
    (root / 'owner.json').write_text(json.dumps(owner, indent=2))
    for _ in range(100):
        if (root / 'endpoint.json').exists():
            break
        if fixture.poll() is not None:
            raise SystemExit('Fixture failed; inspect fixture.log')
        time.sleep(.05)
    endpoint = json.loads((root / 'endpoint.json').read_text())
    owner['fixture_identity'] = process_identity(fixture.pid)
    (root / 'owner.json').write_text(json.dumps(owner, indent=2))
    command('defaults', 'write', bundle, 'verificationURL', endpoint['url'])
    print(root)
    print('Endpoint:', endpoint['url'])
    print('Bundle:', bundle)
    print('Launch:', app)
    print('Doctor: python3 scripts/verification/session.py doctor', root)
elif action == 'doctor':
    root, owner = owned(sys.argv[2])
    if process_identity(owner['fixture_pid']) != owner['fixture_identity']:
        raise SystemExit('Fixture ownership check failed')
    endpoint = json.loads((root / 'endpoint.json').read_text())
    with urllib.request.urlopen(endpoint['url'], timeout=3) as response:
        if response.headers.get('X-T3HUD-Verification') != owner['run']:
            raise SystemExit('Wrong server identity')
    info = plistlib.loads((pathlib.Path(owner['app']) / 'Contents/Info.plist').read_bytes())
    if info['CFBundleIdentifier'] != owner['bundle']:
        raise SystemExit('Wrong bundle identity')
    command('codesign', '--verify', '--strict', owner['app'], stdout=subprocess.DEVNULL)
    print('READY:', owner['run'])
elif action in ('offline', 'online'):
    root, owner = owned(sys.argv[2])
    if process_identity(owner['fixture_pid']) != owner['fixture_identity']:
        raise SystemExit('Fixture ownership check failed')
    if action == 'offline':
        (root / 'offline').touch()
    else:
        (root / 'offline').unlink(missing_ok=True)
    print(action)
elif action == 'cleanup':
    root, owner = owned(sys.argv[2])
    # Explicitly retain the proof and run-owned app. Quit its GUI through its menu first.
    running = subprocess.run(['pgrep', '-f', owner['app'] + '/Contents/MacOS/T3HUD'], capture_output=True, text=True)
    if running.returncode == 0:
        raise SystemExit('Quit the run-owned HUD through its menu before cleanup')
    identity = process_identity(owner['fixture_pid'])
    if identity is not None:
        if identity != owner['fixture_identity']:
            raise SystemExit('Refusing to stop a process with changed ownership')
        import os, signal
        os.kill(owner['fixture_pid'], signal.SIGTERM)
    command('defaults', 'delete', owner['bundle'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    print('Stopped owned fixture and removed its preferences; evidence retained at', root)
else:
    raise SystemExit('Use start, doctor, offline, online, or cleanup')
