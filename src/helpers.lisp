(in-package :jweb.framework)

;; Adds λ
(named-readtables:in-readtable :fn.reader)

;; Make more gensyms for our runtime parenscript needs.
(defpsmacro gensym () (parenscript:ps-gensym))
(defpsmacro gensym-string () (symbol-name (parenscript:ps-gensym)))

;; ;; Use lquery's dollar
;; (defmacro with-lq (&body b)
;;   (macrolet (($ (&rest r) `(lquery:$ ,@r)))
;;     ,@b))

;; Stuff for the Graham/Hoyte macros
#+sbcl
(eval-when (:compile-toplevel :execute)
  (handler-case (progn (sb-ext:assert-version->= 1 2 2)
		       (setq *features* (remove 'old-sbcl *features)))
    (error () (pushnew 'old-sbcl *features*))))

;; Seibel's once-only
(defmacro once-only ((&rest names) &body body)
  (let ((gensyms (loop for n in names collect (gensym))))
    `(let (,@(loop for g in gensyms collect `(,g (gensym))))
       `(let (,,@(loop for g in gensyms for n in names collect ``(,,g ,,n)))
          ,(let (,@(loop for n in names for g in gensyms collect `(,n ,g)))
             ,@body)))))

;; Graham's aif macro + a PS version.
(defmacro+ps aif (test t-branch f-branch)
  `(let ((it ,test))
     (if it
	 ,t-branch
	 ,f-branch)))

;; An awhen macro like aif
(defmacro+ps awhen (test &body t-branch)
  `(let ((it ,test))
     (when it
       ,@t-branch)))

;; Hoyte/Graham alet/alambda
(defmacro alet (letargs &body body)
  `(let ((this) ,@letargs)
     (setq this ,@(last body))
     ,@(butlast body)
     λ(apply this _@)))

(defmacro alambda (parms &body body)
  `(labels ((self ,parms ,@body))
     #'self))

(defmacro hlet (ht vars &body body)
  `(symbol-macrolet
       (,@(mapcar
	    λ(let ((sym (gensym)))
	       `(,(car _) (gethash ',sym ,ht)))
	    (let-binding-transform vars)))
     ,@(mapcar λ`(setf ,(car _) ,@(cdr _)) vars)
     ,@body))

;; Session-based alet. Current body of 'this' is bound to the user session.
;; The other letargs are not session-bound.
(defmacro salet (letargs &body body)
  (let ((args-name (gensym))
	(initial-this (gensym))
	(this-id (symbol-name (gensym))))
    `(lambda (&rest ,args-name)
       (apply
	(symbol-macrolet ((this (gethash ,this-id *session*)))
	  (let ((,initial-this) ,@letargs)
	    (setf ,initial-this ,@(last body))
	    ,@(butlast body)
	    λ(apply (aif (gethash ,this-id *session*) it ,initial-this) _@)))
	,args-name))))

;; Hoyte's dlambda
(defmacro dlambda (&rest ds)
  (let ((args (gensym)))
    `(lambda (&rest ,args)
       (case (car ,args)
         ,@(mapcar
            λ`(,(if (eq t (car _))
                    t
                    (list (car _)))
               (apply (lambda ,@(cdr _))
		                  ,(if (eq t (car _))
                           args
                           `(cdr ,args))))
            ds)))))

;; Hoyte's original alet-fsm
(defmacro alet-fsm (&rest states)
  `(macrolet ((state (s)
                `(setf this #',s)))
     (labels (,@states) #',(caar states))))

;; Hoyte's alet-fsm with modifications for salet. [unnecessary since I got the symbol-macrolet to work].
;; (defmacro salet-fsm (&rest states)
;;   `(macrolet ((state (s)
;;                 `(setf this #',s)))
;;      (labels (,@states) #',(caar states))))

(eval-when (:compile-toplevel :load-toplevel :execute)
  ;; Hoyte's let-binding-transform
  (defun let-binding-transform (bindings)
    (if bindings
	      (cons
	       (cond ((symbolp (car bindings))
		            (list (car bindings)))
	             ((consp (car bindings))
		            (car bindings))
	             (t (error "Bad let bindings")))
	       (let-binding-transform (cdr bindings)))))

  ;; Things for Hoyte's pandoriclet.
  (defun pandoriclet-get (letargs)
    `(case sym
       ,@(mapcar λ`((,(car _)) ,(car _)) letargs)
       (t (error "Unknown pandoric get: ~a"
		             sym))))

  (defun pandoriclet-set (letargs)
    `(case sym
       ,@(mapcar λ`((,(car _))
		                (setf ,(car _) val))
	        letargs)
       (t (error "Unknown pandoric set: ~a"
		             sym val)))))

;; Hoyte's pandoric macros.
(defmacro pandoriclet (letargs &body body)
  (let* ((letargs (let-binding-transform letargs)))
    `(let* (,@letargs)
       ,@(butlast body)
       (dlambda
	      (:pandoric-get (sym)
		                   ,(pandoriclet-get letargs))
	      (:pandoric-set (sym val)
		                   ,(pandoriclet-set letargs))
	      (t (&rest args)
	         (apply ,@(last body) args))))))

(declaim (inline get-pandoric))

(defun get-pandoric (box sym)
  (funcall box :pandoric-get sym))

(defsetf get-pandoric (box sym) (val)
  `(progn
     (funcall ,box :pandoric-set ,sym ,val)
     ,val))

(defmacro with-pandoric (syms box &body body)
  (once-only (box)
    `(symbol-macrolet
	 (,@(mapcar λ`(,_ (get-pandoric ,box ',_))
		    syms))
       ,@body)))

(defun pandoric-hotpatch (box new)
  (with-pandoric (this) box
    (setq this new)))

(defmacro pandoric-recode (vars box new)
  `(with-pandoric (this ,@vars) ,box
     (setq this ,new)))

(defmacro plambda (largs pargs &body body)
  (let ((pargs (mapcar #'list pargs)))
    `(let (this self)
       (setq
	      this (lambda ,largs ,@body)
	      self (dlambda
	            (:pandoric-get (sym)
			                       ,(pandoriclet-get pargs))
	            (:pandoric-set (sym val)
			                       ,(pandoriclet-set pargs))
	            (t (&rest args)
		             (apply this args)))))))

(defmacro defpan (name args &body body)
  `(defun ,name (self)
     ,(if args
	  `(with-pandoric ,args self ,@body)
	  `(progn ,@body))))

(defmacro plabels (funs &body body)
  `(labels ,(mapcar
	     (lambda (fun)
	       `(,(car fun) ,(cons 'self (caddr fun))
		 ,@(aif (cadr fun)
			`((with-pandoric ,it
			      self
			    ,@(cdddr fun)))
			(cdddr fun))))
	     funs)
     ,@body))

;; Define parameterized pandoric method.
(defmacro defppan (name pargs fargs &body body)
  `(defun ,name (self ,@fargs)
     ,(if pargs
	  `(with-pandoric ,pargs self ,@body)
	  `(progn ,@body))))

;; Set something to a value if it is nil
(defmacro setf-if-nil (place value)
  `(unless ,place
     (setf ,place ,value)))

(defmacro define (name &body body)
  (if (consp name)
      `(defun ,(car name) ,(cdr name) ,@body)
      `(defparameter ,name ,@body)))

;; A macro to have an immediately invoked macro expression
(defmacro comptime (&body expr)
  (eval `(progn ,@expr)))

;; Graham's continuations
(defmacro =lambda (parms &body body)
  `(lambda (cont ,@parms)
     (declare (ignorable cont))
     (progn ,@body)))

(defmacro =defun (name parms &body body)
  (let ((f (intern (concatenate 'string
				                        "=" (symbol-name name)))))
    `(progn
       (defmacro ,name ,parms
	       `(,',f cont ,,@parms))
       (defun ,f (cont ,@parms)
	       (declare (ignorable cont))
	       (progn ,@body)))))

;; Changed lambda to alambda to allow recursive continuation functions -- PJL
(defmacro =bind (parms expr &body body)
  `(let ((cont (alambda ,parms ,@body)))
    ,expr))

(defmacro =values (&rest retvals)
  `(funcall cont ,@retvals))

(defmacro =funcall (fn &rest args)
  `(funcall ,fn cont ,@args))

(defmacro =apply (fn &rest args)
  `(apply ,fn cont ,@args))

;; Scheme's define
(defmacro define (name &body body)
  (if (consp name)
      `(defun ,(car name) ,(cdr name) ,@body)
      `(defparameter ,name ,@body)))

;; Graham's delay
(defparameter unforced (gensym))

(defstruct delay forced closure)

(defmacro delay (expr)
  (let ((self (gensym)))
    `(let ((,self (make-delay :forced unforced)))
       (setf (delay-closure ,self)
	     (lambda ()
	       (setf (delay-forced ,self) ,expr)))
       ,self)))

(define (force x)
  (if (delay-p x)
      (if (eq (delay-forced x) unforced)
	  (funcall (delay-closure x))
	  (delay-forced x))
      x))

;; A hack for continuations to work without top-level lexical variables.
(comptime
 (let ((real-cont (gensym)))
   `(progn
      (defvar ,real-cont #'values)
      (define-symbol-macro cont ,real-cont))))

;; Abelson's streams
(define the-empty-stream (gensym))

(define (empty-stream? s)
  (eq s the-empty-stream))

(defmacro cons-stream (x y)
  `(cons ,x (delay ,y)))

(defun list-stream (&rest args)
  (if args
      (cons-stream (car args) (list-stream (cdr args)))
      the-empty-stream))

(define (head s)
  (car s))

(define (tail s)
  (force (cdr s)))

(define (map-stream proc s)
  (if (empty-stream? s)
      the-empty-stream
      (cons-stream
       (funcall proc (head s))
       (map-stream proc (tail s)))))

(define (filter pred s)
  (cond ((empty-stream? s) the-empty-stream)
	((funcall pred (head s))
	 (cons-stream (head s)
		      (filter pred (tail s))))
	(t (filter pred (tail s)))))

(define (accumulate combiner init-val s)
  (if (empty-stream? s)
      init-val
      (funcall combiner (head s)
	       (accumulate combiner
			   init-val
			   (tail s)))))

(define (append-streams s1 s2)
  (if (empty-stream? s1)
      s2
      (cons-stream
       (head s1)
       (append-streams (tail s1)
		       s2))))

(define (enumerate-tree tree)
  (if (not (consp tree))
      (cons-stream tree the-empty-stream)
      (append-streams
       (enumerate-tree
	(car tree))
       (enumerate-tree
	(cdr tree)))))

(define (enum-interval low high)
  (if (> low high)
      the-empty-stream
      (cons-stream
       low
       (enum-interval (1+ low) high))))

(define (flatten st-of-st)
  (accumulate #'append-streams
	      the-empty-stream
	      st-of-st))

(define (flatmap f s)
  (flatten (map-stream f s)))

(define (print-stream s)
  (when s
    (princ (head s))
    (print-stream (tail s))))

;; or= is from https://malisper.me/or/
(defmacro or= (place &rest args)
  (multiple-value-bind
	(temps exprs stores store-expr access-expr)
      (get-setf-expansion place)
    `(let* (,@(mapcar #'list temps exprs)
	    (,(car stores) (or ,access-expr ,@args)))
       ,store-expr)))

;; defmemo is from https://malisper.me/defmemo/
;; TODO: Automatically remove entries older than ~12h at 12:00AM.
(defun memoize (f)
  (let ((cache (make-hash-table :test #'equalp)))
    (lambda (&rest args)
      (or= (gethash args cache)
	   (apply f args)))))

(defmacro defmemo (name args &body body)
  `(setf (symbol-function ',name)
	       (memoize (lambda* ,args ,@body))))

;; Paul Graham's utilities for nondeterministic programming.
(defparameter *paths* nil)
(defparameter failsym (gensym "FAIL"))

(defmacro choose (&rest choices)
  (if choices
      `(progn
	 ,@(mapcar (lambda (c) `(push (lambda () ,c) *paths*))
		   (reverse (cdr choices)))
	 ,(car choices))
      '(c-fail)))

(defmacro choose-bind (var choices &body body)
  `(cb (lambda (,var) ,@body) ,choices))

(defun cb (fn choices)
  (if choices
      (progn
	(when (cdr choices)
	  (push (lambda () (cb fn (cdr choices))) *paths*))
	(funcall fn (car choices)))
      (c-fail)))

(defun c-fail ()
  (if *paths*
      (funcall (pop *paths*))
      failsym))

(defun hard-reset-paths ()
  (setf *paths* nil))


(defmacro do-subs (text &body replacements)
  (let ((retval (gensym)))
    `(let ((,retval ,text))
       ,@(mapcar (lambda (r)
                   `(setf ,retval
                          (substitute ,(car r) ,(cadr r) ,retval)))
                 replacements)
       ,retval)))

;; The following function was partially produced by Grok.
;; The macro is to make the code less annoying.
;; https://grok.com/share/bGVnYWN5_1b419c89-a5ce-4489-83f3-eca34429abb6
(defun straight-text (node)
  "Wrapper around plump:text that replaces common curly quotes with straight quotes."
  (do-subs (plump:text node)
    (#\' (code-char #x2019))
    (#\' (code-char #x2018))
    (#\" (code-char #x201D))
    (#\" (code-char #x201C))
    (#\- (code-char #x2014))
    (#\- (code-char #x2013))
    (#\Space (code-char #x00A0))))
