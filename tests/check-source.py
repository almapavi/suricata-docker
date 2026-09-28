from pathlib import Path
import ast
import importlib.util
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
for path in (root / 'scripts').glob('*.py'):
    ast.parse(path.read_text(), filename=str(path))
spec = importlib.util.spec_from_file_location('validate_settings', root / 'scripts/validate-settings.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
sensor = ET.parse(root / 'templates/Suricata-Proxy-IDS.xml').getroot()
env = {c.attrib['Target']: c.text for c in sensor.findall('Config') if c.attrib['Type'] == 'Variable'}
module.validate(env)
assert sensor.findtext('Repository') == 'ghcr.io/almapavi/suricata-unraid:latest'
assert not sensor.findtext('PostArgs')
assert all(c.attrib['Target'] != '/opt/unraid-ids' for c in sensor.findall('Config'))
gui = ET.parse(root / 'templates/EveBox-Proxy-IDS.xml').getroot()
def logs(doc):
    return next(c.text for c in doc.findall('Config') if c.attrib['Target'] == '/var/log/suricata')
assert logs(sensor) == logs(gui)
for key, bad in [('CAPTURE_INTERFACE','eth0;false'),('ROTATE_SIZE_MB','256\npostrotate'),('IDS_HOME_NET','invalid')]:
    try:
        module.validate(dict(env, **{key: bad}))
    except ValueError:
        pass
    else:
        raise AssertionError(f'Invalid {key} accepted')
print('Source, templates, shared log paths and invalid-setting rejection passed.')
