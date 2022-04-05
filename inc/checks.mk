##########################################
# generic make function calls
# call should result in success or failure
##########################################
Tick  = printf '\033[32m✔ \033[0m %s' $1
Cross = printf "\033[31m✘ \033[0m %s" $1

WriteOut := '\
url [ %{url} ]\n\
response code [ %{http_code} ]\n\
content type  [ %{content_type} ]\n\
SSL verify    [ %{ssl_verify_result} ] should be zero \n\
remote ip     [ %{remote_ip} ]\n\
local ip      [ %{local_ip} ]\n\
speed         [ %{speed_download} ] the average download speed\n\
SIZE     bytes sent \n\
header   [ %{size_header} ] \n\
request  [ %{size_request} ] \n\
download [ %{size_download} ] \n\
TIMER       [ 0.000000 ] start until \n\
namelookup  [ %{time_namelookup} ] DNS resolution  \n\
connect     [ %{time_connect} ] TCP connect \n\
appconnect: [ %{time_appconnect} ] SSL handhake \n\
pretransfer [ %{time_pretransfer} ] before transfer \n\
transfer    [ %{time_starttransfer} ] transfer start \n\
tansfered   [ %{time_total} ] total transfered '

Crl = curl --silent --show-error -L \
 --cacert src/proxy/certs/example.com.pem \
 --connect-timeout 1 \
 --max-time 2 \
 --write-out $(WriteOut) \
 --dump-header $1.headers \
 --output $(1).html $2

	

check1:
	podman ps -a
	$(DASH)
	$(call Crl,$@,https://example.com/)
	#podman run --rm --pod $(POD) $(W3M) -dump http://localhost:8081/xqerl
	echo && $(DASH)
	$(DASH)
	cat 
	#podman run --rm --pod $(POD) $(W3M) -dump http://localhost:8081/xqerl
	$(DASH)

.PHONY: checks _checks/example.com
checks:  _checks/example.com/index

# NOTE: certs pem 
PHONY: _checks/example.com/index
_checks/example.com/index: certs-pem
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	$(DASH)
	$(call Crl,$@,https://example.com/) &>/dev/null
	cat $@.html
	echo && $(DASH) && echo
	$(call Crl,$@,http://example.com)
	cat $@.html
	echo && $(DASH) && echo
	$(call Crl,$@,http://example.com)
	cat $@.html
	echo && $(DASH) && echo

xxxx:
	grep -q 'news from erewhon' $@
	podman run --rm --pod $(POD) $(W3M) -dump http://localhost:8081/example.com/content/home/index | tee -a $@
	$(DASH)



