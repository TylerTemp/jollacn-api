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
import sys
import itertools

import requests
import docpie
from bs4 import BeautifulSoup, Comment

from md import jolla_md_to_html
from jwt_login import LoginReq

# import logging
# logging.basicConfig(level=logging.DEBUG)

sys.stdout.reconfigure(encoding='utf-8')

args = docpie.docpie(__doc__, appearedonly=True, help=False)
if '--host' in args:
    host = args['--host']
    if not host.startswith('http'):
        host = 'http://' + host
else:
    host = args.get('--host', 'https://notexists.top') + '/api'

print('get host {}'.format(host))
user = args.get('--name', None)
if user:
    print('get user from input')
    pwd = args['--password']
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

# level 1 plug
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

    if 'START figure' in comment:
        config_raw_str = comment.split('START figure')[-1].strip()
        config_figure = {'title': None, 'enlarge': 'link'}
        if config_raw_str:
            config_figure.update(json.loads(config_raw_str))

        print(config_figure)

        figure_container = comment.find_next('p')
        print(figure_container)
        # exit()
        img_raw_node = figure_container.find('img')
        img_src = img_raw_node.get('src')
        assert img_src
        print(img_src)

        figure_node = soup.new_tag('figure', **{'class': 'plugin plugin-figure'})
        # figure_node.append(soup.new_tag('img', src=img_src))
        # print(figure_node)
        img_node = soup.new_tag('img', src=img_src, **{'class': 'plugin plugin-figure plugin-figure-img'})

        if config_figure['enlarge']:
            assert config_figure['enlarge'] == 'link'
            a_raw_node = figure_container.find('a')
            a_href = a_raw_node.get('href')
            assert a_href
            print(a_href)
            a_node = soup.new_tag('a', href=a_href, target='_blank', **{'class': 'plugin plugin-figure plugin-figure-enlarge'})
            a_node.append(img_node)

            a_raw_node.extract()

            figure_node.append(a_node)
        else:
            img_raw_node.extract()
            figure_node.append(img_node)

        if config_figure['title']:
            assert config_figure['title'] == 'h6'
            h6_raw_node = comment.find_next('h6')
            fig_caption = soup.new_tag('figcaption', class_='plugin plugin-figure plugin-figure-figcaption')
            for h6_child_raw_node in h6_raw_node.children:
                fig_caption.append(h6_child_raw_node)

            h6_raw_node.extract()
            figure_node.append(fig_caption)

        print(figure_node)
        figure_container.replace_with(figure_node)
        comment.extract()

    if 'END figure' in comment:
        comment.extract()

    if 'START button' in comment:
        config_raw_str = comment.split('START button')[-1].strip()
        config_button = {'center': True}
        if config_raw_str:
            config_button.update(json.loads(config_raw_str))

        print(config_button)

        link_node = comment.find_next('a')
        print(link_node)
        link_text = link_node.text.strip()
        link_href = link_node.get('href')


        center_node = soup.new_tag('center', **{'class': 'plugin plugin-button plugin-button-center'})
        # figure_node.append(soup.new_tag('img', src=img_src))
        # print(figure_node)
        link_new_node = soup.new_tag('a', href=link_href, target='_blank', **{'class': 'plugin plugin-button plugin-button-a'})
        button_node = soup.new_tag('button', **{'class': 'plugin plugin-button plugin-button-button'})
        button_node.append(soup.new_string(link_text))

        link_new_node.append(button_node)

        if config_button['center']:
            main_node = center_node
            main_node.append(link_new_node)
        else:
            main_node = link_new_node

        print(main_node)
        link_node.replace_with(main_node)
        comment.extract()

    if 'END button' in comment:
        comment.extract()

# level 2 plug
image_list = []
config_image_list = {}
in_image_list = False
for first_level_node in soup.find('body').children:
    is_comment = isinstance(first_level_node, Comment)
    # print(first_level_node)
    if is_comment:
        print(first_level_node)

    if is_comment and 'START image_list' in first_level_node:
        in_image_list = True
        image_list.clear()

        config_raw_str = first_level_node.split('START image_list')[-1].strip()
        config_image_list = {'sm': 1, 'md': 3, 'lg': 4}
        if config_raw_str:
            config_image_list.update(json.loads(config_raw_str))

        print(config_figure)
        first_level_node.extract()
        continue

    if is_comment and 'END image_list' in first_level_node:
        assert in_image_list
        in_image_list = False
        # process image list
        print('image list', image_list)
        image_list_node = soup.new_tag('div', **{'class': 'plugin plugin-image-list', 'data-config': json.dumps(config_image_list)})
        for image_node in image_list:
            image_list_node.append(image_node)
        first_level_node.replace_with(image_list_node)
        # first_level_node.extract()
        # exit()
        continue

    if in_image_list and first_level_node.name == 'figure':
        image_list.append(first_level_node)

html = soup.body.encode_contents().decode('utf-8')

# exit()

print(content_md)
print(html)

# exit()

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
        'sailfish 4': 'Sailfish 4',
        'sony xperia': 'Sony Xperia',
        'development': '开发',
        'jolla blog': 'Jolla博客',
        'jolla story': 'Jolla故事',
        'news': '新闻',
        'community': '社区',
        'strategy': '策略',
        'app support': '应用支持',
        'hardware': '硬件',
        'jolla smartphone': 'Jolla 智能手机',
        'developer stories': '开发者故事',
        'open source': '开源',
        'together.jolla.com': 'together.jolla.com',
        'applications': '应用',
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
