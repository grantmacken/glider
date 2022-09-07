module namespace _ = 'http://localhost/#routes';
declare namespace cm ="http://commonmark.org/xml/1.0";
import module namespace cmark = "http://xq/#cm_dispatch";

declare
%rest:path('/localhost/index')
%rest:GET
%rest:produces('text/html')
%output:method('html')
function _:localhost_index(){
try {
  let $dbBase := request:scheme() || ':/'
  let $domain := tokenize(request:path(),'/')[2]
  
  let $dbDocURI :=  $dbBase || request:path()
  let $dbDoc :=  
    if ( $dbDocURI => doc-available() )
    then  $dbDocURI => doc()
    else error( QName(
      'http://localhost', 'NO_DOCUMENT' ),
      ``[ Could not resolve document URI: `{$dbDocURI}` ]``)

  let $dbCollectionURI :=  $dbBase || '/' || $domain
  let $dbResponseHeaderURI := $dbCollectionURI  || '/response_header'
  let $dbResponseHeaderConstructor :=
      if ( $dbResponseHeaderURI =  uri-collection($dbCollectionURI) ) 
      then $dbResponseHeaderURI => db:get()
      else error( QName( 'http://localhost', 'NO_RESPONSE_HEADER_FUNCTION' ), 
                         ``[ Could not resolve response header URI: `{$dbResponseHeaderURI}` ]``)

  let $dbLayoutURI := $dbCollectionURI  || '/layout'
  let $dbLayoutConstructor := 
    if ( $dbLayoutURI =  uri-collection($dbCollectionURI) ) 
    then $dbLayoutURI => db:get()
    else error( QName( 
        'http://localhost', 'NO_LAYOUT_FUNCTION' ),
        ``[ Could not resolve layout URI: `{$dbLayoutURI}` ]``)

  let $Map := $dbDoc => 
              cmark:frontmatter() =>
              map:put( 'content',$dbDoc => cmark:dispatch()   )
  return (
  $dbResponseHeaderConstructor(map { 'status': '200', 'message': 'OK' } ),
  $dbLayoutConstructor( $Map )
 )
  } catch * {
   let $Map := map { 'status': '404', 'message': 'Not Found', 'code': $err:code, 'description' : $err:description }
  return _:problem( $Map) 
  }
};

declare
  %rest:path('/localhost/articles/{$ITEM}')
  %rest:GET
  %rest:produces('text/html')
  %output:method('html')
function _:localhost_articles( $ITEM ){
try {
  let $dbBase := request:scheme() || ':/'
  let $domain := tokenize(request:path(),'/')[2]
  
  let $dbDocURI :=  $dbBase || request:path()
  let $dbDoc :=  
    if ( $dbDocURI => doc-available() )
    then  $dbDocURI => doc()
    else error( QName(
      'http://localhost', 'NO_DOCUMENT' ),
      ``[ Could not resolve document URI: `{$dbDocURI}` ]``)

  let $dbCollectionURI :=  $dbBase || '/' || $domain
  let $dbResponseHeaderURI := $dbCollectionURI  || '/response_header'
  let $dbResponseHeaderConstructor :=
      if ( $dbResponseHeaderURI =  uri-collection($dbCollectionURI) ) 
      then $dbResponseHeaderURI => db:get()
      else error( QName( 'http://localhost', 'NO_RESPONSE_HEADER_FUNCTION' ), 
                         ``[ Could not resolve response header URI: `{$dbResponseHeaderURI}` ]``)

  let $dbLayoutURI := $dbCollectionURI  || '/layout'
  let $dbLayoutConstructor := 
    if ( $dbLayoutURI =  uri-collection($dbCollectionURI) ) 
    then $dbLayoutURI => db:get()
    else error( QName( 
        'http://localhost', 'NO_LAYOUT_FUNCTION' ),
        ``[ Could not resolve layout URI: `{$dbLayoutURI}` ]``)

  let $Map := $dbDoc => 
              cmark:frontmatter() =>
              map:put( 'content',$dbDoc => cmark:dispatch()   )
  return (
  $dbResponseHeaderConstructor(map { 'status': '200', 'message': 'OK' } ),
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
