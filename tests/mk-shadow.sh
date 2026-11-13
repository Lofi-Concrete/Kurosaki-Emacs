#!/bin/sh
# 叠影子树 /tmp/etest/.emacs.d：线上 ~/.emacs.d + 仓库改动 + home/lang/*/langs/，不用 reconfigure。
set -eu
H=/tmp/etest/.emacs.d
REPO=$HOME/guix/home/editor/.emacs.d
rm -rf /tmp/etest && mkdir -p "$H"
for f in $HOME/.emacs.d/* $HOME/.emacs.d/.[!.]*; do
  [ -e "$f" ] || continue
  b=$(basename "$f")
  # lisp/ 与 langs/ 都要用仓库版本重建，不能沿用线上（线上是只读 store 软链）
  case "$b" in lisp|langs) continue;; esac
  ln -s "$f" "$H/$b"
done
cp -a $HOME/.emacs.d/lisp "$H/lisp"
for f in "$REPO"/lisp/*.el; do
  b=$(basename "$f"); [ "$b" = "init-local.el" ] && continue   # 机器本地，别覆盖
  cp --remove-destination "$f" "$H/lisp/$b"
done
cp --remove-destination "$REPO/init.el" "$REPO/early-init.el" "$H/"
mkdir -p "$H/langs/toolchains"
cd $HOME/guix/home/lang
for f in $(find . -path '*/langs/*.el' -not -path '*/toolchains/*'); do cp --remove-destination "$f" "$H/langs/"; done
for f in $(find . -path '*/langs/toolchains/*.el'); do cp --remove-destination "$f" "$H/langs/toolchains/"; done
