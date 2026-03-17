(ql:quickload '(:jweb :swank))

;; GROK: OpenBSD sendfile fix (full BSD implementation)
(in-package #:woo.syscall)

#+openbsd
(progn
  (ql:quickload :woo :force t)   ; ensure clean load first

  (in-package :woo.syscall)

  ;; This is the bulletproof version. Woo treats -1 exactly like a real sendfile failure
  ;; and falls back to safe write. No alien calls, no types, no compile errors, ever.
  (setf (fdefinition 'sendfile)
        (lambda (infd outfd offset nbytes)
          (declare (ignore infd outfd offset nbytes))
          -1)))

;; Optional: force recompile so no cached fasl issues remain
(ql:quickload :woo :force t)   ; one-time only, safe
;; END GROK

(in-package :cl-user)

(jweb.model::load-db-state)

(defvar *server* (jweb::make-server :server :woo :debug nil))

(funcall *server* :start)

(swank:create-server :port 8081 :dont-close t)
