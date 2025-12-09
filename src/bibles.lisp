(in-package :jweb.bibles)

(defparameter* (bible-version-files list)
    '((:kjv . "bibles/EnglishKJBible.xml")
			(:net . "bibles/EnglishNETBible.xml")
			(:tyndale-1537 . "bibles/EnglishTyndale1537Bible.xml")
			(:darby-bible . "bibles/EnglishDarbyBible.xml")))

;;(define-symbol-macro bible-fs)
(defmacro with-document (source &body body)
  `(let ((document (parse-file ,source))) ,@body))

(defun* (bcv-book-to-num -> fixnum) ((book symbol))
  (1+ (position book bcv-names)))

(defun* (num-to-bcv-book -> (or symbol null)) ((num fixnum))
  (aref bcv-names (1- num)))
(defun get-passage (el)
  (gethash "passage" (pl:attributes el)))

(defun bible-url (bible)
  (declare (type symbol bible))
  (cdr (assoc bible bible-version-files)))

(defun book-name (text)
  (declare (type (or fixnum cons) text))
  (the symbol (aref bcv-names
                    (etypecase text
                      (cons (the fixnum (car text)))
                      (fixnum text)))))

(defun name-book (name)
  (declare (type symbol name))
  (the (or fixnum null)
       (ignore-errors (1+ (position name bcv-names)))))

  ;; (num-to-name (etypecase text
	;; 	             (cons (the fixnum (car text)))
	;; 	             (fixnum text))))

(defun get-memoized-bible (bible)
  (declare (type symbol bible))
  (get-bible (bible-url bible)))

(defparameter versions (mapcar #'car bible-version-files))

(defun get-verses (verses version)
  (declare (optimize (speed 3)))
  (declare (type (or cons fixnum) verses))
  (declare (type symbol version))
  (let ((selection verses)
	      (bible-fun (get-bible version)))
    (declare (type (or list fixnum) selection))
    (declare (type function bible-fun))
    (if (and (consp selection)
	           (consp (car selection)))
	      (mapcar bible-fun selection)
	      (funcall bible-fun selection))))

(defun load-chapter (book chapter version)
  (declare (optimize (speed 3)))
  (declare (type fixnum book chapter))
  (declare (type symbol version))
  (get-verses (list book (list chapter (cons 1 999))) version))

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
      (and (cdr list)
	   (fuzzy-member item (cdr list)))))

;; Format: '(bk (ch . (v (v . v) v)) (ch . (v v v (v . v)))) Or a list of those lists.
;; TODO: Make into struct later.
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

(defun parse-file (filename)
  (declare (type string filename)
	         (optimize (speed 3) (safety 0)))
  (pl:parse (alexandria:read-file-into-string filename)))
(declaim (inline parse-file))

;; Custom memoization due to strange errors with generic implementation.
(let ((bibles (make-hash-table :test #'eq :synchronized t)))
  (defun* get-bible ((version symbol))
    (or (gethash version bibles nil)
        (setf (gethash version bibles)
              (let ((document (pl:parse (alexandria:read-file-into-string
                                         (asdf:system-relative-pathname
                                          :jweb
                                          (cdr (assoc version bible-version-files)))))))
                (lambda* ((query (or fixnum cons))
                          &optional ((chapter (or fixnum null)) nil))
                  (if chapter
                      (fetch-bible-chapter document query chapter)
                      (mapcar (lambda (nodes) (mapcar λ(pl:text _) (cdr nodes)))
	                            (etypecase query
		                            (fixnum (fetch-bible-book document query))
		                            (cons (fetch-nodes document query)))))))))))

(defun get-els (document)
  (let ((els (map 'list #'pl:child-elements (pl:child-elements (pl:first-element document)))))
		(concatenate 'vector (car els) (cadr els))))

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
			                  (get-els document)))))

(defun* (fetch-bible-chapter -> list) ((document pl:node) (query fixnum) (chapter-num fixnum))
  ;; Appending at beginning so it doesn't get broken by prior code.
  (t:transduce (t:comp (t:filter (lambda (book)
                                   (equal query (node-num book))))
                       (t:take 1)
                       (t:map #'pl:child-elements)
                       #'t:flatten
                       (t:filter (lambda (chapter)
                                   (equal chapter-num (node-num chapter))))
                       (t:take 1)
                       (t:map #'pl:child-elements)
                       #'t:flatten
                       (t:map #'pl:children)
                       #'t:flatten
                       (t:map #'pl:text))
               #'t:cons
               (get-els document)))

(defun parse-file (filename)
  (pl:parse (alexandria:read-file-into-string filename)))
(declaim (inline parse-file))
