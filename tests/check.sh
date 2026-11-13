#!/bin/sh
# 验收：影子树 dump 后按集合比对变量/PATH（顺序无语义）；用法 ./check.sh [基线]，默认 ~/attic/migration-2026-10/before-emacs-vars.txt
set -eu

BASELINE=${1:-$HOME/attic/migration-2026-10/before-emacs-vars.txt}
HERE=$(cd "$(dirname "$0")" && pwd)
SHADOW=/tmp/etest/.emacs.d

[ -f "$BASELINE" ] || { echo "找不到基线：$BASELINE" >&2; exit 2; }

echo "── 1/3 搭影子树 ──────────────────────────────────────────"
"$HERE/mk-shadow.sh"

echo "── 2/3 dump（影子树）─────────────────────────────────────"
DUMP_OUT=/tmp/vars-post.txt DUMP_OUT2=/tmp/env-post.txt timeout 300 emacs -Q --batch \
  --eval '(setq user-emacs-directory "/tmp/etest/.emacs.d/")' \
  -l "$SHADOW/early-init.el" -l "$SHADOW/init.el" \
  -l "$HERE/dump-vars.el" -l "$HERE/dump-env.el" 2>/tmp/emacs-check.err | grep -E "DUMP-OK|ENV-OK"
[ -s /tmp/vars-post.txt ] || { echo "dump 没产出，看 /tmp/emacs-check.err" >&2; exit 1; }

echo "── 2b/3 dump（线上，用于 PATH 对比）───────────────────────"
DUMP_OUT2=/tmp/env-pre.txt timeout 300 emacs -Q --batch \
  -l "$HOME/.emacs.d/early-init.el" -l "$HOME/.emacs.d/init.el" \
  -l "$HERE/dump-env.el" >/dev/null 2>&1 || true

echo "── 3/3 比对 ──────────────────────────────────────────────"
A="$BASELINE" B=/tmp/vars-post.txt timeout 200 emacs -Q --batch -l "$HERE/cmp-vars.el" 2>&1 |
  grep -vE "^debug-early|^$"
A=/tmp/env-pre.txt B=/tmp/env-post.txt timeout 200 emacs -Q --batch -l "$HERE/cmp-env.el" 2>&1 |
  grep -vE "^debug-early|^$" || true

echo
echo "若上面全是 OK：可以 guix home reconfigure 了。"
echo "（加载语言文件失败会在 /tmp/emacs-check.err 里以「Unzeit: 加载语言配置 … 失败」出现）"
