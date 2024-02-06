"""
Usage:
    pull <url> <output_folder>
"""
import json
import urllib.parse
import docpie
import requests

args = docpie.docpie(__doc__)

print(args)

parsed = urllib.parse.urlparse(args['<url>'])
# print(parsed)
paths = parsed.path.split('/')
uri = paths[-1]
api = f'https://notexists.top/api/post/{uri}'

resp = requests.get(api)
assert resp.status_code == 200

result = resp.json()

output_folder = args['<output_folder>']
with open(f'{output_folder}/translate.md', 'w', encoding='utf-8') as f:
    f.write(f"# {result['title']} #\n\n")
    f.write(result.pop('content_md'))

with open(f'{output_folder}/description.html', 'w', encoding='utf-8') as f:
    f.write(result.pop('description'))

del result['content']
ori_tag_to_trans = {
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
    }
trans_to_ori_tag = dict((v, k) for (k, v) in ori_tag_to_trans.items())
result['tags'] = [trans_to_ori_tag.get(key, key) for key in result['tags']]

with open(f'{output_folder}/meta.json', 'w', encoding='utf-8') as f:
    json.dump(result, f, ensure_ascii=False, indent=4)
