;;;
;;; Commentary:
;;; Code:

(setq pv/org-refile-file (concat org-directory "refile.org"))

(use-package org
 :defer t
 :custom
 ;; ...
 (org-capture-templates
  (quote (("t" "todo" entry (file pv/org-refile-file)
 	"* TODO %?\n%U\n%a\n" :clock-in t :clock-resume t)
   ("r" "respond" entry (file pv/org-refile-file)
 	"* NEXT Respond to %:from on %:subject\nSCHEDULED: %t\n%U\n%a\n" :clock-in t :clock-resume t :immediate-finish t)
   ("n" "note" entry (file pv/org-refile-file)
 	"* %? :NOTE:\n%U\n%a\n" :clock-in t :clock-resume t)
   ("w" "org-protocol" entry (file pv/org-refile-file)
 	"* TODO Review %c\n%U\n" :immediate-finish t)
   ("m" "Meeting" entry (file pv/org-refile-file)
 	"* MEETING with %? :MEETING:\n%U" :clock-in t :clock-resume t))))
 (org-refile-targets (quote ((nil :maxlevel . 9)
                 (org-agenda-files :maxlevel . 9))))
 ;; Use full outline paths for refile targets - we file directly with IDO
 (org-refile-use-outline-path 'file)
  ;; Allow refile to create parent tasks with confirmation
 (org-refile-allow-creating-parent-nodes (quote confirm))
 (org-cite-global-bibliography pv/org-bibtex-files)
 :bind
 ;; ...
 (("C-c a" . 'org-agenda)
  ("C-c c" . 'org-capture)
  :map org-mode-map
  ("C-c C-q" . counsel-org-tag)))

(provide 'init-org-capture)

;;; init-org-capture.el ends here
