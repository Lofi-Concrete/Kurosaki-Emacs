;;; modeline
;;; Commentary:
;;; code:

(use-package powerline
 :ensure t
 :config
 (powerline-default-theme))

(use-package smart-mode-line
 :ensure t
 :init
 ; (setq sml/no-confirm-load-theme t) ; avoid asking when startup
 (sml/setup)
 :config
 (setq rm-blacklist
  (format "^ \\(%s\\)$"
   (mapconcat #'identity
    '("Projectile.*" "company.*" "Google"
  "Undo-Tree" "counsel" "ivy" "yas" "WK")
     "\\|"))))

(provide 'init-modeline)

;;; init-modeline.el ends here
