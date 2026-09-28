from pathlib import Path
import os
import sys
import yaml

sys.path.insert(0, '/opt/unraid-ids')
import importlib.util
spec = importlib.util.spec_from_file_location('configure_sensor', '/opt/unraid-ids/configure-sensor.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
path = Path('/etc/suricata/suricata.yaml')
data = yaml.safe_load(path.read_text())
assert data['vars']['address-groups']['HOME_NET'] == os.environ['IDS_HOME_NET']
assert data['vars']['address-groups']['EXTERNAL_NET'] == 'any'
assert data['vars']['port-groups']['HTTP_PORTS'] == os.environ['IDS_HTTP_PORTS']
backup = path.with_name(path.name + '.before-unraid-template')
assert backup.is_file()
before = path.read_bytes()
original_backup = backup.read_bytes()
module.configure(path, os.environ)
assert path.read_bytes() == before
assert backup.read_bytes() == original_backup
print('Settings, backup and repeated-start behavior verified.')
