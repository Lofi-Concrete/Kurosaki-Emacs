;;; init-org.el --- Unzeit: org 配置 -*- lexical-binding: t; -*-

;; 照 acdcbyl/init-org：缓存与 refile 行为
(setq org-element-use-cache t)
(setq org-element-cache-persistent t)

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
  (org-export-with-smart-quotes t)
  ;; 视觉修饰
  (org-startup-indented t)
  (org-pretty-entities t)
  (org-hide-block-startup t)
  (org-fontify-done-headline t)     ; DONE 的标题用弱化色
  :bind (("C-c l s" . org-store-link)
         ("C-c l i" . org-insert-link-global))
  :hook
  ;; 用鼠标跟随链接 / 在另一个窗口浏览
  ((org-mode . (lambda ()
                 (setq-local line-spacing 0.2)))
   (org-mode . visual-line-mode))
  :config
  (require 'org-tempo)             ; <s TAB 等块模板
  (setf (cdr (assoc 'file org-link-frame-setup)) 'find-file)
  (add-to-list 'org-export-backends 'md))

(use-package org-appear
  :ensure t
  :hook (org-mode . org-appear-mode))

;; org-refile 在独立 feature 里；等它加载后再设 targets/path
(with-eval-after-load 'org-refile
  (setq org-outline-path-complete-in-steps nil
        org-refile-use-outline-path 'file
        org-refile-targets '((nil :maxlevel . 3)
                             (org-agenda-files :maxlevel . 3))))

;; 非 org 的 variable-pitch 也跟正文字体（Maple）；org 整体切到等宽 LXGW
(set-face-attribute 'variable-pitch nil :family "Maple Mono NF CN" :height 1.0)
(set-face-attribute 'fixed-pitch nil :family "Maple Mono NF CN" :height 1.0)

(require 'face-remap)

(defun unzeit/org-fonts ()
  "Org 缓冲整体使用 LXGW WenKai Mono。"
  (unzeit/apply-chinese-font "LXGW WenKai Mono")
  (face-remap-add-relative 'default
                           :family "LXGW WenKai Mono" :height 1.0)
  (face-remap-add-relative 'fixed-pitch
                           :family "LXGW WenKai Mono" :height 1.0))

(add-hook 'org-mode-hook #'unzeit/org-fonts)

;;; ---- org-modern：方正渲染 ----
(use-package org-modern
  :ensure t
  :hook (org-mode . org-modern-mode)
  :custom
  (org-modern-star 'replace)
  (org-modern-replace-stars '("■" "◼" "▪"))
  (org-modern-cycle-stars nil)      ; 更深的层级一律用最小的方块
  (org-modern-timestamp t)
  (org-modern-table t)
  (org-modern-table-vertical 1.0)
  (org-modern-priority t)
  (org-modern-todo t)
  ;; TODO 关键字方框的三态配色（跟着主题的语义 face 走）
  (org-modern-todo-faces
   '(("TODO" :inherit error :inverse-video t :weight semibold)
     ("DOING" :inherit warning :inverse-video t :weight semibold)
     ("DONE" :inherit shadow :inverse-video t :weight semibold)))
  (org-modern-tag t)
  (org-modern-block-name t)
  (org-modern-keyword t)
  (org-modern-progress 12)
  (org-modern-horizontal-rule t)
  (org-modern-label-border 0.1))    ; 标签方框用发丝描边

(font-lock-add-keywords
 'org-mode
 '(("^\\(\\**\\)\\* " (1 'org-hide))))

;;; ---- Org babel ------------------------------------------------
(with-eval-after-load 'ob
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)
     (shell . t)
     (python . t)
     (C . t))))

;;; ---- Org agenda / capture 快捷键（C-c a / C-c c）在 editor.el 中 --------

;;; init-org.el ends here
(provide 'init-org)
