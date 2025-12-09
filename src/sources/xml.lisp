(in-package :jweb.sources.xml)

(defmacro alambda (vars &body body)
  `(labels ((self ,vars ,@body))
     #'self))

(deftag element (contents attrs &key name attributes)
  `(:div :class ,name ,@attributes
	 ,@contents))

;; (defun get-bible (source)
;;   (let ((document (pl:parse (alexandria:read-file-into-string source))))
;;     (lambda (query)
;;       (mapcar (alambda (node)
;; 		(if (pl:text-node node)
;; 		    (with-html (:p (pl:text node)))
;; 		    (with-html (element :name (pl:tag-name node)
;; 					:attributes (pl:attributes node)
;; 					(if (pl:has-child-nodes node)
;; 					    (mapcar #'self (pl:child-elements node)))))))
;; 	      (clss:select query document)))))

(defun query-book (query)
  (car query))

(defun query-chapters (query)
  (mapcar #'car (cdr query)))

(defun query-verses (query chapter)
  (cdr (assoc chapter (cdr query))))

(defun node-num (node)
  (parse-integer (gethash "number" (pl:attributes node))))

(defun fuzzy-member (item list)
  (if (or (and (consp (car list))
	       (>= item (caar list))
	       (<= item (cdar list)))
	  (and (numberp (car list)) (= item (car list))))
      t
      (when (cdr list)
	(fuzzy-member item (cdr list)))))

;; Format: '(bk (ch . (v (v .v) v)) (ch . (v v v (v . v)))) Or a list of those lists
(defun fetch-nodes (document query)
  (car (remove nil (map 'list
			(lambda (book)
			  (when (equal (query-book query) (node-num book))
			    (remove nil (map 'list
					     (lambda (chapter)
					       (let ((chap-num (node-num chapter)))
						 (when (member chap-num (query-chapters query))
						   (cons chap-num (remove nil (map 'list
										   (lambda (verse)
										     (when (fuzzy-member (node-num verse)
													 (query-verses query chap-num))
										       verse))
										   (pl:child-elements chapter)))))))
					     (pl:child-elements book)))))
			(let ((els (map 'list #'pl:child-elements (pl:child-elements (pl:first-element document)))))
			  (concatenate 'vector (car els) (cadr els)))))))

(defun fetch-bible-book (document query)
  (car (remove nil (map 'list
			(lambda (book)
			  (when (equal query (node-num book))
			    (remove nil (map 'list
					     (lambda (chapter)
					       (let ((chap-num (node-num chapter)))
						 (cons chap-num (map 'list
								     (lambda (x) x)
								     (pl:child-elements chapter)))))
					     (pl:child-elements book)))))
			(let ((els (map 'list #'pl:child-elements (pl:child-elements (pl:first-element document)))))
			  (concatenate 'vector (car els) (cadr els)))))))

(defun parse-file (filename)
  (declare (type string filename)
	   (optimize (speed 3) (safety 0)))
  (pl:parse (alexandria:read-file-into-string filename)))
(declaim (inline parse-file))

(defun get-bible (source)
  (declare (type string source))
  (let ((document (parse-file source)))
    (memo (lambda (query)
	    (declare (type (or fixnum cons) query))
	    (mapcar (lambda (l)
		      (mapcar (lambda (node)
				(pl:text node))
			      (cdr l)))
		    (if (integerp query)
			(fetch-bible-book document query)
			(fetch-nodes document query)))))))

;; Format: '(bk (ch . (v (v .v) v)) (ch . (v v v (v . v)))) Or a list of those lists
(defun scrip-ref-to-strings (query)
  (declare (type list query)
	   (values list))
  (let ((book (jweb.bibles:num-to-name (car query))) (chapters (cdr query)))
    (loop for chapter in chapters
	  for verse in chapter
	  append (list (if (consp verse)
			   (format nil "~A|~A|~A|~A|~A" book chapter (car verse) chapter (cdr verse)))))))

;; (defun get-book (source)
;;   (declare (type string source))
;;   (let ((document (parse-file source)))
;;     (plambda (document) (query)
;;       (let ()
;; 	(type (or fixnum list) query)
;; 	(if (numberp query)
;; 	    (fetch-book-page document query)
;; 	    (fetch-book-fragment document (scrip-ref-to-strings query)))))))

;; (defstruct bible-ref
;;   (verse -1 :type (or fixnum cons))
;;   (resource-url "" :type string)
;;   (entry-path nil :type list)
;;   (entry-text "" :type string))

;; (deftype ref-list-type ()
;;   '(vector (vector (list bible-ref))))

;; (defparameter bible-refs
;;   (let ((refs) (refs-path "/tmp/bible-refs.dump"))
;;     (declare (type refs ref-list-type)
;; 	     (type refs-path string))
;;     (labels ((set-initial-array ()
;; 	       (setf refs (make-array 66 :element-type '(vector bible-ref))))
;; 	     (fill-initial-array ()
;; 	       (loop for i from 0 to 66
;; 		     do (setf (aref refs i)
;; 			      (make-array (jweb.bibles:num-to-chapters i) :element-type bible-ref))))
;; 	     (init-refs ()
;; 	       (handler-case (restore refs-path)
;; 		 (file-does-not-exist (c)
;; 		   (declare (ignore c))
;; 		   (set-initial-array)
;; 		   (fill-initial-array)))))
;;       (plambda (refs refs-path) ()
;; 	(if refs
;; 	    refs
;; 	    (init-refs))))))

;; (defpan save-bible-refs (refs refs-path)
;;   (declare (type ref-list-type refs)
;; 	   (type string refs-path))
;;   (cl-binary-store:store refs-path refs))

;; (defppan add-bible-ref (refs) (book chapter ref)
;;   (declare (type ref-list-type refs)
;; 	   (type fixnum book chapter)
;; 	   (type bible-ref ref))
;;   (let ((retval (symbol-macrolet ((the-slot (aref (aref refs book) chapter)))
;; 		  (setf the-slot (cons ref the-slot)))))
;;     (save-bible-refs self)
;;     retval))

;; (defppan get-bible-refs (refs) (book chapter verse)
;;   (declare (type ref-list-type refs)
;; 	   (type fixnum verse book chapter))
;;   (let ((refs (aref (aref refs book) chapter)))
;;     (declare (type list refs))
;;     (remove-if #'nullp (loop for ref in refs
;; 			     nconc (list (let ((ref-verse (bible-ref-verse ref)))
;; 					   (declare (type (or cons fixnum) ref-verse))
;; 					   (when (if (consp ref-verse)
;; 						     (and (>= verse (car ref-verse))
;; 							  (<= verse (cdr ref-verse)))
;; 						     (= verse ref-verse))
;; 					     ref)))))))
