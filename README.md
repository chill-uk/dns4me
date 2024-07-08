# dns4me setup for EdgeOS / VyOS / UnifiOS

Do you hate having to set up DNS4ME's DNS servers on all of your individual devices?

Want to keep your existing upstream DNS provider (1.1.1.1 / 8.8.8.8 / Encrypted DNS)?

This script will enable all of your devices on your network to benefit from geo-unblocking (without individual device configuration) as well as
 automate the download/refresh of DNS4ME's dnsmasq (via their API) on your edgerouter so that you're always up-to-date with their servers.
 
 This setup ONLY sends DNS requests for the services you have geo-unblocked with DNS4ME, allowing you to keep your current DNS upstream server intact. (i.e. Encrypted DNS)

+ With optional telegram notification for new config changes.

| device           | version                | compatible |
|------------------|------------------------|------------|
| EdgeRouterLite-3 | EdgeOS v2.0.9-hotfix.4 | yes |
| UXG-Lite | 3.1.15 | yes |
| UCG-Ultra | 3.2.x x-4.0.x | yes |

The script has been updated to work with UnifiOS, so the folder structure has moved to EdgeOS or UnifiOS (depending on your gateway / edgerouter)
