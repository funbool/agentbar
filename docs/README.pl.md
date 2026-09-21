<!-- LANGS -->
[🇬🇧 English](../README.md) · [🇷🇺 Русский](README.ru.md) · [🇺🇦 Українська](README.uk.md) · [🇩🇪 Deutsch](README.de.md) · [🇫🇷 Français](README.fr.md) · [🇪🇸 Español](README.es.md) · [🇵🇹 Português](README.pt-PT.md) · [🇧🇷 Português (Brasil)](README.pt-BR.md) · **🇵🇱 Polski** · [🇨🇿 Čeština](README.cs.md) · [🇭🇺 Magyar](README.hu.md) · [🇹🇷 Türkçe](README.tr.md) · [🇰🇿 Қазақша](README.kk.md) · [🇮🇳 हिन्दी](README.hi.md) · [🇯🇵 日本語](README.ja.md) · [🇨🇳 简体中文](README.zh-Hans.md) · [🇹🇼 繁體中文](README.zh-Hant.md)
<!-- /LANGS -->

# AgentBar

Lekka aplikacja do paska menu macOS, która pokazuje, ile limitów **Claude**, **Codex** i **Cursor** już zużyłeś — a także statystyki tokenów i to, ile to samo użycie kosztowałoby przez publiczne API.

[![CI](https://github.com/funbool/agentbar/actions/workflows/ci.yml/badge.svg)](https://github.com/funbool/agentbar/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/funbool/agentbar?display_name=tag)](https://github.com/funbool/agentbar/releases/latest)
![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](../LICENSE)

## Funkcje

- **Limity na pierwszy rzut oka** — okna 5-godzinne i tygodniowe dla Claude i Codex, pule użycia w ramach planu dla Cursora; każdy z paskiem postępu, czasem do resetu i dokładną datą resetu.
- **Tygodniowe limity per model** dla Claude (Opus, Sonnet, Fable, …), gdy tylko API je zgłosi.
- **Statystyki użycia** — tokeny wg typu, koszt, podział wg modelu i projektu, wykres dzienny; Dziś / 7 dni / 30 dni / Cały okres.
- **Powiadomienia**, gdy limit przekroczy próg, z progiem domyślnym i regułami dla każdego limitu (wyciszenie, własny próg).
- **Opcjonalne automatyczne odświeżanie**, uruchamianie przy logowaniu, 17 języków interfejsu.
- **Aktualizacje OTA** z GitHub Releases, weryfikowane SHA-256.
- **Bez kont i telemetrii.** AgentBar czyta tokeny, które oficjalne klienty już przechowują na Twoim Macu, i łączy się wyłącznie z API dostawców.

## Wymagania

- macOS 14 Sonoma lub nowszy (Apple Silicon lub Intel).
- Co najmniej jeden zalogowany klient: [Claude Code](https://claude.com/claude-code), [Codex](https://openai.com/codex) (CLI lub aplikacja), [Cursor](https://cursor.com). Nieużywanych dostawców można ukryć w Ustawieniach.

## Instalacja

1. Pobierz `AgentBar.zip` z [najnowszego wydania](https://github.com/funbool/agentbar/releases/latest).
2. Rozpakuj i przenieś `AgentBar.app` do `/Applications`.
3. Otwórz aplikację. Doda się do elementów logowania (można to wyłączyć w Ustawieniach).

**Gatekeeper.** Wydania są podpisane ad hoc, bez notaryzacji. Jeśli macOS odmawia otwarcia świeżo pobranej kopii, kliknij prawym przyciskiem → *Otwórz* jeden raz albo usuń flagę kwarantanny:

```bash
xattr -dr com.apple.quarantine /Applications/AgentBar.app
```

**Monit pęku kluczy.** Przy pierwszym odświeżeniu Claude macOS zapyta, czy `security` może odczytać element *Claude Code-credentials*. Wybierz **Zawsze zezwalaj**. Monit może wrócić po tym, jak Claude Code zrotuje token — to normalne.

Możesz też [zbudować ze źródeł](#budowanie-ze-źródeł).

## Jak to działa

AgentBar nigdy nie prosi o logowanie. Czyta dane uwierzytelniające, które każdy klient już trzyma na Twoim Macu, i wywołuje te same endpointy, co klienty.

| Dostawca | Skąd dane uwierzytelniające | Endpoint | Co jest pokazywane |
|---|---|---|---|
| Claude | Element pęku kluczy `Claude Code-credentials` (odczyt przez `/usr/bin/security`) | `api.anthropic.com/api/oauth/usage` | Okno 5 h, okno tygodniowe, tygodniowe limity per model |
| Codex | `~/.codex/auth.json` (lub `$CODEX_HOME/auth.json`) | `chatgpt.com/backend-api/wham/usage` | Okno 5 h, okno tygodniowe, plan |
| Cursor | `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb` (tylko odczyt) | `cursor.com/api/usage-summary`, `…/get-sand-usage-status` | Pula modeli Cursor (Auto / Composer / Grok), pula modeli API, wydatki na żądanie, Grok Bot tygodniowo, wydatki w cyklu |

AgentBar nie odświeża tokenów. Jeśli dostawca pokazuje *sesja wygasła*, otwórz raz jego klienta — odświeży token, a AgentBar pobierze go przy następnym odświeżeniu.

## Panel

- Kliknij ikonę w pasku menu: wszyscy dostawcy są odświeżani natychmiast; w trakcie ładowania widać poprzednie wartości.
- Paski są zielone poniżej 60 %, żółte powyżej, czerwone po osiągnięciu progu powiadomienia.
- Każdy limit pokazuje pozostały czas i dokładny moment resetu, np. *reset za 2h 15m · czw, 24 wrz 20:00*.
- Dzwonek obok limitu oznacza, że powiadomienia dla niego są włączone (konfiguruje się je w Ustawieniach).
- Stopka: statystyki · odśwież · ustawienia · zakończ.

## Statystyki użycia

Przycisk wykresu w stopce otwiera okno statystyk. U góry przełączasz dostawcę i okres; najechanie na wykres pokazuje sumę dnia lub udział konkretnego modelu.

| Dostawca | Źródło | Koszt |
|---|---|---|
| Claude | Transkrypcje Claude Code (`~/.claude/projects/**/*.jsonl`), indeksowane raz i buforowane per plik | Ile to samo użycie kosztowałoby przez API: wejście/wyjście wg cennika, zapis cache ×1,25 (TTL 5 min) / ×2 (TTL 1 h), odczyt cache ×0,1 |
| Codex | Logi sesji (`~/.codex/sessions/**/*.jsonl`) | Cennik API OpenAI; wejście z cache ×0,1. Modele bez publicznej ceny pokazują tylko tokeny |
| Cursor | Zdarzenia użycia z panelu Cursora, buforowane lokalnie. Przy pierwszym otwarciu wybierasz: cała historia czy tylko bieżący cykl rozliczeniowy; potem pobierane są tylko nowe zdarzenia | Tak, jak Cursor podaje dla każdego żądania |

**Dlaczego sumy Claude w AgentBar różnią się od `/stats` w Claude Code.** Claude Code liczy każdą linię transkrypcji, a odpowiedź z kilku bloków (myślenie, tekst, wywołania narzędzi) jest zapisywana jako kilka linii z tym samym rekordem użycia — więc liczona jest kilkukrotnie. AgentBar liczy każdą odpowiedź raz, biorąc końcowe wartości użycia — dokładnie tyle rozlicza API — a obok pokazuje liczbę z Claude Code dla porównania.

Indeksowanie 700 MB transkrypcji zajmuje ok. 10 sekund za pierwszym razem i znacznie poniżej sekundy później. Bufory leżą w `~/Library/Application Support/AgentBar/`.

## Powiadomienia

- Włącz powiadomienia w Ustawienia → Powiadomienia i wybierz próg domyślny (50–95 %).
- Każdy limit można wyciszyć lub nadać mu własny próg w Ustawienia → Powiadomienia.
- Dostajesz jedno powiadomienie na limit na cykl resetu.
- Limity są sprawdzane przy każdym odświeżeniu: według harmonogramu, jeśli włączono automatyczne odświeżanie, w przeciwnym razie tylko przy otwarciu panelu.

## Ustawienia

- **Ogólne** — interwał odświeżania (wył. / 1 / 5 / 15 / 30 / 60 min), widoczni dostawcy, język, uruchamianie przy logowaniu, aktualizacje.
- **Powiadomienia** — przełącznik główny, próg domyślny, reguły dla limitów.

## Aktualizacje

AgentBar sprawdza GitHub Releases raz dziennie i po kliknięciu *Sprawdź aktualizacje*. Gdy jest nowsza wersja, panel pokazuje przycisk *Aktualizuj*. Aktualizacja jest pobierana, jej SHA-256 weryfikowany z opublikowaną sumą, sprawdzane są identyfikator pakietu i wersja, stara aplikacja trafia do Kosza, a nowa jest uruchamiana. Każde wydanie można też zainstalować ręcznie ze [strony wydań](https://github.com/funbool/agentbar/releases).

## Budowanie ze źródeł

Wymaga Xcode 15 lub nowszego (Swift 5.9). Bez zewnętrznych zależności.

```bash
git clone https://github.com/funbool/agentbar.git
cd agentbar
swift test                 # testy jednostkowe
./scripts/build.sh         # -> build/AgentBar.app
./scripts/install.sh       # zbuduj, skopiuj do /Applications i uruchom
```

Narzędzia debugowania (uruchom binarkę z pakietu lub `.build/debug/AgentBar`):

```bash
AgentBar --dump            # odpytaj każdego dostawcę raz i wypisz sparsowane limity
AgentBar --raw             # wypisz surowy JSON każdego endpointu
AgentBar --stats           # zindeksuj lokalne logi Claude/Codex i wypisz sumy
AgentBar --cursor-events   # pobierz zdarzenia użycia Cursora i wypisz sumy
AgentBar --update          # przeprowadź pełny cykl aktualizacji bez interfejsu
```

### Publikowanie wydania

```bash
./scripts/release.sh 0.2.0
```

Skrypt podbija wersję w `Packaging/Info.plist`, tworzy tag `v0.2.0` i wypycha zmiany. GitHub Actions uruchamia testy, buduje aplikację, publikuje `AgentBar.zip` i `AgentBar.zip.sha256` jako wydanie, a działające kopie pobierają je przy następnym sprawdzeniu.

## Prywatność i bezpieczeństwo

- **Czyta:** element pęku kluczy Claude Code, `~/.codex/auth.json`, `state.vscdb` Cursora (tylko odczyt), lokalne transkrypcje i logi sesji.
- **Zapisuje:** preferencje i bufory w `~/Library/Application Support/AgentBar/`.
- **Sieć:** `api.anthropic.com`, `chatgpt.com`, `cursor.com` (Twoje własne dane o użyciu) oraz `api.github.com` / `github.com` (sprawdzanie i pobieranie aktualizacji). Nic więcej.
- Wydania buduje GitHub Actions z otagowanego źródła; workflow jest w `.github/workflows/release.yml`.

## Rozwiązywanie problemów

| Objaw | Co zrobić |
|---|---|
| *Nie zalogowano — otwórz …* | Zaloguj się raz w tym kliencie; AgentBar odczyta zapisany token przy następnym odświeżeniu. |
| Monit pęku kluczy wraca | Wybierz *Zawsze zezwalaj*. Nowy monit po jakimś czasie oznacza, że Claude Code zrotował token. |
| Cursor nic nie pokazuje | Otwórz raz Cursora, aby odświeżył token sesji, a potem odśwież AgentBar. |
| Aplikacja nie otwiera się po pobraniu | Gatekeeper — zobacz [Instalacja](#instalacja). |
| Statystyki stoją na *Indeksowanie…* | Pierwsze indeksowanie dużych folderów trwa; kolejne uruchomienia korzystają z bufora. |

## Podziękowania

W badaniu endpointów pomógł otwartoźródłowy projekt [CodexBar](https://github.com/steipete/CodexBar).

## Licencja

[MIT](../LICENSE)
