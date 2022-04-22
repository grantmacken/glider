declare variable $src external;
declare variable $uri external;
try {
``[
try { 
let $func := `{  if (file:is-file( string($src)) ) then file:read-text(string($src)) else (error((), 'no file')) }`
return
 if ( $func instance of function(*) )
 then ( true(),db:put( $func, "`{$uri}`" ))
 else false()
} catch * { false() }
]`` => serialize(map{"method": "text"})
} catch * { false() }
