INSTALL
=======
Installation process is currently manual. (I hope to add this to MELPA soon)

    git clone https://github.com/teju85/cmdlogger-el
    ;; add this in your .emacs file
    (add-to-list 'load-path /path/to/cmdlogger-el)

USAGE
=====
Include the following lines in your `.emacs` file:

    (require 'cmdlogger)
    (cmdlogger-mode t)

To disable this mode temporarily in your session:

    (cmdlogger-mode nil)
    ;; do you secret-stuff here!
    (cmdlogger-mode t)

Use `customize` to figure out variables that can be customized.
