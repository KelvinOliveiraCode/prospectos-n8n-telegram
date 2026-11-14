# ProspectOS + n8n + Telegram

Workflow n8n, exportado em JSON, que dispara buscas no ProspectOS e entrega o CSV resultante no Telegram.

[English](README.en.md) | Português (Brasil)

## O que é

Este repositório contém um único artefato executável: o workflow `workflows/ProspectOS_para_Telegram.json`, com 8 nós. Ele recebe uma lista de buscas no formato `nicho em cidade` por um formulário local do n8n, chama a API do ProspectOS (backend Flask que roda em `http://localhost:5000`), acompanha a execução por polling, baixa o CSV completo e envia o arquivo como documento no Telegram.

O ProspectOS não vive aqui. Ele é um projeto separado, em [nando0x/ProspectOS](https://github.com/nando0x/ProspectOS), e precisa estar rodando antes de executar este workflow.

## Status

Funcional como automação de uso pessoal. O que existe hoje:

- Workflow JSON importável, com 8 nós conectados (`workflows/ProspectOS_para_Telegram.json`).
- Script de inicialização para Windows (`iniciar-n8n.bat`).
- Exemplo de saída anonimizado (`examples/exemplo.csv`, 2 linhas de dados).
- Guia curto de operação (`docs/GUIA.md`).

O que não existe: testes automatizados, linter, servidor próprio, Dockerfile, build. A verificação é manual, executando o fluxo no n8n.

## Funcionalidades

O fluxo cobre um caminho só, do formulário ao documento no Telegram:

- Formulário com um campo textarea chamado `queries`, onde cada linha é uma busca independente.
- Normalização do valor em um nó Set (`Montar Queries Multi-Linha`).
- Disparo de `POST /api/buscar` com o corpo `{"queries": "..."}`, preservando as quebras de linha via `JSON.stringify`.
- Polling de `GET /api/buscar/status` a cada 20 segundos, com saída quando o campo `status` é igual a `finalizada`.
- Download de `GET /api/exportar` no formato de arquivo (`responseFormat: file`).
- Envio do CSV para o Telegram como documento (`channel: document`), com resumo das queries na legenda.

## Arquitetura

Os 8 nós do workflow, na ordem real do arquivo:

| Nó | Tipo | typeVersion | Função |
|---|---|---|---|
| Form Trigger (Localidades + Nichos) | n8n-nodes-base.FormTrigger | 1.1 | Campo textarea `queries` |
| Montar Queries Multi-Linha | n8n-nodes-base.Set | 3 | Copia `queries` para a variável do nó |
| ProspectOS Disparar Busca Ampla | n8n-nodes-base.HttpRequest | 4.2 | `POST http://localhost:5000/api/buscar` |
| Aguardar 20s | n8n-nodes-base.Wait | 1.1 | Espera 20 segundos |
| Consultar Status | n8n-nodes-base.HttpRequest | 4.2 | `GET http://localhost:5000/api/buscar/status` |
| Terminou? | n8n-nodes-base.If | 1 | Compara `$json.status` com `finalizada` |
| Baixar CSV Completo | n8n-nodes-base.HttpRequest | 4.2 | `GET http://localhost:5000/api/exportar` |
| Enviar CSV p/ Telegram | n8n-nodes-base.Telegram | 1.2 | `sendDocument` com o CSV |

Conexões, conforme o campo `connections`:

```text
Form Trigger -> Montar Queries Multi-Linha -> ProspectOS Disparar Busca Ampla
             -> Aguardar 20s -> Consultar Status -> Terminou?
                                                  |  true: Baixar CSV Completo -> Enviar CSV p/ Telegram
                                                  |  false: Aguardar 20s
```

O ramo `false` do nó If volta para `Aguardar 20s`, formando o laço de polling. Não há contador de iterações nem timeout no JSON.

## Stack

- n8n `^2.46.6`, declarado como dependência em `package.json`.
- Node.js e npm. O `package.json` não declara campo `engines`, então a versão mínima não está fixada neste repositório.
- Workflow em JSON puro, sem código JavaScript, Python ou TypeScript neste repositório.
- CSV como formato de troca entre ProspectOS, n8n e Telegram.
- Windows como alvo do script auxiliar (`iniciar-n8n.bat`, `.bat`).

## Estrutura do repositório

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

O `.gitignore` cobre `node_modules/`, `.env`, `.env.*` (exceto `.env.example`), `*.csv`, `leads*.csv`, `data/` e `*.log`.

## Pré-requisitos e instalação

Antes de começar:

- Node.js e npm instalados.
- ProspectOS rodando em `http://localhost:5000`. Ele não é instalado por este repositório.
- Bot do Telegram criado no `@BotFather` e Chat ID do destinatário.
- Credencial do tipo Telegram API criada no n8n.

Instalação:

```bash
git clone https://github.com/KelvinOliveiraCode/prospectos-n8n-telegram.git
cd prospectos-n8n-telegram
npm install
```

O `npm install` instala apenas o n8n, que é a única dependência. O `package.json` define o script `start` como `n8n start`.

Sobre o `.env.example`: ele documenta `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`, `PROSPECTOS_API` e `PROSPECTOS_DIR`, mas nenhum arquivo deste repositório lê essas variáveis. O token usado em execução vem da credencial do n8n.

## Como executar

```bash
# 1. Suba o ProspectOS (fora deste repositório)
cd ../ProspectOS
./iniciar.bat

# 2. Suba o n8n deste repositório
cd ../prospectos-n8n-telegram
npx n8n start
# Interface em http://localhost:5678

# 3. No n8n: Workflows > Import from File > workflows/ProspectOS_para_Telegram.json

# 4. Em Credentials > Telegram API, cole o token do BotFather

# 5. No nó "Enviar CSV p/ Telegram", preencha o Chat ID de destino

# 6. Execute o workflow manualmente e preencha o formulário
```

No Windows também é possível usar `iniciar-n8n.bat`, que executa `npx n8n start` na raiz do projeto.

Exemplo de conteúdo aceito no campo `queries`:

```text
dentista em Belem
clinica de estetica em Belem
academia em Ananindeua
```

## Endpoints (se houver API)

Este repositório não expõe API, servidor ou rota HTTP. Ele consome três endpoints do ProspectOS, todos fixos em `http://localhost:5000`:

| Método | Endpoint | Uso no workflow | Evidência |
|---|---|---|---|
| POST | `/api/buscar` | Corpo `{"queries": "<texto com quebras de linha>"}` | `workflows/ProspectOS_para_Telegram.json`, nó `post-buscar` |
| GET | `/api/buscar/status` | Retorna JSON com o campo `status`; o workflow compara com `finalizada` | nó `get-status` e `if-done` |
| GET | `/api/exportar` | Retorna o CSV completo como arquivo | nó `get-csv` |

Os valores de resposta desses endpoints são definidos pelo ProspectOS, não por este repositório.

## Testes e qualidade

Não há testes neste repositório. Verificação feita por leitura direta dos arquivos:

- Nenhum arquivo de teste, nenhum diretório de teste, nenhum framework de teste.
- `package.json` tem apenas o script `start` (`n8n start`), sem `test` e sem `lint`.
- Nenhuma dependência de teste ou de build.

A verificação possível é manual: importar o workflow no n8n, executar com uma busca de referência e conferir o CSV recebido no Telegram. O `docs/GUIA.md` registra um teste de referência com `dentista em Belem`, mas esse resultado vem do ProspectOS e não pode ser reproduzido apenas com este repositório.

## Decisões técnicas e trade-offs

O polling de 20 segundos foi escolhido no lugar de webhook porque o fluxo depende de um backend que não expõe callback de conclusão. O custo é latência de até 20 segundos por iteração e um laço sem limite no JSON.

As quebras de linha são preservadas com `JSON.stringify($json.queries)` no corpo do POST, em vez de montar o JSON por interpolação direta, o que evita corpo malformado quando o usuário cola várias linhas.

O nó HTTP de export usa `responseFormat: file` para tratar o CSV como binário, e não como texto, o que permite o envio direto como documento no Telegram.

O caminho do backend está fixo em `http://localhost:5000` nos três nós HTTP, e não vem de variável de ambiente. Isso simplifica o uso local e impede apontar para outro host sem editar o JSON.

O `.env.example` existe como documentação de configuração, mas o workflow não referencia essas variáveis. A configuração real de acesso ao Telegram é feita pela credencial do n8n, e o Chat ID é preenchido no nó.

## Limitações conhecidas

- O laço de polling não tem limite de iterações nem timeout: se o ProspectOS travar sem mudar o campo `status`, o workflow repete `Aguardar 20s` indefinidamente.
- O nó `Enviar CSV p/ Telegram` no JSON traz apenas `channel: document` e o texto da legenda. Não há `chatId` nem `resource` no arquivo, então o destino precisa ser configurado na interface do n8n após a importação.
- O `.env` não é lido por nenhum código deste repositório. As variáveis do `.env.example` são apenas referência.
- As URLs dos três nós HTTP são fixas em `localhost:5000`.
- O `package.json` não declara `engines`, `test` nem `lint`.
- O `examples/exemplo.csv` tem 2 linhas de dados, com nomes e telefones de exemplo. Não é a base real de leads.
- O `package.json` é marcado como `private: true`, então não há publicação em registry.
- Coleta de dados de Google Maps e Instagram pode violar termos de uso desses serviços. A execução é por conta de quem roda.

## Licença e autor

MIT. Copyright (c) 2026 Kelvin Rebelo de Oliveira. Autor: [Kelvin Oliveira](https://github.com/KelvinOliveiraCode)

Documentação relacionada: [docs/GUIA.md](docs/GUIA.md) e [workflows/ProspectOS_para_Telegram.json](workflows/ProspectOS_para_Telegram.json).