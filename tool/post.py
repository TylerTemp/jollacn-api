"""
Usage:
    post.py new <folder>
    post.py update <slug> [options]

Options:
    -c <img>, --cover=<img>     cover img url
    -h <img>, --headerimg=<img>  header img
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

# import logging
# logging.basicConfig(level=logging.DEBUG)

args = docpie.docpie(__doc__, appearedonly=True, help=False)

host = args.get('--host', 'https://notexists.top/api')

if args['new']:
    # method = 'post'

    folder = args['<folder>']

    slug = os.path.split(folder)[-1]

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

    submit_args = {
        'slug': slug,
        'author': 'TylerTemp',
        'content': html,
        'content_md': content_md,
        'title': title,
        'description': description,
    }

    # assert False, slug

    resp = requests.post(host + '/post', data=json.dumps(submit_args))
    print(resp.text)
    print(resp.status_code)
    print(resp.json()['slug'])

elif args['update']:
    # method = 'patch'
    slug = args['<slug>']

    submit_args = {}
    if '--cover' in args:
        submit_args['cover'] = args['--cover']
    if '--headerimg' in args:
        submit_args['headerimg'] = args['--headerimg']

    assert submit_args
    resp = requests.patch('{}/post/{}'.format(host, slug), data=json.dumps(submit_args))
    print(resp.text)
    print(resp.status_code)
