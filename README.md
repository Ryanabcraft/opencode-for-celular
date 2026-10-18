# OpenCode no celular (Termux)

Roda o [OpenCode](https://opencode.ai) **nativamente dentro do Android** — sem PC, sem SSH, sem container.
Serve pra você pedir e editar código direto no celular, inclusive montar site, e ver rodando no próprio aparelho.

Testado num **moto g32, Android 13, arm64**: TUI abre, aceita prompt e o modelo responde.

## Cole isto no Termux

```bash
curl -fsSL https://raw.githubusercontent.com/Ryanabcraft/opencode-for-celular/main/install-termux.sh | bash
```

Depois:

```bash
opencode          # ou opencode2 — os dois abrem o mesmo app
```

Rodar o mesmo comando de novo **atualiza** para a release mais nova.

> Deu erro de repositório/mirror no `pkg`? Rode `pkg update` e repita o comando.

## Requisitos

- **Termux do [F-Droid](https://f-droid.org/packages/com.termux/)** — o da Play Store está abandonado e quebra os pacotes
- Android 7+ e aparelho **arm64** (todo celular atual; `uname -m` precisa dar `aarch64`)
- ~1 GB livre (o binário tem 173 MB + 22 MB de biblioteca)

## O que o instalador faz

1. Pede a permissão de armazenamento (`termux-setup-storage`) — só se você ainda não liberou, e negar não trava a instalação. É isso que deixa o OpenCode abrir projetos que estão no `/sdcard`.
2. Confere se `unzip` e `curl` existem (já vêm no Termux) e instala se faltar.
3. Descobre a release mais nova do [guysoft/opencode-termux](https://github.com/guysoft/opencode-termux) (o build Android do OpenCode).
4. Baixa o zip e **confere o SHA256** contra o manifesto da própria release.
5. Instala em `$PREFIX/bin/opencode2` + `$PREFIX/libexec/opencode2/` (o layout que o wrapper espera).
6. Roda `opencode2 --version` — se o binário não rodar neste Android, ele grita em vez de fingir que deu certo.
7. Cria o atalho `opencode` (só se você não tiver um `opencode` instalado, ex. a v1).
8. Instala o `ripgrep` se faltar — é o `rg`, a busca de arquivos que o agente usa pra achar texto no seu projeto.

Offline / zip já baixado: `OC_ZIP=<zip> OC_SUMS=<SHA256SUMS> bash install-termux.sh`.

## Primeiro uso

```bash
cd minha-pasta
opencode
```

Já vem com um **modelo grátis** selecionado (`Nemotron 3.5 Super VL Free`) — deu pra mandar prompt sem login nenhum.
Para usar seus provedores (Anthropic, OpenAI, OpenRouter...):

```bash
opencode auth login
```

Já tem OpenCode configurado no PC? Dá pra levar as credenciais:

```bash
# no PC
opencode auth export > creds.json      # contém segredos, não cole em chat
# no celular
opencode auth import < creds.json && rm creds.json
```

## Criar site direto no celular

```bash
pkg install -y git nodejs-lts python
mkdir meu-site && cd meu-site && git init
opencode
```

O projeto está nos arquivos do celular (Downloads, Documentos)? O caminho é `~/storage/shared/...`
— ex: `cd ~/storage/shared/Download/meu-site`. É pra isso que serve a permissão de armazenamento do passo 1.

Peça o site normal. Para ver o resultado, suba um preview e abra no navegador do próprio celular:

```bash
python -m http.server 8080     # abra http://localhost:8080
```

Dica: `termux-wake-lock` antes de tarefa longa (senão o Android mata a sessão com a tela apagada).
Teclado: o Termux já traz a barra com ESC/CTRL/ALT — ajuda bastante.

## Atualizar / desinstalar

```bash
# atualizar: rode o mesmo comando do topo

# desinstalar
rm -f "$PREFIX/bin/opencode2" "$PREFIX/bin/opencode" && rm -rf "$PREFIX/libexec/opencode2"
```

## Limites conhecidos

- É a linha **2.x pré-release** do build Android: a versão é `2.0.0-android-termux.2` (o OpenCode oficial já está em 2.0.32).
- File watcher desligado (o `@parcel/watcher` só existe pra x86 — cai em polling). Funciona, gasta mais bateria.
- Sem `bun upgrade` e sem auto-update pelo app: atualize rodando o comando do topo.
- FFI/TinyCC pode gerar código inválido em ARM64 (raro; o OpenCode quase não usa).
- É TUI, não GUI.

## Por que não dá pra usar o binário oficial

O OpenCode oficial é um binário compilado com [Bun](https://bun.sh), e Bun **não suporta Android**
([issue fechada como "not planned"](https://github.com/oven-sh/bun/issues/9)). Além disso o seccomp do Android
mata com `SIGSYS` qualquer binário que chame `close_range` — que o Bun chama. O build usado aqui é o
Bun + WebKit/JSC cross-compilados para Android, com esse bug corrigido.

## Alternativas

- **OpenCode 1.x nativo (estável)** — mesmo repo, pacote `opencode` (v1). Use se o 2.x te travar.
- **[bun-termux](https://github.com/Happ1ness-dev/bun-termux)** — shim do Bun + `replace_runtime.py` para trocar o runtime de um bundle oficial.
- **UDocker/Cortermux** — Ubuntu em container dentro do Termux; pesa mais, roda o binário oficial Linux.
- **`opencode serve` no PC + web UI** — o jeito mais leve de usar do celular; não é este projeto.

## Créditos

- Binários: [guysoft/opencode-termux](https://github.com/guysoft/opencode-termux) (MIT)
- OpenCode: [anomalyco/opencode](https://github.com/anomalyco/opencode)
