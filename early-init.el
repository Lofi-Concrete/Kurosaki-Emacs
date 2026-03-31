;;; The initialization file for Emacs 27 and later.

;;; Commentary:

;; Emacs 27 and later will automatically initialize the package manager.
;; Therefore, to ensure that different Emacs versions can run packages in the desired order, we disable this feature here.

;;; Code:

(setq package-enable-at-startup nil)

;; VPN
(setq url-proxy-services '(
  ("http" . "127.0.0.1:7897")
  ("https" . "127.0.0.1:7897")
))

;; Prevent duplicate loading
(provide 'early-init)

;;; early-init.el ends here
