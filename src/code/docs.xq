import module namespace cmark = "http://xq/#cm_dispatch";
declare variable $src external;
(: documentation generator :)
try {
let $dbCollection := function( $uri ){
  let $dbPathTokens := $uri => tokenize('/')
  let $dbPathTokensCount := $dbPathTokens => count()
  return
   $dbPathTokens => remove($dbPathTokensCount ) => string-join('/')
  }

let $dbItem := function ( $uri ){
  let $dbPathTokens := $uri => tokenize('/')
  let $dbPathTokensCount := $dbPathTokens => count()
  return
  $dbPathTokens => subsequence($dbPathTokensCount)
}

let $dbDomain := function ( $uri ){
  let $dbPathTokens := $uri => tokenize('/')
  let $dbPathTokensCount := $dbPathTokens => count()
  return
  $dbPathTokens => subsequence(3,1)
}

let $getContent := function( $m as map(*) ) as map(*){
   let $xDoc :=  $m?document
   let $key := 'content'
   let $value := $xDoc => cmark:dispatch()
   return 
   if ( $value instance of item() ) 
   then map:put($m, $key, $value)
   else map:put($m,'problem','unable to parse content')
}

let $getFrontMatter := function( $map as map(*)) as map(*){
  if ( map:contains($map, 'problem') )
  then ( $map )
  else
  let $xDoc :=  $map?document
  let $fm  := $xDoc => cmark:frontmatter()
  return
  if ( $fm instance of map(*) ) 
  then map:merge(($map, $fm ))
  else map:put( $map, 'problem', 'unable to get frontmatter')
}

let $pageLayout := function( $map as map(*)) {
if ( map:contains( $map, 'problem') )
then ``[  TODO ]``
else 
let $dbItemPath := concat( $map?collection ,'/',$map?layout ) 
let $dbCollection :=  $map?collection => uri-collection()
return 
if ( $dbItemPath = $dbCollection ) then
  let $dbFunctionItem := $dbItemPath => db:get()
  return 
    if ( $dbFunctionItem instance of function(*) ) 
    then $map => $dbFunctionItem()
    else ``[
- xqerl database XDM item: `{$dbItemPath}` is not a XDM function
-  a XDM function item in needed to render this page
   ]``
else ``[
 - xqerl database does not contain XDM item: `{$dbItemPath}`
-  this XDM function item is need to render this page
 ]``
}

(:
let $pageOut := function( $path ) {
 let $file :=  file:write-text#2("priv/static/assets/" || $path || ".html"
,  ?)
}
:)

let $scheme := 'http://'
let $dbPath :=   $src =>  replace('.md','') => substring-after('/data/')
let $fileOut := "priv/static/assets/" || $dbPath || ".html"
let $uri := $scheme || $dbPath
let $resMap := 
    map{'uri': $uri, 
        'domain': $dbDomain($uri),
        'collection' : $dbCollection($uri), 
        'item':  $dbItem($uri)}

let $htm := 
  if ( fn:doc-available( $uri  )) 
  then
    let $key := 'document'
    let $value := $uri => doc()
    return
    map:put($resMap ,$key, $value) =>
    $getContent() =>
    $getFrontMatter() => 
    $pageLayout() =>
    serialize(map{"method": "html"})
  else error()
let $dir := file:create-dir("priv/static/assets" )
let $file := "priv/static/assets/index.html"
let $wrt := file:write-text( $file, $htm )
return ( $file ) 
} catch * { ``[ caught error ]`` }
