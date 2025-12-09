(in-package :jweb)

(deftag toast-widget (_ attrs &key (title "Error") (message "There was an error"))
  (let ((toast-id (symbol-name (gensym "TOAST"))))
    `(:div :class (bs position-fixed bottom-0 end-0 p-3)
	   :style "z-index: 11"
	   (:div :class (bs toast hide)
		 :id ,toast-id
		 :role "alert"
		 :aria-live "assertive"
		 :aria-atomic "true"
		 (:div :class (bs toast-header)
		       ,title
		       (:button :type "button"
				:class (bs btn-close)
				:data-bs-dismiss "toast"))
		 (:div :class (bs toast-body) ,message))
	   (insert-script (let* ((toast-id (lisp (make-id-string ,toast-id)))
				 (toast (new (chain bootstrap (-toast (aref ($ toast-id) 0))))))
			    (chain htmx (on "htmx:responseError" (lambda () (chain toast (show))))))))))
