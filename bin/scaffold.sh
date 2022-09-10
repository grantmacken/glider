#!/usr/bin/env bash
set -euo pipefail
read -p "Enter your domain: " DOMAIN
read -p "Continue? (Y/N): " CONFIRM
[[ "$CONFIRM" == [yY] ]]
mkdir -p ../$DOMAIN
cp -v .env Makefile ../$DOMAIN/
pushd ../$DOMAIN || exit
ln -sf ../glider/inc . 
ln -sf ../glider/bin .
mkdir -p src/{assets,code/{escripts,routes},data/${DOMAIN},proxy/{certs,conf}}
touch .gitignore && echo '_*' > .gitignore
cat <<EOF | tee src/code/routes/${DOMAIN}.xqm
module namespace _ = 'http://${DOMAIN}/#routes';
declare
%rest:path('/${DOMAIN}/index')
%rest:GET
%rest:produces('text/html')
%output:method('html')
function _:index(){
<html>
  <head><title>${DOMAIN}</title></head>
  <body>Hello World!</body>
</html>
};
EOF
cat <<EOF | tee .env
DOMAIN=${DOMAIN}
SCHEME=
PORT=
EOF
popd || exit

