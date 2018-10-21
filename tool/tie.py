"""
Usage:
    tie.py new <file> [options]
    tie.py update <id> [options]

Options:
    -m <media>..., --media=<media>...             medias
    -p <preview>..., --preview=<preview>...   preview medias
    -h <host>, --host=<host>                      server host
"""

import json
import requests
import docpie
from md import jolla_md_to_html

# import logging
# logging.basicConfig(level=logging.DEBUG)

args = docpie.docpie(__doc__, appearedonly=True, help=False)

host = args.get('--host', 'https://notexists.top/api')

if args['new']:
    method = 'post'

    filepath = args['<file>']
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    sep = content.split('\n\n')

    markdown = sep[1]
    html = jolla_md_to_html(markdown)

    print(markdown)
    print(html)

    submit_args = {
        'author': 'TylerTemp',
        'content': html,
        'content_md': markdown,
    }

    resp = requests.post(host + '/tie', data=json.dumps(submit_args))
    print(resp.text)
    print(resp.status_code)

elif args['update']:
    method = 'patch'
    tie_id = int(args['<id>'])

    submit_args = {}
    if '--media' in args:
        submit_args['medias'] = [{'type': 'img', 'src': src} for src in args['--media']]
    if '--preview' in args:
        submit_args['media_previews'] = [{'type': 'img', 'src': src} for src in args['--preview']]

    assert submit_args
    resp = requests.patch('{}/tie/{}'.format(host, tie_id), data=json.dumps(submit_args))
    print(resp.text)
    print(resp.status_code)
