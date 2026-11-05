<div align="center">

[English](README.en.md) · **Português (Brasil)**

</div>

[![n8n](https://img.shields.io/badge/n8n-automation-blue?style=flat-square)](https://n8n.io/) [![Telegram](https://img.shields.io/badge/Telegram-Bot_API-26A5E4?style=flat-square&logo=telegram&logoColor=white)](https://core.telegram.org/bots/api) [![ProspectOS](https://img.shields.io/badge/ProspectOS-integration-107a4a?style=flat-square)](https://github.com/nando0x/ProspectOS) [![Node.js](https://img.shields.io/badge/Node.js-20+-339933?style=flat-square&logo=node.js&logoColor=white)](https://nodejs.org/) [![JSON](https://img.shields.io/badge/Workflow-JSON-000000?style=flat-square)](workflows/ProspectOS_para_Telegram.json) [![MIT License](https://img.shields.io/badge/License-MIT-f4c430?style=flat-square)](LICENSE)

### n8n automation that triggers broad ProspectOS searches and delivers the full CSV to Telegram

**497 leads in the base without automation → 502 in 1 real test** (5 new: 3 no-site + 2 bad-site in ~2 min of scanning, 20 companies captured).

---

## What it is

Fully automatic lead prospecting orchestration: paste **multiple lines** `niche in city` in the n8n Form, it triggers the search on ProspectOS via API, waits for completion, downloads the full CSV and delivers it to your Telegram — already organized by area mapping for direct contact.

Without automation: open ProspectOS → New Search → type → wait → download CSV → open Excel → send to yourself.
With automation: fill 1 Form → receive on Telegram.

---

## Numbers (real test 05/11/2026)

| Metric | Without automation | With n8n + ProspectOS + Telegram |
|---|---|---|
| Initial base | 497 leads in `leads.db` | — |
| Test search | `dentist in Belem` | 1 line |
| Companies captured | 20 (manual) | 20 (automatic) |
| New leads | — | **5 (3 no-site + 2 bad-site)** |
| Already in base | 7 updated | 7 deduplicated |
| Good site (discarded) | 8 | 8 |
| Time | ~15 min manual | **~2 min** |
| Delivery | manual | **CSV on Telegram in ~2 min** |

> Anonymized sample in `examples/exemplo.csv` — 502 real rows, 0 sensitive data versioned.

---

## Potential

- **Native multi-line:** the backend accepts `queries` with `\n`, so `clinic in Belem\n gym in Ananindeua\n dentist in Castanhal` = 1 broad shot, not 3 separate searches. Limit in code: `MAX_LINHAS_QUERIES_BUSCA`.
- **Scale:** base grew **497 → 502** in 1 shot. With 5 areas × 3 niches = 15 lines in 1 workflow, gain is linear without opening the frontend.
- **Reproducible:** pure **JSON workflow** (`workflows/ProspectOS_para_Telegram.json`), importable into any self-hosted n8n. No mandatory Docker (runs with `npm`).
- **Ready delivery:** `/api/exportar` returns CSV with `name, category, address, rating, reviews, whatsapp_link, phone, niche, city, site_status, site_url, generated_message` — direct contact with no rework.

## Utility

For those who sell websites/landing pages to local businesses without a site or with a bad site: prospect on autopilot, receive the strategy ready on Telegram and attack by area with an organized spreadsheet. Saves ~1-2h per search batch and eliminates manual download/send.

> **Warning:** Google Maps/Instagram scraping may violate ToS. Run at your own risk. See the ProspectOS README for risks and mitigation.

---

## Quick Start

```powershell
# 1. Start ProspectOS (backend at http://127.0.0.1:5000)
cd C:\Users\Kelvin\Desktop\ProspectOS
.\iniciar.bat

# 2. Install and start n8n in this repo
cd ..\prospectos-n8n-telegram
npm install n8n
npx n8n start
# Open http://localhost:5678

# 3. Import the workflow
# n8n > Workflows > Import from File > workflows/ProspectOS_para_Telegram.json

# 4. Configure Telegram credential (BotFather > Token)
# Credentials > Telegram API > paste the token
# In the "Send CSV to Telegram" node: paste your Chat ID
```

### Create the Bot on Telegram

1. Talk to `@BotFather` → `/newbot`
2. Copy the token (`123456:ABC-DEF...`) — **never version it**
3. Talk to `@getmyid_bot` → copy your Chat ID
4. Send `/start` to your bot once (otherwise `getUpdates` stays empty)

---

## How it works

```
Form (multi-line textarea)
        ↓
SET queries = {{ $json.queries }}
        ↓
POST /api/buscar  {"queries":"..."}        → ProspectOS scans Maps + analyzes site
        ↓
Wait 20s → GET /api/buscar/status         → polling until running=false
        ↓
If status=finished
        ↓
GET /api/exportar → binary CSV             → direct-contact columns
        ↓
Telegram sendDocument (summary caption + file)
```

| Node | What it does |
|---|---|
| **Form Trigger** | Receives N `niche in city` lines |
| **SET** | Normalizes `queries` |
| **HTTP POST** | Triggers `POST /api/buscar` on ProspectOS |
| **Wait + HTTP GET** | Polling loop every 20s |
| **If** | Exits loop when finished |
| **HTTP GET** | Downloads full CSV from `/api/exportar` |
| **Telegram** | Sends summary + CSV as document |

### Map mode (pin + radius)

The backend also accepts `{"niches":[...],"areas":[{"lat":...,"lng":...,"raio_m":...,"rotulo":"..."}]}`. To use it, swap the POST body to that format (see `rotas_leads.py:_validar_busca_por_mapa`).

---

## Capabilities

| Capability | Description |
|---|---|
| Broad multi-query search | N lines in 1 POST shot |
| Polling with retry | Wait 20s until finished |
| Full export | CSV via `/api/exportar` (21 columns) |
| Telegram delivery | Summary + document with friendly name |
| Sanitization | `.env` ignored, `*.csv` ignored, workflow without embedded token/chat |

---

## FAQ

<details>
<summary><strong>Why poll every 20s instead of a webhook?</strong></summary>

ProspectOS does not expose a completion webhook. Polling on `/api/buscar/status` (the `running` field) is the pattern already used by the frontend. 20s avoids overloading and still delivers fast.

</details>

<details>
<summary><strong>Can I send to a group?</strong></summary>

Yes, add the bot to the group and use the group `chat_id`. For a personal chat the flow is identical.

</details>

<details>
<summary><strong>What if the search takes 10 min?</strong></summary>

The loop goes back to Wait automatically. No iteration limit in the workflow — only stop if ProspectOS hangs (check `GET /api/buscar/status` manually).

</details>

<details>
<summary><strong>Does the CSV contain personal data?</strong></summary>

The real CSV comes from your `leads.db`. **Do not version** real data. This repo only brings anonymized `examples/exemplo.csv`. Add `*.csv` to `.gitignore` (already done).

</details>

---

## Documentation

- **Source code** — `workflows/ProspectOS_para_Telegram.json` is the only executable artifact
- **Original ProspectOS** — [nando0x/ProspectOS](https://github.com/nando0x/ProspectOS)
- **Detailed guide** — `docs/GUIA.md`
- **Output example** — `examples/exemplo.csv`

## License

[MIT](LICENSE) · Kelvin Oliveira

---

<div align="center">

**Built with** n8n 2.46 · ProspectOS (Flask) · Telegram Bot API

**Author** · [Kelvin Oliveira](https://github.com/KelvinOliveiraCode) · [Portfolio](https://kelvinoliveiracode.github.io/portfolio/)

</div>
