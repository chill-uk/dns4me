# dns4me setup for UnifiOS

Do you hate having to set up DNS4ME's DNS servers on all of your individual devices?

Want to keep your existing upstream DNS provider (1.1.1.1 / 8.8.8.8 / Encrypted DNS)?

This script will enable all of your devices on your network to benefit from geo-unblocking (without individual device configuration) as well as
 automate the download/refresh of DNS4ME's dnsmasq (via their API) on your edgerouter so that you're always up-to-date with their servers.
 
 This setup ONLY sends DNS requests for the services you have geo-unblocked with DNS4ME, allowing you to keep your current DNS upstream server intact. (i.e. Encrypted DNS)

+ With optional telegram notification for new config changes.

| device           | version                | compatible |
|------------------|------------------------|------------|
| UXG-Lite | 3.1.15 | yes        |
| UCG-Ultra | 3.2.x - 4.1x | yes |
| UDM Pro | untested | untested |

## Overview

* The script periodically downloads DNS4ME's dnsmasq config (via their API).
* The config is stored in memory (/dev/shm/) to avoid storage writes.
* A `diff` is performed to compare the current and downloaded configs.
* If the downloaded config is different, the current config is backed up in /tmp/ and the current config is overwritten.
* The dnsmasq service is then restarted for the new changes to take effect.
* (optional) A telegram notification is sent containing the change to the config.

## Assumptions:

I'm assuming that you have a `dhcp-server` service running on your gateway/udm device and the `dns-server` is set to itself.

## Pre-requisites:

* [Create and account with DNS4ME and set it up to your liking](https://dns4me.net/)
  * Be sure to check that you've added your public IP and enabled the services you want to be unblocked.
* [SSH access to your UnifiOS device](https://help.ui.com/hc/en-us/articles/204909374-UniFi-Connect-with-SSH-Advanced)

## Configuring and setup

### Quick Install

You can install everything with a single command:

```sh
curl -fsSL https://raw.githubusercontent.com/chill-uk/dns4me/main/setup_dns4me.sh | sudo bash
```

### Manual Install

* SSH into your UnifiOS device and place the following script `dns4me.sh` into the `/data/custom/dns4me` folder.

```sh
mkdir -p /data/custom/dns4me
cd /data/custom/dns4me
curl https://raw.githubusercontent.com/chill-uk/dns4me/main/UnifiOS/data/custom/dns4me/dns4me.sh -O
```

* Make the script executable

```sh
cd /data/custom/dns4me
chmod +x dns4me.sh
```

* Add the `dns4me.service` to the system.d folder
```sh
cd /lib/systemd/system
curl https://raw.githubusercontent.com/chill-uk/dns4me/main/UnifiOS/lib/systemd/system/dns4me.service -O
```
* Reload systemd, enable the dns4me service and start it

```sh
systemctl daemon-reload
systemctl enable dns4me.service
systemctl start dns4me.service
```

* To view logs for the service, use:
```sh
journalctl -u dns4me.service
```

* Log into DNS4ME and navigate to the [hostfile page](https://dns4me.net/user/hosts_file) and copy your `Raw dnsmasq API URL`

It should look something like `https://dns4me.net/api/v2/get_hosts/dnsmasq/{APIKEY}`

* Edit the following line in the dns4me.sh script with your API Key

```sh
dns4meApikey=xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

* Add a `cron job` to run periodically

```sh
cd /etc/cron.d
curl https://raw.githubusercontent.com/chill-uk/dns4me/main/UnifiOS/dns4me_cron -O
/etc/init.d/cron restart
```

## Optional - telegram notifications:

If you want telegram integrations, follow the instructions below:

* [Create a telegram bot (for change notification - optional)](https://sendpulse.com/knowledge-base/chatbot/create-telegram-chatbot)

Make sure to make a note of the groupId and botToken

* Add your `botToken` and `groupId` to the `dns4me.sh` script

```sh
groupId=xxxxxxxx
botToken=xxxxx:xxxxxx-xxxxx-xxxx
```

Uncomment these lines in the dns4me.sh script:

```sh
#curl -s --data "text=DNS4ME changed: $diff_status" --data "chat_id=$groupId" 'https://api.telegram.org/bot'$botToken'/sendMessage' > /dev/null
```
and
```sh
#curl -s --data "text=smartdns setup complete" --data "chat_id=$groupId" 'https://api.telegram.org/bot'$botToken'/sendMessage' > /dev$
```

## Finished!

* Manually run the script once to check everything is working

```sh
cd /data/custom/dns4me
./dns4me.sh
```
Output:
```sh
Updating DNS4ME
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  2684  100  2684    0     0   4364      0 --:--:-- --:--:-- --:--:--  4364
No config file found. Setting up smartdns
```

* If all went well, visit the [DNS4ME Status](http://dns4me.net/check) page to check if all of the tests pass.

* Sit back and enjoy all of your favourite services geo-unblocked on all of your devices on your network.

## FAQ

* I cannot access dns4me.net after running your script.

You have probably entered the wrong dns4me Api Key.

Delete the current dns4me config:

```sh
rm /run/dnsmasq.conf.d/dns4me.conf
killall dnsmasq
```

Check your dns4me Api Key and try again

* My gateway restarted/updated and geo-unblocking is not working

Unfortunately it looks like the dnsmasq entries get removed after an upgrade or a reboot.

I have tried to use the @reboot entry in cron to automatically reload dns4me after a restart, but it doesnt look like it's supported. 

You might have to manually log back in and run the script manually.
```sh
cd /data/custom/dns4me
./dns4me.sh
```

## CREDITS
Big shout out to [StoneLabs](https://github.com/StoneLabs) for working out how to add persistent dnsmasq entries to UnifiOS.\
The repo can be found here: [StoneLabs/unifi-uxg-dnsmasq](https://github.com/StoneLabs/unifi-uxg-dnsmasq)
