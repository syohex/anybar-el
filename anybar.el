;;; anybar.el -- Control AnyBar from Emacs

;; Copyright (c) 2016  Christopher Shea

;; Author: Christopher Shea <cmshea@gmail.com>
;; Version: 0.1.0
;; Keywords: anybar

;; This Source Code Form is subject to the terms of the Mozilla Public
;; License, v. 2.0. If a copy of the MPL was not distributed with this
;; file, You can obtain one at https://mozilla.org/MPL/2.0/.

;;; Commentary:

;; AnyBar is an application that puts an indicator in the menubar in
;; OS X. This package lets you interact with that indicator from
;; Emacs. See: https://github.com/tonsky/AnyBar

;; Basic usage:
;;
;;   (require 'anybar)
;;
;; Start AnyBar:
;;
;;   (anybar-start)
;;
;; Set indicator to a color:
;;
;;   (anybar-set "red")
;;
;; Quit AnyBar:
;;
;;   (anybar-quit)
;;
;; Those functions also take an optional argument to specify a port
;; number, if you want to run multiple instances or use a different
;; port than AnyBar's default, 1738.
;;
;; `anybar-set' will complain if you try to set the indicator to an
;; invalid style, which is anything outside of the default styles (see
;; `anybar-styles') or any custom images set in "~/.AnyBar". To
;; refresh the list of images anybar.el knows about, call
;; `anybar-images-reset'.
;;
;; These functions may be called interactively.
;;
;; Enjoy!

;;; Code:

(defconst anybar-default-port
  1738
  "The default port AnyBar runs on.")

(defconst anybar-styles
  (list "white"
        "red"
        "orange"
        "yellow"
        "green"
        "cyan"
        "blue"
        "purple"
        "black"
        "question"
        "exclamation")
  "The built-in styles for AnyBar.")

(defun anybar-images-reset ()
  "Sets anybar-images to a list of images available for AnyBar."
  (interactive)
  (defconst anybar-images
    (mapcar
     (lambda (filename)
       (save-match-data
         (and (string-match "\\(.*?\\)\\(@2x\\)?.png$" filename)
              (match-string 1 filename))))
     (directory-files "~/.AnyBar" nil "\.png$"))
    "Images available to set as the AnyBar style."))

(anybar-images-reset)

(defun anybar--read-style ()
  (completing-read "Style: "
                   (append anybar-styles anybar-images)))

(defun anybar--read-port ()
  (read-number "Port: " anybar-default-port))

(defun anybar-send (command &optional port)
  "Sends the command to the AnyBar instance running on port."
  (interactive (list (read-string "Command: ")
                     (anybar--read-port)))
  (let* ((port (or port anybar-default-port))
         (conn (make-network-process
                :name "anybar"
                :type 'datagram
                :host 'local
                :service port)))
    (process-send-string conn command)
    (delete-process conn)))

(defun anybar-set (style &optional port)
  "Sets the AnyBar running on the specified port to style. Will
warn if the style is not valid."
  (interactive (list (anybar--read-style)
                     (anybar--read-port)))
  (let ((port (or port anybar-default-port))
        (available-styles (append anybar-styles anybar-images)))
    (if (member style available-styles)
        (anybar-send style port)
      (display-warning "AnyBar" (format "Not a style: %s" style)))))

(defun anybar-quit (&optional port)
  "Quit the AnyBar instance running on the specified port."
  (interactive (list (anybar--read-port)))
  (let ((port (or port anybar-default-port)))
    (anybar-send "quit" port)))

(defun anybar-start (&optional port)
  "Start an instance of AnyBar on the specified port."
  (interactive (list (anybar--read-port)))
  (let* ((port (or port anybar-default-port))
         (command (format "ANYBAR_PORT=%d open -n ~/Applications/AnyBar.app"
                          port)))
    (shell-command command)))

(provide 'anybar)
;;; anybar.el ends here
