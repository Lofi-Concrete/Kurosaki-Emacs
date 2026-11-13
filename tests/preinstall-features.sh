#!/bin/sh
# 预装 2026-11 新增功能包：语言模式 / 补全 / 文件树 / Git / 笔记。
# 优先使用 ~/.emacs.d/elpa 中已存在的包；缺失的从 ELPA 镜像安装。
set -eu
EMACS=${EMACS:-emacs}
"$EMACS" --batch -Q \
  --eval '(progn
            (require (quote package))
            (setq package-user-dir (expand-file-name "~/.emacs.d/elpa"))
            (package-initialize)
            (dolist (p (quote (dart-mode julia-mode julia-ts-mode php-mode
                               scala-ts-mode swift-ts-mode powershell
                               cmake-mode csv-mode fish-mode protobuf-mode
                               scss-mode ron-mode markdown-mode
                               markdown-mermaid mermaid-ts-mode
                               inf-ruby rspec-mode ruby-refactor
                               consult-dir consult-yasnippet consult-todo
                               consult-flyspell wgrep link-hint
                               browse-kill-ring easy-kill smart-region
                               drag-stuff avy-zap rg
                               region-occurrences-highlighter hl-todo
                               treemacs treemacs-magit treemacs-nerd-icons
                               magit-todos git-timemachine browse-at-remote
                               git-messenger git-modes
                               org-roam org-roam-ui emacsql websocket
                               simple-httpd)))
              (unless (package-installed-p p)
                (condition-case err
                    (package-install p)
                  (error (message "skip %s: %s" p err))))))'
