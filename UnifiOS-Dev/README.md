# dns4me setup for UnifiOS-Dev

THIS IS THE ALPHA-DEVELOPMENT SCRIPT FOR FIRMWARE 4.3.5

THIS SCRIPT WILL ALTER ubios-udapi-server.state FILE VIA THE ubios-udapi-client POST COMMAND.

CURRENTLY IT WILL JUST READ YOUR STATE FILE, BUT ONCE TESTING IS COMPLETE, IT WILL AUTOMATICALLY MODIFY YOUR STATE FILE!

Do you hate having to set up DNS4ME's DNS servers on all of your individual devices?

Want to keep your existing upstream DNS provider (1.1.1.1 / 8.8.8.8 / Encrypted DNS)?

This script will enable all of your devices on your network to benefit from geo-unblocking (without individual device configuration) as well as
 automate the download/refresh of DNS4ME's dnsmasq (via their API) on your edgerouter so that you're always up-to-date with their servers.
 
 This setup ONLY sends DNS requests for the services you have geo-unblocked with DNS4ME, allowing you to keep your current DNS upstream server intact. (i.e. Encrypted DNS)

+ With optional telegram notification for new config changes.

| device           | version                | compatible |
|------------------|------------------------|------------|
| UXG-Lite | 3.1.15 | yes        |
| UCG-Ultra | 4.3.5 | TESTING |
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
* [SSH access to your UnifiOS-Dev device](https://help.ui.com/hc/en-us/articles/204909374-UniFi-Connect-with-SSH-Advanced)

## Configuring and setup

### Quick Install

You can install everything with a single command:

```sh
curl -fsSL https://raw.githubusercontent.com/chill-uk/dns4me/main/UnifiOS-Dev/setup_dns4me.sh | sudo bash
```

### Manual Install

* SSH into your UnifiOS-Dev device and place the following script `dns4me.sh` into the `/data/custom/dns4me` folder.

```sh
mkdir -p /data/custom/dns4me
curl -o /data/custom/dns4me/dns4me.sh https://raw.githubusercontent.com/chill-uk/dns4me/main/UnifiOS-Dev/data/custom/dns4me/dns4me.sh
```

* Make the script executable

```sh
chmod +x dns4me.sh
```

* Log into DNS4ME and navigate to the [hostfile page](https://dns4me.net/user/hosts_file) and copy your `Raw dnsmasq API URL`

It should look something like `https://dns4me.net/api/v2/get_hosts/dnsmasq/{APIKEY}`

* Edit the following line in the dns4me.sh script with your API Key

```sh
dns4meApikey=xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

* Add the `dns4me.service` to the systemd folder
```sh
curl -o /lib/systemd/system/dns4me.service https://raw.githubusercontent.com/chill-uk/dns4me/main/UnifiOS-Dev/lib/systemd/system/dns4me.service 
```
* Reload systemd, enable the dns4me service and start it

```sh
sudo systemctl daemon-reload
sudo systemctl enable dns4me.service
sudo systemctl start dns4me.service
```

* To view logs for the service, use:
```sh
sudo journalctl -u dns4me.service
```
## Setting up a timer for automatic updates

### Systemd Timer Setup

* Add a `systemd timer` to run periodically. 

```sh
curl -o /lib/systemd/system/dns4me.timer https://raw.githubusercontent.com/chill-uk/dns4me/main/UnifiOS-Dev/lib/systemd/system/dns4me.timer
sudo systemctl daemon-reload
sudo systemctl enable --now dns4me.timer
```

This will run the update at midnight every night (and, if configured, at boot).

You can check the timer status with:

```sh
sudo systemctl status dns4me.timer
```

Logs for the timer activity can be viewed with:

```sh
sudo journalctl -u dns4me.timer
```

Note: `journalctl -u dns4me.timer` shows timer scheduling events, while `journalctl -u dns4me.service` shows the script’s output.

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
