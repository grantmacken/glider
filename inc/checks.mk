##########################################
# generic make function calls
# call should result in success or failure
##########################################
Tick  = printf '\033[32m✔ \033[0m %s' $1
Cross = printf "\033[31m✘ \033[0m %s" $1

WriteOut := '\
url [ %{url} ]\n\
response code [ %{http_code} ]\n\
'
#
# content type  [ %{content_type} ]\n\
# SSL verify    [ %{ssl_verify_result} ] should be zero \n\
# remote ip     [ %{remote_ip} ]\n\
# local ip      [ %{local_ip} ]\n\
# speed         [ %{speed_download} ] the average download speed\n\
# SIZE     bytes sent \n\
# header   [ %{size_header} ] \n\
# request  [ %{size_request} ] \n\
# download [ %{size_download} ] \n\
# TIMER       [ 0.000000 ] start until \n\
# namelookup  [ %{time_namelookup} ] DNS resolution  \n\
# connect     [ %{time_connect} ] TCP connect \n\
# appconnect: [ %{time_appconnect} ] SSL handhake \n\
# pretransfer [ %{time_pretransfer} ] before transfer \n\
# transfer    [ %{time_starttransfer} ] transfer start \n\
# tansfered   [ %{time_total} ] total transfered '

 #--cacert src/proxy/certs/example.com.pem 


Crl = curl --silent --show-error -L \
 --connect-timeout 1 \
 --max-time 2 \
 --write-out $(WriteOut) \
 --dump-header $(1)/headers.txt \
 --output $1/body.html $(2)$(3)


Crl = curl --silent --show-error -L \
 --connect-timeout 1 \
 --max-time 2 \
 --write-out $(WriteOut) \
 --dump-header $(1)/headers.txt \
 --output $1/body.html $(2)$(3)

checkGreeter:
	mkdir -p _checks/$@
	podman run --rm --pod $(POD) $(CURL) \
		--silent --show-error --connect-timeout 1 --max-time 2 \
		http://localhost:8081/xqerl
	echo && $(DASH)

checkDbColl:
	mkdir -p _checks/$@
	podman run --rm --pod $(POD) $(CURL) \
		--silent --show-error --connect-timeout 1 --max-time 2 \
		http://localhost:8081/db/example.com
	echo && $(DASH)

check01:
	mkdir -p _checks/$@
	$(call Crl,_checks/$@,http://example.com,/) 
	echo && $(DASH)

check1:
	CHECK=POST_XML_DATA
	COLLECTION=docs
	RESOURCE=testing-data.xml
	CHECK_PATH=_checks/$${CHECK}/$${COLLECTION}
	mkdir -p $$CHECK_PATH
	curl --silent --show-error --connect-timeout 1 --max-time 2 \
		--dump-header $${CHECK_PATH}/headers.txt \
		--write-out '\nresponse code [ %{http_code} ]\ncontent type [ %{content_type} ]' \
		--header 'Content-Type: application/xml' \
		--header "Slug: $${RESOURCE}" \
		--data '<test>data</test>' \
		http://example.com/db/$${COLLECTION} > $${CHECK_PATH}/write-out.txt
	echo && $(DASH)

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





