#!/bin/sh
# 拼「部署后同构」影子树跑 smoke.el：仓库目录缺 langs/；用法 smoke.sh，退出码 0 = 全过。
set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo=$(dirname -- "$here")            # .../home/editor
langdir=$(CDPATH= cd -- "$repo/../lang" && pwd)
tmp=${TMPDIR:-/tmp}/unzeit-smoke.$$

cleanup() { rm -rf "$tmp"; }
trap cleanup EXIT INT TERM

mkdir -p "$tmp/lisp" "$tmp/langs/toolchains"
cp "$repo"/.emacs.d/*.el "$tmp"/
cp "$repo"/.emacs.d/lisp/*.el "$tmp/lisp"/
cp -r "$repo"/.emacs.d/images "$tmp"/ 2>/dev/null || true
for f in "$langdir"/*/langs/*.el; do cp "$f" "$tmp/langs/"; done
for f in "$langdir"/*/langs/toolchains/*.el; do cp "$f" "$tmp/langs/toolchains/"; done

echo "影子树：$tmp"
# 影子树的 user-emacs-directory 不是 ~/.emacs.d：补回 profile 与本地手编语法的两条路径。
# 沙箱/只读用途下可用 UNZEIT_SMOKE_ELPA 指向一份可写的 elpa 副本。
elpa=${UNZEIT_SMOKE_ELPA:-$HOME/.emacs.d/elpa}
exec emacs --batch --init-directory "$tmp" \
  --eval "(setq package-user-dir \"$elpa\")" \
  --eval '(setq native-comp-jit-compilation nil
                native-comp-deferred-compilation nil
                package-native-compile nil)' \
  -l "$tmp/early-init.el" -l "$tmp/init.el" \
  --eval '(setq treesit-extra-load-path
                (list (expand-file-name "~/.guix-home/profile/lib/tree-sitter")
                      (expand-file-name "~/.emacs.d/tree-sitter")))' \
  -l "$here/smoke.el"
