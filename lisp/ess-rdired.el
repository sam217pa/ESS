;;; ess-rdired.el --- prototype object browser for R, looks like dired mode.  -*- lexical-binding: t; -*-

;; Copyright (C) 2002--2019 A.J. Rossini, Richard M. Heiberger, Martin
;;      Maechler, Kurt Hornik, Rodney Sparapani, Stephen Eglen, and J. Alexander Branham.

;; Author: Stephen Eglen <stephen@anc.ed.ac.uk>
;; Created: Thu 24 Oct 2002
;; Maintainer: ESS-core <ESS-core@r-project.org>

;; This file is part of ESS

;; This file is not part of GNU Emacs.

;; ess-rdired.el is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; ess-rdired.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; A copy of the GNU General Public License is available at
;; https://www.r-project.org/Licenses/

;; This provides a dired-like buffer for R objects.  Instead of
;; operating on files, we operate on R objects in the current
;; environment.  Objects can be viewed, edited, deleted, plotted and
;; so on.

;;; Commentary:

;; Do "M-x R" to start an R session, then create a few variables:
;;
;; s <- sin(seq(from=0, to=8*pi, length=100))
;; x <- c(1, 4, 9)
;; y <- rnorm(20)
;; z <- TRUE

;; Then in Emacs, do "M-x ess-rdired" and you should see the following in
;; the buffer *R dired*:
;; Name              Class    Length     Size
;; s                  numeric    100        848 bytes
;; x                  numeric    3          80 bytes
;; y                  numeric    20         208 bytes
;; z                  logical    1          56 bytes

;; Type "?" in the buffer to see the documentation.  e.g. when the
;; cursor is on the line for `s', type 'p' to plot it, or `v' to view
;; its contents in a buffer.  Then type 'd' to delete it.

;; How it works.

;; Most of the hard work is done by the R routine .rdired.objects(),
;; which, when called, produces the list of objects in a tidy format.
;; This function is stored within the Lisp variable `ess-rdired-objects'.

;; Todo - How to select alternative environments?  Currently only
;; shows objects in the .GlobalEnv?  See BrowseEnv() in 1.6.x for way
;; of browsing other environments.

;; Todo - problem with fix -- have to wait for fix() command to return
;; before *R* buffer can be used again.  This can get stuck, umm. not
;; sure what is going wrong here.  Maybe add a hook to the temp buffer
;; so that when buffer is killed, we send an instruction to R to
;; update the value of the variable to the contents of the buffer.
;; This way *R* doesn't have to wait.

;; Todo - small bug in .rdired.objects -- if we have a variable called
;; `my.x', its value is replaced by the value of my.x used in the
;; sapply() calls within .rdired.objects().

;;; Code:

(require 'ess-inf)

(eval-when-compile
  (require 'subr-x))

(defvar ess-rdired-objects "local({.rdired.objects <- function(objs) {
  if (length(objs)==0) {
    \"No objects to view!\"
  } else {
  mode <- sapply(objs, function(my.x) {
    eval( parse( text=sprintf('data.class(get(\"%s\"))', my.x))) })
  length <- sapply(objs, function(my.x) {
    eval( parse( text=sprintf('length(get(\"%s\"))', my.x))) })
  size <- sapply(objs, function(my.x) {
    eval( parse( text=sprintf('format(object.size(get(\"%s\")), units=\"b\")', my.x))) })
  d <- data.frame(mode, length, size)

  var.names <- row.names(d)

  ## If any names contain spaces, we need to quote around them.
  quotes = rep('', length(var.names))
  spaces = grep(' ', var.names)
  if (any(spaces))
    quotes[spaces] <- '\"'
  var.names = paste(quotes, var.names, quotes, sep='')
  row.names(d) <- paste('  ', var.names, sep='')
  d
  }
<<<<<<< HEAD
}; cat('\n'); print(.rdired.objects(ls(all.names=TRUE)))}\n"
=======
}; cat('\n'); print(.rdired.objects(ls(envir = .GlobalEnv)))})\n"
>>>>>>> d31b96e02cb4c5d71effab893da9cd81f30d0470
  "Function to call within R to print information on objects.
The last line of this string should be the instruction to call
the function which prints the output for rdired.")

(defvar ess-rdired-buffer "*R dired*"
  "Name of buffer for displaying R objects.")

(defvar ess-rdired-auto-update-timer nil
  "The timer object for auto updates.")

(defcustom ess-rdired-auto-update-interval 5
  "Seconds between refreshes of the `ess-rdired' buffer."
  :type '(choice (const nil :tag "No auto updates") (integer :tag "Seconds"))
  :group 'ess-R
  :package-version '(ess . "19.04"))

(defvar ess-rdired-mode-map
<<<<<<< HEAD
  (let ((ess-rdired-mode-map (make-sparse-keymap)))
    (if (require 'hide-lines nil t)
        (define-key ess-rdired-mode-map "/" 'hide-lines))
    (define-key ess-rdired-mode-map "?" 'ess-rdired-help)
    (define-key ess-rdired-mode-map "d" 'ess-rdired-delete)
    (define-key ess-rdired-mode-map "u" 'ess-rdired-undelete)
    (define-key ess-rdired-mode-map "x" 'ess-rdired-expunge)
    ;; editing requires a little more work.
    ;;(define-key ess-rdired-mode-map "e" 'ess-rdired-edit)
    (define-key ess-rdired-mode-map "v" 'ess-rdired-view)
    (define-key ess-rdired-mode-map "V" 'ess-rdired-View)
    (define-key ess-rdired-mode-map "p" 'ess-rdired-plot)
    (define-key ess-rdired-mode-map "l" 'ess-rdired-length)
    (define-key ess-rdired-mode-map "s" 'ess-rdired-sort)
    (define-key ess-rdired-mode-map "r" 'ess-rdired-reverse)
    (define-key ess-rdired-mode-map "q" 'ess-rdired-quit)
    (define-key ess-rdired-mode-map "y" 'ess-rdired-type) ;what type?
    (define-key ess-rdired-mode-map " "  'ess-rdired-next-line)
    (define-key ess-rdired-mode-map [backspace] 'ess-rdired-previous-line)
    (define-key ess-rdired-mode-map "\C-n" 'ess-rdired-next-line)
    (define-key ess-rdired-mode-map "\C-p" 'ess-rdired-previous-line)
    ;; (define-key ess-rdired-mode-map "n" 'ess-rdired-next-line)
    ;; (define-key ess-rdired-mode-map "p" 'ess-rdired-previous-line)

    ;; R mode keybindings.
    (define-key ess-rdired-mode-map "\C-c\C-s" 'ess-rdired-switch-process)
    (define-key ess-rdired-mode-map "\C-c\C-y" 'ess-switch-to-ESS)
    (define-key ess-rdired-mode-map "\C-c\C-z" 'ess-switch-to-end-of-ESS)

    (define-key ess-rdired-mode-map [down] 'ess-rdired-next-line)
    (define-key ess-rdired-mode-map [up] 'ess-rdired-previous-line)
    (define-key ess-rdired-mode-map "g" 'revert-buffer)
    (define-key ess-rdired-mode-map [mouse-2] 'ess-rdired-mouse-view)
    ess-rdired-mode-map))

(defun ess-rdired-mode ()
=======
  (let ((map (make-sparse-keymap)))
    (define-key map "d" #'ess-rdired-delete)
    (define-key map "x" #'ess-rdired-delete)
    (define-key map "v" #'ess-rdired-view)
    (define-key map "V" #'ess-rdired-View)
    (define-key map "p" #'ess-rdired-plot)
    (define-key map "y" #'ess-rdired-type)
    (define-key map "\C-c\C-s" #'ess-rdired-switch-process)
    (define-key map "\C-c\C-y" #'ess-switch-to-ESS)
    (define-key map "\C-c\C-z" #'ess-switch-to-end-of-ESS)
    map))

(define-derived-mode ess-rdired-mode tabulated-list-mode "Rdired"
>>>>>>> d31b96e02cb4c5d71effab893da9cd81f30d0470
  "Major mode for output from `ess-rdired'.
`ess-rdired' provides a dired-like mode for R objects.  It shows the
list of current objects in the current environment, one-per-line.  You
can then examine these objects, plot them, and so on."
  :group 'ess-R
  (setq mode-name (concat "RDired " ess-local-process-name))
  (setq tabulated-list-format
        `[("Name" 18 t)
          ("Class" 10 t)
          ("Length" 10 ess-rdired--length-predicate)
          ("Size" 10 ess-rdired--size-predicate)])
  (add-hook 'tabulated-list-revert-hook #'ess-rdired-refresh nil t)
  (when (and (not ess-rdired-auto-update-timer)
             ess-rdired-auto-update-interval)
    (setq ess-rdired-auto-update-timer
          (run-at-time t ess-rdired-auto-update-interval #'ess-rdired-refresh)))
  (add-hook 'kill-buffer-hook #'ess-rdired-cancel-auto-update-timer nil t)
  (tabulated-list-init-header))

;;;###autoload
(defun ess-rdired ()
  "Show R objects from the global environment in a separate buffer.
You may interact with these objects, see `ess-rdired-mode' for
details."
  (interactive)
<<<<<<< HEAD
  (let  ((proc ess-local-process-name)
         (buff (get-buffer-create ess-rdired-buffer)))

    (ess-command ess-rdired-objects buff)
    (ess-setq-vars-local (symbol-value ess-local-customize-alist) buff)

    (with-current-buffer buff
      (setq ess-local-process-name proc)
      (ess-rdired-mode)

      ;; When definiting the function .rdired.objects(), a "+ " is printed
      ;; for every line of the function definition; these are deleted
      ;; here.
      (goto-char (point-min))
      (delete-region (point-min) (1+ (point-at-eol)))

      ;; todo: not sure how to make ess-rdired-sort-num buffer local?
      ;;(set (make-local-variable 'ess-rdired-sort-num) 2)
      ;;(make-variable-buffer-local 'ess-rdired-sort-num)
      (setq ess-rdired-sort-num 1)
      (ess-rdired-insert-set-properties (save-excursion
                                          (goto-char (point-min))
                                          (forward-line 1)
                                          (point))
                                        (point-max))
      (setq buffer-read-only t)
      )

    (pop-to-buffer buff)
    ))


(defun ess-rdired-object ()
  "Return name of object on current line.
Handle special case when object contains spaces."
  (save-excursion
    (beginning-of-line)
    (forward-char 2)

    (cond ((looking-at " ")             ; First line?
           nil)
          ((looking-at "\"")            ; Object name contains spaces?
           (let (beg)
             (setq beg (point))
             (forward-char 1)
             (search-forward "\"")
             (buffer-substring-no-properties beg (point))))
          (t                            ;should be a regular object.
           (let (beg)
             (setq beg (point))
             (search-forward " ") ;assume space follows object name.
             (buffer-substring-no-properties beg (1- (point))))))))
=======
  (unless (and (string= "R" ess-dialect)
               ess-local-process-name)
    (error "Not in an R buffer with attached process"))
  (let ((proc ess-local-process-name))
    (pop-to-buffer (get-buffer-create ess-rdired-buffer))
    (setq ess-local-process-name proc)
    (ess-rdired-mode)
    (ess-rdired-refresh)))

(defun ess-rdired-refresh ()
  "Refresh the `ess-rdired' buffer."
  (let* ((buff (get-buffer-create ess-rdired-buffer))
         (proc-name (buffer-local-value 'ess-local-process-name buff))
         (proc (get-process proc-name))
         (out-buff (get-buffer-create " *ess-rdired-output*"))
         text)
    (when (and proc-name proc
               (not (process-get proc 'busy)))
      (ess-command ess-rdired-objects out-buff nil nil nil proc)
      (with-current-buffer out-buff
        (goto-char (point-min))
        ;; Delete two lines. One filled with +'s from R's prompt
        ;; printing, the other with the header info from the data.frame
        (delete-region (point-min) (1+ (point-at-eol 2)))
        (setq text (split-string (buffer-string) "\n" t "\n"))
        (erase-buffer))
      (with-current-buffer buff
        (setq tabulated-list-entries
              (mapcar #'ess-rdired--tabulated-list-entries text))
        (let ((entry (tabulated-list-get-id))
              (col (current-column)))
          (tabulated-list-print)
          (while (not (equal entry (tabulated-list-get-id)))
            (forward-line))
          (move-to-column col))))))

(defun ess-rdired-cancel-auto-update-timer ()
  "Cancel the timer `ess-rdired-auto-update-timer'."
  (setq ess-rdired-auto-update-timer
        (cancel-timer ess-rdired-auto-update-timer)))

(defun ess-rdired--tabulated-list-entries (text)
  "Return a value suitable for `tabulated-list-entries' from TEXT."
  (let (name class length size)
    (if (not (string-match-p " +\"" text))
        ;; Normal-world
        (setq text (split-string text " " t)
              name (nth 0 text)
              text (cdr text))
      ;; Else, someone has spaces in their variable names
      (string-match "\"\\([^\"]+\\)" text)
      (setq name (substring (match-string 0 text) 1)
            text (split-string (substring text (1+ (match-end 0))) " " t)))
    (setq class (nth 0 text)
          length (nth 1 text)
          size (nth 2 text))
    (list name
          `[(,name
             help-echo "mouse-2, RET: View this object"
             action ess-rdired-view)
            ,class
            ,length
            ,size])))
>>>>>>> d31b96e02cb4c5d71effab893da9cd81f30d0470

(defun ess-rdired-edit ()
  "Edit the object at point."
  (interactive)
  (ess-command (concat "edit(" (tabulated-list-get-id) ")\n")))

(defun ess-rdired-view (&optional _button)
  "View the object at point."
  (interactive)
  (ess-execute (ess-rdired-get (tabulated-list-get-id))
               nil "R view" ))

(defun ess-rdired-get (name)
  "Generate R code to get the value of the variable NAME.
This is complicated because some variables might have spaces in their names.
Otherwise, we could just pass the variable name directly to *R*."
  (concat "get(" (ess-rdired-quote name) ")")
  )

(defun ess-rdired-quote (name)
  "Quote NAME if not already quoted."
  (if (equal (substring name 0 1) "\"")
      name
    (concat "\"" name "\"")))

(defun ess-rdired-View ()
  "View the object at point in its own buffer.
Like `ess-rdired-view', but the object gets its own buffer name."
  (interactive)
  (let ((objname (tabulated-list-get-id)))
    (ess-execute (ess-rdired-get objname)
                 nil (concat "R view " objname ))))

<<<<<<< HEAD
(defmacro ess-rdired-defun (cmd docstring)
  (declare (indent defun) (doc-string 2))
  (let ((gfun (intern (concat "ess-rdired-" cmd))))
    `(progn
       (defun ,gfun ()
         ,docstring
         (interactive)
         (ess-eval-linewise
          (format "%s(%s)" ,cmd (ess-rdired-get (ess-rdired-object))))))))

(ess-rdired-defun "length"
  "Get length of object on current line.")

(ess-rdired-defun "plot"
  "Plot the object on current line.")
=======
(defun ess-rdired-plot ()
  "Plot the object on current line."
  (interactive)
  (let ((objname (tabulated-list-get-id)))
    (ess-eval-linewise (format "plot(%s)" (ess-rdired-get objname)))))
>>>>>>> d31b96e02cb4c5d71effab893da9cd81f30d0470

(defun ess-rdired-type ()
  "Run the mode() on command at point."
  (interactive)
  (let ((objname (tabulated-list-get-id))
        ;; create a temp buffer, and then show output in echo area
        (tmpbuf (get-buffer-create "**ess-rdired-mode**")))
    (if objname
        (progn
          (ess-command (concat "mode(" (ess-rdired-get objname) ")\n")
                       tmpbuf )
          (set-buffer tmpbuf)
          (message "%s" (concat
                         objname ": "
                         (buffer-substring (+ 4 (point-min)) (1- (point-max)))))
          (kill-buffer tmpbuf)))))

(defalias 'ess-rdired-expunge #'ess-rdired-delete)

<<<<<<< HEAD
(defun ess-rdired-sort ()
  "Sort the rdired output according to one of the columns.
Rotate between the alternative sorting methods."
  (interactive)
  (setq ess-rdired-sort-num (1+ ess-rdired-sort-num))
  (let ((buffer-read-only nil)
        (beg (save-excursion
               (goto-char (point-min))
               (forward-line 1)
               (point)))
        (end (point-max)))
    (if (> ess-rdired-sort-num 4)
        (setq ess-rdired-sort-num 1))
    (cond ((eq ess-rdired-sort-num 1)
           (sort-fields 1 beg end))
          ((eq ess-rdired-sort-num 2)
           (sort-fields 2 beg end))
          ((eq ess-rdired-sort-num 3)
           (sort-numeric-fields 3 beg end))
          ((eq ess-rdired-sort-num 4)
           (sort-numeric-fields 4 beg end)))))

(defun ess-rdired-reverse ()
  "Reverse the current sort order."
  (interactive)
  (let ((buffer-read-only nil)
        (beg (save-excursion
               (goto-char (point-min))
               (forward-line 1)
               (point)))
        (end (point-max)))
    (reverse-region beg end)))

(defun ess-rdired-next-line (arg)
  "Move down lines then position at object.
Optional prefix ARG says how many lines to move; default is one line."
  (interactive "p")
  (forward-line arg)
  (ess-rdired-move-to-object))

(defun ess-rdired-previous-line (arg)
  "Move up lines then position at object.
Optional prefix ARG says how many lines to move; default is one line."
  (interactive "p")
  (forward-line (- (or arg 1))) ; -1 if arg was nil
  (ess-rdired-move-to-object))

(defun ess-rdired-move-to-object ()
  "Put point at start of object."
  (beginning-of-line)
  (forward-char 2)
  )

(defun ess-rdired-mouse-view (event)
  "In rdired, visit the object on the line you click on."
  (interactive "e")
  (let (window pos)
    (save-excursion
      (setq window (posn-window (event-end event))
            pos (posn-point (event-end event)))
      (if (not (windowp window))
          (error "No file chosen"))
      (set-buffer (window-buffer window))
      (goto-char pos)
      (ess-rdired-view))))

(defun ess-rdired-insert-set-properties (beg end)
  "Add mouse highlighting to each object name in the R dired buffer."
  (save-excursion
    (goto-char beg)
    (while (< (point) end)
      (ess-rdired-move-to-object)
      (add-text-properties
       (point)
       (save-excursion
         (search-forward " ")
         (1- (point)))
       '(mouse-face highlight
                    help-echo "mouse-2: view object in other window"))
      (forward-line 1))))
=======
(defun ess-rdired-delete ()
  "Delete the object at point."
  (interactive)
  (let ((objname (tabulated-list-get-id)))
    (when (yes-or-no-p (format "Really delete %s? " objname))
      (ess-eval-linewise (format "rm(%s)" (ess-rdired-quote objname)) nil nil nil t)
      (revert-buffer))))
>>>>>>> d31b96e02cb4c5d71effab893da9cd81f30d0470

(defun ess-rdired-switch-process ()
  "Switch to examine different *R* process.
If you have multiple R processes running, e.g. *R*, *R:2*, *R:3*, you can
use this command to choose which R process you would like to examine.
After switching to a new process, the buffer is updated."
  (interactive)
  (ess-switch-process)
  (ess-rdired))

(defun ess-rdired--length-predicate (A B)
  "Enable sorting by length in `ess-rdired' buffers.
Return t if A's length is < than B's length."
  (let ((lenA (aref (cadr A) 2))
        (lenB (aref (cadr B) 2)))
    (< (string-to-number lenA) (string-to-number lenB))))

(defun ess-rdired--size-predicate (A B)
  "Enable sorting by size in `ess-rdired' buffers.
Return t if A's size is < than B's size."
  (let ((lenA (aref (cadr A) 3))
        (lenB (aref (cadr B) 3)))
    (< (string-to-number lenA) (string-to-number lenB))))

(define-obsolete-function-alias 'ess-rdired-quit #'quit-window "ESS 19.04")
(define-obsolete-function-alias 'ess-rdired-next-line #'forward-to-indentation "ESS 19.04")
(define-obsolete-function-alias 'ess-rdired-previous-line #'backward-to-indentation "ESS 19.04")
(define-obsolete-function-alias 'ess-rdired-move-to-object #'back-to-indentation "ESS 19.04")

(provide 'ess-rdired)

;;; ess-rdired.el ends here
