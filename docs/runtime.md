
### Up and Down

We bring the pod up by running `make up` 
and conversely by running `make down` we stop the the running containers

### the .env file

When running `make up` **make** will read from the `.env` file where it will pick up
container *runtime* variables

 **TIMEZONE**: XQuery has rich set of functions and operators for 
dates, times and durations. This needs to be adjusted to your timezone, otherwise 
some of these XQuery functions and operators will not work as expected.

**Image Versions**:  These can be adjusted to the latest image versions
 
**DNS_DOMAIN**: The intial dns domain in the environment file is `example.com`.

##  Switching DNS Domains

To switch development to a dns domain you control,
 change the value of the `DNS_DOMAIN` in the .env file.
 Next invoke the `make init` target.
 The target will create some some boilerplate src files for your dns domain.

Below we will use 'markup.nz' as an example domain.

`make init` this generates
 1. data files 
  - `src/data/markup.nz/index.md`: a markdown document
  - `src/data/markup.nz/default_layout.xq`: a XQuery main module
 2. `src/code/restXQ/markup.nz.xqm`, a XQuery library module which will set the restXQ endpoints for the dns domain.
When we run `make` which is our *build* target,
 1. the src *code* file will be compiled and set the restXQ endpoints
 2. the src *data* files will be stored as XDM items in the xqerl database.

##  DNS Resolution With /etc/hosts

Our initial example site uses the classic 'example.com' domain. 
Since we do not own or control the 'example.com' domain,
we can modify our '/etc/hosts' file, so 'example.com' will resolve to 'localhost'

The Make target `make hosts` will add an entry to the '/etc/hosts' file.
The `make hosts` target uses the value of the `DNS_DOMAIN` in the .env file.
Note: The target requires us to use super do `sudo` .
The `make hosts` target is an alias for following shell script.

```shell
grep -q '127.0.0.1   example.com' /etc/hosts || \
echo '127.0.0.1   example.com' | \
sudo tee -a /etc/hosts
```

`make hosts-remove` will remove the entry to the '/etc/hosts' file.
You can use the 'host' command to check if to see if 'example.com' is resolving to localhost

```
> host example.com
# Loopback entries; do not change.
# For historical reasons, localhost precedes localhost.localdomain:
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
# See hosts(5) for proper format and other examples:
# 192.168.1.10 foo.mydomain.org foo
# 192.168.1.13 bar.mydomain.org bar
127.0.0.1   example.com
```

With our dns domain resolving to `example.com`
we can now make a HTTP request to 
`http://example.com/xqerl and get the xqerl greeter response 
from our local running pod.

## On Pods, Ports and Belonging to a Network 

Our xqerl container named **xq** and nginx container named *or* are in a pod named 'podx'.
When we created our pod, we 
   - published ports: `80:80` for HTTP requests and '443:443' for HTTPS requests
   - set up network named **podman** that the running containers will join. 
     Note: the podman network is the default network

xqerl which listens on port 8081, is running in the internal 'podman' network
so `http://example.com:8081` is not reachable outside the pod because port '8081'
is not an exposed published port for the pod.

Outside of the pod, to reach xqerl on the internet, all requests are via ngnix set up as a 
[reverse proxy](https://www.nginx.com/resources/glossary/reverse-proxy-server/)
