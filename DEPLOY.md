# Nazari Fulfilment Center – online zetten op nazarifulfilment.nl

Deze map bevat de complete website: `index.html` (één bestand, geen build nodig).
De site komt op dezelfde server als fulfilkit (178.104.3.252), maar in een eigen map en een
eigen nginx-blok. Fulfilkit (hethandel.nl, /opt/fulfilkit, service `fulfilkit`) wordt NIET aangeraakt.

## Stap 1 – DNS (bij Mijndomein, al gedaan)

| Type | Naam | Waarde        |
|------|------|---------------|
| A    | @    | 178.104.3.252 |
| A    | www  | 178.104.3.252 |

Een nieuw domein kan tot een paar uur nodig hebben voordat het overal naar de server wijst.

## Stap 2 – Plak dit in Claude Code (op de computer waarmee je normaal deployt)

Open Claude Code in deze map (`nazari-fulfilment-site`) en plak:

```
Zet de statische website in deze map (index.html) online op https://nazarifulfilment.nl
(en https://www.nazarifulfilment.nl als doorverwijzing naar zonder www), op de server
root@178.104.3.252.

STRIKTE REGELS – de draaiende fulfilkit (hethandel.nl) mag op geen enkele manier geraakt worden:
- NIET aankomen: /opt/fulfilkit, de systemd-service "fulfilkit", de database, en de
  bestaande nginx-configuratie van hethandel.nl en andere sites (perqo/bolkit).
- Geen nginx restart, alleen "nginx -t" en daarna "systemctl reload nginx".
- Maak eerst een back-up van /etc/nginx voordat je iets toevoegt.

Stappen:
1. Controleer dat nazarifulfilment.nl en www.nazarifulfilment.nl naar 178.104.3.252 wijzen
   (dig +short, of nslookup). Zo niet: stop en meld dat de DNS nog niet klaar is.
2. ssh naar de server: maak /var/www/nazarifulfilment en zet index.html daarin (rsync of scp).
3. Bekijk hoe de bestaande sites in nginx zijn ingericht (sites-available/conf.d) en maak in
   dezelfde stijl een NIEUW los bestand voor alleen server_name nazarifulfilment.nl en
   www.nazarifulfilment.nl, root /var/www/nazarifulfilment, index index.html.
   Wijzig geen bestaande bestanden.
4. nginx -t  →  alleen als dat OK is: systemctl reload nginx.
5. Certificaat, alleen voor deze twee namen:
   certbot --nginx -d nazarifulfilment.nl -d www.nazarifulfilment.nl --redirect
   Zorg daarna dat www.nazarifulfilment.nl doorverwijst (301) naar https://nazarifulfilment.nl.
6. Controleer en meld de uitkomst van alle vier:
   - https://nazarifulfilment.nl geeft 200 en toont "Nazari Fulfilment Center"
   - https://www.nazarifulfilment.nl verwijst door naar https://nazarifulfilment.nl
   - https://hethandel.nl/login geeft nog steeds 200 (fulfilkit werkt nog)
   - systemctl is-active fulfilkit = active
```

## Later bijwerken

Nieuwe versie van de site? Alleen `index.html` opnieuw naar `/var/www/nazarifulfilment/` kopiëren.
Geen herstart nodig.

## Offerteformulier

Het formulier opent een ingevulde e-mail naar info@nazarigroup.nl in het e-mailprogramma van de
bezoeker. Wil je dat aanvragen direct binnenkomen zonder e-mailprogramma, dan kan daar later een
klein verzendscript voor komen.
