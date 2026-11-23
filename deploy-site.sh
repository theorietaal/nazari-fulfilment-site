#!/bin/bash
# Update nazarifulfilment.nl: haalt de nieuwste site-bundel van GitHub, controleert
# elk bestand (sha256), zet de site atomair live en houdt een back-up.
# Gebruik (Hetzner-console):  bash /opt/nfc-site/update.sh
# Raakt fulfilkit, hethandel.nl en het klantportaal niet aan.
set -euo pipefail
REPO=theorietaal/nazari-fulfilment-site
WEB=/var/www/nazarifulfilment
CONF=/etc/nginx/sites-available/nazarifulfilment
WERK=$(mktemp -d); trap 'rm -rf "$WERK"' EXIT
SHA=${1:-$(curl -sf "https://api.github.com/repos/$REPO/commits?path=site-bundle.json&per_page=1" | grep -m1 '"sha"' | cut -d'"' -f4)}
[ -n "$SHA" ] || { echo "FOUT: versie niet gevonden"; exit 1; }
echo "versie: $SHA"
curl -sfL -o "$WERK/b.json" "https://raw.githubusercontent.com/$REPO/$SHA/site-bundle.json"
mkdir "$WERK/site"
python3 - "$WERK/b.json" "$WERK/site" <<'PY'
import json, sys, os, base64, hashlib
b = json.load(open(sys.argv[1], encoding="utf-8")); doel = sys.argv[2]
for pad, f in b["files"].items():
    if pad.startswith("/") or ".." in pad.split("/"): sys.exit("FOUT: ongeldig pad " + pad)
    data = base64.b64decode(f["b"]) if "b" in f else f["t"].encode("utf-8")
    if hashlib.sha256(data).hexdigest() != f["sha256"]: sys.exit("FOUT: controle mislukt voor " + pad)
    p = os.path.join(doel, pad); os.makedirs(os.path.dirname(p), exist_ok=True)
    open(p, "wb").write(data)
print("bestanden gecontroleerd:", len(b["files"]))
PY
[ -f "$WERK/site/index.html" ] && [ -f "$WERK/site/404.html" ] || { echo "FOUT: bundel onvolledig"; exit 1; }
chmod -R u=rwX,go=rX "$WERK/site"
STAMP=$(date +%Y%m%d-%H%M%S)
cp -a "$WEB" "/root/site-backup-$STAMP"
rm -rf "$WEB.nieuw"; cp -a "$WERK/site" "$WEB.nieuw"
mv "$WEB" "$WEB.oud" && mv "$WEB.nieuw" "$WEB" && rm -rf "$WEB.oud"
echo "site geplaatst (back-up: /root/site-backup-$STAMP)"

# nginx: echte 404 i.p.v. altijd de homepage, en gzip voor css/svg/xml
cp "$CONF" "/root/nginx-nazarifulfilment-$STAMP.conf"
sed -i 's#try_files $uri $uri/ /index.html;#try_files $uri $uri/ =404;#' "$CONF"
grep -q 'error_page 404 /404.html;' "$CONF" || sed -i 's#^\(\s*\)index index.html;#\1index index.html;\n\1error_page 404 /404.html;\n\1gzip_types text/css image/svg+xml application/xml text/plain application/json;#' "$CONF"
if nginx -t 2>/dev/null; then systemctl reload nginx; echo "nginx bijgewerkt"; else cp "/root/nginx-nazarifulfilment-$STAMP.conf" "$CONF"; nginx -t && systemctl reload nginx; echo "LET OP: nginx-wijziging teruggedraaid"; fi

mkdir -p /opt/nfc-site
[ -f "$WERK/site/deploy-site.sh" ] && install -m 755 "$WERK/site/deploy-site.sh" /opt/nfc-site/update.sh && rm -f "$WEB/deploy-site.sh"

echo "== controle"
c() { curl -s -o /dev/null -w '%{http_code}' --resolve nazarifulfilment.nl:443:127.0.0.1 "https://nazarifulfilment.nl$1"; }
for p in / /tarieven/ /bol-fulfilment/ /kennisbank/ /robots.txt /sitemap.xml /og.png; do echo "$p $(c $p)"; done
echo "/bestaat-niet $(c /bestaat-niet) (moet 404 zijn)"
echo "www: $(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' --resolve www.nazarifulfilment.nl:443:127.0.0.1 https://www.nazarifulfilment.nl/tarieven/)"
echo "hethandel: $(curl -s -o /dev/null -w '%{http_code}' https://hethandel.nl/login)  portaal: $(curl -s -o /dev/null -w '%{http_code}' https://portaal.nazarifulfilment.nl/login)  fulfilkit: $(systemctl is-active fulfilkit)"
echo "== klaar"
