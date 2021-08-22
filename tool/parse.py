# -*- coding: utf-8 -*-
"""
Usage:
    parse <url> [<save-dir>]
"""

import logging
import json
from bs4 import BeautifulSoup
import requests
import socks
import socket
import html2text
#socks.setdefaultproxy(socks.PROXY_TYPE_SOCKS5, "127.0.0.1", 1080)
#socket.socket = socks.socksocket

try:
    from urllib.request import urlretrieve
    from urllib.parse import urlparse
except ImportError:
    from urllib import urlretrieve, urlparse


logger = logging.getLogger('new_trans')


def mk_soup(url):
    resp = requests.get(url)
    return BeautifulSoup(resp.content, 'html5lib')


def parse_reviewjolla(url):
    soup = mk_soup(url)
    # with open('/tmp/save.html', 'r', encoding='utf-8') as f:
    #     soup = BeautifulSoup(f.read(), 'html5lib')
    result = {}

    title = soup.find(None, {'class': 'post-title'}).text.strip()
    logger.debug(title)
    result['title'] = title

    body = soup.find(None, {'class': 'post-body'})
    # logger.debug(body.text)

    banner_img = body.find('img')
    banner = banner_img.get('src')
    a = banner_img.parent
    assert a.name == 'a'
    cover = a.get('href')
    logger.debug(banner)
    logger.debug(cover)
    result['banner'] = banner
    result['cover'] = cover
    result['imgs'] = imgs = []

    for each in body.find_all('img'):
        small = each.get('src')
        if small.endswith('favicon.png'):
            continue

        parent = each.parent
        if parent.name == 'a':
            big = parent.get('href')
            if big == 'javascript:;':
                big = None
        else:
            big = None

        imgs.append((small, big))

    result['author'] = 'Simo Ruoho'
    result['content'] = html2text.html2text(str(body))

    return result


def parse_jolla(url):
    soup = mk_soup(url)
    # with open('/tmp/save.html', 'r', encoding='utf-8') as f:
    #     soup = BeautifulSoup(f.read(), 'html5lib')
    #     # f.write(soup.prettify())

    result = {'platform': 'jollablog', 'url': url}

    img_div = soup.find(None, {'class': 'blog-img-wrap'})
    banner = img_div.find('img').get('src')
    logger.debug(banner)
    result['banner'] = banner

    tags = set()
    tags_tag = soup.find(None, {'class': 'blog-cats'})
    for a_tag in tags_tag.find_all('a'):
        tags.add(a_tag.text.strip())
    logger.debug(tags)
    result['tags'] = list(tags)

    profile_node = soup.find(None, {'class': 'profile-section'})
    author_node = profile_node.find('strong')
    if author_node is None:
        author_node = profile_node.find('h3', {'class': 'author-name'})

    author_display_name = author_node.text.strip()
    author_img = profile_node.find('img', src=True)
    src = author_img.get('src')
    assert src is not None, str(profile_node)
    srcset = author_img.get('srcset')
    author_avatar = {'default': src}
    if srcset:
        for each in srcset.split(','):
            avatar_url, avatar_size = [part.strip() for part in each.strip().split()]
            author_avatar[avatar_size] = avatar_url
    author_name = {
        'David Greaves / lbt': 'David Greaves'
    }.get(author_display_name, author_display_name)
    logger.debug(author_name)

    # author_name_node = profile_node.find(None, {'class': 'author-name'})
    description_node = author_node.find_next_sibling('p')
    if description_node is None:
        description_node = author_node.parent.find_next_sibling('p')
    for img in description_node.find_all('img'):  # emoji img
        alt = img.get('alt')
        if alt:
            img.replace_with(alt)
    description = description_node.prettify()

    result['author'] = {
        'name': author_name,
        'display_name': author_display_name,
        'avatar': author_avatar,
        'description': description,
    }
    result['source_authors'] = [
        {
            'name': author_name,
            'display_name': author_display_name,
            'avatar': author_avatar,
            'description': description,
        }
    ]

    blog = soup.find(None, {'class': 'blog-wrap'})
    title = blog.find('h1').text.strip()
    result['title'] = title

    imgs = []
    for img in blog.find_all('img'):
        small = img.get('src')
        parent = img.parent
        if parent.name == 'a':
            big = parent.get('href')
            if big == 'javascript:;':
                big = None
        else:
            big = None

        if small == big:
            small = None

        imgs.append((small, big))

    result['imgs'] = imgs

    result['cover'] = _find_jolla_cover(url)
    result['content'] = html2text.html2text(str(blog))

    return result


def _find_jolla_cover(url):
    page = 1
    while True:
        if page == 1:
            url_page = 'https://blog.jolla.com/'
        else:
            url_page = 'https://blog.jolla.com/page/%s/' % page
        logger.debug('looking %s', url_page)

        resp = requests.get(url_page)
        if resp.status_code >= 400:
            logger.critical('%s not found', url_page)
            return None

        soup = mk_soup(url_page)
        for article in soup.find_all('article'):
            right = article.find(None, {'class': 'cont-right'})
            a_tag = right.find('a')
            href = a_tag.get('href')
            if href == url:
                return a_tag.find('img').get('src')

        page += 1


def save(dic, folder):
    content = dic.pop('content')
    with open(os.path.join(folder, 'meta_raw.json'), 'w', encoding='utf-8') as f:
        json.dump(dic, f, indent=2, ensure_ascii=False)

    meta = {
        'slug': _guess_fname(urlparse(dic['url']).path),
        'source_title': dic['title'],
        'source_author_info': dic['author'],
        'source_author': dic['author']['name'],
        'source_authors': [dic['author']['name']],
        'source_type': 'translation',
        'source_url': dic['url'],
        'tags': dic['tags'],
        'author': dic['author']['name'],
        'cover': dic['cover'],
        'headerimg': dic['banner'],
    }
    url_to_path = []

    with open(os.path.join(folder, 'content.md'), 'w', encoding='utf-8') as f:
        f.write(content)

    for key in ('cover', 'banner'):
        url = dic[key]
        if not url:
            continue
        ext = os.path.splitext(url)[-1]
        path = os.path.join(folder, key + ext)

        url_to_path.append((url, path))

    for small, big in dic['imgs']:

        if big and big not in (dic['cover'], dic['banner']):
            fname = _guess_fname(big)
            url_to_path.append((big, os.path.join(folder, fname)))

        if small and small not in (dic['cover'], dic['banner']):
            fname = _guess_fname(small)
            if big:
                big_name = _guess_fname(big)
                if big_name == fname:
                    parts = os.path.splitext(fname)
                    fname = '-small'.join(parts)

            url_to_path.append((small, os.path.join(folder, fname)))

    author_meta = dict(dic['author'])
    author_meta.pop('avatar')
    author_meta['avatar'] = avatar_fileinfo = {}
    for size, url in dic['author']['avatar'].items():
        url_path = urlparse(url).path
        filename = os.path.split(url_path)[-1]
        target_file = os.path.join(folder, 'author', filename)
        url_to_path.append((url, target_file))
        avatar_fileinfo[size] = filename

    for url, path in url_to_path:
        if os.path.isfile(path):
            logger.info('%s exists, skip', path)
            continue
        logger.debug('%s -> %s', url, path)
        target_folder = os.path.dirname(path)
        if not os.path.isdir(target_folder):
            os.makedirs(target_folder)

        _fname, _headers = urlretrieve(url, path)
        logger.info(_fname)

    with open(os.path.join(folder, 'author', 'meta.json'), 'w', encoding='utf-8') as f:
        # print(author_meta)
        json.dump(author_meta, f, indent=2, ensure_ascii=False)
    with open(os.path.join(folder, 'meta.json'), 'w', encoding='utf-8') as f:
        json.dump(meta, f, indent=2, ensure_ascii=False)


def _guess_fname(url):
    parts = url.split('/')
    return parts[-1] if parts[-1] else parts[-2]


def parse(url):
    parsed = urlparse(url)
    netloc = parsed.netloc
    if netloc.startswith('blog.jolla.'):
        return parse_jolla(url)
    if netloc.startswith('reviewjolla.blogspot.'):
        return parse_reviewjolla(url)

    raise ValueError('%r not suport' % url)


if __name__ == '__main__':
    import docpie
    from pprint import pformat
    import os

    logging.basicConfig(level=logging.DEBUG)
    logging.getLogger('docpie').setLevel(logging.CRITICAL)
    logging.getLogger('requests').setLevel(logging.CRITICAL)

    args = docpie.docpie(__doc__)
    url = args['<url>']
    result = parse(url)

    logger.info('\n' + pformat(result))

    save_dir = args['<save-dir>']
    if save_dir:
        folder = os.path.expanduser(save_dir)
        if not os.path.isdir(folder):
            os.makedirs(folder)
        save(result, folder)
