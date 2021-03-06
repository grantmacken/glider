#  xqerl database 

The xqerl database volume contains hierarchical collections of 
1. XDM items as defined in the [XQuery and XPath Data Model](https://www.w3.org/TR/xpath-datamodel-31).
2. link items pointing to a container file location  

Invoking the Make target `make` will parse and load structured markup data sources 
from the`src/data` directory into the xqerl database as XDM items. 

## Building From Data Sources

Structured markup data sources are parsed and loaded into the xqerl database as [XDM](https://www.w3.org/TR/xpath-datamodel-31) items
These XDM database items include document-nodes, maps, arrays, and even functions.

 - a XML text when parsed is stored as an `instance of document-node()`
 - JSON object when parsed stored as an `instance of map(*)`
 - JSON array when parsed stored as an `instance of array(*)`
 - CSV text when parsed stored as an `instance of array(*)`
 - XQuery main module function:  when compiled stored as an `instance of function(*)`

When items are stored as XDM items into the xqerl database the query power of XQuery 3.1 is amplified. 
XQuery was originally designed to work with structured data in the context of a XML database. With XQuery 3.1 the xPath 
XQuery data model is extended to include maps and arrays, so it is important that these items can be queried from the database.

Prior to storing, the data can be linted, checked and preprocessed.
Some examples:

 - **XML text**: well formed check (xmllint) then store as document-node item
 - **JSON** well formed check (jq) then store as map or array item
 - **markdown** text: preprocess with cmark then store as document-node
 - **XQuery main module function** compile check then store as function

 Our example data sources

```
src
  ├── data
  │   └── example.com
  │       ├── default_layout.xq => into db - stored as XDM function item
  │       └── index.md => into db - stored as XDM document-node
```

When the source file becomes a XDM item stored in the the database,
*by convention* the database item identifier(URI) will have no extension.  

```
src
  ├── data
  │   └── example.com
  │       ├── default_layout.xq => db identifier: http://example.com/default_layout
  │       └── index.md       => db identifier: http://example.com/index
```

## unparsed text

TODO

<!--
 - If the data source is not marked up then this data can be stored as unparsed text. 
 - If the data source is binary then a link item pointing to the file location can be stored in the database.
-->

## link items

TODO

## Collection Lists and Item Retieval

The XQuery expression to get a list of URI in the  'example.com' database

```
'http://example.com' => uri-collection() => string-join('&#10;')
```

This expression needs to run in the context of the running container instance

```
 podman exec xq xqerl eval "xqerl:run(\"'http://example.com' => uri-collection() => string-join('&#10;') \")"
```


<!--

Note: The `src/data/{DNS_DOMAIN}` directory structure is just a build process convenience. 
There other ways of getting data into the database and you don't have to follow 
the 'no extension' convention.

Note: The database db identifier does not represent a web resource but a xqerl database resource.
- web URI: `http://example.com/index` a web server resource hosted by 'example.com'
- db URI:  `http://example.com/index` a database XDM item in the 'example.com' xqerl database

A URI can be broken down into is constituent parts, a scheme, an authority and a path
A web resources *authority* is a dns domain or IP address.
For this project our db *authority* in the URI is always just a 'dns domain'.
-->
<!--
## Listing Database Items 

Once the data is in the database you can see what 
data is stored under our development dns domain.

### Using A XQuery Expression To List Items

 ```



### Using GET

Any HTTP request URI with path segment starting with `/db`, 
the xqerl XQuery application server will respond with the enabled db REST service.

In our pod, all HTTP and HTTPS web request URI locations are filtered via nginx.
On the web we filter the `/db/` location so only GET requests are let through.

```
location /db {
  limit_except GET {
    allow 192.168.1.0/32;
    deny  all;
  }
  more_set_headers    "Server: xqerl";
  proxy_http_version 1.1;
  rewrite ^/db/?(.*)$ /db/$domain break;
  proxy_pass http://localhost:8081;
}
```

-->







