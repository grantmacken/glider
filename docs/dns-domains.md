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

To Make target `make hosts-remove` will remove the entry to the '/etc/hosts' file.

