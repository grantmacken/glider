define index_md
 <!--
 title: Alter Me 
 layout: default_layout
-->

## A boilerplate document

The source for this page is a markdown document located in 'src/data/$(DNS_DOMAIN)/index.md'

The source is **stored** in the xqerl database as a
[cmark](https://github.com/commonmark/cmark) converted XML document.

The frontmatter section is a HTML comment block at the 
start of the document

Page 'layout' can be specified in the frontmatter.
If no page layout is specified then a default layout will be used.
Layout refers to xQuery function item **stored** in the xqerl database.
The layout source is 'src/data/$(DNS_DOMAIN)/default_layout.xq'

The xqerl database can store any XDM item. 

endef

