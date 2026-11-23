#!/bin/bash
# Zet nazarifulfilment.nl online. Raakt fulfilkit/hethandel.nl en andere sites niet aan.
set -u
D=$(cd "$(dirname "$0")" && pwd)
LOG=/root/nazarifulfilment-install.log
exec > >(tee "$LOG") 2>&1
echo "== start $(date)"
if grep -rqs "nazarifulfilment" /etc/nginx/sites-enabled /etc/nginx/conf.d; then
  echo "LET OP: er bestaat al nginx-config voor nazarifulfilment; alleen site-bestand bijwerken."
  EXISTS=1
else EXISTS=0; fi
B=/root/nginx-backup-$(date +%Y%m%d-%H%M%S).tgz
tar czf "$B" -C / etc/nginx && echo "back-up nginx: $B"
mkdir -p /var/www/nazarifulfilment
install -m 644 "$D/index.html" /var/www/nazarifulfilment/index.html
echo "site geplaatst: $(md5sum /var/www/nazarifulfilment/index.html)"
if [ "$EXISTS" = 0 ]; then
  install -m 644 "$D/nazarifulfilment.conf" /etc/nginx/sites-available/nazarifulfilment
  ln -s /etc/nginx/sites-available/nazarifulfilment /etc/nginx/sites-enabled/nazarifulfilment
fi
if nginx -t; then
  systemctl reload nginx && echo "nginx herladen (geen restart)"
else
  echo "FOUT in nginx-test -> nieuwe config weer verwijderd, niets herladen"
  [ "$EXISTS" = 0 ] && rm -f /etc/nginx/sites-enabled/nazarifulfilment /etc/nginx/sites-available/nazarifulfilment
  exit 1
fi
echo "lokale test http: $(curl -s -o /dev/null -w '%{http_code}' -H 'Host: nazarifulfilment.nl' http://127.0.0.1/)"
IP=$(dig +short nazarifulfilment.nl @8.8.8.8 2>/dev/null | tail -1)
IPW=$(dig +short www.nazarifulfilment.nl @8.8.8.8 2>/dev/null | tail -1)
echo "DNS: nazarifulfilment.nl=$IP www=$IPW"
if [ "$IP" = "178.104.3.252" ] && [ "$IPW" = "178.104.3.252" ]; then
  certbot --nginx -n -d nazarifulfilment.nl -d www.nazarifulfilment.nl --redirect && echo "CERT OK" || echo "CERT MISLUKT"
  nginx -t && systemctl reload nginx
else
  echo "DNS nog niet doorgekomen -> certificaat later: bash $D/install.sh opnieuw draaien"
fi
echo "== controle"
echo "https site:   $(curl -s -o /dev/null -w '%{http_code}' --resolve nazarifulfilment.nl:443:127.0.0.1 https://nazarifulfilment.nl/)"
echo "www redirect: $(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' --resolve www.nazarifulfilment.nl:443:127.0.0.1 https://www.nazarifulfilment.nl/)"
echo "hethandel:    $(curl -s -o /dev/null -w '%{http_code}' https://hethandel.nl/login)"
echo "fulfilkit:    $(systemctl is-active fulfilkit)"
echo "== klaar"
