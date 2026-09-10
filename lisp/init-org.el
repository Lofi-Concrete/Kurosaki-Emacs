;;; init-org.el --- Unzeit: org 配置 -*- lexical-binding: t; -*-

;;; Commentary:
;; Org 配置：默认目录、日程文件、TODO 工作流、快速捕获、视觉修饰
;; （缩进、折叠标题星号），以及这台机器上可用语言的 babel 执行
;; 完整快捷键参见 ~/org/操作手册.org（SPC o m 打开）

;;; Code:

(use-package org
  :ensure nil
  :defer t
  :custom
  (org-directory "~/org")
  (org-default-notes-file (expand-file-name "inbox.org" org-directory))
  (org-agenda-files (list (expand-file-name "inbox.org" org-directory)
                          (expand-file-name "projects.org" org-directory)))
  (org-return-follows-link t)                 ; 回车跟随链接
  (org-hide-emphasis-markers t)               ; 隐藏 *加粗* 等标记符
  (org-startup-folded 'content)               ; 启动时按内容层级折叠
  (org-insert-heading-respect-content t)
  (org-cycle-separator-lines 1)
  ;; TODO 工作流：待办 -> 进行中 -> 完成
  (org-todo-keywords '((sequence "TODO(t)" "DOING(i)" "DONE(d)")))
  (org-todo-keyword-faces
   '(("TODO" . error)
     ("DOING" . warning)
     ("DONE" . success)))
  (org-capture-templates
   '(("t" "任务" entry (file "")
      "* TODO %?\n  %U\n" :empty-lines 1)
     ("n" "笔记" entry (file "notes.org")
      "* %?\n  %U\n" :empty-lines 1)))
  (org-clock-into-drawer t)
  (org-log-done 'time)
  ;; 视觉修饰
  (org-startup-indented t)
  (org-pretty-entities t)
  (org-hide-block-startup t)
  (org-fontify-done-headline t)     ; DONE 的标题用弱化色
  :hook
  ;; 用鼠标跟随链接 / 在另一个窗口浏览
  ((org-mode . (lambda ()
                 (setq-local line-spacing 0.2)))
   (org-mode . visual-line-mode))
  :config
  (require 'org-tempo))             ; <s TAB 等块模板

;;; ---- org-modern：方正渲染 -----------------------------------------
;; 标题星号换成方块的实心度（■ ◼ ▪ 按层级），TODO/标签/优先级变成方框，
;; 表格画成网格、代码块名与 #+ 元数据变成小标签、[1/3] 变成色块进度条。
;; 刻意避开 org-modern 默认的 ◉○◈◇✳（圈）与默认的三角折叠符号。
;; 注：方块星号的颜色跟随 org-level-N，不需要单独配色
(use-package org-modern
  :ensure t
  :hook (org-mode . org-modern-mode)
  :custom
  (org-modern-star 'replace)
  (org-modern-replace-stars '("■" "◼" "▪"))
  (org-modern-cycle-stars nil)      ; 更深的层级一律用最小的方块
  (org-modern-timestamp t)
  (org-modern-table t)
  (org-modern-table-vertical 2)     ; 表格竖线细一点（默认 3）
  (org-modern-priority t)
  (org-modern-todo t)
  ;; TODO 关键字方框的三态配色（跟着主题的语义 face 走）
  (org-modern-todo-faces
   '(("TODO" :inherit unzeit-face-critical :inverse-video t :weight semibold)
     ("DOING" :inherit unzeit-face-popout :inverse-video t :weight semibold)
     ("DONE" :inherit unzeit-face-subtle :inverse-video t :weight semibold)))
  (org-modern-tag t)
  (org-modern-block-name t)
  (org-modern-keyword t)
  (org-modern-progress 12)
  (org-modern-horizontal-rule t)
  (org-modern-label-border 0.1))    ; 标签方框用发丝描边

;; org-indent-mode 开启时 org 自己不再隐藏前导星号，而 org-modern 只把
;; 「最后一个星号」换成方块，于是二级以下会出现 **▪ 这样的残留。这里把
;; 最后一个星号之前的部分涂成 org-hide（前景=背景），标题前就只剩方块
(font-lock-add-keywords
 'org-mode
 '(("^\\(\\**\\)\\* " (1 'org-hide))))

;;; ---- Org babel ------------------------------------------------
;; 为本机已安装的语言执行代码块
(with-eval-after-load 'ob
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)
     (shell . t)
     (python . t)
     (C . t))))

;;; ---- Org agenda 快捷键（SPC o）在 editor.el 中 -------------

;;; init-org.el ends here
(provide 'init-org)
