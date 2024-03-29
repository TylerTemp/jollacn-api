import bleach
import html2text
import logging

import markdown
# import markdown_newtab
import nlcontinuous
import md_video
# import underline
# from ..markdown_gridtables import mdx_grid_tables
# from amazedown_patched import \
#     link_icon_tab, link_image_block, image_block, \
#     list_gallery, list_avg_gallery, quote_by

logger = logging.getLogger('MARKDOWN')
logger.setLevel(logging.CRITICAL)

# __all__ = ['md2html', 'html2md', 'escape']

extend = [
    # nlcontinuous.makeExtension(),
    # md_video.makeExtension(crossorigin="anonymous"),
    # define attributes, {: #someid .someclass somekey='some value' }
    # 'markdown.extensions.attr_list',
    # use fenced code block by 3 back quotes
    'markdown.extensions.fenced_code',
    # footnotes, text[^name]\n\n[^name]: explain
    'markdown.extensions.footnotes',
    'markdown.extensions.tables',
    # new line to <br />
    # 'markdown.extensions.nl2br',
    # code highlight, and <pre><code></code></pre> added
    'markdown.extensions.codehilite',
    # ++text++ for <ins>text</ins> and ~~text~~ for <del>text</del>
    # 'del_ins',
    # add '_blank' for links
    # markdown_newtab.makeExtension(),
    # table extend
    # mdx_grid_tables.makeExtension(),
    # replace <<, >> , ..., ect to HTML entity equivalents
    # 'markdown.extensions.smarty',
    # Table of Contents, https://pythonhosted.org/Markdown/extensions/toc.html
    # add menu in table at the head by [TOC] at the top
    'markdown.extensions.toc',
    # convert any [[text]] to <a href="/text/" class="wikilink">text</a>
    # 'markdown.extensions.wikilinks',
    # https://pythonhosted.org/Markdown/extensions/admonition.html
    # !!! danger
    #     some text
    'markdown.extensions.admonition'
]

# 'a', 'abbr', 'acronym', 'b', 'blockquote', 'code', 'em',
# 'i', 'li', 'ol', 'strong', 'ul'
white_tags = list(bleach.ALLOWED_TAGS)
white_tags.extend(('span',
                   'table', 'caption', 'thead', 'tbody', 'tfoot',
                   'tr', 'td', 'th',
                   'ins', 'del', 'center', 'pre', 'u',
                   'em', 'strong', 'code', 'del', 'abbr',
                   'h2', 'h3', 'h4', 'h5', 'h6',
                   'dl', 'dt', 'dd',
                   'sup', 'sub',
                   'quoteblock',
                   'video', 'source'))

attributes = {'*': ('href', 'src', 'title', 'name', 'alt', 'height', 'length'
                    'border', 'text-align', 'type', 'controls', 'markdown')}

# _md = markdown.Markdown(smart_emphasis=False, safemode=False,
#                         output_format='html5', extensions=extend)
#
# md2html = _md.convert
def md2html(md, smart_emphasis=False, safemode=False, extensions=None):
    global extend
    if extensions is None:
        extensions = extend
    else:
        extensions.extend(extend)

    return markdown.markdown(md, output_format='html5',
                             smart_emphasis=smart_emphasis,
                             safemode=safemode,
                             extensions=extensions)

_parser = html2text.HTML2Text()
_parser.body_width = 0
html2md = _parser.handle


def escape(content):
    return bleach.clean(content, tags=white_tags, attributes=attributes)


def jolla_md_to_html(md):
    return md2html(
            md,
            extensions=[
                nlcontinuous.makeExtension(),
                md_video.makeExtension(crossorigin="anonymous"),
                # define attributes, {: #someid .someclass somekey='some value' }
                # 'markdown.extensions.attr_list',
                # use fenced code block by 3 back quotes
                'markdown.extensions.fenced_code',
                # footnotes, text[^name]\n\n[^name]: explain
                'markdown.extensions.footnotes',
                'markdown.extensions.tables',
                # new line to <br />
                # 'markdown.extensions.nl2br',
                # code highlight, and <pre><code></code></pre> added
                'markdown.extensions.codehilite',
                # ++text++ for <ins>text</ins> and ~~text~~ for <del>text</del>
                # 'del_ins',
                # add '_blank' for links
                # markdown_newtab.makeExtension(),
                # table extend
                # mdx_grid_tables.makeExtension(),
                # replace <<, >> , ..., ect to HTML entity equivalents
                # 'markdown.extensions.smarty',
                # Table of Contents, https://pythonhosted.org/Markdown/extensions/toc.html
                # add menu in table at the head by [TOC] at the top
                'markdown.extensions.toc',
                # convert any [[text]] to <a href="/text/" class="wikilink">text</a>
                # 'markdown.extensions.wikilinks',
                # https://pythonhosted.org/Markdown/extensions/admonition.html
                # !!! danger
                #     some text
                # 'markdown.extensions.admonition'
                # underline.makeExtension(tag='strong', cls='underline'),
                # image_block.makeExtension(),
                # link_image_block.makeExtension(),
                # link_icon_tab.makeExtension(host='notexists.top'),
                # list_gallery.makeExtension(),
                # list_avg_gallery.makeExtension(),
                # quote_by.makeExtension(),
            ])

if __name__ == '__main__':
    import sys

    # if len(sys.argv) <= 2:
    #     print('reading')
    #     content = sys.stdin.read()
    # else:
    #     print(len(sys.argv))
    content = sys.argv[1]

    html = jolla_md_to_html(content)
    print(html)
