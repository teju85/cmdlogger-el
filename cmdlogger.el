;;; cmdlogger.el --- log all commands typed into emacs
;; -*- coding: utf-8 -*-
;;
;; Copyright 2018 by Thejaswi Rao
;;
;; Author: Thejaswi Rao
;; Maintainer: Thejaswi Rao
;; Created: 2018
;;
;;
;; cmdlogger is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3 of the License, or
;; (at your option) any later version.
;;
;; Version 0.1 - 2018-01 - Thejaswi Rao
;; * First version
;;

;;; Commentary:
;;
;; cmdlogger is just a facility to log every command/keystroke you type
;; while inside emacs session(s). They all will be stored, by default inside
;; ~/.emacs.d/cmdlogger/keys.txt in a human readable format.
;;
;; How to use?
;; Include the following lines in your .emacs file:
;;   (require 'cmdlogger)
;;   (cmdlogger-mode t)
;;
;; Special note:
;; In case you are entering password!
;;   (cmdlogger-mode nil)        ;; disable logging mode
;;   <enter your password here>
;;   (cmdlogger-mode t)          ;; enable it back
;;
;; Why no analysis code?
;; This tries to keep the Unix philosophy of doing one thing well.
;;
;;; Code:


(defgroup cmdlogger nil
  "Group for the minor-mode cmdlogger-mode."
  :package-version '(cmdlogger . "0.1")
  :group           'local
  :prefix          "cmdlogger")

(defcustom cmdlogger/root-dir
  (expand-file-name "cmdlogger" user-emacs-directory)
  "Dir where to store the cmdlogger files"
  :group 'cmdlogger
  :type  'string)

(defcustom cmdlogger/main-file "keys.txt"
  "Main file to store all commands/keystrokes across all emacs sessions"
  :group 'cmdlogger
  :type  'string)

(defcustom cmdlogger/temp-file-prefix "tmp-keys-"
  "Prefix for the per-emacs-session temp files"
  :group 'cmdlogger
  :type  'string)

(defcustom cmdlogger/save-threshold 100
  "Number of commands before flushing them into temp-file of this session"
  :group 'cmdlogger
  :type  'integer)


(defvar cmdlogger/--temp-file nil
  "[internal] abs path for temp file of this session")
(defvar cmdlogger/--main-file nil "[internal] abs path to the main-file")
(defvar cmdlogger/--strokes '() "[internal] list of strokes logged so far")
(defvar cmdlogger/--num-strokes 0 "[internal] num strokes logged so far")

(defun cmdlogger/--concat-files(src dst)
  "[internal] Concat the contents of src file into dst file"
  (with-temp-buffer
    (find-file dst)
    (goto-char (point-max))
    (insert-file-contents src)
    (save-buffer)
    (kill-buffer)))

(defun cmdlogger/--save-strokes(strokes temp-file)
  "[internal] Save the strokes logged so far into the per-session temp-file"
  (let ((rstrokes (reverse strokes))
        (cmd))
    (while rstrokes
      (append-to-file (car rstrokes) nil temp-file)
      (setq rstrokes (cdr rstrokes)))))

(defun cmdlogger/--save-hook()
  "[internal] Save the session-wide temp-file into main-file before emacs exit"
  (if (> cmdlogger/--num-strokes 0)
      (cmdlogger/--save-strokes cmdlogger/--strokes cmdlogger/--temp-file))
  (if (file-exists-p cmdlogger/--temp-file)
      (progn
        (cmdlogger/--concat-files cmdlogger/--temp-file cmdlogger/--main-file)
        (delete-file cmdlogger/--temp-file))))

(defun cmdlogger/--log-hook()
  "[internal] Main hook to log each command/keystroke"
  (let ((command)
        (cmdstr (format "%s" this-command)))
    (if (string= "self-insert-command" cmdstr)
        (setq cmdstr "."))
    (setq command (format "%s %s\n"
                          cmdstr
                          (key-description (this-command-keys))))
    (setq cmdlogger/--strokes (push command cmdlogger/--strokes))
    (setq cmdlogger/--num-strokes (1+ cmdlogger/--num-strokes)))
  (if (>= cmdlogger/--num-strokes cmdlogger/save-threshold)
      (progn
        (cmdlogger/--save-strokes cmdlogger/--strokes cmdlogger/--temp-file)
        (setq cmdlogger/--strokes '())
        (setq cmdlogger/--num-strokes 0))))

(defun cmdlogger/--start()
  "[internal] Starts the key-logging process."
  (interactive)
  (if (not (file-directory-p cmdlogger/root-dir))
        (make-directory cmdlogger/root-dir))
  ;; trying to be re-entrant
  ;; especially, in a given session, if the user enables/disables this mode
  ;; multiple times
  (setq cmdlogger/--main-file (expand-file-name cmdlogger/main-file
                                                cmdlogger/root-dir))
  (if (null cmdlogger/--temp-file)
      (setq cmdlogger/--temp-file (expand-file-name
                                   (make-temp-name cmdlogger/temp-file-prefix)
                                   cmdlogger/root-dir)))
  (add-hook 'pre-command-hook 'cmdlogger/--log-hook)
  (add-hook 'kill-emacs-hook 'cmdlogger/--save-hook))

(defun cmdlogger/--stop()
  "[internal] Stops the key-logging process. Note that we still need to continue
to keep the kill-emacs-hook, as there might be some extra commands which have
been executed before disabling this minor mode!"
  (remove-hook 'pre-command-hook 'cmdlogger/log-hook))


(define-minor-mode cmdlogger-mode
  "Cmdlogger minor mode.
This records *every* command/keystroke made by the user in the current emacs
session and it will be stored in a text file for future processing. It will
create a per-emacs-session temporary file and logs all commands there. It adds a
kill-emacs-hook which finally concats this per-session info into the
cmdlogger/main-file. This is needed as a user might be running multiple sessions
concurrently!"
  :group      'cmdlogger
  :global     t
  :init-value nil
  :lighter    nil
  :keymap     nil
  (if cmdlogger-mode
      (cmdlogger/--start)
    (cmdlogger/--stop)))

(provide 'cmdlogger)
