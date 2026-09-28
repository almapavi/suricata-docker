#!/usr/bin/env python3
"""Update only the three GUI-owned scalar variables; preserve other YAML text."""
import json
import os
from pathlib import Path
import re
import shutil
import sys

def configure(path, env):
    path = Path(path)
    original = path.read_text()
    result = original
    for key, variable in [('HOME_NET','IDS_HOME_NET'),('EXTERNAL_NET','IDS_EXTERNAL_NET'),('HTTP_PORTS','IDS_HTTP_PORTS')]:
        pattern = re.compile(r'^(\s*)' + key + r':[^\n]*$', re.MULTILINE)
        matches = list(pattern.finditer(result))
        if len(matches) != 1:
            raise ValueError(f'Expected one active {key} field in {path}, found {len(matches)}; review configuration')
        result = pattern.sub(lambda m: m.group(1) + key + ': ' + json.dumps(env[variable]), result)
    backup = path.with_name(path.name + '.before-unraid-template')
    if not backup.exists():
        shutil.copy2(path, backup)
    if result != original:
        path.write_text(result)

if __name__ == '__main__':
    try:
        configure(sys.argv[1], os.environ)
    except (ValueError, KeyError, OSError) as error:
        raise SystemExit(f'Cannot configure sensor: {error}')
