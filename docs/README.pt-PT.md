<!-- LANGS -->
[🇬🇧 English](../README.md) · [🇷🇺 Русский](README.ru.md) · [🇺🇦 Українська](README.uk.md) · [🇩🇪 Deutsch](README.de.md) · [🇫🇷 Français](README.fr.md) · [🇪🇸 Español](README.es.md) · **🇵🇹 Português** · [🇧🇷 Português (Brasil)](README.pt-BR.md) · [🇵🇱 Polski](README.pl.md) · [🇨🇿 Čeština](README.cs.md) · [🇭🇺 Magyar](README.hu.md) · [🇹🇷 Türkçe](README.tr.md) · [🇰🇿 Қазақша](README.kk.md) · [🇮🇳 हिन्दी](README.hi.md) · [🇯🇵 日本語](README.ja.md) · [🇨🇳 简体中文](README.zh-Hans.md) · [🇹🇼 繁體中文](README.zh-Hant.md)
<!-- /LANGS -->

# AgentBar

Uma aplicação leve para a barra de menus do macOS que mostra quanto dos seus limites de **Claude**, **Codex** e **Cursor** já utilizou — além de estatísticas de tokens e quanto a mesma utilização custaria através das API públicas.

[![CI](https://github.com/funbool/agentbar/actions/workflows/ci.yml/badge.svg)](https://github.com/funbool/agentbar/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/funbool/agentbar?display_name=tag)](https://github.com/funbool/agentbar/releases/latest)
![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](../LICENSE)

## Funcionalidades

- **Limites num relance** — janelas de 5 horas e semanais para Claude e Codex, pools de utilização incluída para o Cursor, cada um com barra de progresso, tempo restante até ao reinício e data exata.
- **Limites semanais por modelo** para o Claude (Opus, Sonnet, Fable, …) assim que a API os reporta.
- **Estatísticas de utilização** — tokens por tipo, custo, repartição por modelo e por projeto, gráfico diário; Hoje / 7 dias / 30 dias / Tudo.
- **Notificações** quando um limite ultrapassa um limiar, com valor global e regras por limite (silenciar, limiar próprio).
- **Atualização automática** opcional, arranque ao iniciar sessão, 17 idiomas de interface.
- **Atualizações remotas** a partir do GitHub Releases, verificadas com SHA-256.
- **Sem contas nem telemetria.** O AgentBar lê os tokens que os clientes oficiais já guardam no seu Mac e comunica apenas com as API dos próprios fornecedores.

## Requisitos

- macOS 14 Sonoma ou posterior (Apple Silicon ou Intel).
- Pelo menos um destes clientes com sessão iniciada: [Claude Code](https://claude.com/claude-code), [Codex](https://openai.com/codex) (CLI ou aplicação), [Cursor](https://cursor.com). Os fornecedores que não usa podem ser ocultados nas Definições.

## Instalação

1. Descarregue `AgentBar.zip` a partir da [versão mais recente](https://github.com/funbool/agentbar/releases/latest).
2. Descompacte e mova `AgentBar.app` para `/Applications`.
3. Abra a aplicação. Regista-se como item de início de sessão (pode desativar nas Definições).

**Gatekeeper.** As versões são assinadas ad hoc, sem notarização. Se o macOS recusar abrir uma cópia acabada de descarregar, faça clique direito → *Abrir* uma vez, ou remova o atributo de quarentena:

```bash
xattr -dr com.apple.quarantine /Applications/AgentBar.app
```

**Pedido do porta-chaves.** Na primeira atualização do Claude, o macOS pergunta se o `security` pode ler o item *Claude Code-credentials*. Escolha **Permitir sempre**. O pedido pode voltar depois de o Claude Code rodar o token — é esperado.

Também pode [compilar a partir do código-fonte](#compilar-a-partir-do-código-fonte).

## Como funciona

O AgentBar nunca pede para iniciar sessão. Lê as credenciais que cada cliente já mantém no seu Mac e chama os mesmos endpoints que os clientes usam.

| Fornecedor | Credenciais lidas de | Endpoint | O que é mostrado |
|---|---|---|---|
| Claude | Item do porta-chaves `Claude Code-credentials` (lido via `/usr/bin/security`) | `api.anthropic.com/api/oauth/usage` | Janela de 5 h, janela semanal, limites semanais por modelo |
| Codex | `~/.codex/auth.json` (ou `$CODEX_HOME/auth.json`) | `chatgpt.com/backend-api/wham/usage` | Janela de 5 h, janela semanal, plano |
| Cursor | `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb` (só leitura) | `cursor.com/api/usage-summary`, `…/get-sand-usage-status` | Pool de modelos Cursor (Auto / Composer / Grok), pool de modelos API, gastos a pedido, Grok Bot semanal, gasto no ciclo |

O AgentBar não renova tokens. Se um fornecedor mostrar *sessão expirada*, abra esse cliente uma vez — ele renova o token e o AgentBar apanha-o na atualização seguinte.

## O painel

- Clique no ícone da barra de menus: todos os fornecedores são atualizados de imediato; durante o carregamento mantêm-se os valores anteriores.
- As barras são verdes abaixo de 60 %, amarelas acima e vermelhas ao atingir o limiar de notificação.
- Cada limite mostra o tempo restante e o momento exato do reinício, p. ex. *reinicia em 2h 15m · qui, 24 set 20:00*.
- O sino junto a um limite abre a sua regra de notificação (ligar/desligar, limiar).
- Rodapé: estatísticas · atualizar · definições · sair.

## Estatísticas de utilização

O botão de gráfico no rodapé abre a janela de estatísticas. No topo muda de fornecedor e período; ao passar o rato pelo gráfico vê o total do dia ou a quota de um modelo.

| Fornecedor | Fonte | Custo |
|---|---|---|
| Claude | Transcrições do Claude Code (`~/.claude/projects/**/*.jsonl`), indexadas uma vez e guardadas em cache por ficheiro | O que a mesma utilização custaria via API: entrada/saída ao preço de tabela, escritas de cache ×1,25 (TTL 5 min) / ×2 (TTL 1 h), leituras de cache ×0,1 |
| Codex | Registos de sessões (`~/.codex/sessions/**/*.jsonl`) | Preços de tabela da API OpenAI; entrada em cache ×0,1. Modelos sem preço público mostram apenas tokens |
| Cursor | Eventos de utilização do painel do Cursor, em cache local. Na primeira abertura escolhe carregar todo o histórico ou apenas o ciclo de faturação atual; depois só são obtidos eventos novos | Conforme reportado pelo Cursor por pedido |

**Porque é que os totais do Claude no AgentBar diferem do `/stats` do Claude Code.** O Claude Code conta cada linha da transcrição, e uma resposta com vários blocos (raciocínio, texto, chamadas de ferramentas) é gravada como várias linhas que partilham o mesmo registo de utilização, sendo contada várias vezes. O AgentBar conta cada resposta uma só vez com os valores finais — o que a API fatura de facto — e mostra ao lado o número do Claude Code para referência.

Indexar 700 MB de transcrições demora cerca de 10 segundos na primeira vez e bem menos de um segundo depois. As caches ficam em `~/Library/Application Support/AgentBar/`.

## Notificações

- Ative as notificações em Definições → Notificações e escolha um limiar predefinido (50–95 %).
- Qualquer limite pode ser silenciado ou ter um limiar próprio — nas Definições ou pelo sino no painel.
- Recebe uma notificação por limite e por ciclo de reinício.
- Os limites são verificados a cada atualização: por agenda se a atualização automática estiver ligada; caso contrário, só ao abrir o painel.

## Definições

- **Geral** — intervalo de atualização (desligado / 1 / 5 / 15 / 30 / 60 min), fornecedores visíveis, idioma, arranque ao iniciar sessão, atualizações.
- **Notificações** — interruptor global, limiar predefinido, regras por limite.

## Atualizações

O AgentBar consulta o GitHub Releases uma vez por dia e sempre que carregar em *Procurar atualizações*. Quando existe uma versão mais recente, o painel mostra um botão *Atualizar*. A atualização é descarregada, o SHA-256 é verificado contra a soma publicada, o identificador do bundle e a versão são confirmados, a aplicação antiga vai para o Lixo e a nova é lançada. Também pode instalar qualquer versão manualmente a partir da [página de versões](https://github.com/funbool/agentbar/releases).

## Compilar a partir do código-fonte

Requer Xcode 15 ou posterior (Swift 5.9). Sem dependências de terceiros.

```bash
git clone https://github.com/funbool/agentbar.git
cd agentbar
swift test                 # testes unitários
./scripts/build.sh         # -> build/AgentBar.app
./scripts/install.sh       # compilar, copiar para /Applications e lançar
```

Ferramentas de depuração (execute o binário do bundle ou `.build/debug/AgentBar`):

```bash
AgentBar --dump            # consultar cada fornecedor uma vez e imprimir os limites analisados
AgentBar --raw             # imprimir o JSON bruto de cada endpoint
AgentBar --stats           # indexar os registos locais de Claude/Codex e imprimir totais
AgentBar --cursor-events   # obter eventos de utilização do Cursor e imprimir totais
AgentBar --update          # executar o ciclo completo de atualização sem interface
```

### Publicar uma versão

```bash
./scripts/release.sh 0.2.0
```

Isto incrementa a versão em `Packaging/Info.plist`, cria a etiqueta `v0.2.0` e faz push. O GitHub Actions corre os testes, compila a aplicação, publica `AgentBar.zip` e `AgentBar.zip.sha256` como versão, e as cópias em execução apanham-na na verificação seguinte.

## Privacidade e segurança

- **Lê:** o item do porta-chaves do Claude Code, `~/.codex/auth.json`, o `state.vscdb` do Cursor (só leitura), transcrições e registos de sessão locais.
- **Escreve:** preferências e caches em `~/Library/Application Support/AgentBar/`.
- **Rede:** `api.anthropic.com`, `chatgpt.com`, `cursor.com` (os seus próprios dados de utilização) e `api.github.com` / `github.com` (verificação e descarga de atualizações). Nada mais.
- As versões são compiladas pelo GitHub Actions a partir do código etiquetado; o workflow está em `.github/workflows/release.yml`.

## Resolução de problemas

| Sintoma | O que fazer |
|---|---|
| *Sessão não iniciada — abra …* | Inicie sessão nesse cliente uma vez; o AgentBar lê o token guardado na atualização seguinte. |
| O pedido do porta-chaves continua a aparecer | Escolha *Permitir sempre*. Um novo pedido passado algum tempo significa que o Claude Code rodou o token. |
| O Cursor não mostra nada | Abra o Cursor uma vez para renovar o token de sessão e depois atualize o AgentBar. |
| A aplicação não abre após a descarga | Gatekeeper — ver [Instalação](#instalação). |
| As estatísticas ficam em *A indexar…* | A primeira indexação de pastas grandes demora; as execuções seguintes usam a cache. |

## Agradecimentos

A investigação dos endpoints foi facilitada pelo projeto open source [CodexBar](https://github.com/steipete/CodexBar).

## Licença

[MIT](../LICENSE)
