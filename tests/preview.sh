#!/bin/sh
# 在影子树里预览仓库里的 Unzeit（不碰 ~/.emacs.d，也不 reconfigure）。
# 前提：现代化包已装进 ~/.emacs.d/elpa（先跑 tests/preinstall-modern.sh）。
set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo=$(dirname -- "$here")            # .../home/editor
langdir=$(CDPATH= cd -- "$repo/../lang" && pwd)
tmp=${UNZEIT_PREVIEW_DIR:-$HOME/tmp/unzeit-preview}

rm -rf "$tmp"
mkdir -p "$tmp/lisp" "$tmp/langs/toolchains"
cp "$repo"/.emacs.d/*.el "$tmp"/
cp "$repo"/.emacs.d/lisp/*.el "$tmp/lisp"/
cp -r "$repo"/.emacs.d/images "$tmp"/ 2>/dev/null || true

# 影子树的 package-user-dir 默认是 $tmp/elpa：直接指向真实 elpa，避免重复安装。
ln -s "$HOME/.emacs.d/elpa" "$tmp/elpa"

for f in "$langdir"/*/langs/*.el; do cp "$f" "$tmp/langs/"; done
for f in "$langdir"/*/langs/toolchains/*.el; do cp "$f" "$tmp/langs/toolchains/"; done

# 机器本地文件（不随 home 部署）：init-local 与 Customize/主屏台词。
for f in init-local.el custom-state.el dashboard-quotes.el; do
  [ -f "$HOME/.emacs.d/lisp/$f" ] && cp "$HOME/.emacs.d/lisp/$f" "$tmp/lisp/" 2>/dev/null || true
  [ -f "$HOME/.emacs.d/$f" ] && cp "$HOME/.emacs.d/$f" "$tmp/" 2>/dev/null || true
done

echo "预览目录：$tmp"
echo "包目录：$tmp/elpa -> $HOME/.emacs.d/elpa"
exec emacs --init-directory "$tmp" "$@"
