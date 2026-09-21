<!-- LANGS -->
[🇬🇧 English](../README.md) · [🇷🇺 Русский](README.ru.md) · [🇺🇦 Українська](README.uk.md) · [🇩🇪 Deutsch](README.de.md) · [🇫🇷 Français](README.fr.md) · [🇪🇸 Español](README.es.md) · [🇵🇹 Português](README.pt-PT.md) · **🇧🇷 Português (Brasil)** · [🇵🇱 Polski](README.pl.md) · [🇨🇿 Čeština](README.cs.md) · [🇭🇺 Magyar](README.hu.md) · [🇹🇷 Türkçe](README.tr.md) · [🇰🇿 Қазақша](README.kk.md) · [🇮🇳 हिन्दी](README.hi.md) · [🇯🇵 日本語](README.ja.md) · [🇨🇳 简体中文](README.zh-Hans.md) · [🇹🇼 繁體中文](README.zh-Hant.md)
<!-- /LANGS -->

# AgentBar

Um app leve para a barra de menus do macOS que mostra quanto dos seus limites do **Claude**, **Codex** e **Cursor** você já usou — além de estatísticas de tokens e quanto o mesmo uso custaria pelas APIs públicas.

[![CI](https://github.com/funbool/agentbar/actions/workflows/ci.yml/badge.svg)](https://github.com/funbool/agentbar/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/funbool/agentbar?display_name=tag)](https://github.com/funbool/agentbar/releases/latest)
![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](../LICENSE)

## Recursos

- **Limites de relance** — janelas de 5 horas e semanais para Claude e Codex, pools de uso incluído para o Cursor, cada um com barra de progresso, tempo restante até o reinício e data exata.
- **Limites semanais por modelo** para o Claude (Opus, Sonnet, Fable, …) assim que a API os informa.
- **Estatísticas de uso** — tokens por tipo, custo, detalhamento por modelo e por projeto, gráfico diário; Hoje / 7 dias / 30 dias / Tudo.
- **Notificações** quando um limite passa de um limiar, com valor global e regras por limite (silenciar, limiar próprio).
- **Atualização automática** opcional, abrir ao fazer login, 17 idiomas de interface.
- **Atualizações remotas** pelo GitHub Releases, verificadas com SHA-256.
- **Sem contas, sem telemetria.** O AgentBar lê os tokens que os clientes oficiais já guardam no seu Mac e só fala com as APIs dos próprios provedores.

## Requisitos

- macOS 14 Sonoma ou mais recente (Apple Silicon ou Intel).
- Pelo menos um destes clientes logado: [Claude Code](https://claude.com/claude-code), [Codex](https://openai.com/codex) (CLI ou app), [Cursor](https://cursor.com). Provedores que você não usa podem ser ocultados nas Configurações.

## Instalação

1. Baixe o `AgentBar.zip` na [versão mais recente](https://github.com/funbool/agentbar/releases/latest).
2. Descompacte e mova o `AgentBar.app` para `/Applications`.
3. Abra o app. Ele se registra como item de login (dá para desligar nas Configurações).

**Gatekeeper.** As versões são assinadas ad hoc, sem notarização. Se o macOS se recusar a abrir uma cópia recém-baixada, clique com o botão direito → *Abrir* uma vez, ou remova o atributo de quarentena:

```bash
xattr -dr com.apple.quarantine /Applications/AgentBar.app
```

**Aviso das Chaves.** Na primeira atualização do Claude, o macOS pergunta se o `security` pode ler o item *Claude Code-credentials*. Escolha **Sempre permitir**. O aviso pode voltar depois que o Claude Code rotacionar o token — isso é esperado.

Você também pode [compilar a partir do código-fonte](#compilar-a-partir-do-código-fonte).

## Como funciona

O AgentBar nunca pede login. Ele lê as credenciais que cada cliente já mantém no seu Mac e chama os mesmos endpoints que os clientes usam.

| Provedor | Credenciais lidas de | Endpoint | O que é mostrado |
|---|---|---|---|
| Claude | Item das Chaves `Claude Code-credentials` (lido via `/usr/bin/security`) | `api.anthropic.com/api/oauth/usage` | Janela de 5 h, janela semanal, limites semanais por modelo |
| Codex | `~/.codex/auth.json` (ou `$CODEX_HOME/auth.json`) | `chatgpt.com/backend-api/wham/usage` | Janela de 5 h, janela semanal, plano |
| Cursor | `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb` (somente leitura) | `cursor.com/api/usage-summary`, `…/get-sand-usage-status` | Pool de modelos do Cursor (Auto / Composer / Grok), pool de modelos API, gasto sob demanda, Grok Bot semanal, gasto no ciclo |

O AgentBar não renova tokens. Se um provedor mostrar *sessão expirada*, abra aquele cliente uma vez — ele renova o token e o AgentBar pega na próxima atualização.

## O painel

- Clique no ícone da barra de menus: todos os provedores são atualizados na hora; enquanto carrega, os valores anteriores continuam visíveis.
- As barras ficam verdes abaixo de 60 %, amarelas acima e vermelhas ao atingir o limiar de notificação.
- Cada limite mostra o tempo restante e o momento exato do reinício, p. ex. *reinicia em 2h 15m · qui, 24 set 20:00*.
- O sino ao lado de um limite abre a regra de notificação dele (ligar/desligar, limiar).
- Rodapé: estatísticas · atualizar · configurações · sair.

## Estatísticas de uso

O botão de gráfico no rodapé abre a janela de estatísticas. No topo você troca provedor e período; passando o mouse no gráfico vê o total do dia ou a parte de um modelo.

| Provedor | Fonte | Custo |
|---|---|---|
| Claude | Transcrições do Claude Code (`~/.claude/projects/**/*.jsonl`), indexadas uma vez e cacheadas por arquivo | Quanto o mesmo uso custaria pela API: entrada/saída pelo preço de tabela, gravações de cache ×1,25 (TTL 5 min) / ×2 (TTL 1 h), leituras de cache ×0,1 |
| Codex | Logs de sessões (`~/.codex/sessions/**/*.jsonl`) | Preços de tabela da API da OpenAI; entrada em cache ×0,1. Modelos sem preço público mostram só tokens |
| Cursor | Eventos de uso do painel do Cursor, cacheados localmente. Na primeira abertura você escolhe carregar todo o histórico ou só o ciclo de cobrança atual; depois só eventos novos são buscados | Conforme o Cursor informa por solicitação |

**Por que os totais do Claude no AgentBar diferem do `/stats` do Claude Code.** O Claude Code conta cada linha da transcrição, e uma resposta com vários blocos (raciocínio, texto, chamadas de ferramentas) é gravada como várias linhas que compartilham o mesmo registro de uso — então é contada várias vezes. O AgentBar conta cada resposta uma vez com os valores finais — o que a API cobra de fato — e mostra ao lado o número do Claude Code para referência.

Indexar 700 MB de transcrições leva uns 10 segundos na primeira vez e bem menos de um segundo depois. Os caches ficam em `~/Library/Application Support/AgentBar/`.

## Notificações

- Ative as notificações em Configurações → Notificações e escolha um limiar padrão (50–95 %).
- Qualquer limite pode ser silenciado ou receber um limiar próprio — nas Configurações ou pelo sino no painel.
- Você recebe uma notificação por limite por ciclo de reinício.
- Os limites são checados a cada atualização: por agenda se a atualização automática estiver ligada; senão, só ao abrir o painel.

## Configurações

- **Geral** — intervalo de atualização (desligado / 1 / 5 / 15 / 30 / 60 min), provedores visíveis, idioma, abrir ao fazer login, atualizações.
- **Notificações** — chave geral, limiar padrão, regras por limite.

## Atualizações

O AgentBar consulta o GitHub Releases uma vez por dia e sempre que você clica em *Verificar atualizações*. Quando há versão mais nova, o painel mostra um botão *Atualizar*. A atualização é baixada, o SHA-256 é conferido com a soma publicada, o identificador do bundle e a versão são checados, o app antigo vai para o Lixo e o novo é aberto. Você também pode instalar qualquer versão manualmente pela [página de versões](https://github.com/funbool/agentbar/releases).

## Compilar a partir do código-fonte

Requer Xcode 15 ou mais recente (Swift 5.9). Sem dependências de terceiros.

```bash
git clone https://github.com/funbool/agentbar.git
cd agentbar
swift test                 # testes unitários
./scripts/build.sh         # -> build/AgentBar.app
./scripts/install.sh       # compilar, copiar para /Applications e abrir
```

Ferramentas de depuração (execute o binário do bundle ou `.build/debug/AgentBar`):

```bash
AgentBar --dump            # consultar cada provedor uma vez e imprimir os limites analisados
AgentBar --raw             # imprimir o JSON bruto de cada endpoint
AgentBar --stats           # indexar os logs locais de Claude/Codex e imprimir totais
AgentBar --cursor-events   # buscar eventos de uso do Cursor e imprimir totais
AgentBar --update          # rodar o ciclo completo de atualização sem interface
```

### Publicar uma versão

```bash
./scripts/release.sh 0.2.0
```

Isso sobe a versão em `Packaging/Info.plist`, cria a tag `v0.2.0` e faz push. O GitHub Actions roda os testes, compila o app, publica `AgentBar.zip` e `AgentBar.zip.sha256` como release, e as cópias em execução pegam na próxima verificação.

## Privacidade e segurança

- **Lê:** o item das Chaves do Claude Code, `~/.codex/auth.json`, o `state.vscdb` do Cursor (somente leitura), transcrições e logs de sessão locais.
- **Grava:** preferências e caches em `~/Library/Application Support/AgentBar/`.
- **Rede:** `api.anthropic.com`, `chatgpt.com`, `cursor.com` (seus próprios dados de uso) e `api.github.com` / `github.com` (verificação e download de atualizações). Nada mais.
- As versões são compiladas pelo GitHub Actions a partir do código com tag; o workflow está em `.github/workflows/release.yml`.

## Solução de problemas

| Sintoma | O que fazer |
|---|---|
| *Não conectado — abra o …* | Faça login nesse cliente uma vez; o AgentBar lê o token salvo na próxima atualização. |
| O aviso das Chaves continua aparecendo | Escolha *Sempre permitir*. Um novo aviso depois de um tempo significa que o Claude Code rotacionou o token. |
| O Cursor não mostra nada | Abra o Cursor uma vez para renovar o token de sessão e depois atualize o AgentBar. |
| O app não abre depois do download | Gatekeeper — veja [Instalação](#instalação). |
| As estatísticas ficam em *Indexando…* | A primeira indexação de pastas grandes demora; as execuções seguintes usam o cache. |

## Agradecimentos

A pesquisa dos endpoints contou com a ajuda do projeto open source [CodexBar](https://github.com/steipete/CodexBar).

## Licença

[MIT](../LICENSE)
