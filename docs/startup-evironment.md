
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

##  DNS Resolution With /etc/hosts

Our initial example site will use the classic 'example.com' domain
Since we do not own or control the 'example.com' domain,
we can modify our '/etc/hosts' file, so 'example.com' will resolve to 'localhost'

I have created a Make target `make hosts` will add an entry to the '/etc/hosts' file.
Note: The target requires us to use super do `sudo` .
The `make rootless` target is an alias for following shell script.

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
