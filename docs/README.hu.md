<!-- LANGS -->
[🇬🇧 English](../README.md) · [🇷🇺 Русский](README.ru.md) · [🇺🇦 Українська](README.uk.md) · [🇩🇪 Deutsch](README.de.md) · [🇫🇷 Français](README.fr.md) · [🇪🇸 Español](README.es.md) · [🇵🇹 Português](README.pt-PT.md) · [🇧🇷 Português (Brasil)](README.pt-BR.md) · [🇵🇱 Polski](README.pl.md) · [🇨🇿 Čeština](README.cs.md) · **🇭🇺 Magyar** · [🇹🇷 Türkçe](README.tr.md) · [🇰🇿 Қазақша](README.kk.md) · [🇮🇳 हिन्दी](README.hi.md) · [🇯🇵 日本語](README.ja.md) · [🇨🇳 简体中文](README.zh-Hans.md) · [🇹🇼 繁體中文](README.zh-Hant.md)
<!-- /LANGS -->

# AgentBar

Könnyű macOS menüsor-alkalmazás, amely megmutatja, mennyit használtál el a **Claude**, **Codex** és **Cursor** kereteidből — továbbá token-statisztikát ad, és kiszámolja, mennyibe kerülne ugyanez a használat a nyilvános API-kon keresztül.

[![CI](https://github.com/funbool/agentbar/actions/workflows/ci.yml/badge.svg)](https://github.com/funbool/agentbar/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/funbool/agentbar?display_name=tag)](https://github.com/funbool/agentbar/releases/latest)
![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](../LICENSE)

## Funkciók

- **Keretek egy pillantásra** — 5 órás és heti ablakok a Claude-hoz és a Codexhez, csomagban foglalt használati keretek a Cursorhoz; mindegyikhez folyamatjelző, a nullázásig hátralévő idő és a pontos dátum.
- **Modellenkénti heti keretek** a Claude-hoz (Opus, Sonnet, Fable, …), amint az API jelenti őket.
- **Használati statisztika** — tokenek típus szerint, költség, bontás modell és projekt szerint, napi diagram; Ma / 7 nap / 30 nap / Összes.
- **Értesítések**, ha egy keret átlép egy küszöböt, globális alapértékkel és keretenkénti szabályokkal (némítás, saját küszöb).
- **Opcionális automatikus frissítés**, indítás bejelentkezéskor, 17 felületi nyelv.
- **Távoli frissítés** a GitHub Releases-ből, SHA-256-tal ellenőrizve.
- **Nincs fiók, nincs telemetria.** Az AgentBar azokat a tokeneket olvassa, amelyeket a hivatalos kliensek már a Maceden tárolnak, és csak a szolgáltatók saját API-jaival kommunikál.

## Követelmények

- macOS 14 Sonoma vagy újabb (Apple Silicon vagy Intel).
- Legalább egy bejelentkezett kliens: [Claude Code](https://claude.com/claude-code), [Codex](https://openai.com/codex) (CLI vagy alkalmazás), [Cursor](https://cursor.com). A nem használt szolgáltatók elrejthetők a Beállításokban.

## Telepítés

1. Töltsd le az `AgentBar.zip` fájlt a [legfrissebb kiadásból](https://github.com/funbool/agentbar/releases/latest).
2. Csomagold ki, és helyezd az `AgentBar.app`-ot az `/Applications` mappába.
3. Nyisd meg az alkalmazást. Bejegyzi magát bejelentkezési elemként (a Beállításokban kikapcsolható).

**Gatekeeper.** A kiadások ad hoc aláírásúak, nem közjegyzőzöttek. Ha a macOS nem hajlandó megnyitni a frissen letöltött példányt, jobb kattintás → *Megnyitás* egyszer, vagy távolítsd el a karanténjelzőt:

```bash
xattr -dr com.apple.quarantine /Applications/AgentBar.app
```

**Kulcskarika-kérdés.** Az első Claude-frissítéskor a macOS megkérdezi, olvashatja-e a `security` a *Claude Code-credentials* elemet. Válaszd a **Mindig engedélyezés** lehetőséget. A kérdés visszatérhet, miután a Claude Code lecserélte a tokenjét — ez normális.

[Forrásból is fordíthatod](#fordítás-forrásból).

## Hogyan működik

Az AgentBar soha nem kér bejelentkezést. Azokat a hitelesítő adatokat olvassa, amelyeket minden kliens már a Maceden tart, és ugyanazokat a végpontokat hívja, mint a kliensek.

| Szolgáltató | Hitelesítő adatok forrása | Végpont | Mit mutat |
|---|---|---|---|
| Claude | Kulcskarika-elem `Claude Code-credentials` (a `/usr/bin/security` segítségével olvasva) | `api.anthropic.com/api/oauth/usage` | 5 órás ablak, heti ablak, modellenkénti heti keretek |
| Codex | `~/.codex/auth.json` (vagy `$CODEX_HOME/auth.json`) | `chatgpt.com/backend-api/wham/usage` | 5 órás ablak, heti ablak, csomag |
| Cursor | `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb` (csak olvasásra) | `cursor.com/api/usage-summary`, `…/get-sand-usage-status` | Cursor-modellek kerete (Auto / Composer / Grok), API-modellek kerete, igény szerinti költés, heti Grok Bot, a ciklusban elköltött összeg |

Az AgentBar nem frissít tokeneket. Ha egy szolgáltatónál *lejárt munkamenet* látszik, nyisd meg egyszer a klienst — az frissíti a tokent, és az AgentBar a következő frissítéskor átveszi.

## A panel

- Kattints a menüsor ikonjára: minden szolgáltató azonnal frissül; betöltés közben a korábbi értékek maradnak láthatók.
- A sávok 60 % alatt zöldek, felette sárgák, az értesítési küszöb elérésekor pirosak.
- Minden keret mutatja a hátralévő időt és a nullázás pontos időpontját, pl. *nullázás 2ó 15p múlva · csüt., szept. 24. 20:00*.
- A keret melletti csengő azt jelzi, hogy az értesítések be vannak kapcsolva hozzá (a Beállításokban állítható).
- Lábléc: statisztika · frissítés · beállítások · kilépés.

## Használati statisztika

A lábléc diagram gombja megnyitja a statisztikaablakot. Fent válthatsz szolgáltatót és időszakot; a diagram fölé vive az egeret látod a nap összesítését vagy egy modell részét.

| Szolgáltató | Forrás | Költség |
|---|---|---|
| Claude | Claude Code-átiratok (`~/.claude/projects/**/*.jsonl`), egyszer indexelve, fájlonként gyorsítótárazva | Amennyibe ugyanez a használat kerülne az API-n: be-/kimenet listaáron, gyorsítótár-írás ×1,25 (5 perces TTL) / ×2 (1 órás TTL), gyorsítótár-olvasás ×0,1 |
| Codex | Munkamenetnaplók (`~/.codex/sessions/**/*.jsonl`) | OpenAI API listaárak; gyorsítótárazott bemenet ×0,1. Nyilvános ár nélküli modelleknél csak tokenek jelennek meg |
| Cursor | Használati események a Cursor irányítópultjáról, helyben gyorsítótárazva. Első megnyitáskor választasz: teljes előzmény vagy csak az aktuális számlázási ciklus; később csak az új események töltődnek le | Ahogy a Cursor kérésenként jelenti |

**Miért térnek el az AgentBar Claude-összegei a Claude Code `/stats` értékétől.** A Claude Code minden átiratsort megszámol, és egy több blokkból (gondolkodás, szöveg, eszközhívások) álló válasz több, azonos használati rekordot megosztó sorként kerül mentésre — így többször számít. Az AgentBar minden választ egyszer számol a végleges értékekkel — ennyit számláz ténylegesen az API —, és mellette összehasonlításképp mutatja a Claude Code számát.

700 MB átirat indexelése először kb. 10 másodperc, utána jóval kevesebb mint egy másodperc. A gyorsítótárak a `~/Library/Application Support/AgentBar/` mappában vannak.

## Értesítések

- Kapcsold be az értesítéseket a Beállítások → Értesítések alatt, és válassz alapértelmezett küszöböt (50–95 %).
- Bármely keret némítható vagy saját küszöböt kaphat a Beállítások → Értesítések alatt.
- Keretenként és nullázási ciklusonként egy értesítés érkezik.
- A kereteket minden frissítéskor ellenőrzi: ütemezetten, ha be van kapcsolva az automatikus frissítés, egyébként csak a panel megnyitásakor.

## Beállítások

- **Általános** — frissítési időköz (ki / 1 / 5 / 15 / 30 / 60 perc), látható szolgáltatók, nyelv, indítás bejelentkezéskor, frissítések.
- **Értesítések** — főkapcsoló, alapértelmezett küszöb, keretenkénti szabályok.

## Frissítések

Az AgentBar naponta egyszer és a *Frissítések keresése* gombra kattintva ellenőrzi a GitHub Releases-t. Ha van újabb verzió, a panelen megjelenik egy *Frissítés* gomb. A frissítés letöltődik, SHA-256-a egyezik-e a közzétett ellenőrző összeggel, ellenőrzi a csomagazonosítót és a verziót, a régi alkalmazás a Kukába kerül, az új elindul. Bármelyik kiadás kézzel is telepíthető a [kiadások oldaláról](https://github.com/funbool/agentbar/releases).

## Fordítás forrásból

Xcode 15 vagy újabb szükséges (Swift 5.9). Nincs külső függőség.

```bash
git clone https://github.com/funbool/agentbar.git
cd agentbar
swift test                 # egységtesztek
./scripts/build.sh         # -> build/AgentBar.app
./scripts/install.sh       # fordítás, másolás az /Applications mappába és indítás
```

Hibakeresési segédek (a csomagban lévő binárist vagy a `.build/debug/AgentBar`-t futtasd):

```bash
AgentBar --dump            # minden szolgáltató egyszeri lekérdezése, a feldolgozott keretek kiírása
AgentBar --raw             # minden végpont nyers JSON-jának kiírása
AgentBar --stats           # helyi Claude/Codex naplók indexelése és összegek kiírása
AgentBar --cursor-events   # Cursor használati események letöltése és összegek kiírása
AgentBar --update          # a teljes frissítési ciklus futtatása felület nélkül
```

### Kiadás készítése

```bash
./scripts/release.sh 0.2.0
```

Ez megemeli a verziót a `Packaging/Info.plist`-ben, létrehozza a `v0.2.0` címkét és pushol. A GitHub Actions lefuttatja a teszteket, lefordítja az alkalmazást, közzéteszi az `AgentBar.zip` és `AgentBar.zip.sha256` fájlokat kiadásként, a futó példányok pedig a következő ellenőrzéskor felveszik.

## Adatvédelem és biztonság

- **Olvas:** a Claude Code kulcskarika-elemét, a `~/.codex/auth.json`-t, a Cursor `state.vscdb` fájlját (csak olvasásra), helyi átiratokat és munkamenetnaplókat.
- **Ír:** beállításokat és gyorsítótárakat a `~/Library/Application Support/AgentBar/` alá.
- **Hálózat:** `api.anthropic.com`, `chatgpt.com`, `cursor.com` (a saját használati adataid) és `api.github.com` / `github.com` (frissítések ellenőrzése és letöltése). Semmi más.
- A kiadásokat a GitHub Actions készíti a címkézett forrásból; a workflow a `.github/workflows/release.yml` fájlban van.

## Hibaelhárítás

| Tünet | Teendő |
|---|---|
| *Nincs bejelentkezve — nyisd meg: …* | Jelentkezz be egyszer az adott kliensbe; az AgentBar a következő frissítéskor beolvassa a mentett tokent. |
| A kulcskarika-kérdés újra és újra megjelenik | Válaszd a *Mindig engedélyezés* lehetőséget. Ha egy idő után újra megjelenik, a Claude Code lecserélte a tokenjét. |
| A Cursor nem mutat semmit | Nyisd meg egyszer a Cursort, hogy frissítse a munkamenet-tokent, majd frissítsd az AgentBart. |
| Az alkalmazás nem nyílik meg letöltés után | Gatekeeper — lásd [Telepítés](#telepítés). |
| A statisztika *Indexelés…* állapotban ragad | Nagy átiratmappák első indexelése eltart egy ideig; a későbbi futások a gyorsítótárat használják. |

## Köszönet

A végpontok feltérképezésében segített a nyílt forráskódú [CodexBar](https://github.com/steipete/CodexBar) projekt.

## Licenc

[MIT](../LICENSE)
