<!-- LANGS -->
[🇬🇧 English](../README.md) · [🇷🇺 Русский](README.ru.md) · [🇺🇦 Українська](README.uk.md) · **🇩🇪 Deutsch** · [🇫🇷 Français](README.fr.md) · [🇪🇸 Español](README.es.md) · [🇵🇹 Português](README.pt-PT.md) · [🇧🇷 Português (Brasil)](README.pt-BR.md) · [🇵🇱 Polski](README.pl.md) · [🇨🇿 Čeština](README.cs.md) · [🇭🇺 Magyar](README.hu.md) · [🇹🇷 Türkçe](README.tr.md) · [🇰🇿 Қазақша](README.kk.md) · [🇮🇳 हिन्दी](README.hi.md) · [🇯🇵 日本語](README.ja.md) · [🇨🇳 简体中文](README.zh-Hans.md) · [🇹🇼 繁體中文](README.zh-Hant.md)
<!-- /LANGS -->

# AgentBar

Eine leichtgewichtige Menüleisten-App für macOS, die zeigt, wie viel deiner **Claude**-, **Codex**- und **Cursor**-Limits verbraucht ist — plus Token-Statistiken und was dieselbe Nutzung über die öffentlichen APIs kosten würde.

[![CI](https://github.com/funbool/agentbar/actions/workflows/ci.yml/badge.svg)](https://github.com/funbool/agentbar/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/funbool/agentbar?display_name=tag)](https://github.com/funbool/agentbar/releases/latest)
![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](../LICENSE)

## Funktionen

- **Limits auf einen Blick** — 5-Stunden- und Wochenfenster für Claude und Codex, enthaltene Nutzungspools für Cursor, jeweils mit Fortschrittsbalken, verbleibender Zeit bis zum Reset und exaktem Reset-Datum.
- **Wochenlimits pro Modell** für Claude (Opus, Sonnet, Fable, …), sobald die API sie meldet.
- **Nutzungsstatistik** — Tokens nach Typ, Kosten, Aufschlüsselung nach Modell und Projekt, Tagesdiagramm; Heute / 7 Tage / 30 Tage / Gesamt.
- **Benachrichtigungen**, wenn ein Limit eine Schwelle überschreitet, mit globalem Standard und Regeln pro Limit (stummschalten, eigene Schwelle).
- **Optionale automatische Aktualisierung**, Start bei Anmeldung, 17 Oberflächensprachen.
- **Over-the-Air-Updates** aus GitHub Releases, per SHA-256 geprüft.
- **Keine Konten, keine Telemetrie.** AgentBar liest die Tokens, die die offiziellen Clients bereits auf deinem Mac speichern, und spricht nur mit den APIs der Anbieter.

## Voraussetzungen

- macOS 14 Sonoma oder neuer (Apple Silicon oder Intel).
- Mindestens einer dieser Clients, angemeldet: [Claude Code](https://claude.com/claude-code), [Codex](https://openai.com/codex) (CLI oder Desktop-App), [Cursor](https://cursor.com). Nicht genutzte Anbieter lassen sich in den Einstellungen ausblenden.

## Installation

1. Lade `AgentBar.zip` aus dem [neuesten Release](https://github.com/funbool/agentbar/releases/latest) herunter.
2. Entpacke es und verschiebe `AgentBar.app` nach `/Applications`.
3. Öffne die App. Sie trägt sich als Anmeldeobjekt ein (in den Einstellungen abschaltbar).

**Gatekeeper.** Releases sind ad hoc signiert, nicht notarisiert. Weigert sich macOS, eine frisch geladene Kopie zu öffnen, wähle per Rechtsklick einmal *Öffnen* oder entferne das Quarantäne-Flag:

```bash
xattr -dr com.apple.quarantine /Applications/AgentBar.app
```

**Schlüsselbund-Abfrage.** Bei der ersten Claude-Aktualisierung fragt macOS, ob `security` das Element *Claude Code-credentials* lesen darf. Wähle **Immer erlauben**. Die Abfrage kann erneut erscheinen, nachdem Claude Code sein Token rotiert hat — das ist normal.

Du kannst die App auch [aus dem Quellcode bauen](#aus-dem-quellcode-bauen).

## Funktionsweise

AgentBar verlangt nie eine Anmeldung. Es liest die Zugangsdaten, die jeder Client bereits auf deinem Mac ablegt, und ruft dieselben Endpunkte auf wie die Clients selbst.

| Anbieter | Zugangsdaten aus | Endpunkt | Angezeigt wird |
|---|---|---|---|
| Claude | Schlüsselbund-Element `Claude Code-credentials` (gelesen über `/usr/bin/security`) | `api.anthropic.com/api/oauth/usage` | 5-Stunden-Fenster, Wochenfenster, Wochenlimits pro Modell |
| Codex | `~/.codex/auth.json` (oder `$CODEX_HOME/auth.json`) | `chatgpt.com/backend-api/wham/usage` | 5-Stunden-Fenster, Wochenfenster, Tarif |
| Cursor | `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb` (nur lesend) | `cursor.com/api/usage-summary`, `…/get-sand-usage-status` | Pool der Cursor-Modelle (Auto / Composer / Grok), Pool der API-Modelle, On-Demand-Ausgaben, Grok Bot wöchentlich, Ausgaben im Zeitraum |

AgentBar erneuert keine Tokens. Zeigt ein Anbieter *Sitzung abgelaufen*, öffne den Client einmal — er erneuert das Token, und AgentBar übernimmt es bei der nächsten Aktualisierung.

## Das Panel

- Klick auf das Menüleisten-Symbol: alle Anbieter werden sofort aktualisiert; während des Ladens bleiben die letzten Werte sichtbar.
- Balken sind grün unter 60 %, gelb darüber, rot ab der Benachrichtigungsschwelle.
- Jedes Limit zeigt die Restzeit und den genauen Reset-Zeitpunkt, z. B. *Reset in 2h 15m · Do, 24. Sep 20:00*.
- Eine Glocke neben einem Limit bedeutet, dass Benachrichtigungen dafür aktiv sind (konfiguriert in den Einstellungen).
- Fußzeile: Statistik · Aktualisieren · Einstellungen · Beenden.

## Nutzungsstatistik

Der Diagramm-Button in der Fußzeile öffnet das Statistikfenster. Oben wechselst du Anbieter und Zeitraum; beim Überfahren des Diagramms siehst du die Tagessumme oder den Anteil eines einzelnen Modells.

| Anbieter | Quelle | Kosten |
|---|---|---|
| Claude | Claude-Code-Transkripte (`~/.claude/projects/**/*.jsonl`), einmal indexiert und pro Datei gecacht | Was dieselbe Nutzung über die API kosten würde: Ein-/Ausgabe zum Listenpreis, Cache-Schreiben ×1,25 (5-Min-TTL) / ×2 (1-Std-TTL), Cache-Lesen ×0,1 |
| Codex | Sitzungsprotokolle (`~/.codex/sessions/**/*.jsonl`) | OpenAI-API-Listenpreise; gecachte Eingabe ×0,1. Modelle ohne öffentlichen Preis zeigen nur Tokens |
| Cursor | Nutzungsereignisse aus dem Cursor-Dashboard, lokal gecacht. Beim ersten Öffnen wählst du: gesamter Verlauf oder nur aktueller Abrechnungszeitraum; spätere Aktualisierungen holen nur neue Ereignisse | Wie von Cursor pro Anfrage gemeldet |

**Warum die Claude-Summen von `/stats` in Claude Code abweichen.** Claude Code zählt jede Transkriptzeile; eine Antwort mit mehreren Inhaltsblöcken (Thinking, Text, Tool-Aufrufe) wird als mehrere Zeilen mit demselben Nutzungsdatensatz gespeichert, sodass solche Antworten mehrfach zählen. AgentBar zählt jede Antwort einmal mit den finalen Nutzungswerten — das ist, was die API tatsächlich berechnet — und zeigt die Claude-Code-Zahl daneben zum Vergleich.

Das Indexieren von 700 MB Transkripten dauert beim ersten Mal etwa 10 Sekunden, danach deutlich unter einer Sekunde. Caches liegen in `~/Library/Application Support/AgentBar/`.

## Benachrichtigungen

- Aktiviere Benachrichtigungen unter Einstellungen → Benachrichtigungen und wähle eine Standardschwelle (50–95 %).
- Jedes Limit kann unter Einstellungen → Benachrichtigungen stummgeschaltet oder mit eigener Schwelle versehen werden.
- Pro Limit und Reset-Zyklus gibt es eine Benachrichtigung.
- Limits werden bei jeder Aktualisierung geprüft: nach Zeitplan bei aktiver automatischer Aktualisierung, sonst nur beim Öffnen des Panels.

## Einstellungen

- **Allgemein** — Aktualisierungsintervall (aus / 1 / 5 / 15 / 30 / 60 Min.), sichtbare Anbieter, Sprache, Start bei Anmeldung, Updates.
- **Benachrichtigungen** — Hauptschalter, Standardschwelle, Regeln pro Limit.

## Updates

AgentBar prüft GitHub Releases einmal täglich und bei Klick auf *Nach Updates suchen*. Gibt es eine neuere Version, zeigt das Panel einen *Aktualisieren*-Button. Das Update wird heruntergeladen, sein SHA-256 gegen die veröffentlichte Prüfsumme verifiziert, Bundle-Identifier und Version werden geprüft, die alte App wandert in den Papierkorb und die neue startet. Jedes Release lässt sich auch manuell von der [Releases-Seite](https://github.com/funbool/agentbar/releases) installieren.

## Aus dem Quellcode bauen

Benötigt Xcode 15 oder neuer (Swift 5.9). Keine Drittabhängigkeiten.

```bash
git clone https://github.com/funbool/agentbar.git
cd agentbar
swift test                 # Unit-Tests
./scripts/build.sh         # -> build/AgentBar.app
./scripts/install.sh       # bauen, nach /Applications kopieren und starten
```

Debug-Helfer (Binary im Bundle oder `.build/debug/AgentBar` ausführen):

```bash
AgentBar --dump            # alle Anbieter einmal abfragen und geparste Limits ausgeben
AgentBar --raw             # rohes JSON jedes Endpunkts ausgeben
AgentBar --stats           # lokale Claude/Codex-Protokolle indexieren und Summen ausgeben
AgentBar --cursor-events   # Cursor-Nutzungsereignisse laden und Summen ausgeben
AgentBar --update          # den kompletten Update-Zyklus ohne UI durchlaufen
```

### Release veröffentlichen

```bash
./scripts/release.sh 0.2.0
```

Das erhöht die Version in `Packaging/Info.plist`, setzt den Tag `v0.2.0` und pusht. GitHub Actions führt die Tests aus, baut die App, veröffentlicht `AgentBar.zip` und `AgentBar.zip.sha256` als Release, und laufende Installationen übernehmen es bei der nächsten Prüfung.

## Datenschutz und Sicherheit

- **Liest:** das Claude-Code-Schlüsselbund-Element, `~/.codex/auth.json`, Cursors `state.vscdb` (nur lesend), lokale Transkripte und Sitzungsprotokolle.
- **Schreibt:** Einstellungen und Caches unter `~/Library/Application Support/AgentBar/`.
- **Netzwerk:** `api.anthropic.com`, `chatgpt.com`, `cursor.com` (deine eigenen Nutzungsdaten) sowie `api.github.com` / `github.com` (Update-Prüfung und -Download). Sonst nichts.
- Releases werden von GitHub Actions aus dem getaggten Quellcode gebaut; der Workflow liegt in `.github/workflows/release.yml`.

## Fehlerbehebung

| Symptom | Abhilfe |
|---|---|
| *Nicht angemeldet — öffne …* | Melde dich einmal in diesem Client an; AgentBar liest das gespeicherte Token bei der nächsten Aktualisierung. |
| Schlüsselbund-Abfrage kommt immer wieder | Wähle *Immer erlauben*. Eine neue Abfrage nach einiger Zeit bedeutet, dass Claude Code sein Token rotiert hat. |
| Cursor zeigt nichts | Öffne Cursor einmal, damit es sein Sitzungstoken erneuert, und aktualisiere dann AgentBar. |
| App öffnet sich nach dem Download nicht | Gatekeeper — siehe [Installation](#installation). |
| Statistik hängt bei *Indexierung…* | Die erste Indexierung großer Transkriptordner dauert; spätere Läufe nutzen den Cache. |

## Danksagung

Die Recherche der Endpunkte wurde durch das Open-Source-Projekt [CodexBar](https://github.com/steipete/CodexBar) erleichtert.

## Lizenz

[MIT](../LICENSE)
