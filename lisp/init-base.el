;;; A miscellaneous transitional module
;;; Commentary:
;;; Code:

(electric-pair-mode t)    ; Auto-complete parentheses/pairs
(add-hook 'prog-mode-hook #'show-paren-mode)    ; Highlight matching parenthesis in programming modules
(column-number-mode t)    ; Display column number in mode line
(global-auto-revert-mode t)    ; Automatically reload files when they change on disk
(delete-selection-mode t)    ; Delete selected text when typing
(setq inhibit-startup-message t)    ; Hide startup message
(setq make-backup-files nil)    ; Disable backup files
(add-hook 'prog-mode-hook #'hs-minor-mode)    ; Enable code folding in programming modes
(global-display-line-numbers-mode t)    ; Display line numbers in all buffers
(tool-bar-mode -1)    ; Disable toolbar
(menu-bar-mode -1)    ; Disable menu bar
(when (display-graphic-p) (toggle-scroll-bar -1))   ; Hide scroll bar in graphical mode
(savehist-mode 1)   ; Enable history saving
(setq display-line-numbers-type 'relative)    ; Display line numbers in all buffers

;; elpa
(require 'package)
(setq package-archives '(
  ("gnu" . "https://elpa.gnu.org/packages/")
  ("melpa" . "https://melpa.org/packages/")
))
(package-initialize)

;; packages
;; Init and install use-package
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
;; enable use-package
(eval-when-compile
  (require 'use-package))
(setq use-package-always-ensure t)

;; Prevent duplicate loading
(provide 'init-base)

;;; init-base.el ends here
