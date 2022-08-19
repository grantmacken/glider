#  xqerl code

The 'src/code' files contain XQuery modules.

```shell
src
└── code
    ├── cm_dispatch.xqm
    ├── db-store.xq
    └── routes
        └── localhost.xqm
```

XQuery defines two types of [modules](https://www.w3.org/TR/xquery-31/#doc-xquery31-Module)
 1. library modules: by convention we give these a `.xqm` extension
 2. main modules:  by convention we give these a `.xq` extension

 ## Compiling XQuery Library Modules

```shell
> make code
##[ src/code/cm_dispatch.xqm ]##
"src/code/cm_dispatch.xqm:1:Info: compiled ok! http___xq_#cm_dispatch"
##[ src/code/routes/localhost.xqm ]##
"src/code/routes/localhost.xqm:1:Info: compiled ok! http___localhost_#routes"
```

 When we invoke `make` the xQuery *library modules* with extension `.xqm` 
 in the src/code directory are compiled by xqerl into beam files to run on the 
 [BEAM](https://en.wikipedia.org/wiki/BEAM_(Erlang\_virtual_machine)) 

 If the code does not compile, the beam file will NOT be created or updated.
 When you run `make` and a compile failure happens, 
 you should get a error line, showing the 
1. the error src file that failed to compile
2. the line number where the compile failed
3. the error line message

Compiled beam files are stored in the container xqerl-code volume.

## Listing Compiled XQuery Library Modules

The invoked Make target `make code-library-list`
will list the compiled library namespaces available in the 
xqerl XQuery application server.  

```shell
> make code-library-list
##[ code-library-list ##]
http://xq/#cm_dispatch
http://localhost/#routes
```

## RestXQ Library Modules

Like [other](https://docs.basex.org/wiki/RESTXQ) XQuery application servers, 
the xqerl code server has a [restXQ](https://exquery.github.io/exquery/exquery-restxq-specification/restxq-1.0-specification.html) implemention.
In this project restXQ XQuery library modules are in the `src/code/routes` directory,

RestXQ library modules on a basic level associate HTTP requests with XQuery functions.
In our pod all HTTP requests are pass thru our reverse proxy server.
The nginx reverse proxy server has its own location rewrite capablities.
The file `./src/proxy/conf/locations.conf` holds the location rewrites 

```nginx
location ~* ^/(index|index.html)?$ {
  rewrite ^/?(.*)$ /$domain/index break;
  proxy_pass http://localhost:8081;
}

location / {
  rewrite ^/?(.*)$ /$domain/$1 break;
  proxy_pass http://localhost:8081;
}
```
The above rewrite has the following effect.

1. `http://localhost/` will be proxy passed as `http://localhost:8081/localhost/index`
2. `https://example.com/` will be proxy passed as `http://localhost:8081/example.com/index`
3. `https://example.com/articles/my-article` will be proxy passed as `http://localhost:8081/example.com/articles/my-article`

Note: the nginx rewrite is domain based, and no adjustment to the nginx conf files is need when we swap out domains. 
When we develop restXQ routes for our domains each domain gets its own restXQ library module.

```shell
src
└── code
    └── routes
        ├── localhost.xqm
        └── example.com.xqm
```

In each domain based restXQ module the `rest:path` will start with the 'domain'.

```xquery
module namespace _ = 'http://example.com/#routes';
declare
  %rest:path("/example.com/index")
  ...
 function _:index(){( ... )}

declare
  %rest:path("/example.com/articles{$ARTICLE}")
  ...
function _:articles( $ARTICLE ){( ... )}
```

## Web Request URI and Xqerl Database Identifier URI

A URI can be broken down into is constituent parts, a scheme, an authority and a path.
Xqerl database URI are also based on a URI scheme-authority-path pattern.
wing this, we put data into the xqerl database that we know will share a common 'authority-path' pattern with a web request URI. 

```shell
src
├── code
│   ├── cm_dispatch.xqm # a library module that can be imported
│   └── routes  # directory to put restXQ modules 
│       └── example.com.xqm # restXQ module that serves HTTP requests for domain `example.com`
├─ data
│   └── example.com # data for database identifier `http://example.com`
│       └── docs # data for database collection identifier `http://example.com/docs`
│           ├── intro.md # data for database item identifier `http://example.com/docs/intro`
```

## Compile Module Order

When we invoke `make` the restXQ modules found in the `routes` will compile after other XQuery library modules.
We do this because the restXQ library will often import other libraries, 
so we need to compile these libraries first.
