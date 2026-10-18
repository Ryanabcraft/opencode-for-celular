#!/data/data/com.termux/files/usr/bin/sh
# OpenCode 2 nativo no Termux (Android arm64). Rodar de novo = atualizar.
# Offline: OC_ZIP=<zip> OC_SUMS=<SHA256SUMS> bash install-termux.sh
set -eu
REPO="${OC_REPO:-guysoft/opencode-termux}"; DEST="$PREFIX/libexec/opencode2"
die() { echo "erro: $*" >&2; exit 1; }

[ -n "${PREFIX:-}" ] && [ -d "$PREFIX/bin" ] || die "rode isto dentro do Termux"
[ "$(uname -m)" = aarch64 ] || die "só existe build arm64; este aparelho é $(uname -m)"
export TMPDIR="${TMPDIR:-$PREFIX/tmp}"   # o app precisa de temp gravável (alguns shims não setam)

# Libera os arquivos do celular (/sdcard). Inútil pro OpenCode em si: pule se já tem.
if [ ! -e "$HOME/storage/shared" ] && command -v termux-setup-storage >/dev/null; then
  echo "aceite a permissão de armazenamento se quiser abrir projetos que estão no /sdcard"
  termux-setup-storage || true
fi

for p in unzip curl; do
  command -v "$p" >/dev/null || pkg install -y "$p" || die "falta $p — rode: pkg install $p"
done

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

if [ -n "${OC_ZIP:-}" ]; then
  file=$(basename "$OC_ZIP"); cp "$OC_ZIP" "$tmp/$file"
  [ -z "${OC_SUMS:-}" ] || cp "$OC_SUMS" "$tmp/SHA256SUMS"
else
  url=$(curl -fsSL "https://api.github.com/repos/$REPO/releases?per_page=5" \
    | grep -o '"browser_download_url": *"[^"]*opencode2-[^"]*-android-aarch64\.zip"' \
    | head -n1 | sed 's/.*"\(https[^"]*\)"/\1/') || true
  [ -n "${url:-}" ] || die "não achei a release; use OC_ZIP=<zip> OC_SUMS=<SHA256SUMS>"
  file=$(basename "$url"); echo "baixando $file ..."
  curl -fL --progress-bar -o "$tmp/$file" "$url"
  curl -fsSL -o "$tmp/SHA256SUMS" "$(dirname "$url")/SHA256SUMS"
fi

# O hash tem que constar no manifesto da própria release (pega download corrompido)
[ ! -f "$tmp/SHA256SUMS" ] \
  || grep -q "^$(sha256sum "$tmp/$file" | cut -d' ' -f1)" "$tmp/SHA256SUMS" \
  || die "hash do zip não confere — download corrompido ou trocado"

unzip -q -o "$tmp/$file" -d "$tmp/x"
mkdir -p "$DEST"
# Renomear por cima em vez de copiar direto: cp dá "Text file busy" com o opencode aberto
put() { cp "$1" "$2.new" && mv -f "$2.new" "$2"; }
put "$tmp/x/opencode2" "$PREFIX/bin/opencode2"
put "$tmp/x/opencode2.bin" "$DEST/opencode2.bin"
put "$tmp/x/libopentui.so" "$DEST/libopentui.so"
chmod 755 "$PREFIX/bin/opencode2" "$DEST/opencode2.bin"; chmod 644 "$DEST/libopentui.so"

"$PREFIX/bin/opencode2" --version || die "instalou mas não executou — github.com/$REPO/issues"
[ -e "$PREFIX/bin/opencode" ] || ln -s opencode2 "$PREFIX/bin/opencode"   # atalho
command -v ripgrep >/dev/null || pkg install -y ripgrep >/dev/null 2>&1 \
  || echo "FALTA: rode 'pkg install ripgrep' — é a busca do agente"

echo; echo "pronto. rode:  opencode   (se estava aberto, feche e abra de novo)"
