# ProspectOS + n8n + Telegram

n8n workflow, exported as JSON, that triggers searches on ProspectOS and delivers the resulting CSV to Telegram.

English | [Português (Brasil)](README.md)

## What it is

This repository contains a single executable artifact: the workflow `workflows/ProspectOS_para_Telegram.json`, with 8 nodes. It receives a list of searches in the `niche in city` format through a local n8n form, calls the ProspectOS API (Flask backend running at `http://localhost:5000`), follows execution through polling, downloads the full CSV and sends the file as a document on Telegram.

ProspectOS does not live here. It is a separate project, at [nando0x/ProspectOS](https://github.com/nando0x/ProspectOS), and it must be running before this workflow is executed.

## Status

Usable as a personal automation. What exists today:

- Importable JSON workflow, with 8 connected nodes (`workflows/ProspectOS_para_Telegram.json`).
- Startup script for Windows (`iniciar-n8n.bat`).
- Anonymized output sample (`examples/exemplo.csv`, 2 data rows).
- Short operating guide (`docs/GUIA.md`).

What does not exist: automated tests, linter, own server, Dockerfile, build. Verification is manual, by running the flow in n8n.

## Features

The flow covers a single path, from the form to the document on Telegram:

- Form with a textarea field called `queries`, where each line is an independent search.
- Value normalization in a Set node (`Montar Queries Multi-Linha`).
- Trigger of `POST /api/buscar` with the body `{"queries": "..."}`, preserving line breaks through `JSON.stringify`.
- Polling of `GET /api/buscar/status` every 20 seconds, exiting when the `status` field equals `finalizada`.
- Download of `GET /api/exportar` in file format (`responseFormat: file`).
- Delivery of the CSV to Telegram as a document (`channel: document`), with a summary of the queries in the caption.

## Architecture

The 8 nodes of the workflow, in the real order of the file:

| Node | Type | typeVersion | Role |
|---|---|---|---|
| Form Trigger (Localidades + Nichos) | n8n-nodes-base.FormTrigger | 1.1 | `queries` textarea field |
| Montar Queries Multi-Linha | n8n-nodes-base.Set | 3 | Copies `queries` to the node variable |
| ProspectOS Disparar Busca Ampla | n8n-nodes-base.HttpRequest | 4.2 | `POST http://localhost:5000/api/buscar` |
| Aguardar 20s | n8n-nodes-base.Wait | 1.1 | Waits 20 seconds |
| Consultar Status | n8n-nodes-base.HttpRequest | 4.2 | `GET http://localhost:5000/api/buscar/status` |
| Terminou? | n8n-nodes-base.If | 1 | Compares `$json.status` with `finalizada` |
| Baixar CSV Completo | n8n-nodes-base.HttpRequest | 4.2 | `GET http://localhost:5000/api/exportar` |
| Enviar CSV p/ Telegram | n8n-nodes-base.Telegram | 1.2 | `sendDocument` with the CSV |

Connections, as in the `connections` field:

```text
Form Trigger -> Montar Queries Multi-Linha -> ProspectOS Disparar Busca Ampla
             -> Aguardar 20s -> Consultar Status -> Terminou?
                                                  |  true: Baixar CSV Completo -> Enviar CSV p/ Telegram
                                                  |  false: Aguardar 20s
```

The `false` branch of the If node returns to `Aguardar 20s`, forming the polling loop. There is no iteration counter and no timeout in the JSON.

## Stack

- n8n `^2.46.6`, declared as a dependency in `package.json`.
- Node.js and npm. `package.json` declares no `engines` field, so the minimum version is not pinned in this repository.
- Workflow in pure JSON, with no JavaScript, Python or TypeScript code in this repository.
- CSV as the exchange format between ProspectOS, n8n and Telegram.
- Windows as the target of the helper script (`iniciar-n8n.bat`, `.bat`).

## Repository structure

```text
prospectos-n8n-telegram/
├── .env.example
├── .gitignore
├── LICENSE
├── README.md
├── README.en.md
├── iniciar-n8n.bat
├── package.json
├── docs/
│   └── GUIA.md
├── examples/
│   └── exemplo.csv
└── workflows/
    └── ProspectOS_para_Telegram.json
```

`.gitignore` covers `node_modules/`, `.env`, `.env.*` (except `.env.example`), `*.csv`, `leads*.csv`, `data/` and `*.log`.

## Prerequisites and installation

Before starting:

- Node.js and npm installed.
- ProspectOS running at `http://localhost:5000`. It is not installed by this repository.
- Telegram bot created in `@BotFather` and the recipient Chat ID.
- Telegram API credential created in n8n.

Installation:

```bash
git clone https://github.com/KelvinOliveiraCode/prospectos-n8n-telegram.git
cd prospectos-n8n-telegram
npm install
```

`npm install` installs only n8n, the single dependency. `package.json` defines the `start` script as `n8n start`.

About `.env.example`: it documents `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`, `PROSPECTOS_API` and `PROSPECTOS_DIR`, but no file in this repository reads those variables. The token used at runtime comes from the n8n credential.

## How to run

```bash
# 1. Start ProspectOS (outside this repository)
cd ../ProspectOS
./iniciar.bat

# 2. Start n8n from this repository
cd ../prospectos-n8n-telegram
npx n8n start
# UI at http://localhost:5678

# 3. In n8n: Workflows > Import from File > workflows/ProspectOS_para_Telegram.json

# 4. In Credentials > Telegram API, paste the BotFather token

# 5. In the "Enviar CSV p/ Telegram" node, fill in the destination Chat ID

# 6. Run the workflow manually and fill in the form
```

On Windows you can also use `iniciar-n8n.bat`, which runs `npx n8n start` in the project root.

Example content accepted in the `queries` field:

```text
dentist in Belem
aesthetic clinic in Belem
gym in Ananindeua
```

## Endpoints (if there is an API)

This repository does not expose an API, server or HTTP route. It consumes three ProspectOS endpoints, all fixed at `http://localhost:5000`:

| Method | Endpoint | Use in the workflow | Evidence |
|---|---|---|---|
| POST | `/api/buscar` | Body `{"queries": "<text with line breaks>"}` | `workflows/ProspectOS_para_Telegram.json`, node `post-buscar` |
| GET | `/api/buscar/status` | Returns JSON with the `status` field; the workflow compares it with `finalizada` | nodes `get-status` and `if-done` |
| GET | `/api/exportar` | Returns the full CSV as a file | node `get-csv` |

The response values of these endpoints are defined by ProspectOS, not by this repository.

## Tests and quality

There are no tests in this repository. Verification done by direct reading of the files:

- No test file, no test directory, no test framework.
- `package.json` has only the `start` script (`n8n start`), with no `test` and no `lint`.
- No test or build dependency.

The possible verification is manual: import the workflow into n8n, run it with a reference search and check the CSV received on Telegram. `docs/GUIA.md` records a reference test with `dentista em Belem`, but that result comes from ProspectOS and cannot be reproduced with this repository alone.

## Technical decisions and trade-offs

The 20-second polling was chosen over a webhook because the flow depends on a backend that exposes no completion callback. The cost is latency of up to 20 seconds per iteration and a loop with no limit in the JSON.

Line breaks are preserved with `JSON.stringify($json.queries)` in the POST body, instead of building the JSON by direct interpolation, which avoids a malformed body when the user pastes several lines.

The export HTTP node uses `responseFormat: file` to treat the CSV as binary, not as text, which allows direct delivery as a document on Telegram.

The backend path is fixed at `http://localhost:5000` in the three HTTP nodes, and does not come from an environment variable. This simplifies local use and prevents pointing to another host without editing the JSON.

`.env.example` exists as configuration documentation, but the workflow does not reference those variables. The real Telegram access configuration is done through the n8n credential, and the Chat ID is filled in the node.

## Known limitations

- The polling loop has no iteration limit and no timeout: if ProspectOS hangs without changing the `status` field, the workflow repeats `Aguardar 20s` indefinitely.
- The `Enviar CSV p/ Telegram` node in the JSON carries only `channel: document` and the caption text. There is no `chatId` or `resource` in the file, so the destination must be configured in the n8n UI after import.
- `.env` is not read by any code in this repository. The `.env.example` variables are reference only.
- The URLs of the three HTTP nodes are fixed at `localhost:5000`.
- `package.json` declares neither `engines`, `test` nor `lint`.
- `examples/exemplo.csv` has 2 data rows, with example names and phone numbers. It is not the real lead base.
- `package.json` is marked `private: true`, so there is no registry publication.
- Collecting data from Google Maps and Instagram may violate the terms of use of those services. Execution is at the runner's own risk.

## License and author

MIT. Copyright (c) 2026 Kelvin Rebelo de Oliveira. Autor: [Kelvin Oliveira](https://github.com/KelvinOliveiraCode)

Related documentation: [docs/GUIA.md](docs/GUIA.md) and [workflows/ProspectOS_para_Telegram.json](workflows/ProspectOS_para_Telegram.json).