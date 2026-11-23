#!/bin/bash
# Zet de beheerder-login van het NFC-portaal op nazaribv5@gmail.com met een nieuw wachtwoord.
set -eu
APP=/opt/nfc-portaal
NIEUW=nazaribv5@gmail.com
OUD=info@nazarigroup.nl
WW=$(tr -dc 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ23456789' </dev/urandom | head -c 14 || true)
# bestaande beheerder hernoemen (behoudt alles wat eraan hangt)
sudo -u postgres psql -d nfc_portaal -qtA -v ON_ERROR_STOP=1 -c "UPDATE \"User\" SET email='$NIEUW' WHERE email='$OUD' AND NOT EXISTS (SELECT 1 FROM \"User\" WHERE email='$NIEUW');" >/dev/null
# wachtwoord zetten (maakt de login aan als hij nog niet bestaat)
su -s /bin/bash nfcportaal -c "cd $APP && HOME=/var/lib/nfcportaal npx tsx scripts/maak-gebruiker.ts $NIEUW '$WW' 'Javid'"
echo "$WW" > /root/nfc-portaal-beheerder.txt; chmod 600 /root/nfc-portaal-beheerder.txt
echo
sudo -u postgres psql -d nfc_portaal -qtA -c "SELECT email, role FROM \"User\" ORDER BY \"createdAt\";"
echo
echo "BEHEERDER  e-mail: $NIEUW"
echo "WACHTWOORD (per teken):  $(echo "$WW" | sed 's/./& /g')"
