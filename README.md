# dns4me setup for EdgeOS / VyOS

Do you hate having to set up DNS4ME's DNS servers on all of your individual devices?

Want to keep your existing upstream DNS provider (1.1.1.1 / 8.8.8.8 / Encrypted DNS)?

This script will enable all of your devices on your network to benefit from geo-unblocking (without individual device configuration) as well as
 automate the download/refresh of DNS4ME's dnsmasq (via their API) on your edgerouter so that you're always up-to-date with their servers.
 
 This setup ONLY sends DNS requests for the services you have geo-unblocked with DNS4ME, allowing you to keep your current DNS upstream server intact. (i.e. Encrypted DNS)

+ With optional telegram notification for new config changes.


## Overview

* The script periodically downloads DNS4ME's dnsmasq config (via their API).
* The config is stored in memory (/dev/shm/) to avoid storage writes.
* A `diff` is performed to compare the current and downloaded configs.
* If the downloaded config is different, the current config is backed up in /tmp/ and the current config is overwritten.
* The dnsmasq service is then restarted for the new changes to take effect.
* (optional) A telegram notification is sent contianing the change to the config.

## Assumptions:

I'm assuming that you have a `dhcp-server` service running on your edgerouter/vyos device and the `dns-server` is set to itself.


e.g.
```
set service dhcp-server disabled false
set service dhcp-server hostfile-update disable
set service dhcp-server shared-network-name LAN1 authoritative enable
set service dhcp-server shared-network-name LAN1 subnet 192.168.1.0/24 default-router 192.168.1.1
set service dhcp-server shared-network-name LAN1 subnet 192.168.1.0/24 dns-server 192.168.1.1
set service dhcp-server shared-network-name LAN1 subnet 192.168.1.0/24 lease 86400
set service dhcp-server shared-network-name LAN1 subnet 192.168.1.0/24 start 192.168.1.38 stop 192.168.1.243
set service dhcp-server static-arp disable
```

## Pre-requisites:

* [Create and account with DNS4ME and set it up to your liking](https://dns4me.net/)

(Be sure to check that you've added your public IP and enabled the services you want to be unblocked.)

* Enable the dnsmasq service on your edgerouter:

```
configure 
set service dhcp-server use-dnsmasq enable 
commit ; save ; exit
```

### Optional install of nano to edit your scripts easily

* [Add Debian Packages to EdgeOS v2.0.0 and Newer](https://help.ui.com/hc/en-us/articles/205202560-EdgeRouter-Add-Debian-Packages-to-EdgeOS#2)

```vyos
configure
set system package repository stretch components 'main contrib non-free' 
set system package repository stretch distribution stretch
set system package repository stretch url http://http.us.debian.org/debian
commit ; save ; exit
```

:::*WARNING: Do not use the apt-get upgrade command as it can break the customized Debian packages used in EdgeOS.*:::


* Install nano

```sh
sudo apt-get update
sudo apt install nano -y
```

## Configuring and setup

* Place the following script `dns4me.sh` into the `/config/scripts` folder on your edgerouter.

* Make the script executable

```sh
cd /config/scripts
chmod+x dns4me.sh
```

* Log into DNS4ME and navigate to the [hostfile page](https://dns4me.net/user/hosts_file) and copy your `Raw dnsmasq API URL`

`It should look something like "https://dns4me.net/api/v2/get_hosts/dnsmasq/(APIKEY)"`

* Edit the following line in the dns4me.sh script with your API Key

```sh
dns4meApikey=xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

* Setup task-scheduler to execute the dns4me script:
```
configure
set system task-scheduler task dns4me executable path /config/scripts/dns4me.sh
set system task-scheduler task dns4me interval 1d
commit ; save ; exit
```
### Optional - telegram notifications:

If you want telegram integrations, follow the instructions below:

* [Create a telegram bot (for change notification - optional)](https://sendpulse.com/knowledge-base/chatbot/create-telegram-chatbot)

Make sure to make a note of the GROUP_ID and BOT_TOKEN

* Add your `BOT_TOKEN` and `GROUP_ID` to the `dns4me.sh` script

```sh
GROUP_ID=xxxxxxxx
BOT_TOKEN=xxxxx:xxxxxx-xxxxx-xxxx
```

Uncomment this line in the dns4me.sh script:

```sh
#curl -s --data "text=DNS4ME changed: $diff_status" --data "chat_id=$GROUP_ID" 'https://api.telegram.org/bot'$BOT_TOKEN'/sendMessage' > /dev/null
```

## Finished!

* If all went well, visit the [DNS4ME Status](http://dns4me.net/check) page to check if all of the tests pass.

* Sit back and enjoy all of your favourite services geo-unblocked on all of your devices on your network.

## FAQ

* I cannot access dns4me.net after running your script.

You have probably entered the wrong dns4me Api Key.

Delete the current dns4me config:

```sh
rm /etc/dnsmasq.d/03-dns4me.conf
service dnsmasq restart
```

Check your dns4me Api Key and try again
