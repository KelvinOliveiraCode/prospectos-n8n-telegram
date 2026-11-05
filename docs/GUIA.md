# Guia - ProspectOS + n8n + Telegram

> Dados de exemplo anonimizados. Nunca versione tokens ou CSVs reais.

## Ligar tudo

1. ProspectOS: `cd ..\ProspectOS; .\iniciar.bat` (backend :5000)
2. n8n: `npm install n8n; npx n8n start` → http://localhost:5678
3. Importar `workflows/ProspectOS_para_Telegram.json`
4. Credencial Telegram + Chat ID no nó Telegram

## Multi-linhas

Cole no Form:

```
dentista em Belem
clinica de estetica em Belem
academia em Ananindeua
```

O n8n envia `{"queries":"..."}` com quebras de linha. O backend valida `MAX_LINHAS_QUERIES_BUSCA` e dispara 1 varredura ampla (dedupe automático na base).

## Teste do repo

Busca de referência: `dentista em Belem` → 20 capturadas, 5 novas (3 sem site + 2 site ruim), 7 já estavam na base, 8 site bom descartados, base 497→502.

## Segurança

- Token e Chat ID vivem em `.env` (ignorado pelo git)
- `*.csv` e `leads*.csv` ignorados
- Workflow versionado sem credenciais embutidas
