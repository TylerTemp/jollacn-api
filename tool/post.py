"""
Usage:
    post.py [options] [new|update] <folder>

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

folder = args['<folder>']

with open(os.path.join(folder, 'meta.json'), 'r', encoding='utf-8') as f:
    meta = json.load(f)

with open(os.path.join(folder, 'description.html'), 'r', encoding='utf-8') as f:
    description = f.read()

with open(os.path.join(folder, 'translate.md'), 'r', encoding='utf-8') as f:
    title_md = next(f).strip()
    assert title_md.startswith('# '), title_md
    assert title_md.endswith(' #'), title_md
    title = title_md[2:-2]
    print(title)
    empty_line = next(f).strip()
    assert not empty_line, empty_line
    content_md = f.read().strip() + '\n'

html = jolla_md_to_html(content_md)

print(content_md)
print(html)

# title
# headerimg
# description
# content
# author

original_tags = meta.get('tags', None)
if original_tags is None:
    tags = None
else:
    tags = [{
        'guest': '嘉宾',
        'sailfish x': 'Sailfish X',
        'software updates': '软件更新',
        'sailfish os': 'Sailfish系统',
        'sailfish 3': 'Sailfish 3',
    }[tag.lower()] for tag in original_tags]

submit_args = {
    'slug': meta['slug'],
    'author': 'TylerTemp',
    'content': html,
    'content_md': content_md,
    'title': title,
    'description': description,
    'cover': meta.get('cover', None),
    'headerimg': meta.get('headerimg', None),
    # 'source_author': meta.get('source_author', None),
    'source_authors': meta.get('authors', None) or [],
    'source_type': meta.get('source_type', None),
    'source_url': meta.get('source_url', None),
    'source_title': meta.get('source_title', None),
    'tags': tags,
}

if args['new']:
    resp = login_req.post(host + '/post', json=submit_args)
else:
    slug = submit_args.pop('slug')
    resp = login_req.patch('{}/post/{}'.format(host, slug), json=submit_args)

print(resp.text)
print(resp.status_code)
print(resp.json()['slug'])
