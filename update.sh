#!/bin/bash
# Update het NFC-klantportaal: haalt de nieuwste versie van GitHub, ontsleutelt
# die met de sleutel op deze server en installeert hem. Raakt fulfilkit niet aan.
# Gebruik (in de Hetzner-console):  bash /opt/nfc-portaal/deploy/update.sh
set -euo pipefail
REPO=theorietaal/nazari-fulfilment-site
SLEUTEL=/root/.nfc-portaal-key
[ -f "$SLEUTEL" ] || { echo "FOUT: sleutel $SLEUTEL ontbreekt"; exit 1; }
WERK=$(mktemp -d)
trap 'rm -rf "$WERK"' EXIT
SHA=$(curl -sf "https://api.github.com/repos/$REPO/commits?path=nfc-portaal.enc&per_page=1" | grep -m1 '"sha"' | cut -d'"' -f4)
[ -n "$SHA" ] || { echo "FOUT: kon de nieuwste versie niet bepalen"; exit 1; }
echo "versie: $SHA"
curl -sfL -o "$WERK/p.enc" "https://raw.githubusercontent.com/$REPO/$SHA/nfc-portaal.enc"
openssl enc -d -aes-256-cbc -pbkdf2 -k "$(tr -d '\n' < "$SLEUTEL")" -in "$WERK/p.enc" -out "$WERK/p.tgz"
mkdir "$WERK/src" && tar xzf "$WERK/p.tgz" -C "$WERK/src"
chmod -R u=rwX,go=rX "$WERK/src"
[ -f "$WERK/src/deploy/update.sh" ] && install -m 755 "$WERK/src/deploy/update.sh" /opt/nfc-portaal/deploy/update.sh
bash "$WERK/src/deploy/install-portaal.sh"
