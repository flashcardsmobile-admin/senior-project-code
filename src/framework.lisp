(in-package :jweb.framework)

;; Adds λ
(named-readtables:in-readtable :fn.reader)

;; For the start/stop functions
(defvar app (make-instance 'ningle:app))

;; Build changes
(defun rl ()
  (ql:quickload :jweb))

(defmacro req-headers ()
  `(lack.request:request-headers ningle:*request*))

(defmacro res-headers ()
  `(lack.response:response-headers ningle:*response*))

(defmacro res-status ()
  `(lack.response:response-status ningle:*response*))

;; (declaim (inline htmx-request-p))
;; (defun htmx-request-p ()
;;   (gethash "HX-Request" (req-headers)))

(defun rdr-to (url &key (code 303))
  (setf (res-headers)
	      (append (res-headers)
		            (list :location url)))
  (setf (res-status) code)
  "")

(defmacro cur-user ()
  `(gethash "user" ningle:*session*))

(defun auth-or-bail (fun &optional bail)
  λ(cond
     ((cur-user) (apply fun _@))
     (bail (apply bail _@))
     (t (rdr-to "/" :code 401))))

(defun apply-middleware (function current-middleware)
  (typecase current-middleware
    (null function)
    (list (apply-middleware (funcall (car current-middleware) function)
                            (cdr current-middleware)))
    (t (funcall current-middleware function))))

;; Get a route with these args
(defmacro get-route (&body args)
  `(ningle:route app ,@args))

;; Define a route. Anaphoricaly binds params.
(defmacro defroute (args middleware &body body)
  (let ((handler-name (gensym)))
    `(setf (get-route ,@args)
	         (labels ((self (params)
		                  (declare (ignorable params))
		                  ,@body))
	           ,(if middleware
		              `(apply-middleware #'self (list ,@middleware))
		              `#'self)))))

;; Define a route that uses finite-state logic.
(defmacro defroute-fsm ((&rest args) (&key binds) &body body)
  `(setf (ningle:route app ,@args)
	       (salet (,@binds) (alet-fsm ,@body))))

(declaim (inline normalize-url))
(defun* (normalize-url -> string) ((url string))
  (if (str:ends-with-p "/" url) url (str:concat url "/")))

(defun* (get-obj-slots -> list) (obj)
  (mapcar λ(slot-value _ 'sb-pcl::name)
	        (let ((class (class-of obj)))
	          (c2mop:ensure-finalized class)
	          (c2mop:class-slots class))))

;; (defun* (render-list -> string) ((data list)
;; 				 &optional ) ;; TODO --- work from here.

;; (defun* (controller -> (function (association-list) string))
;;     ((method (member :get-all :get-one :post :put :patch :delete))
;;      (handler (or (function (integer) list)
;; 		  (function () list))))
;;   (case method
;;     (:get-all (lambda (params)

;; (defun* (defresource -> function) ((url string)
;; 				   &key ((get-all function))
;; 				   ((get-one (or null function)))
;; 				   ((post (or null function)))
;; 				   ((put (or null function)))
;; 				   ((patch (or null function)))
;; 				   ((delete (or null function)))
;; 				   ((item-tag string) ":id"))
;;   (let* ((url (normalize-url url))
;; 	 (item-url (str:concat url item-tag)))
;;     (when get-all (defroute (url) get-all))
;;     (when get-one (defroute (item-url) get-one))
;;     (when post (defroute (url :method :POST) post))
;;     (when put (defroute (item-url :method :PUT) put))
;;     (when patch (defroute (item-url :method :PATCH) patch))
;;     (when delete (defroute (item-url :method :DELETE) delete))
;;     (dlambda
;;      (:get (&optional id)
;; 	   (if id (get-one id) (get-all)))
;;      (:post (&rest args)
;; 	    (apply post args))
;;      (:put (&rest args)
;; 	   (apply put args))
;;      (:patch (&rest args)
;; 	     (apply patch args))
;;      (:delete (id)
;; 	      (delete id)))))

;; Create a combined bootstrap string from symbols.
;; This actually works for HTML classes in general,
;; but the name is everywhere in my code, so it's staying.
(defmacro+ps bs (&body params)
  (str:join #\Space (mapcar λ(str:downcase (symbol-name _)) params)))

;; Get an item from request data.
(defun* get-req-item ((name (or string symbol)) (params association-list))
  (if (symbolp name)
      (cdr (assoc name params :test #'eq))
      (cdr (assoc name params :test #'string=))))

;; To make old code work.
(defmacro get-post-item (&rest rest)
  `(get-req-item ,@rest))

(defparameter continuations (make-hash-table :test #'equal :synchronized t))

(defmacro not-found (&key message)
  `(block nil
	   (declare (ignore _))
	   (setf res-status 404)
	   ,(or message "")))

(dolist (method '(:GET :POST :PUT :DELETE :OPTIONS))
  (defroute ("/cont/:continuation" :method method) ()
    (funcall (the function (gethash (get-req-item :continuation params)
				                            continuations
				                            (lambda (_)
				                              (declare (ignore _))
				                              (setf res-status 404)
				                              "")))
	           params)))

;; Bind a gensym'ed route to a handler function.
(defun* (make-temp-route -> string) ((handler function))
  (declare (speed 3) (safety 0))
  (let ((route-key (fuuid:to-string (fuuid:make-v4))))
    (setf (gethash route-key continuations)
	        (lambda (params)
	          (let ((res (funcall handler params)))
	            (setf (gethash route-key continuations) nil)
	            res)))
    (str:concat "/cont/" route-key)))

(defmacro session-item (name &optional default)
  `(gethash ,name *session* ,default))

;; Link to the session so that we don't have unauthorized access.
;; (if (gethash key-name *session*)
;;        ;; Do stuff
;; 	  (defroute (route-name) nil)))
;; route-name

(defpsmacro copy-obj (a b)
  `(chain -object
	        (keys ,a)
	        (for-each
	         (lambda (k)
	           (setf (getprop ,b k) (getprop ,a k))))))

;;; Signals for Parenscript
;; (defparameter signals
;;   (ps (defun make-signal (value)
;; 	      (let ((event-id (chain crypto (random-u-u-i-d))))
;; 	        (ps:create
;;            :get (lambda () value)
;;            :set (lambda (v)
;; 		              (setf value v)
;; 		              ($ document (trigger event-id)))
;; 	         :sub (lambda (f)
;; 		              ($ document (on event-id f [value]))))))))

;;; Custom attrs
(defmacro custom-attrs (&body additional-attrs)
  (ps (let ((custom-attrs (lisp
			                     `(ps:create
			                       ,@(let ((retlist))
				                         (dolist (attr additional-attrs retlist)
				                           (setf retlist (cons `(lambda (this) ,@(cdr attr)) retlist))
				                           (setf retlist (cons (format nil "[~a]" (car attr)) retlist))))))))
	      ($ document (ready (lambda ()
			                       (dolist (key (chain object (keys custom-attrs)))
			                         (let ((act-on-attr (lambda (elt)
                                                    ($ elt (parent) (find key) (each (getprop custom-attrs key))))))
				                         (act-on-attr document)
				                         (chain htmx (on-load act-on-attr))))))))))

;;; Panes
(defparameter pane-style (css-lite:css
			                    (("html" "body")
			                     ((:margin 0)
			                      (:padding 0)
			                      (:height "100%")))
			                    ((".pane")
			                     ((:border-style "solid")
			                      (:height "100%")
			                      (:width "100%")
			                      (:box-sizing "border-box")))))

(deftag pane (content attrs &key)
  `(:div :class (bs pane)
	       ,@content))

(deftag panes (content attrs &key)
  `(:div :class (bs panes container)
	       ,@content))

;; Handling windows.
;; (deftag window (content attrs &rest data-vars)
;;   (let ((window-id (symbol-name (gensym "ID"))))
;;     `(:div :hx-disable t
;;       (:div :class (bs window)
;; 	    :style "display: none;"
;; 	    :id ,window-id
;; 	    ,@(funcall (alambda (vars)
;; 			 (when (car vars)
;; 			   (cons (intern (str:upcase (str:concat "data-" (symbol-name (car vars)))) "KEYWORD")
;; 				 (cons (cadr vars) (self (cddr vars))))))
;; 		       data-vars)
;; 	    (:div :class (bs content)
;; 		  ,@content))
;;       (:script (:raw (ps ($ document (on (lisp ,(getf data-vars :event))
;; 					 (lambda () (launch-window ($ ,(lisp (str:concat "#" window-id)))))))))))))

;; (defparameter window-init
;;   (ps
;;     (var char-width)
;;     (defun get-width ()
;;       (if char-width
;; 	  char-width
;; 	  (setf char-width (let* ((tmp-el ($ "<div>"
;; 					     (css (create
;; 						   width "1ch"
;; 						   position "absolute"
;; 						   visibility "hidden"))
;; 					     (append-to "body")))
;; 				  (width (chain tmp-el (width))))
;; 			     (chain tmp-el (remove))
;; 			     width))))
;;     ($ document (ready get-width))
;;     (defun launch-window (el &optional (event-prefix (chain crypto (random-u-u-i-d))))
;;       (let* ((merge-objects (lambda (a b)
;; 			      (let ((res (create)))
;; 				(copy-obj a res)
;; 				(copy-obj b res)
;; 				res)))
;; 	     (content ($ el (children ".content") (first) (clone)))
;; 	     (evt-resize (+ event-prefix "-resize"))
;; 	     (evt-create (+ event-prefix "-create"))
;; 	     (evt-full (+ event-prefix "-fullscreen"))
;; 	     (evt-max (+ event-prefix "-maximize"))
;; 	     (evt-res (+ event-prefix "-restore"))
;; 	     (evt-close (+ event-prefix "-close"))
;; 	     (update-column-count (lambda ()
;; 				    (chain content
;; 					   (css "columnCount"
;; 						(chain -math (ceil
;; 							      (/ (chain content (width))
;; 								 (* 70 (get-width))))))))))
;; 	($ content (on (+ evt-resize " "
;; 			  evt-create " "
;; 			  evt-full " "
;; 			  evt-max " "
;; 			  evt-res " ")
;; 		       update-column-count))
;; 	(new (-win-box (merge-objects (create
;; 				       mount (aref (chain content) 0)
;; 				       onresize (lambda ()
;; 						  ($ content (trigger evt-resize))
;; 						  (values))
;; 				       oncreate (lambda ()
;; 						  ($ content (trigger evt-create))
;; 						  (values))
;; 				       onclose (lambda ()
;; 						 ($ content (trigger evt-close))
;; 						 (values))
;; 				       onfullscreen (lambda ()
;; 						      ($ content (trigger evt-full))
;; 						      (values))
;; 				       onmaximize (lambda ()
;; 						    ($ content (trigger evt-max))
;; 						    (values))
;; 				       onrestore (lambda ()
;; 						   ($ content (trigger evt-res))
;; 						   (values)))
;; 				      ($ el (data)))))
;; 	(chain htmx (process (aref (chain content) 0)))))))

;; An easier way to use signals
;; (defpsmacro use-signal (the-signal &body body)
;;   `(chain ,the-signal (:sub (lambda (curr-state) ,@body))))

;;; Database macros
;; ;; Create a pandoric closure with a database connection set.
;; (defmacro with-db (connection letargs &body body)
;;   `(pandoriclet ((*connection* ,connection) ,@letargs)
;;      ;; (macrolet ((retrieve-one (&rest args) `(funcall ,,#'retrieve-one ,@args :*connection* *connection*))
;;      ;; 	   (retrieve-all (&rest args) `(funcall ,,#'retrieve-all ,@args :*connection* *connection*))
;;      ;; 	   (execute (&rest args) `(funcall ,,#'execute ,@args :*connection* *connection*)))
;;      (unwind-protect (progn ,@body)
;;        (dbi:disconnect ,connection))))

;; ;; Create a sqlite connection
;; (defmacro create-sqlite (name)
;;   `(dbi:connect :sqlite3
;; 		:database-name ,name))

;; Get a temporary connection to a random sqlite database.
(defmacro create-tmp-db ()
  (let ((db-name (str:concat
		              (symbol-name (gensym "./db-"))
		              ".sqlite")))
    `(create-sqlite ,db-name)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun sym-to-key (sym)
    (intern (symbol-name sym) "KEYWORD")))

(defparameter *handler-where-clause* '(:= :NULL :NULL))

(defmacro def-restart-fun (restart)
  `(defun ,restart (c)
     (let ((restart (find-restart ',restart)))
       (when restart (invoke-restart restart)))))

(def-restart-fun replace-existing)

(defun flatten-list (list)
  (loop for el in list
	      when (listp el)
	        append (flatten-list el)
	      else
	        append (list el)))

(defun pair-up (vars vals)
  (flatten-list (mapcar (lambda (var val) (list var val)) vars vals)))

;; (defmacro defmodel (connection &body column-groups)
;;   (let ((tables (mapcar λ`(,(sym-to-key (car _)) ,(cdr _)) column-groups)))
;;     `(progn
;;        ,@(mapcar λ`(defstruct ,(car _) ,@(mapcar #'car (cdr _))) column-groups)
;;        (let ((connection ,connection)
;; 	     (tables-classes ',(mapcar λ(cons (sym-to-key (car _)) (car _)) column-groups)))
;; 	 (plambda (&rest args) (connection)
;; 	   (with-connection connection
;; 	     (macrolet ((use-fun (fun)
;; 			  `(apply ,fun (cdr args)))
;; 			(multi-ret-this (table &body body)
;; 			  (let ((fun-name (gensym))
;; 				(table (intern (symbol-name table))))
;; 			    `(labels ((,fun-name () ,@body))
;; 			       ;; Pandoric from surrounding lexical scope.
;; 			       (if multi-ret
;; 				   (retrieve-all (,fun-name) :as (cdr (assoc ,table tables-classes)))
;; 				   (retrieve-one (,fun-name) :as (cdr (assoc ,table tables-classes))))))))
;; 	       (labels ((runtime-call-sxql (keyword &rest args)
;; 			  (apply (fn~ #'sxql::make-clause keyword) args))
;; 			(set-nonsense (statement)
;; 			  (flatten-list (mapcar (fn+ #'sxql::expand-op #'eval) statement)))
;; 			(where-nonsense (statement)
;; 			  ;; Based on the macros used by SXQL internally.
;; 			  (if (and (listp statement)
;; 				   (keywordp (car statement)))
;; 			      (eval (sxql::expand-op statement))
;; 			      statement))
;; 			(inserter (table cols data &key multi-ret)
;; 			  (block parent
;; 			    (restart-case (multi-ret-this table (insert-into table cols data (returning :*)))
;; 			      (replace-existing ()
;; 				(return-from parent
;; 				  (updater table *handler-where-clause* (pair-up cols data) :multi-ret multi-ret))))))
;; 			(replace-if-exists (table cols data where-clause &key multi-ret)
;; 			  (let ((*handler-where-clause* where-clause))
;; 			    (handler-bind ((sqlite:sqlite-error #'replace-existing))
;; 			      (inserter table cols data :multi-ret multi-ret))))
;; 			(selector (table where-statement &key multi-ret)
;; 			    (multi-ret-this table (select :*
;; 						    (from table)
;; 						    (where where-statement))))
;; 			(updater (table where-statement data &key multi-ret)
;; 			  (multi-ret-this table (update table
;; 						  (apply (fn~ #'runtime-call-sxql :set=)
;; 							 (set-nonsense data))
;; 						  (runtime-call-sxql :where
;; 								     (where-nonsense where-statement))
;; 						  (returning :*))))
;; 			(deleter (table where-statement)
;; 			  (execute (delete-from table
;; 				     (runtime-call-sxql :where (where-nonsense where-statement)))))
;; 			(init-tables ()
;; 			  ,@(mapcar λ`(execute
;; 				       (create-table (,(car _) :if-not-exists t)
;; 					   ,(mapcar (lambda (row)
;; 						      `(,(car row)
;; 							,@(loop
;; 							    with even = nil
;; 							    for i in (cdr row)
;; 							    when (and even (not (eq i t)))
;; 							      collect `(quote ,i)
;; 							    else
;; 							      collect i
;; 							    end do (setf even (not even)))))
;; 						    (cadr _))))
;; 				    tables)))
;; 		 (aif (car args)
;; 		      (ccase (the keyword it)
;; 			(:insert (use-fun #'inserter))
;; 			(:replace (use-fun #'replace-if-exists))
;; 			(:select (use-fun #'selector))
;; 			(:update (use-fun #'updater))
;; 			(:delete (use-fun #'deleter))
;; 			(:init-tables (init-tables)))
;; 		      (init-tables))))))))))

;; (defun get-method (box sym)
;;   (fn~ box sym))

;; (defmacro self-dot (sym)
;;   `(get-method self ,sym))

;; (defmacro with-connection (connection &body body)
;;   (let ((con-sym (gensym)))
;;     `(flet ((execute (statement &key (,con-sym ,connection))
;; 	      (execute statement :*connection* ,con-sym))
;; 	    (retrieve-one (statement &key (as datafly.db:*default-row-type*) (prettify t) (,con-sym ,connection))
;; 	      (retrieve-one statement :as as :prettify prettify :*connection* ,con-sym))
;; 	    (retrieve-all (statement &key (as datafly.db:*default-row-type*) (prettify t) (,con-sym ,connection))
;; 	      (retrieve-all statement :as as :prettify prettify :*connection* ,con-sym)))
;;        (declare (inline execute retrieve-one retrieve-all))
;;        (progn ,@body))))

;; (defmacro defmodule (connection tables business-logic &body controllers)
;;   (let ((exports))
;;     `(let ((model (defmodel ,connection ,@tables)))
;;        (plabels ,(mapcar (lambda (fun)
;; 			   `(,(let ((def (car fun)))
;; 				(if (consp def)
;; 				    (let ((name (car def))
;; 					  (options (cdr def)))
;; 				      (loop for option in options
;; 					    ;; Special forms here.
;; 					    do (case option
;; 						 (public (setf exports (cons name exports)))))
;; 				      name)
;; 				    def))
;; 			     (connection) ,(cadr fun)
;; 			     (with-connection connection
;; 			       ,@(cddr fun))))
;; 			 business-logic)
;; 	 ,@(mapcar (lambda (controller)
;; 		     `(defroute ,@controller))
;; 		   controllers)
;; 	 (dlambda
;; 	  ,@(mapcar (lambda (export)
;; 		      `(,(sym-to-key export) (&rest args)
;; 			(apply (fn~ #',export model) args)))
;; 		    exports)
;; 	  (t (&rest args)
;; 	     ;; Pass remaining instructions to the model.
;; 	     (apply model args)))))))

;; (defun dump-data (data)
;;   (ironclad:byte-array-to-hex-string (cl-binary-store:store nil data)))

;; (defun restore-data (data)
;;   (cl-binary-store:restore (ironclad:hex-string-to-byte-array data)))

;; TODO: Test this.
;; (defmacro defmodels (name connection tables &rest handlers)
;;   `(progn
;;      ,@(mapcar λ`(defstruct ,(intern (str:concat (symbol-name (car _))))
;; 		   ,@(mapcar λ(car _) (cdr _)))
;; 	       tables)
;;      (defparameter ,name
;;        (pandoriclet ((connection ,connection)
;; 		     ,@(mapcar λ`(,(car _) (lambda ,@(cdr _))) handlers))
;; 	 (lambda ()
;; 	   ,@(mapcar λ`(execute (create-table (,(intern (symbol-name (car _)) "KEYWORD") :if-not-exists t)
;; 				    ,(cdr _))
;; 				:*connection* connection)
;; 		     tables))))))

(defun dedup (list &key (key (lambda (x) x)))
  (nreverse (funcall
	           (alambda (list prior)
	             (if list
		               (if (member (funcall key (car list)) prior :test #'equal :key #'car)
		                   (self (cdr list) prior)
		                   (self (cdr list) (cons (car list) prior)))
		               prior))
	           list nil)))

(defun build-link (root &rest new-params)
  (let ((first t)
	      (params (dedup (concatenate 'list new-params (session-item "current-params"))
		                   :key #'car)))
    (apply #'str:concat `(,root ,@(mapcar (lambda (_)
					                                  (str:concat (if first
							                                              (progn (setf first nil) "?")
							                                              "&")
							                                          (car _) "=" (format nil "~A" (cdr _))))
					                                params)))))

(deftag nav-item (_ attrs &key text link (active nil))
  `(:li :class (bs nav-item)
	      ,@attrs
	      (:a :class (bs nav-link ,(when active 'active))
	          :href ,link
	          ,text)))

(deftag navbar (content attrs &key brand-link brand)
  `(:nav :class (bs navbar navbar-expand-lg bg-body-tertiary fixed-top)
	       :style "position: sticky;"
	       (:div :class (bs container-fluid)
	             (:a :class (bs navbar-brand) :href ,brand-link ,brand)
	             (:button :class (bs navbar-toggler) :type "button"
			                  :data-bs-toggle "collapse"
			                  :data-bs-target "#navbarSupportedContent"
			                  (:span :class (bs navbar-toggler-icon)))
	             (:div :class (bs collapse navbar-collapse) :id "navbarSupportedContent"
		                 (:ul :class (bs navbar-nav me-auto mb-2 mb-lg-0) ,@content)))))

(defparameter mobile-dropdown
  (ps
   (chain document
	        (query-selector-all ".navbar-toggler")
	        (for-each (lambda (toggler)
		                  (chain toggler (add-event-listener "click"
							                                           (lambda ()
							                                             (let ((target (chain document
										                                                            (query-selector
										                                                             (chain this
											                                                                  (get-attribute "data-bs-target"))))))
							                                               (when target
								                                               (chain target
								                                                      class-list
								                                                      (toggle "show")))
							                                               undefined))))
		                  undefined)))))

;; (defparameter dropdown-setter
;;   (ps (chain document (add-event-listener "click"
;; 					                                (lambda (e)
;; 					                                  (let ((toggle (chain e target (closest ".dropdown-toggle"))))
;; 					                                    (if toggle
;; 						                                      (let ((menu (getprop toggle 'next-element-sibling)))
;; 						                                        (chain menu
;; 							                                             class-list
;; 							                                             (toggle "show"))
;; 						                                        (chain toggle
;; 							                                             (set-attribute "aria-expanded"
;; 									                                                        (chain menu class-list contains "show"))))
;; 						                                      (chain document
;; 							                                           (query-selector-all ".dropdown-menu.show")
;; 							                                           (for-each (lambda (menu)
;; 								                                                     (chain menu
;; 									                                                          class-list
;; 									                                                          (remove "show"))
;; 								                                                     (chain menu
;; 									                                                          previous-element-sibling
;; 									                                                          (set-attribute "aria-expanded"
;; 											                                                                     "false"))))))
;; 					                                    undefined))))))

(defpsmacro setup-custom-el (name &optional (subclass '-h-t-m-l-element))
  `(progn (defun ,name ()
            (chain -reflect (construct ,subclass [] ,name)))
          (setf (@ ,name prototype) (chain -object (create (@ ,subclass prototype))))
          (setf (@ ,name prototype constructor) ,name)))


;; Adapted from something Grok gave me.
(defparameter filter-style "/* Turn off default markers so we can take full control (optional but recommended) */
ol[is=\"filter-ol\"] {
  list-style: none;
  counter-reset: item;
  padding-left: 2.8em;          /* adjust to taste – room for your numbers */
  margin: 0;
}

ol[is=\"filter-ol\"] > li {
  counter-increment: item;
  position: relative;
}

/* Our custom number (replaces the native ::marker) */
ol[is=\"filter-ol\"] > li::before {
  content: counter(item) \".\";
  position: absolute;
  left: -2.2em;
  width: 2em;
  text-align: right;
  color: #666;                  /* or whatever style you have */
  font-weight: bold;
}

/* The key rule for filter/hidden items */
ol[is=\"filter-ol\"] > li.filter-out {
  visibility: hidden;            /* ← disappears visually but still increments counter */
  height: 0px;
}
ul[is=\"filter-ul\"] > li.filter-out {
display: none;
}")

(defparameter filter-list
  (ps
   (let* ((keyup-callback
            (lambda (root)
              (lambda (e)
                (let* ((input (@ e target))
                       (search (chain input value (to-upper-case))))
                  (dolist (li (chain root (query-selector-all ":scope > li")))
                    (if (> (chain li text-content
                                  (to-upper-case)
                                  (index-of search))
                           -1)
                        (chain li class-list (remove "filter-out"))
                        (chain li class-list (add "filter-out"))))))))
          (con-callback
             (lambda ()
               (let* ((searchbar (with-html (:label "Search: " (:input))))
                      (root (@ searchbar first-element-child)))
                 (chain root (add-event-listener "keyup" (keyup-callback this)))
                 (chain this (prepend searchbar))
                 null))))
      (setup-custom-el filter-ul -h-t-m-l-u-list-element)
      (setup-custom-el filter-ol -h-t-m-l-o-list-element)
      (setf (chain filter-ul prototype connected-callback) con-callback)
      (setf (chain filter-ol prototype connected-callback) con-callback)
      (chain custom-elements (define "filter-ul" filter-ul (ps:create extends "ul")))
      (chain custom-elements (define "filter-ol" filter-ol (ps:create extends "ol"))))))

(defparameter win-box
  (ps:ps
   (let* ((con-callback (lambda ()
                          (ps:new (-win-box (or (ps:@ this dataset title) "New Window")
                                            (ps:create :root this))))))
     (setup-custom-el win-box)
     (setf (ps:@ win-box prototype connected-callback) con-callback)
     (ps:chain custom-elements (define "win-box" win-box)))))

(defmacro wrap-html-stream (&body body)
  `(lambda (responder)
     (let* ((writer (funcall responder '(200 (:content-type "text/html"))))
	          (*html* (make-writer-stream writer)))
       ,@body
       (finish-output *html*))))

(defmacro with-html-stream (&body body)
  `(wrap-html-stream
    (with-html ,@body)))

(defparameter main-style
  (css-lite:css
   ((body)
    (font-family "Garamond, Baskerville, Baskerville Old Face, Hoefler Text, Times New Roman, serif"))
   ((".verses li:hover")
    (:background-color "darkgray"))))

(defparameter dropdown-style
  (css-lite:css
   ((".dropdown-menu")
    (:display "none"
     :position "absolute"
     :top "100%"
     :left "0"))
   ((".dropdown-menu.show")
    (display "block"))))

;;; HTML-based macros
;; Create full HTML pages.
(defmacro with-page ((&key (title "Charito") css js nav-items custom-attrs hide-banner) &body body)
  `(with-html-stream
	   (:doctype)
     (:html :data-bs-theme (if (and (cur-user) (ap5::theonly mode ap5::s.t.
                                                             (jweb.model::user-dark-mode (cur-user) mode)))
                               "dark"
                               "light")
            (:meta :charset "utf-8")
	          (:title ,title)
	          (:meta :name "viewport" :content "width=device-width, initial-scale=1")
	          (:link :rel "stylesheet" :href "/static/bootstrap.min.css")
	          (:style (:raw ,pane-style
			                    ,dropdown-style
			                    ,main-style
                          ,filter-style
                          "@view-transition { navigation: auto; }"))
	          ,(when css
	             `(:style (:raw ,css)))
	          ;; (:script :src "/static/htmx.min.js")
	          (:script (:raw ,filter-list))
	          ,(when custom-attrs
	             `(:script (:raw (custom-attrs ,custom-attrs))))
	          ,(when js
	             `(:script (:raw ,js)))
            (:iframe :hidden t
                     :name "htmz"
                     :onload (:raw (ps:ps (set-timeout
                                           (lambda ()
                                             (let ((el (ps:chain document (query-selector
                                                                           (ps:or (ps:@ content-window location hash)
                                                                                  nil)))))
                                               (ps:when el
                                                 (ps:chain el replace-with
                                                           (apply el (ps:@ content-document
                                                                           body
                                                                           child-nodes)))
                                                 (setf src "about:blank"))
                                                 (return)))))))
            ,(unless hide-banner
               `(progn
	                (navbar :brand "Charito" :brand-link (build-link "/")
		                      (nav-item :active t :link (build-link "/") :text "Home")
		                      (if (cur-user)
		                          (progn (nav-item :link "/settings" :text "Settings")
                                     (:li :class (bs nav-item)
                                          (:form :method "POST" :action "/logout"
	                                               (:input :type "submit"
                                                         :class (bs nav-link)
                                                         :value "Log Out"))))
		                          (progn (nav-item :link "/login" :text "Log In")
                                     (nav-item :link "/register" :text "Register")))
			                    ,@nav-items)
	                (:script (:raw ,mobile-dropdown))))
	          ,@body)))

(defun* (make-id-string -> string) ((name string))
  (str:concat "#" name))

(deftag insert-script (content attrs &key)
  `(:script (:raw (ps ,@content))))

;;; The start and stop functions.
(defun make-server (&key (port 8080) (server :hunchentoot))
  (let ((curr-instance nil))
    (labels ((srv-start (port server)
               ;; One instance per lisp image.
               (when curr-instance
                 (srv-stop))
               (setf curr-instance
	                   (clack:clackup
	                    (lack:builder :session
		                                (:static :path "/static/"
				                                     :root (asdf:system-relative-pathname :jweb "static/"))
		                                app)
	                    :port port
	                    :server server)))
             (srv-stop ()
               (when curr-instance
                 (clack:stop curr-instance)
                 (setf curr-instance nil))))
      (init-html-els)
      (dlambda
       (:start (&key (port port) (server server))
               (srv-start port server))
       (:stop () (srv-stop))))))

(defun init-html-els ()
  "Consider removing since it doesn't seem to have an effect."
  (with-html
      (:thml-div1
       (:thml-div2
        (:thml-div3
         (:thml-pb)
         (:thml-h1)
         (:thml-h2)
         (:thml-h3)
         (:thml-h4)
         (:thml-h5)
         (:thml-h6)
         (:thml-argument)
         (:thml-scripCom)
         (:thml-scripture)
         (:thml-scripContext)
         (:thml-sync)
         (:thml-note)
         (:thml-foreign)
         (:thml-attr)
         (:thml-unclear)
         (:thml-citation)
         (:thml-name)
         (:thml-date)
         (:thml-verse)
         (:thml-insertIndex)
         (:thml-electronicEdInfo)
         (:thml-authorID)
         (:thml-workID)
         (:thml-versionID)
         (:thml-bkgID)
         (:thml-DC)
         (:thml-l)
         (:thml-hymn)
         (:thml-meter)
         (:thml-author)
         (:thml-tune)
         (:thml-composer)
         (:thml-incipit)
         (:thml-music)
         (:thml-index)
         (:thml-glossary)
         (:thml-term)
         (:thml-def)
         (:thml-added)
         (:thml-deleted)
         (:thml-p))))))
