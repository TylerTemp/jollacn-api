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
import itertools

import requests
import docpie
from bs4 import BeautifulSoup, Comment

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
soup = BeautifulSoup(html, 'html5lib')


for comment in soup.find_all(string=lambda t: isinstance(t, Comment)):
    # print(comment)
    # so far deal with table only
    # assert ' START table' in comment
    if ' START table' in comment:
        table = comment.find_next('table')

        tag_end = None
        tag_start = None
        tag_comp = []
        tag_content = None
        for tag in itertools.chain(table.find_all('th'), table.find_all('td')):
            # print(tag)
            tag_string = tag.string
            if tag_string.strip() == '<-':
                tag_comp.append(tag)
                tag_start = tag
            elif tag_string.strip() == '->':
                tag_comp.append(tag)
                tag_end = tag
            else:
                if tag_end is not None:  # group over
                    expand_count = len(tag_comp)
                    tag_keep = tag_comp.pop(0)
                    assert tag_content is not None
                    tag_keep.string = tag_content
                    tag_keep['colspan'] = str(expand_count)

                    for tag_exa in tag_comp:
                        tag_exa.extract()

                    tag_start = None
                    tag_end = None
                    tag_comp[:] = []
                elif tag_start is not None:
                    assert tag_content is None, tag_content
                    tag_content = tag.string
                    tag_comp.append(tag)
        comment.extract()
        # print(table)
    if ' END table' in comment:
        comment.extract()

    # if ' START hard_style' in comment:
    #     config = json.loads(comment.split('=', 1)[-1])
    #
    #     child_collect = []
    #     replace_node = None
    #     print(comment)
    #
    #     while True:
    #         next_node = comment.next_sibling
    #         print(next_node)
    #         if isinstance(next_node, Comment) and ' END hard_style' in next_node:
    #             replace_node = next_node
    #             break
    #         child_collect.append(next_node)
    #     comment.extract()
    #     div_wrapper = soup.new_tag('div')
    #     replace_node.replace_with(div_wrapper)

html = soup.body.encode_contents().decode('utf-8')

# exit()

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
        'sony xperia': 'Sony Xperia',
        'development': '开发',
        'jolla blog': 'Jolla博客',
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
    'source_authors': meta.get('source_authors', None) or [],
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
