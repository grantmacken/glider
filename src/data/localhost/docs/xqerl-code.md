#  xqerl code

The 'src/code' files contain XQuery modules.

```
src
└── code
    ├── cm_dispatch.xqm
    ├── db-store.xq
    └── restXQ
        └── example.com.xqm
```

XQuery defines two types of [modules](https://www.w3.org/TR/xquery-31/#doc-xquery31-Module)
 1. library modules: by convention we give these a `.xqm` extension
 2. main modules:  by convention we give these a `.xq` extension

 ## Compiling XQuery Library Modules

 When we invoke `make` the xQuery *library modules* with extension `.xqm` 
 in the src/code directory are compiled by xqerl into beam files to run on the 
 [BEAM](https://en.wikipedia.org/wiki/BEAM_(Erlang_virtual_machine)beam. 

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

## RestXQ Library Modules

Like [other](https://docs.basex.org/wiki/RESTXQ) XQuery application servers, the xqerl code server has a restXQ implemention.
In this project restXQ XQuery library modules are in the `src/code/restXQ` directorqy,


RestXQ library modules on a basic level associates HTTP requests with XQuery functions.
In our pod these HTTP requests are filtered via nginx acting as a reverse proxy.
Before the URI is poxy passed to the xqerl XQuery application server we rewrite the location path 
so it includes the **dns domain** in the request.


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

1. `http://example.com/` will be proxy passed as `http://localhost:8081/example.com/index`
2. `http://markup.nz/`   will be proxy passed as `http://localhost:8081/markup.nz/index`

Note: the nginx rewrite is domain based, and no adjustment to the nginx conf files is need when we swap out domains. 

When we develop restXQ routes for our domains each domain gets its own restXQ library module.

```
src
└── code
    └── restXQ
        ├── example.com.xqm
        └── markup.nz.xqm
```

1. `http://example.com` source module `src/code/restXQ/example.com.xqm`
2. `http://markup.nz` source module `src/code/restXQ/markup.nz.xqm`

In each domain based restXQ module the `rest:path` will start with the 'domain'


```
module namespace _ = 'http://example.com/#routes';
declare
  %rest:path("/example.com/{$ITEM}")
  %rest:GET
  %rest:produces("text/html")
  %output:method("html")
function _:erewhon($ITEM){
...
```

 ## Web Request URI and Xqerl Database URI

A URI can be broken down into is constituent parts, a scheme, an authority and a path
As Xqerl database URI are also based on a URI scheme-authority-path pattern,
we can put data into the xqerl database that we know will share a common 'authority-path' pattern with a web request URI
If we put data item into the xqerl database URI 'http://example.com/{path-to-some-data}'
we can say, the data is *hosted* by 'example.com' and our restXQ functions will know this.

1. nginx receives: https://example.com
2. nginx rewrite proxy pass: http://localhost:8081/example.com/index
3. xqerl restXQ path: /example.com/{$ITEM} invokes XQuery function
4. XQerl function can associate request URI pattern with a db identifier because they share a common 'authority-path' pattern

## Compile Module Order

When we invoke `make` the restXQ modules will compile after other XQuery library modules.
We do this because the restXQ library will often import other libraries, 
so we need to compile these libraries first.
