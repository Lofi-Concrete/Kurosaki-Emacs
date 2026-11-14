;;; unzeit-editing.el --- Unzeit: 编辑 UX（Centaur 精选） -*- lexical-binding: t; -*-

;;; Commentary:
;; 只收和 meow/现有 move-text/whole-line 不冲突的项：
;; mwim、hungry-delete、iedit、expand-region、vundo、goto-chg、anzu、
;; beginend、ace-pinyin、pulsar、goggles、page-break-lines、nerd-icons-corfu。
;; multiple-cursors 只安装、不启用（meow 的选择模型会打架）。

;;; Code:

;; C-a / C-e：第一次到行首/行尾，第二次到代码首/尾（Centaur 同款）。
(use-package mwim
  :ensure t
  :bind (([remap move-beginning-of-line] . mwim-beginning)
         ([remap move-end-of-line] . mwim-end)))

;; 删除时吃掉整段空白。
(use-package hungry-delete
  :ensure t
  :hook (after-init . global-hungry-delete-mode)
  :custom
  (hungry-delete-chars-to-skip " \t\f\v")
  :config
  (dolist (mode '(help-mode minibuffer-mode minibuffer-inactive-mode calc-mode))
    (add-to-list 'hungry-delete-except-modes mode)))

;; 多点编辑（iedit）与语义扩展选区（expand-region）。
(use-package iedit
  :ensure t
  :bind ("C-;" . iedit-mode))

(use-package expand-region
  :ensure t
  :bind ("C-=" . er/expand-region))

;; 树状撤销 UI（Centaur）；持久化撤销仍由 init-misc 的 undo-fu-session 负责。
(use-package vundo
  :ensure t
  :bind ("C-x u" . vundo)
  :config
  (setq vundo-glyph-alist vundo-unicode-symbols))

;; 跳到上一次修改处。
(use-package goto-chg
  :ensure t
  :bind ("C-," . goto-last-change))

;; 搜索/替换计数。
(use-package anzu
  :ensure t
  :demand t
  :config
  (global-anzu-mode 1))

;; M-< / M-> 变成 mode 感知（buffer / defun / page）。
(use-package beginend
  :ensure t
  :demand t
  :config
  (beginend-global-mode 1))

;; avy 跳转支持中文拼音首字母。
(use-package ace-pinyin
  :ensure t
  :demand t
  :config
  (ace-pinyin-global-mode 1))

;; 跳转后脉冲高亮。
(use-package pulsar
  :ensure t
  :demand t
  :config
  (pulsar-global-mode 1))

;; 显示刚改动的区域。
(use-package goggles
  :ensure t
  :hook (prog-mode . goggles-mode))

;; ^L 分页符渲染成细线。
(use-package page-break-lines
  :ensure t
  :demand t
  :config
  (global-page-break-lines-mode 1))

;; corfu 候选左边距显示文件/模式图标。
(use-package nerd-icons-corfu
  :ensure t
  :after corfu
  :config
)

;; 只装不启用：和 meow 的选择/编辑模型冲突，留给需要时手动开。
(use-package multiple-cursors
  :ensure t
  :defer t)

;; CamelCase 子词移动（内置）。
(add-hook 'prog-mode-hook #'subword-mode)

(provide 'unzeit-editing)
;;; unzeit-editing.el ends here
