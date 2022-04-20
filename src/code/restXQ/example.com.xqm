module namespace _ = 'http://example.com/#routes';
declare namespace cm ="http://commonmark.org/xml/1.0";
import module namespace cmark = "http://xq/#cm_dispatch";

declare
  %rest:path("/example.com/{$ITEM}")
  %rest:GET
  %rest:produces("text/html")
  %output:method("html")
function _:erewhon($ITEM){
  try {
  let $uri := 'http://example.com/' || $ITEM
  let $resMap := 
      map{'uri': $uri, 
          'domain': 'example.com',
          'collection' : _:dbCollection($uri), 
          'item':  _:dbItem($uri)}
  return
    if ( fn:doc-available( $uri  )) 
    then
      let $key := 'document'
      let $value := $uri => doc()
      return
        map:put($resMap ,$key, $value) =>
        _:getContent() =>
        _:getFrontMatter() => 
        _:pageLayout()
    else _:notFound($resMap) 
  } catch * {(
    _:svrErr(
		map { 'uri': 'http://' || 'example.com:/' || $ITEM, 
             'problem' : 'xQuery dynamic error',
             'code' : $err:code, 
             'description' : $err:description
             } 
      )
   )}
};

declare function _:resHeader( $map as map(*)) as element() {
element rest:response {
  element http:response {
  attribute status { $map?status },
  attribute message {$map?message },
  element http:header {
    attribute name {'Content-Type'},
    attribute value {'text/html'}
    }
  }
}
};

declare function _:getContent( $map as map(*) ) as map(*){
 let $xDoc :=  $map?document
 let $key := 'content'
 let $value := $xDoc => cmark:dispatch()
 return 
   if ( $value instance of item() ) 
   then map:put($map, $key, $value)
   else map:put($map,'problem','unable to parse content')
};

declare function _:getFrontMatter( $map as map(*)) as map(*){
if ( map:contains($map, 'problem') )
then ( $map )
else
let $xDoc :=  $map?document
let $fm  := $xDoc => cmark:frontmatter()
return
if ( $fm instance of map(*) ) 
then map:merge(($map, $fm ))
else map:put( $map, 'problem', 'unable to get frontmatter')
};

declare function _:pageLayout( $map as map(*)) {
if ( map:contains( $map, 'problem') )
then $map  => _:svrErr()
else 
let $dbItemPath := concat( $map?collection ,'/',$map?layout ) 
let $dbCollection :=  $map?collection => uri-collection()
let $defaultLayout := concat($map?collection,'/default_layout' )
return
if ( $dbItemPath = $dbCollection ) then
  let $dbFunctionItem := $dbItemPath => db:get()
  return 
    if ( $dbFunctionItem instance of function(*) ) 
    then ( _:resHeader( map { 'status': '200', 'message': 'OK' } ),$map => $dbFunctionItem())
    else _:svrErr( map:put($map,'problem',``[
 - xqerl database XDM item: `{$dbItemPath}` is not a XDM function
-  a XDM function item in needed to render this page
 ]``))
else (: try the default layout function for collection:)
if ( $defaultLayout = $dbCollection ) then
  let $dbFunctionItem := $defaultLayout  => db:get()
  return 
    if ( $dbFunctionItem instance of function(*) ) 
    then ( _:resHeader( map { 'status': '200', 'message': 'OK' } ),$map => $dbFunctionItem())
    else 
    _:svrErr( map:put($map,'problem',``[
 - xqerl database XDM item: `{$defaultLayout}` is not a XDM function
-  a XDM function item in needed to render this page
 ]``))
else (: give up :)
_:svrErr( map:put($map,'problem', 
``[
 - xqerl database does not contain XDM item: `{$dbItemPath}`
-  this XDM function item is need to render this page
 ]``))
};

declare function _:dbCollection( $uri ){
let $dbPathTokens := $uri => tokenize('/')
let $dbPathTokensCount := $dbPathTokens => count()
return
 $dbPathTokens => remove($dbPathTokensCount ) => string-join('/')
};

declare function _:dbItem( $uri ){
let $dbPathTokens := $uri => tokenize('/')
let $dbPathTokensCount := $dbPathTokens => count()
return
$dbPathTokens => subsequence($dbPathTokensCount)
};

declare function _:notFound( $map as map(*) ) as item()+ {(
_:resHeader( map { 'status': '404', 'message': 'Not Found' }),
_:problemBody( map:put($map, 'problem', ``[ could not find document at `{ $map?uri }` ]``))
)};

declare function _:svrErr( $map as map(*)) as item()+ {(
_:resHeader( map { 'status': '500', 'message': 'Internal Server Error' }),
 _:problemBody( map:put($map,'problem_title','server error: xqerl thrown error') )
)};

declare function _:problemBody( $map as map(*)) {
element html {
  attribute lang {'en'},
  element head {
    element title { 'Huston We Have A Problem' }
  },
  element body {
    element p { 'erewhon: we have a problem' },
    element dl {(
      if ( map:contains($map, 'uri')) then (element dt { 'uri' }, element dd { $map?uri}) else (),
      if ( map:contains($map, 'problem')) then (element dt { 'problem' }, element dd { $map?problem}) else (),
      if ( map:contains($map, 'code')) then (element dt { 'code' }, element dd { $map?code}) else (),
      if ( map:contains($map, 'description')) then (element dt { 'description' }, element dd { $map?description}) else ()
    )}
  }
}
};
