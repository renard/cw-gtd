;;; cw-gtd.el --- 

;; Copyright © 2010 Sebastien Gross <seb•ɑƬ•chezwam•ɖɵʈ•org>

;; Author: Sebastien Gross <seb•ɑƬ•chezwam•ɖɵʈ•org>
;; Keywords: 
;; Created: 2011-07-18
;; Last changed: 2011-09-12 10:18:02
;; Licence: WTFPL, grab your copy here: http://sam.zoy.org/wtfpl/

;; This file is NOT part of GNU Emacs.

;;; Commentary:
;; 


;;; Code:

(eval-when-compile (require 'org))
(eval-when-compile (require 'org-capture))
(eval-when-compile (require 'org-clock))
(eval-when-compile (require 'org-datetree))
(eval-when-compile (require 'org-faces))
(eval-when-compile (require 'org-contacts))

(defvar cw:gtd:agendas-dir 
  (concat (file-name-as-directory user-emacs-directory) "gtd")
  "Directory where agendas are stored. See also
  `cw:gtd:agendas'.")

(defvar cw:gtd:bookmark-file 
  (concat (file-name-as-directory cw:gtd:agendas-dir)
	  "bookmark.org")
  "File to store bookmarks")

(defvar cw:gtd:agendas
  '("todo" "done")
  "List of agendas to search within `cw:gtd:agendas-dir'. '.org'
  extension is automaicaly added.")

(defvar cw:gtd:require-contacts t
  "Require `org-contacts' at init time.")

;; http://web.archiveorange.com/archive/v/Fv8aA6rn4VybD0r1cBen

;;;###autoload
(defun cw:gtd:init()
  "Initialize `cw-gtd'."

  (eval-after-load "org"
    '(progn
       (when cw:gtd:require-contacts (require 'org-contacts))
       (setq

	;; Define agenda files according `cw:gtd:agendas'
	org-agenda-files
	(loop for path in `(
			    ,@(loop for a in cw:gtd:agendas
				    collect (concat
					     (file-name-as-directory
					      cw:gtd:agendas-dir)
					     a ".org"))
			    ,@(when (boundp 'org-contacts-files)
				org-contacts-files)
			    ,cw:gtd:bookmark-file)
	      when (file-exists-p (expand-file-name path))
	      collect path)

	org-use-fast-todo-selection t
	org-fast-tag-selection-single-key nil
	;; Use IDO for target completion
	org-completion-use-ido t

	;; Targets include this file and any file contributing to the agenda
	;; up to 5 levels deep
	org-refile-targets
	'((org-agenda-files :maxlevel . 5)
	  (nil :maxlevel . 5))
	

	org-return-follows-link t

	;; Do not open new frames when following link
	org-link-frame-setup
	'((gnus . org-gnus-no-new-news)
	  (file . find-file))
	
	)))

  (eval-after-load "org-agenda"
    `(progn
       
       (setq
	org-agenda-clock-consistency-checks
	'(:max-duration "4:00"
			:min-duration 0
			:max-gap 0
			:gap-ok-around ("4:00")
			:default-face ((:background "DarkRed")
				       (:foreground "white"))
			:overlap-face (:background "Red")
			:gap-face  (:background "Blue")
			:no-end-time-face nil
			:long-face nil
			:short-face nil)


	;; Agenda clock report parameters
	org-agenda-clockreport-parameter-plist
	'(:link t
		:step week
		:stepskip0 t
		:emphasize nil
		:maxlevel 5
		:fileskip0 t
		:narrow 100!
		:indent 2
		:tcolumns 1
		:formula %))
	
       ))

  (eval-after-load "org-capture"
    '(progn

       (setq

	org-capture-templates
	;; Task
	'(("t" "Task" entry
	   (file+datetree (format "%s/todo.org" cw:gtd:agendas-dir))
	   "*** STARTED %? %^g\n"
	   :clock-in t :clock-keep t)
	  ;; Todo
	  ("T" "todo" entry
	   (file+headline (format "%s/todo.org" cw:gtd:agendas-dir) "Incoming")
	   "** TODO %? %^g
   SCHEDULED: %(cw:gtd:get-date 2)
"
	   :clock-in t :clock-resume t)
	  ;; bookmarks
	  ("B" "Bookmark" entry
	   (file+headline cw:gtd:bookmark-file "Unsorted")
	   "** %x"
	   :immediate-finish t)))

       ))

  (eval-after-load "org-clock"
    '(progn
       ;; Remove empty LOGBOOK drawers on clock out
       (defun cw:org:remove-empty-drawer-on-clock-out ()
	 (interactive)
	 (save-excursion
	   (beginning-of-line 0)
	   (org-remove-empty-drawer-at "LOGBOOK" (point))))
       (add-hook 'org-clock-out-hook 
		 'cw:org:remove-empty-drawer-on-clock-out
		 'append)

       ;; Resume clocking tasks when emacs is restarted
       (org-clock-persistence-insinuate)
       (setq 
	org-clock-history-length 10
	;; Resume clocking task on clock-in if the clock is open
	org-clock-in-resume t
	;; Do not change task states when clocking in
        org-clock-in-switch-to-state nil
	;; Save clock data and state changes and notes in the LOGBOOK drawer
	org-clock-into-drawer t
	;; removes clocked tasks with 0:00 duration
	org-clock-out-remove-zero-time-clocks t
	;; Clock out when moving task to a done state
	org-clock-out-when-done t
	;; Save the running clock and all clock history when exiting Emacs,
	;; load it on startup
	org-clock-persist 'history
	;; Enable auto clock resolution for finding open clocks
	org-clock-auto-clock-resolution 'when-no-clock-is-running
	;; Include current clocking task in clock reports
	org-clock-report-include-clocking-task t)))

  (eval-after-load "org-faces"
    `(progn
       (setq org-todo-keyword-faces
	     '(("TODO" :foreground "red" :weight bold)
	       ("STARTED" :foreground "blue" :weight bold)
	       ("DONE" :foreground "forest green" :weight bold)
	       ("WAITING" :foreground "orange" :weight bold)
	       ("SOMEDAY" :foreground "magenta" :weight bold)
	       ("CANCELLED" :foreground "forest green" :weight bold)))))

  (global-set-key (kbd "<C-f12>") 'org-capture)
  (global-set-key (kbd "<C-S-f12>") 'org-clock-goto)
  (global-set-key (kbd "<f12>") 'org-agenda-list)
  (global-set-key (kbd "C-c a") 'org-agenda)
  (global-set-key (kbd "<C-f5>") 'cw:gtd:open-bookmark))


(defun cw:gtd:open-bookmark()
  "Open bookmark file."
  (interactive)
  (find-file cw:gtd:bookmark-file))


(defun cw:gtd:get-date(&optional days)
  "Retrieve a date with an optional delta of DAYS days."
  (let ((days (or days 0))
	(dt-list (decode-time)))
    (+ days (nth 3 dt-list))
    (setcar (nthcdr 3 dt-list) (+ days (nth 3 dt-list)))
    (format-time-string "<%Y-%m-%d %a>" (apply 'encode-time dt-list))))


;;;###autoload
(defun cw:gtd:refile-task()
  "Refile task to appropriate file given a target agenda.
A target file is a \"@\" followed by the file name in the
`cw:gtd:agendas-dir'."
  (interactive)
  (let* ((date-str
	  (org-entry-get (point) "CLOCK"))
	 (dct (parse-time-string date-str))
	 (y (nth 5 dct))
	 (m (nth 4 dct))
	 (d (nth 3 dct))
	 (rf-alist (mapcar
		    (lambda(x) 
		      `(,(file-name-nondirectory 
			  (file-name-sans-extension x)) . ,x))
		    org-agenda-files))
	  file)
    (org-back-to-heading t)

    (setq file (loop for files in 
		     (loop for tag in (org-get-tags)
			   when (string= "@" (substring tag 0 1))
			   collect (substring tag 1))
		     when (assoc files rf-alist)
		     return (cdr (assoc files rf-alist))))

    (unless file (error "No refile target found"))

    (org-cut-subtree)
    (with-current-buffer (find-file-noselect file)
      (org-datetree-file-entry-under (current-kill 0) `(,m ,d ,y))
      (save-buffer))
    (save-buffer)))

(provide 'cw-gtd)
