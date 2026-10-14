# Regras para Agentes de IA - Repositorio Pantanal

## Arquitetura de Protecao por Senha

Este site usa **criptografia AES-256-CBC + HMAC-SHA256 client-side** para proteger dados pessoais.
O arquivo publicado (`index.html`) contem apenas uma tela de login e dados criptografados ilegiveis.
O conteudo real do site existe apenas em `index_original.html`, que **nunca deve ser publicado**.

### Estrutura de Arquivos

| Arquivo | Finalidade | No Git? |
|---------|-----------|---------|
| `index_original.html` | Conteudo real do site (texto aberto) - **EDITAR ESTE** | NAO (.gitignore) |
| `index.html` | Versao criptografada com tela de login - **GERADO AUTOMATICAMENTE** | SIM |
| `protect.ps1` | Script PowerShell que criptografa `index_original.html` -> `index.html` | SIM |
| `login_template.html` | Template HTML da tela de login (usado pelo protect.ps1) | SIM |
| `.password` | Contem a senha de criptografia (texto plano, 1 linha) | NAO (.gitignore) |
| `.gitignore` | Impede publicacao de arquivos sensiveis | SIM |
| `AGENTS.md` | Este arquivo de regras | SIM |
| `protect_page.js` | Mesma criptografia do `protect.ps1`, em Node (`node protect_page.js [pasta]`) | SIM |
| `cariri/` | Roteiro do Cariri, publicado em `/cariri/` (mesma estrutura: `index_original.html`, `.password`, `login_template.html`, `index.html`) | so `index.html` e `login_template.html` |

## REGRA CRITICA: Seguranca da Senha

- A senha esta armazenada APENAS no arquivo `.password` (local, nunca comitado).
- **NUNCA escreva a senha em nenhum arquivo que sera comitado** (incluindo este AGENTS.md, commits, comentarios no codigo, etc.).
- O repositorio e PUBLICO. Qualquer texto comitado e visivel para o mundo inteiro.
- O script `protect.ps1` le a senha automaticamente do arquivo `.password`.

## Regras Obrigatorias para Edicao do Site

### 1. SEMPRE editar `index_original.html`

- **NUNCA edite `index.html` diretamente.** Ele e gerado automaticamente e qualquer edicao manual sera sobrescrita.
- Todas as alteracoes de conteudo, estilo, layout e dados devem ser feitas em `index_original.html`.

### 2. APOS editar, SEMPRE gerar o arquivo criptografado

Depois de qualquer alteracao em `index_original.html`, execute:

```powershell
powershell -ExecutionPolicy Bypass -File protect.ps1
```

O script le a senha automaticamente do arquivo `.password`. Nao e necessario passa-la como parametro.

### 3. Fluxo completo de publicacao

```powershell
# 1. Editar index_original.html (ja feito pelo agente)
# 2. Gerar versao criptografada (le senha de .password)
powershell -ExecutionPolicy Bypass -File protect.ps1
# 3. Fazer commit e push
git add .
git commit -m "descricao da alteracao"
git push origin main
```

### 4. Verificacao

Apos o push, o site estara acessivel em GitHub Pages. Para verificar:
- Acessar a URL do site -> deve mostrar a tela de login
- Digitar a senha -> deve mostrar o conteudo atualizado

### 5. Outros roteiros (subpastas)

Cada viagem extra fica numa subpasta com os mesmos arquivos (ex.: `cariri/`), acessivel em `https://geraldotfilho.github.io/pantanal/<pasta>/`.
A senha de cada roteiro fica no `.password` da propria subpasta (ignorado pelo git). Para gerar o arquivo criptografado:

```bash
node protect_page.js cariri
```

O `login_template.html` de cada subpasta usa uma chave propria no `localStorage` (ex.: `_exp_cariri_key`), para nao conflitar com o "Lembrar" do Pantanal.

## Informacoes Tecnicas

- **Algoritmo:** AES-256-CBC com PBKDF2 (600.000 iteracoes, SHA-256) + HMAC-SHA256
- **PBKDF2 gera 64 bytes:** 32 para AES key + 32 para HMAC key
- **Salt:** 32 bytes aleatorios (regenerado a cada criptografia)
- **IV:** 16 bytes aleatorios (regenerado a cada criptografia)
- **Descriptografia:** Feita no browser via Web Crypto API
- **"Lembrar neste dispositivo":** Usa `localStorage` (chave: `_exp_ms_key`)
- **Hospedagem:** GitHub Pages (repo: `geraldotfilho/pantanal`)

## O que NAO fazer

- NAO editar `index.html` diretamente
- NAO fazer push sem rodar `protect.ps1` depois de editar `index_original.html`
- NAO remover `index_original.html` ou `.password` do `.gitignore`
- NAO fazer commit do `index_original.html` (contem dados pessoais em texto aberto)
- NAO escrever a senha em NENHUM arquivo comitado (repo publico!)
- NAO alterar `login_template.html` sem re-rodar a criptografia
