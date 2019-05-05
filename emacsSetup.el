;; (setq sql-postgres-login-params
;;       '((user :default "postgres")
;; 	(database :default "postgres")
;; 	(server :default "localhost")
;; 	(port :default 5433)
;; 	(password :default "mysecretpassword")))


;; Store postgresTutorial password in pass.
;; Use 'M-x sql-connect postgresTutorial' to connect.
;; See https://stackoverflow.com/a/51850601/268040
(require 'subr-x)
(setq sql-postgres-login-params '())
(defun my-pass (key)
  (string-trim-right (shell-command-to-string (concat "pass " key))))

(setq sql-connection-alist
      '((postgrestTutorial (sql-product 'postgres)
	    (sql-database (concat "postgresql://postgres:"
				  (my-pass "postgrestTutorial")
				  "@localhost/postgres")))))
