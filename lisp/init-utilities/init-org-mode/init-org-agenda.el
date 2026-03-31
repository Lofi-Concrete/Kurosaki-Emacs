;;; Org can select items based on various criteria and display them in a separate buffer
;;; Commentary:
;;; Code:

(setq org-directory (file-truename "~/org/"))
(setq pv/org-agenda-files `(,(concat org-directory "Agenda/")))

(use-package org
 :defer t
 :init
 (require 'org-indent)
 :config
 (defun pv/init-org-hook ()
	(setq truncate-lines nil)
	(org-toggle-pretty-entities)) ; display LaTeX symbols
 (defun pv/org-skip-subtree-if-priority (priority)
	"Skip an agenda subtree if it has a priority of PRIORITY.

PRIORITY may be one of the characters ?A, ?B, or ?C."
	(let ((subtree-end (save-excursion (org-end-of-subtree t)))
     (pri-value (* 1000 (- org-lowest-priority priority)))
     (pri-current (org-get-priority (thing-at-point 'line t))))
   (if (= pri-value pri-current)
     subtree-end
 nil)))
 (defun pv/org-skip-subtree-if-habit ()
	"Skip an agenda entry if it has a STYLE property equal to \"habit\"."
	(let ((subtree-end (save-excursion (org-end-of-subtree t))))
   (if (string= (org-entry-get nil "STYLE") "habit")
     subtree-end
 nil)))
 :hook
 (org-mode . pv/init-org-hook)
 :custom
 (org-hide-leading-stars t "clearer way to display")
 (org-startup-with-inline-images t "always display inline image")
 (org-image-actual-width 600 "set width of image when displaying")
 (org-outline-path-complete-in-steps nil)
 (org-todo-keywords
  (quote ((sequence "TODO(t)" "NEXT(n)" "|" "DONE(d)")
   (sequence "WAITING(w@/!)" "|" "CANCELLED(c@/!)" "MEETING"))))
 (org-todo-keyword-faces
  (quote (("TODO" :foreground "goldenrod1" :weight bold)
   ("NEXT" :foreground "DodgerBlue1" :weight bold)
   ("DONE" :foreground "SpringGreen2" :weight bold)
   ("WAITING" :foreground "LightSalmon1" :weight bold)
   ("CANCELLED" :foreground "LavenderBlush4" :weight bold)
   ("MEETING" :foreground "IndianRed1" :weight bold))))
 (org-todo-state-tags-triggers
  (quote (("CANCELLED" ("CANCELLED" . t))
   ("WAITING" ("WAITING" . t))
   (done ("WAITING"))
   ("TODO" ("WAITING") ("CANCELLED"))
   ("NEXT" ("WAITING") ("CANCELLED"))
   ("DONE" ("WAITING") ("CANCELLED")))))
 (org-adapt-indentation t)
 (org-agenda-files pv/org-agenda-files)
 ;; Do not dim blocked tasks
 (org-agenda-dim-blocked-tasks nil)
 ;; compact the block agenda view
 (org-agenda-compact-blocks t)
 (org-agenda-span 7)
 (org-agenda-start-day "-2d")
 (org-agenda-start-on-weekday nil)
 (org-agenda-tags-column -86) ; default value auto has issues
 ;; Custom agenda command definitions
 (org-agenda-custom-commands
  (quote (("d" "Daily agenda and all TODOs"
 	((tags "PRIORITY=\"A\""
          ((org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
  	(org-agenda-overriding-header "High-priority unfinished tasks:")))
  (agenda "" ((org-agenda-ndays 1)))
  (alltodo ""
    ((org-agenda-skip-function '(or (pv/org-skip-subtree-if-habit)
        (pv/org-skip-subtree-if-priority ?A)
        (org-agenda-skip-if nil '(scheduled deadline))))
            (org-agenda-overriding-header "ALL normal priority tasks:"))))
 	((org-agenda-compact-blocks t)))
   ("p" "Projects"
 	((agenda "" nil)
       (tags "REFILE"
    ((org-agenda-overriding-header "Tasks to Refile")
  	(org-tags-match-list-sublevels nil)))
       (tags-todo "-CANCELLED/!"
   ((org-agenda-overriding-header "Stuck Projects")
             (org-agenda-skip-function 'bh/skip-non-stuck-projects)
             (org-agenda-sorting-strategy
             '(category-keep))))
       (tags-todo "-CANCELLED/!NEXT"
   ((org-agenda-overriding-header (concat "Project Next Tasks"
         (if bh/hide-scheduled-and-waiting-next-tasks
          ""
                                 " (including WAITING and SCHEDULED tasks)")))
             (org-agenda-skip-function 'bh/skip-projects-and-habits-and-single-tasks)
             (org-tags-match-list-sublevels t)
             (org-agenda-todo-ignore-scheduled bh/hide-scheduled-and-waiting-next-tasks)
             (org-agenda-todo-ignore-deadlines bh/hide-scheduled-and-waiting-next-tasks)
             (org-agenda-todo-ignore-with-date bh/hide-scheduled-and-waiting-next-tasks)
             (org-agenda-sorting-strategy
             '(todo-state-down effort-up category-keep))))
       (tags "-REFILE/"
    ((org-agenda-overriding-header "Tasks to Archive")
  	(org-agenda-skip-function 'bh/skip-non-archivable-tasks)
  	(org-tags-match-list-sublevels nil))))
 	nil))))
 :bind
 (("C-c a" . 'org-agenda)
  :map org-mode-map
  ("C-c C-q" . counsel-org-tag)))

(provide 'init-org-agenda)

;;; init-org-agenda.el ends here
