
#!/bin/bash

groupId=xxxxxxxxx
botToken=xxxxxxxxx:xxxxxx-xxxxxxxxxxxxxxxxxxxx-xxxxxxx
dns4meApikey=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
currentConfig=/etc/dnsmasq.d/03-dns4me.conf
tempConfig=/dev/shm/03-dns4me.conf
backupConfig=/tmp/03-dns4me_`date +%d%b%Y`.conf

echo "Updating DNS4ME"
dnsmasqEntries=$(curl "https://dns4me.net/api/v2/get_hosts/dnsmasq/$dns4meApikey")

# Checking to see if $dnsmasqEntries downloaded correctly. 
if [ -z "$dnsmasqEntries" ]
then
    echo "Could not download dnsmasq entries from dns4me.net. Please check your dns4me Api Key and try again."
else
    # Scraping your closest DNS4ME DNS servers
    dnsServer1=$(echo "$dnsmasqEntries" | sed -n '1p')
    dnsServer2=$(echo "$dnsmasqEntries" | sed -n '2p')

cat << EOF > "$tempConfig"
$dnsmasqEntries
# Adding dnsmasq for dns4me.net so the tests pass
# http://dns4me.net/check
server=/dns4me.net/${dnsServer1##*/}
server=/dns4me.net/${dnsServer2##*/}
EOF

    if [ -f "$currentConfig" ]
        then
        diffStatus="$(diff $currentConfig $tempConfig)"
        if $diffStatus > /dev/null 2>&1
            then
                echo "config files are equal"
            else
                echo "config files are different"
                mv $currentConfig $backupConfig
                mv $tempConfig $currentConfig
                service dnsmasq restart
                curl -s --data "text=DNS4ME changed: $diffStatus" --data "chat_id=$groupId" 'https://api.telegram.org/bot'$botToken'/sendMessage' > /dev/n$
            fi
        else
            echo "No config file found. Setting up smartdns"
            mv $tempConfig $currentConfig
            service dnsmasq restart
            curl -s --data "text=smartdns setup complete" --data "chat_id=$groupId" 'https://api.telegram.org/bot'$botToken'/sendMessage' > /dev$
    fi
fi
