#!/data/data/com.termux/files/usr/bin/sh
# Instala/atualiza o OpenCode 2 nativo no Termux (Android arm64). Rodar de novo = atualizar.
# Instalação offline / zip já baixado:  OC_ZIP=<zip> OC_SUMS=<SHA256SUMS> bash install-termux.sh
set -eu

REPO="${OC_REPO:-guysoft/opencode-termux}"
DEST="$PREFIX/libexec/opencode2"

die() { echo "erro: $*" >&2; exit 1; }

[ -n "${PREFIX:-}" ] && [ -d "$PREFIX/bin" ] || die "rode isto dentro do Termux"
[ "$(uname -m)" = "aarch64" ] || die "só existe build arm64 (aarch64); este aparelho é $(uname -m)"

# 0. Permissão de armazenamento: permite abrir projetos que estão no /sdcard
#    (ex: ~/storage/shared/Download/meu-site). Pula se você já liberou e não é
#    obrigatório pro OpenCode — se você negar a permissão, a instalação segue.
if [ ! -e "$HOME/storage/shared" ] && command -v termux-setup-storage >/dev/null; then
  echo "pedindo permissão de armazenamento — aceite na tela pra o OpenCode ver seus arquivos"
  termux-setup-storage || true
fi
command -v unzip >/dev/null || die "falta unzip — rode: pkg install unzip"

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

# 1. Conseguir o zip (release mais nova, ou o que o usuário passar) e o SHA256SUMS
if [ -n "${OC_ZIP:-}" ]; then
  file=$(basename "$OC_ZIP")
  cp "$OC_ZIP" "$tmp/$file"
  if [ -n "${OC_SUMS:-}" ]; then
    cp "$OC_SUMS" "$tmp/SHA256SUMS"
  else
    echo "aviso: sem OC_SUMS, não vou poder conferir o hash"
  fi
else
  command -v curl >/dev/null || die "falta curl — rode: pkg install curl"
  url=$(curl -fsSL "https://api.github.com/repos/$REPO/releases?per_page=5" \
    | grep -o '"browser_download_url": *"[^"]*opencode2-[^"]*-android-aarch64\.zip"' \
    | head -n 1 | sed 's/.*"\(https[^"]*\)"/\1/') || true
  [ -n "${url:-}" ] || die "não achei a release; use OC_ZIP=<zip> OC_SUMS=<SHA256SUMS>"
  file=$(basename "$url")
  echo "baixando $file ..."
  curl -fL --progress-bar -o "$tmp/$file" "$url"
  curl -fsSL -o "$tmp/SHA256SUMS" "$(dirname "$url")/SHA256SUMS"
fi

# 2. Conferir integridade: o hash tem que estar no manifesto da própria release
if [ -f "$tmp/SHA256SUMS" ]; then
  sum=$(sha256sum "$tmp/$file" | cut -d' ' -f1)
  grep -q "^$sum" "$tmp/SHA256SUMS" || die "hash do zip não confere — download corrompido ou arquivo trocado"
fi

# 3. Instalar no layout que o wrapper procura: bin/ + libexec/opencode2/
unzip -q -o "$tmp/$file" -d "$tmp/x"
mkdir -p "$DEST"
cp "$tmp/x/opencode2" "$PREFIX/bin/opencode2"
cp "$tmp/x/opencode2.bin" "$DEST/opencode2.bin"
cp "$tmp/x/libopentui.so" "$DEST/libopentui.so"
chmod 755 "$PREFIX/bin/opencode2" "$DEST/opencode2.bin"
chmod 644 "$DEST/libopentui.so"

# 4. O teste que importa: o binário roda neste Android?
"$PREFIX/bin/opencode2" --version || die "instalou mas não executou — github.com/$REPO/issues"

# 5. Atalho: digitar 'opencode' também abre (não sobrescreve um opencode já instalado, ex. v1)
[ -e "$PREFIX/bin/opencode" ] || ln -s opencode2 "$PREFIX/bin/opencode"

# 6. ripgrep é dependência de runtime (busca do agente), não da instalação
if ! command -v ripgrep >/dev/null; then
  pkg install -y ripgrep >/dev/null 2>&1 || echo "FALTA(pkg): rode 'pkg install ripgrep' — o agente usa na busca"
fi

echo
echo "pronto. rode:  opencode   (ou opencode2)"
