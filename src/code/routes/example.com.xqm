module namespace _ = 'http://example.com/#routes';
declare namespace cm ="http://commonmark.org/xml/1.0";
import module namespace cmark = "http://xq/#cm_dispatch";

declare
%rest:path('/example.com/index')
%rest:GET
%rest:produces('text/html')
%output:method('html')
function _:index(){
try {
  let $dbBase := request:scheme() || ':/'
  let $domain := tokenize(request:path(),'/')[2]
  let $dbDocURI :=  $dbBase || request:path()
  let $dbDoc :=  
    if ( $dbDocURI => doc-available() )
    then  $dbDocURI => doc()
    else error( QName(
      'http://example.com', 'NO_DOCUMENT' ),
      ``[ Could not resolve document URI: `{$dbDocURI}` ]``)
  let $dbCollectionURI :=  $dbBase || '/' || $domain

  let $dbLayoutURI := $dbCollectionURI  || '/layout'
  let $dbLayoutConstructor := 
    if ( $dbLayoutURI =  uri-collection($dbCollectionURI) ) 
    then $dbLayoutURI => db:get()
    else error( QName( 
        'http://example.com', 'NO_LAYOUT_FUNCTION' ),
        ``[ Could not resolve layout URI: `{$dbLayoutURI}` ]``)

  let $dbAssetsURI := $dbCollectionURI  || '/assets'
  let $dbAssetsMap := 
    if ( $dbAssetsURI =  uri-collection($dbCollectionURI) ) 
    then $dbAssetsURI => db:get()
    else error( QName( 
        'http://example.com', 'NO_ASSETS_MAP' ),
        ``[ Could not resolve assets URI: `{$dbAssetsURI}` ]``)

  let $Map := $dbDoc => 
              cmark:frontmatter() =>
              map:put( 'content',$dbDoc => cmark:dispatch()) =>
              map:put ( 'assets', $dbAssetsMap )
  return (
  _:response_header(map { 'status': '200', 'message': 'OK' } ),
  $dbLayoutConstructor( $Map )
 )
  } catch * {
   let $Map := map { 'status': '404', 'message': 'Not Found', 'code': $err:code, 'description' : $err:description }
  return _:problem( $Map) 
  }
};

declare
  %rest:path('/example.com/articles/{$ITEM}')
  %rest:GET
  %rest:produces('text/html')
  %output:method('html')
function _:articles( $ITEM ){
try {
  let $dbBase := request:scheme() || ':/'
  let $domain := tokenize(request:path(),'/')[2]
  
  let $dbDocURI :=  $dbBase || request:path()
  let $dbDoc :=  
    if ( $dbDocURI => doc-available() )
    then  $dbDocURI => doc()
    else error( QName(
      'http://example.com', 'NO_DOCUMENT' ),
      ``[ Could not resolve document URI: `{$dbDocURI}` ]``)

  let $dbCollectionURI :=  $dbBase || '/' || $domain
  let $dbLayoutURI := $dbCollectionURI  || '/layout'
  let $dbLayoutConstructor := 
    if ( $dbLayoutURI =  uri-collection($dbCollectionURI) ) 
    then $dbLayoutURI => db:get()
    else error( QName( 
        'http://example.com', 'NO_LAYOUT_FUNCTION' ),
        ``[ Could not resolve layout URI: `{$dbLayoutURI}` ]``)

  let $Map := $dbDoc => 
              cmark:frontmatter() =>
              map:put( 'content',$dbDoc => cmark:dispatch())
  return (
  _:response_header( map { 'status': '200', 'message': 'OK' } ),
  $dbLayoutConstructor( $Map )
 )
  } catch * {
   let $Map := map { 'status': '404', 'message': 'Not Found', 'code': $err:code, 'description' : $err:description }
  return _:problem( $Map) 
  }
};

declare function _:problem( $Map as map(*)) {(
element rest:response {
  element http:response {
  attribute status { $Map?status },
  attribute message {$Map?message },
  element http:header {
    attribute name {'Content-Type'},
    attribute value {'text/html'}}}}, 
element html {
  attribute lang {'en'},
  element head { element title { 'erewhon' }},
  element body {
    element p { 'erewhon: we have a problem' },
    element dl {(
      if ( map:contains($Map, 'code')) then (element dt { 'code' }, element dd { $Map?code}) else (),
      if ( map:contains($Map, 'description')) then (element dt { 'description' }, element dd { $Map?description}) else ()
    )}
  }
}
)};

declare function _:response_header( $Map as map(*)) {
element rest:response {
  element http:response {
  attribute status { $Map?status },
  attribute message {$Map?message },
  element http:header {
    attribute name {'Content-Type'},
    attribute value {'text/html'}}}}
};
