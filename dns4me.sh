
#!/bin/bash

groupId=xxxxxxxxx
botToken=xxxxxxxxx:xxxxxx-xxxxxxxxxxxxxxxxxxxx-xxxxxxx

echo "Updating DNS4ME"
curl https://dns4me.net/api/v2/get_hosts/dnsmasq/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx > /dev/shm/03-dns4me.conf

# Scraping your closest DNS4ME DNS servers
dnsServer1=$(tail -1 /dev/shm/03-dns4me.conf)
dnsServer2=$(tail -2 /dev/shm/03-dns4me.conf | head -1)

# Adding dnsmasq for DNS4ME so your tests pass
# http://dns4me.net/check
cat << EOF >> /dev/shm/03-dns4me.conf

server=/dns4me.net/${dnsServer1##*/}
server=/dns4me.net/${dnsServer2##*/}
EOF

diffStatus="$(diff /etc/dnsmasq.d/03-dns4me.conf /dev/shm/03-dns4me.conf)"
if $diffStatus > /dev/null 2>&1
then
    echo "Configs are the same"
else
    echo "Config has changed"
    mv /etc/dnsmasq.d/03-dns4me.conf /tmp/03-dns4me_`date +%d%b%Y`.conf
    mv /dev/shm/03-dns4me.conf /etc/dnsmasq.d/03-dns4me.conf
    service dnsmasq restart
    curl -s --data "text=DNS4ME changed: $diffStatus" --data "chat_id=$groupId" 'https://api.telegram.org/bot'$botToken'/sendMessage' > /dev/null
fi
