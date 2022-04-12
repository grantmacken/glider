declare variable $src external;
try {
``[
try { 
let $path :=  "http://`{ $src => substring-after('/data/') => replace('.xq$','') }`"
let $func := `{  if (file:is-file( string($src)) ) then file:read-text(string($src)) else (error((), 'no file')) }`
return
 if ( $func instance of function(*) )
 then ( true(),db:put( $func, $path ))
 else false()
} catch * { false() }
]`` => serialize(map{"method": "text"})
} catch * { false() }
