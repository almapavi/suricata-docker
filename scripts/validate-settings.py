#!/usr/bin/env python3
"""Validate template input without evaluating it as shell or Python code."""
import ipaddress
import os
import re

def network_group(value):
    if value == 'any':
        return
    parts = value[1:-1].split(',') if value.startswith('[') and value.endswith(']') else [value]
    for item in parts:
        ipaddress.ip_network(item.strip(), strict=False)

def validate(env):
    interface = env.get('CAPTURE_INTERFACE', 'eth0')
    if not re.fullmatch(r'[A-Za-z0-9_.:-]{1,15}', interface):
        raise ValueError('CAPTURE_INTERFACE must be a Linux interface name')
    network_group(env.get('IDS_HOME_NET', '[192.168.0.0/16,10.0.0.0/8,172.16.0.0/12]'))
    external = env.get('IDS_EXTERNAL_NET', 'any')
    if external != '!$HOME_NET':
        network_group(external)
    ports = env.get('IDS_HTTP_PORTS', '[80,8080]')
    if ports == 'any':
        raise ValueError('Use explicit HTTP ports; any can invalidate rules containing negated port groups')
    for part in ports.strip('[]').split(','):
        if not part.strip().isdigit() or not 1 <= int(part.strip()) <= 65535:
            raise ValueError('IDS_HTTP_PORTS must be a comma-separated list of TCP port numbers')
    for key in ('UPDATE_RULES_ON_START', 'DAILY_RULE_UPDATES'):
        if env.get(key, 'yes') not in ('yes', 'no'):
            raise ValueError(f'{key} must be yes or no')
    for key, default, low, high in [('ROTATE_SIZE_MB','256',1,102400),('ROTATE_COUNT','7',1,100)]:
        value = env.get(key, default)
        if not value.isdigit() or not low <= int(value) <= high:
            raise ValueError(f'{key} must be an integer from {low} to {high}')

if __name__ == '__main__':
    try:
        validate(os.environ)
    except ValueError as error:
        raise SystemExit(f'Invalid template setting: {error}')
