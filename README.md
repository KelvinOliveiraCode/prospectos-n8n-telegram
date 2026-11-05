<div align="center">

[English](README.en.md) · **Português (Brasil)**

</div>

[![n8n](https://img.shields.io/badge/n8n-automation-blue?style=flat-square)](https://n8n.io/) [![Telegram](https://img.shields.io/badge/Telegram-Bot_API-26A5E4?style=flat-square&logo=telegram&logoColor=white)](https://core.telegram.org/bots/api) [![ProspectOS](https://img.shields.io/badge/ProspectOS-integração-107a4a?style=flat-square)](https://github.com/nando0x/ProspectOS) [![Node.js](https://img.shields.io/badge/Node.js-20+-339933?style=flat-square&logo=node.js&logoColor=white)](https://nodejs.org/) [![JSON](https://img.shields.io/badge/Workflow-JSON-000000?style=flat-square)](workflows/ProspectOS_para_Telegram.json) [![MIT License](https://img.shields.io/badge/License-MIT-f4c430?style=flat-square)](LICENSE)

### Automação n8n que dispara buscas amplas no ProspectOS e entrega o CSV completo no Telegram

**497 leads na base sem automação → 502 em 1 teste real** (5 novos: 3 sem site + 2 site ruim em ~2 min de varredura, 20 empresas capturadas).

---

## O que é

Orquestração de prospecção 100% automática: você cola **várias linhas** `nicho em cidade` no Form do n8n, ele dispara a busca no ProspectOS via API, aguarda finalizar, baixa o CSV completo e entrega no seu Telegram — já organizado por mapeamento de área para contato direto.

Sem automação: abrir o ProspectOS → Nova Busca → digitar → esperar → baixar CSV → abrir Excel → enviar para si mesmo.
Com automação: preencher 1 Form → receber no Telegram.

---

## Números (teste real 05/11/2026)

| Métrica | Sem automação | Com n8n + ProspectOS + Telegram |
|---|---|---|
| Base inicial | 497 leads em `leads.db` | — |
| Busca de teste | `dentista em Belem` | 1 linha |
| Empresas capturadas | 20 (manual) | 20 (automático) |
| Leads novos | — | **5 (3 sem site + 2 site ruim)** |
| Já na base | 7 atualizados | 7 deduplicados |
| Site bom (descartados) | 8 | 8 |
| Tempo | ~15 min manual | **~2 min** |
| Entrega | manual | **CSV no Telegram em ~2 min** |

> Amostra anonimizada em `examples/exemplo.csv` — 502 linhas reais, 0 dado sensível versionado.

---

## Potencial

- **Multi-linhas nativas:** o backend aceita `queries` com `\n`, então `clinica em Belem\nacademia em Ananindeua\ndentista em Castanhal` = 1 disparo amplo, não 3 buscas separadas. Limite no código: `MAX_LINHAS_QUERIES_BUSCA`.
- **Escala:** base saiu de **497 → 502** em 1 disparo. Com 5 áreas × 3 nichos = 15 linhas em 1 workflow, o ganho é linear sem abrir o frontend.
- **Reprodutível:** workflow **JSON puro** (`workflows/ProspectOS_para_Telegram.json`), importável em qualquer n8n self-host. Sem Docker obrigatório (roda com `npm`).
- **Entrega pronta:** `/api/exportar` retorna CSV com `nome, categoria, endereco, nota, num_avaliacoes, whatsapp_link, telefone, nicho, cidade, site_status, site_url, mensagem_gerada` — contato direto sem retrabalho.

## Utilidade

Para quem vende sites/landing pages para negócios locais sem site ou com site ruim: prospecta em piloto automático, recebe a estratégia pronta no Telegram e ataca por área com planilha organizada. Economiza ~1-2h por lote de busca e elimina o baixar/enviar manual.

> **Aviso:** scraping de Google Maps/Instagram pode violar ToS. Rode por conta e risco. Veja README do ProspectOS para riscos e mitigação.

---

## Início Rápido

```powershell
# 1. Suba o ProspectOS (backend em http://127.0.0.1:5000)
cd C:\Users\Kelvin\Desktop\ProspectOS
.\iniciar.bat

# 2. Instale e suba o n8n neste repo
cd ..\prospectos-n8n-telegram
npm install n8n
npx n8n start
# Abra http://localhost:5678

# 3. Importe o workflow
# n8n > Workflows > Import from File > workflows/ProspectOS_para_Telegram.json

# 4. Configure credencial Telegram (BotFather > Token)
# Credentials > Telegram API > cole o token
# No nó "Enviar CSV p/ Telegram": cole seu Chat ID
```

### Crie o Bot no Telegram

1. Fale com `@BotFather` → `/newbot`
2. Copie o token (`123456:ABC-DEF...`) — **nunca versione**
3. Fale com `@getmyid_bot` → copie seu Chat ID
4. Envie `/start` ao seu bot uma vez (senão o `getUpdates` fica vazio)

---

## Como funciona

```
Form (textarea multi-linhas)
        ↓
SET queries = {{ $json.queries }}
        ↓
POST /api/buscar  {"queries":"..."}        → ProspectOS varre Maps + analisa site
        ↓
Wait 20s → GET /api/buscar/status         → polling até rodando=false
        ↓
If status=finalizada
        ↓
GET /api/exportar → CSV binário            → colunas de contato direto
        ↓
Telegram sendDocument (caption com resumo + arquivo)
```

| Nó | O que faz |
|---|---|
| **Form Trigger** | Recebe N linhas `nicho em cidade` |
| **SET** | Normaliza `queries` |
| **HTTP POST** | Dispara `POST /api/buscar` no ProspectOS |
| **Wait + HTTP GET** | Loop de polling a cada 20s |
| **If** | Sai do loop quando finaliza |
| **HTTP GET** | Baixa CSV completo de `/api/exportar` |
| **Telegram** | Envia resumo + CSV como documento |

### Modo mapa (pino + raio)

O backend também aceita `{"nichos":[...],"areas":[{"lat":...,"lng":...,"raio_m":...,"rotulo":"..."}]}`. Para usar, troque o corpo do nó POST para esse formato (veja `rotas_leads.py:_validar_busca_por_mapa`).

---

## Capacidades

| Capacidade | Descrição |
|---|---|
| Busca ampla multiquery | N linhas em 1 disparo POST |
| Polling com retry | Wait 20s até finalizar |
| Export completo | CSV via `/api/exportar` (21 colunas) |
| Entrega Telegram | Resumo + documento com nome amigável |
| Sanitização | `.env` ignorado, `*.csv` ignorado, workflow sem token/chat embutido |

---

## Perguntas Frequentes

<details>
<summary><strong>Por que polling a cada 20s em vez de webhook?</strong></summary>

O ProspectOS não expõe webhook de término. O polling em `/api/buscar/status` (campo `rodando`) é o padrão já usado pelo frontend. 20s evita sobrecarregar e ainda entrega rápido.

</details>

<details>
<summary><strong>Posso enviar para um grupo?</strong></summary>

Sim, adicione o bot ao grupo e use o `chat_id` do grupo. Para chat pessoal o fluxo é idêntico.

</details>

<details>
<summary><strong>E se a busca demorar 10 min?</strong></summary>

O loop volta para o Wait automaticamente. Sem limite de iterações no workflow — só pare se o ProspectOS travar (ver `GET /api/buscar/status` manualmente).

</details>

<details>
<summary><strong>O CSV contém dados pessoais?</strong></summary>

O CSV real vem do seu `leads.db`. **Não versione** dados reais. Este repo traz só `examples/exemplo.csv` anonimizado. Adicione `*.csv` ao `.gitignore` (já feito).

</details>

---

## Documentação

- **Código-fonte** — `workflows/ProspectOS_para_Telegram.json` é o único artefato executável
- **ProspectOS original** — [nando0x/ProspectOS](https://github.com/nando0x/ProspectOS)
- **Guia detalhado** — `docs/GUIA.md`
- **Exemplo de saída** — `examples/exemplo.csv`

## Licença

[MIT](LICENSE) · Kelvin Oliveira

---

<div align="center">

**Construído com** n8n 2.46 · ProspectOS (Flask) · Telegram Bot API

**Autor** · [Kelvin Oliveira](https://github.com/KelvinOliveiraCode) · [Portfólio](https://kelvinoliveiracode.github.io/portfolio/)

</div>
