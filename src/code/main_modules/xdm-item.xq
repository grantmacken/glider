declare namespace binary = "http://expath.org/ns/binary";
declare namespace file = "http://expath.org/ns/file";
declare variable $uri external;
declare variable $b64 external;
try {(
file:write-text( './code/main_modules/xdm_item.xq',
``[ 
try {
let $item := `{  $b64 => xs:base64Binary() => binary:decode-string() }`
return
 if ( $item instance of item() )
 then ( true(),db:put( $item, "`{$uri}`" ))
 else false()
} catch * { false()}
]``),true()
)} catch * {  false() }
