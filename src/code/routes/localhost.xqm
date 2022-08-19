module namespace _ = 'http://localhost/#routes';
import module namespace cmark = "http://xq/#cm_dispatch";

declare
  %rest:path('/localhost/index')
  %rest:GET
  %rest:produces('text/html')
  %output:method('html')
function _:localhost_item(){
  let $dbBase := request:scheme() || ':/'
  let $domain := tokenize(request:path(),'/')[2]
  let $dbDocURI :=  $dbBase || request:path()
  let $dbCollectionURI :=  $dbBase || '/' || $domain
  let $dbLayoutURI := $dbCollectionURI  || '/layout'
  let $dbLayoutConstructor := $dbLayoutURI => db:get()
  (: let $dbCollection :=  $dbCollectionURI => uri-collection() :)
  return (
  _:resHeader( map { 'status': '200', 'message': 'OK' } ),
element html {
  attribute lang {'en'},
  _:index_head(map { 'title': 'xqerl glider docs'}),
   element body{
    element header { attribute role { "banner" }, element h1 { 'xqerl glider docs' }},
    element main { 
      element article { 
      element ul {
        attribute hx-boost {'true'},
        attribute role {'list'},
        element li { 
          element a {
            attribute href {'/docs/intro'},
            text {'Introduction'}}},
            element li { 
              element a {
              attribute href {'/docs/build'},
              text {'The Development Build Cycle'}}},
        element li { 
          element a {
            attribute href {'/docs/proxy-conf'},
            text {'Reverse Proxy Configuration'}}},
        element li { 
          element a {
            attribute href {'/docs/xqerl-database'},
            text {'Working with Xqerl Databases'}}},
       element li { 
          element a {
            attribute href {'/docs/xqerl-code'},
            text {'Working with XQuery Xqerl Code'}}},

      element li { 
            element a {
              attribute href {'/docs/static-assets'},
              text {'Working with Static Assets'}}}}
(:
     element div {  
        attribute id { 'demo' },
        element script{ "AsciinemaPlayer.create('/assets/casts/xqerl-up-and-flying.cast', document.getElementById('demo'));" }
      }
:)
      }}}}
 )};

declare
  %rest:path('/localhost/docs/{$ITEM}')
  %rest:GET
  %rest:produces('text/html')
  %output:method('html')
function _:localhost_item( $ITEM ){
let $dbBase := request:scheme() || ':/'
let $domain := tokenize(request:path(),'/')[2]
let $dbDocURI :=  $dbBase || request:path()
return 
if (doc-available( $dbDocURI ))
then
element body{
  element header {
    attribute role { "banner" },
    element h1 { 'xqerl glider docs' }},
  element main { $dbDocURI => doc() => cmark:dispatch()},
  element footer { 'footer placeholder'}}
else  ()
};


declare function _:resHeader( $m as map(*) ) as element() {
element rest:response {
  element http:response {
  attribute status { $m?status },
  attribute message {$m?message },
  element http:header {
    attribute name {'Content-Type'},
    attribute value {'text/html'}}}}
};


declare function _:index_head( $m as map(*) ) as element() { 
element head {
  element meta {
    attribute charset {'UTF-8'}},
  element meta {
    attribute name { 'viewport'},
    attribute content { 'width=device-width, initial-scale=1'}},
  element title { $m?title },
    element link { 
      attribute rel {"icon"},
      attribute href { "/assets/images/favicon.ico"},
      attribute sizes {"any"}
    },
  element link { 
    attribute rel {'stylesheet'},
    attribute href {'https://unpkg.com/dracula-prism/dist/css/dracula-prism.min.css'},
    attribute type {'text/css'}},
  element link { 
    attribute rel {'stylesheet'},
    attribute href {'/assets/styles/index.css'},
    attribute type {'text/css'}},
  element script { 
    attribute src {'/assets/scripts/htmx.min.js'}},
  element script { 
    attribute src {'/assets/scripts/asciinema-player.min.js'}},
  element script { 
    attribute src {'/assets/scripts/prism.js'}},
  element script { 
    text {'htmx.onLoad(function(){Prism.highlightAll();})'}}}
};




declare function _:header( $m as map(*) ) as element() { 
  element header {
    attribute role { "banner" },
    element h1 { $m?header_title }}
};
