"""
Usage:
    tie.py [options] <folder>
    tie.py [options] <tie_id> <folder>

Options:
    -h <host>, --host=<host>                      server host
    -u <user>, --user=<user>
    -p <pwd>, --pwd=<pwd>
"""

import json
import os
import requests
import docpie
from md import jolla_md_to_html
from jwt_login import LoginReq

# import logging
# from docpie import bashlog
#
# bashlog.stdoutlogger(logging.getLogger(), logging.DEBUG)

# import logging
# logging.basicConfig(level=logging.DEBUG)

args = docpie.docpie(__doc__, appearedonly=True, help=False)

host = args.get('--host', 'https://notexists.top') + '/api'
if not host.startswith('http'):
    host = 'http://' + host

print('get host {}'.format(host))
user = args.get('--user', None)
if user:
    print('get user from input')
    pwd = args['--pwd']
else:
    print('get user from account.json')
    with open(os.path.normpath(os.path.join(__file__, '..', 'account.json')), 'r', encoding='utf-8') as f:
        account = json.load(f)
    user = account['username']
    pwd = account['password']

login_req = LoginReq(user, pwd, host)

folder = args['<folder>']

print('get folder {}'.format(folder))

with open(os.path.join(folder, 'translate.md'), 'r', encoding='utf-8') as f:
    content = f.read()
markdown = content.rstrip() + '\n'
html = jolla_md_to_html(markdown)

with open(os.path.join(folder, 'meta.json'), 'r', encoding='utf-8') as f:
    meta = json.load(f)

submit_args = {
    'author': 'TylerTemp',
    'content': html,
    'content_md': markdown,
}

submit_args.update(meta)

print(submit_args)

tie_id = args.get('<tie_id>', None)

if tie_id:
    resp = requests.patch('{}/tie/{}'.format(host, tie_id), json=submit_args)
else:
    resp = requests.post(host + '/tie', data=json.dumps(submit_args))

print(resp.text)
print(resp.status_code)
print('tie id: {id}'.format(**resp.json()))
