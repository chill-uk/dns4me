
#!/bin/bash

# This script is used to update the dnsmasq configuration for DNS4ME.
# It downloads the latest DNS4ME entries and updates the dnsmasq configuration file.
# It also sends a message to a Telegram group if the configuration has changed.


# Make sure to set the following variables before running the script
groupId=xxxxxxxxx
# groupId: The Telegram group ID where the message will be sent.
botToken=xxxxxxxxx:xxxxxx-xxxxxxxxxxxxxxxxxxxx-xxxxxxx
# botToken: The Telegram bot token used to send the message.
dns4meApikey=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
# dns4meApikey: Your DNS4ME API key.
currentConfig=/dev/shm/current-dns.conf
tempConfig=/dev/shm/temp-dns.conf
backupConfig=/data/udapi-config/ubios-udapi-server/ubios-udapi-server.state.bak
dnsServer1=xxxx
dnsServer2=xxxx

echo "Updating DNS4ME"
dnsmasqEntries=$(curl "https://dns4me.net/api/v2/get_hosts/dnsmasq/$dns4meApikey")

# Checking to see if $dnsmasqEntries downloaded correctly.
if [ -z "$dnsmasqEntries" ]
then
    echo "Could not download dnsmasq entries from dns4me.net. Please check your dns4me Api Key and try again."
else
    ubios-udapi-client GET -r /services | jq '[.dnsForwarder.domainForwards[].domainName] | sort' > $currentConfig
    
    { echo "$dnsmasqEntries" | grep -v '52\.29\.2\.17$' | sed 's/^server=\///; s/3\.10\.65\.124//g' | tr '/' '\n'; echo "dns4me.net"; } | sort | awk 'NF' | jq -R . | jq -s . > $tempConfig

    diffStatus="$(diff $currentConfig $tempConfig)"
    if $diffStatus > /dev/null 2>&1
    then
        echo "config files are equal"
        curl -s --data "text=DNS4ME config files equal" --data "chat_id=$groupId" 'https://api.telegram.org/bot'$botToken'/sendMessage' > /dev/null 2>&1
    else
        echo "config files are different"
        curl -s --data "text=DNS4ME changed: $diffStatus" --data "chat_id=$groupId" 'https://api.telegram.org/bot'$botToken'/sendMessage' > /dev/null 2>&1
    fi
fi
