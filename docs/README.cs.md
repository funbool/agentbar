<!-- LANGS -->
[🇬🇧 English](../README.md) · [🇷🇺 Русский](README.ru.md) · [🇺🇦 Українська](README.uk.md) · [🇩🇪 Deutsch](README.de.md) · [🇫🇷 Français](README.fr.md) · [🇪🇸 Español](README.es.md) · [🇵🇹 Português](README.pt-PT.md) · [🇧🇷 Português (Brasil)](README.pt-BR.md) · [🇵🇱 Polski](README.pl.md) · **🇨🇿 Čeština** · [🇭🇺 Magyar](README.hu.md) · [🇹🇷 Türkçe](README.tr.md) · [🇰🇿 Қазақша](README.kk.md) · [🇮🇳 हिन्दी](README.hi.md) · [🇯🇵 日本語](README.ja.md) · [🇨🇳 简体中文](README.zh-Hans.md) · [🇹🇼 繁體中文](README.zh-Hant.md)
<!-- /LANGS -->

# AgentBar

Lehká aplikace pro řádek nabídek macOS, která ukazuje, kolik z limitů **Claude**, **Codex** a **Cursor** jste už vyčerpali — plus statistiky tokenů a kolik by stejné využití stálo přes veřejná API.

[![CI](https://github.com/funbool/agentbar/actions/workflows/ci.yml/badge.svg)](https://github.com/funbool/agentbar/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/funbool/agentbar?display_name=tag)](https://github.com/funbool/agentbar/releases/latest)
![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](../LICENSE)

## Funkce

- **Limity na první pohled** — 5hodinová a týdenní okna pro Claude a Codex, zahrnuté pooly využití pro Cursor; každý s ukazatelem průběhu, zbývajícím časem do resetu a přesným datem.
- **Týdenní limity podle modelu** pro Claude (Opus, Sonnet, Fable, …), jakmile je API nahlásí.
- **Statistiky využití** — tokeny podle typu, cena, rozpad podle modelu a projektu, denní graf; Dnes / 7 dní / 30 dní / Celkem.
- **Oznámení**, když limit překročí práh, s globálním prahem a pravidly pro jednotlivé limity (ztlumit, vlastní práh).
- **Volitelné automatické obnovování**, spuštění při přihlášení, 17 jazyků rozhraní.
- **Aktualizace vzduchem** z GitHub Releases ověřené pomocí SHA-256.
- **Žádné účty, žádná telemetrie.** AgentBar čte tokeny, které oficiální klienti už na vašem Macu mají, a komunikuje jen s API samotných poskytovatelů.

## Požadavky

- macOS 14 Sonoma nebo novější (Apple Silicon nebo Intel).
- Alespoň jeden přihlášený klient: [Claude Code](https://claude.com/claude-code), [Codex](https://openai.com/codex) (CLI nebo aplikace), [Cursor](https://cursor.com). Nepoužívané poskytovatele lze v Nastavení skrýt.

## Instalace

1. Stáhněte `AgentBar.zip` z [nejnovějšího vydání](https://github.com/funbool/agentbar/releases/latest).
2. Rozbalte a přesuňte `AgentBar.app` do `/Applications`.
3. Otevřete aplikaci. Zaregistruje se jako položka po přihlášení (lze vypnout v Nastavení).

**Gatekeeper.** Vydání jsou podepsána ad hoc, bez notarizace. Pokud macOS odmítne otevřít čerstvě staženou kopii, klikněte pravým tlačítkem → *Otevřít* jednou, nebo odstraňte příznak karantény:

```bash
xattr -dr com.apple.quarantine /Applications/AgentBar.app
```

**Dotaz Klíčenky.** Při prvním obnovení Claude se macOS zeptá, zda smí `security` číst položku *Claude Code-credentials*. Zvolte **Vždy povolit**. Dotaz se může vrátit poté, co Claude Code obmění svůj token — to je v pořádku.

Můžete také [sestavit ze zdrojů](#sestavení-ze-zdrojů).

## Jak to funguje

AgentBar nikdy nevyžaduje přihlášení. Čte přihlašovací údaje, které každý klient už na vašem Macu uchovává, a volá stejné endpointy jako samotní klienti.

| Poskytovatel | Údaje čtené z | Endpoint | Co se zobrazuje |
|---|---|---|---|
| Claude | Položka Klíčenky `Claude Code-credentials` (čtená přes `/usr/bin/security`) | `api.anthropic.com/api/oauth/usage` | 5hodinové okno, týdenní okno, týdenní limity podle modelu |
| Codex | `~/.codex/auth.json` (nebo `$CODEX_HOME/auth.json`) | `chatgpt.com/backend-api/wham/usage` | 5hodinové okno, týdenní okno, tarif |
| Cursor | `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb` (jen pro čtení) | `cursor.com/api/usage-summary`, `…/get-sand-usage-status` | Pool modelů Cursor (Auto / Composer / Grok), pool API modelů, útrata na vyžádání, Grok Bot týdně, útrata v období |

AgentBar tokeny neobnovuje. Pokud poskytovatel hlásí *relace vypršela*, otevřete jednou jeho klienta — obnoví token a AgentBar ho při dalším obnovení převezme.

## Panel

- Klik na ikonu v řádku nabídek: všichni poskytovatelé se okamžitě obnoví; během načítání zůstávají vidět předchozí hodnoty.
- Ukazatele jsou zelené pod 60 %, žluté nad tím, červené po dosažení prahu oznámení.
- Každý limit ukazuje zbývající čas a přesný okamžik resetu, např. *reset za 2h 15m · čt 24. 9. 20:00*.
- Zvonek u limitu znamená, že jsou pro něj oznámení zapnutá (nastavují se v Nastavení).
- Patička: statistiky · obnovit · nastavení · ukončit.

## Statistiky využití

Tlačítko grafu v patičce otevře okno statistik. Nahoře přepínáte poskytovatele a období; najetím na graf uvidíte součet dne nebo podíl konkrétního modelu.

| Poskytovatel | Zdroj | Cena |
|---|---|---|
| Claude | Přepisy Claude Code (`~/.claude/projects/**/*.jsonl`), jednou indexované a cachované po souborech | Kolik by stejné využití stálo přes API: vstup/výstup podle ceníku, zápis cache ×1,25 (TTL 5 min) / ×2 (TTL 1 h), čtení cache ×0,1 |
| Codex | Záznamy relací (`~/.codex/sessions/**/*.jsonl`) | Ceník OpenAI API; vstup z cache ×0,1. Modely bez veřejné ceny zobrazují jen tokeny |
| Cursor | Události využití z panelu Cursoru, cachované lokálně. Při prvním otevření zvolíte celou historii, nebo jen aktuální zúčtovací období; dále se stahují jen nové události | Tak, jak Cursor uvádí u každého požadavku |

**Proč se součty Claude v AgentBaru liší od `/stats` v Claude Code.** Claude Code počítá každý řádek přepisu a odpověď s více bloky (myšlení, text, volání nástrojů) je uložena jako více řádků se stejným záznamem využití — započte se tedy vícekrát. AgentBar počítá každou odpověď jednou s konečnými hodnotami — přesně to, co účtuje API — a vedle zobrazuje číslo z Claude Code pro srovnání.

Indexace 700 MB přepisů trvá poprvé asi 10 sekund a poté výrazně méně než sekundu. Cache jsou v `~/Library/Application Support/AgentBar/`.

## Oznámení

- Zapněte oznámení v Nastavení → Oznámení a zvolte výchozí práh (50–95 %).
- Každý limit lze ztlumit nebo mu dát vlastní práh v Nastavení → Oznámení.
- Dostanete jedno oznámení na limit a cyklus resetu.
- Limity se kontrolují při každém obnovení: podle plánu, pokud je zapnuté automatické obnovování, jinak jen při otevření panelu.

## Nastavení

- **Obecné** — interval obnovování (vypnuto / 1 / 5 / 15 / 30 / 60 min), viditelní poskytovatelé, jazyk, spuštění při přihlášení, aktualizace.
- **Oznámení** — hlavní přepínač, výchozí práh, pravidla pro limity.

## Aktualizace

AgentBar kontroluje GitHub Releases jednou denně a po stisku *Zkontrolovat aktualizace*. Když existuje novější verze, panel zobrazí tlačítko *Aktualizovat*. Aktualizace se stáhne, její SHA-256 se ověří proti zveřejněnému součtu, zkontroluje se identifikátor balíčku a verze, stará aplikace putuje do Koše a nová se spustí. Jakékoli vydání lze nainstalovat i ručně ze [stránky vydání](https://github.com/funbool/agentbar/releases).

## Sestavení ze zdrojů

Vyžaduje Xcode 15 nebo novější (Swift 5.9). Bez závislostí třetích stran.

```bash
git clone https://github.com/funbool/agentbar.git
cd agentbar
swift test                 # jednotkové testy
./scripts/build.sh         # -> build/AgentBar.app
./scripts/install.sh       # sestavit, zkopírovat do /Applications a spustit
```

Ladicí režimy (spusťte binárku z balíčku nebo `.build/debug/AgentBar`):

```bash
AgentBar --dump            # jednou se dotázat všech poskytovatelů a vypsat rozparsované limity
AgentBar --raw             # vypsat surový JSON každého endpointu
AgentBar --stats           # zaindexovat lokální logy Claude/Codex a vypsat součty
AgentBar --cursor-events   # stáhnout události Cursoru a vypsat součty
AgentBar --update          # projet celý aktualizační cyklus bez UI
```

### Vydání verze

```bash
./scripts/release.sh 0.2.0
```

Skript zvýší verzi v `Packaging/Info.plist`, vytvoří tag `v0.2.0` a odešle změny. GitHub Actions spustí testy, sestaví aplikaci, zveřejní `AgentBar.zip` a `AgentBar.zip.sha256` jako vydání a běžící kopie si ho stáhnou při další kontrole.

## Soukromí a bezpečnost

- **Čte:** položku Klíčenky Claude Code, `~/.codex/auth.json`, `state.vscdb` Cursoru (jen pro čtení), lokální přepisy a záznamy relací.
- **Zapisuje:** předvolby a cache v `~/Library/Application Support/AgentBar/`.
- **Síť:** `api.anthropic.com`, `chatgpt.com`, `cursor.com` (vaše vlastní data o využití) a `api.github.com` / `github.com` (kontrola a stahování aktualizací). Nic dalšího.
- Vydání sestavuje GitHub Actions z otagovaného zdroje; workflow je v `.github/workflows/release.yml`.

## Řešení potíží

| Příznak | Co dělat |
|---|---|
| *Nepřihlášeno — otevřete …* | Přihlaste se jednou v daném klientovi; AgentBar načte uložený token při dalším obnovení. |
| Dotaz Klíčenky se stále vrací | Zvolte *Vždy povolit*. Nový dotaz po čase znamená, že Claude Code obměnil token. |
| Cursor nic nezobrazuje | Otevřete jednou Cursor, aby obnovil token relace, a pak obnovte AgentBar. |
| Aplikace se po stažení neotevře | Gatekeeper — viz [Instalace](#instalace). |
| Statistiky stojí na *Indexování…* | První indexace velkých složek s přepisy chvíli trvá; další běhy používají cache. |

## Poděkování

Při zkoumání endpointů pomohl open-source projekt [CodexBar](https://github.com/steipete/CodexBar).

## Licence

[MIT](../LICENSE)
