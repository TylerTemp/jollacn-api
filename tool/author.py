"""
Usage:
    post.py [options] <meta>...

Options:
    -n <str>, --name=<str>       user name
    -p <str>, --password=<str>   user password
    --host <host>                host
"""

# title
# headerimg
# description
# content
# author

import json
import os
import requests
import docpie

try:
    from urllib.parse import quote
except ImportError:
    from urllib import quote

from md import jolla_md_to_html
from jwt_login import LoginReq

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

for filename in args['<meta>']:
    with open(filename, 'r', encoding='utf-8') as f:
        meta = json.load(f)

    print(meta)
    meta_no_name = dict(meta)
    name = meta_no_name.pop('name')

    resp = login_req.patch('{}/author/{}'.format(host, quote(name)), json=meta_no_name)
    if resp.status_code == 404:
        resp = login_req.post(host + '/author', json=meta)

    print(resp.text)
    print(resp.status_code)
    print(resp.json())
