#!/bin/sh
# 预装现代化层的新 ELPA 包（在真实 ~/.emacs.d/elpa 可写时运行一次）。
# 之后启动 Emacs 不会再因为缺包去联网；不跑也能启动，只是首次启动会自行安装。
set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cfg=$(dirname -- "$here")

exec emacs --batch \
  -l "$cfg/.emacs.d/lisp/unzeit-modern.el" \
  --eval "(progn
  (require 'package)
  (setq package-user-dir (expand-file-name \"~/.emacs.d/elpa\")
        package-quickstart nil
        package-archives
        (list (cons \"gnu\" \"https://mirrors.tuna.tsinghua.edu.cn/elpa/gnu/\")
              (cons \"nongnu\" \"https://mirrors.tuna.tsinghua.edu.cn/elpa/nongnu/\")
              (cons \"melpa\" \"https://mirrors.tuna.tsinghua.edu.cn/elpa/melpa/\")))
  (package-initialize)
  (package-refresh-contents)
  (dolist (p unzeit/modern-packages)
    (unless (package-installed-p p)
      (message \"安装 %s…\" p)
      (condition-case e (package-install p)
        (error (message \"安装 %s 失败：%S\" p e)))))
  (package-quickstart-refresh)
  (message \"现代化包预装完成\"))"
