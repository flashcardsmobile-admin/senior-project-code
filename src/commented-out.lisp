;; This is for chunks of code that I don't currently need but may want to reference later.

;; (defppan add-resource (connection) (title uri &optional (versification "modern"))
;;   (with-connection connection
;;     (retrieve-one (insert-into :resource
;; 		    (set= :title title
;; 			  :uri uri
;; 			  :versification versification
;; 			  :type type)
;; 		    (returning :*))
;; 		  :as 'resource)))

;; (defppan add-section (connection) (addr resource-id)
;;   (with-connection connection
;;     (retrieve-one (insert-into :section
;; 		    (set= :addr addr
;; 			  :resource-id resource-id)
;; 		    (returning :*))
;; 		  :as 'section)))

;; (flet ((gen-args (query)
;; 	 `((select :*
;; 	     (from :resource)
;; 	     (where ,@query))
;; 	   :as 'resource)))
;;   (declare (inline gen-args))
;;   (defppan get-resources (connection) (query)
;;     (let ((args (gen-args query)))
;;       (with-connection connection
;; 	(apply retrieve-all args))))

;;   (defppan get-resource (connection) (query)
;;     (let ((args (gen-args query)))
;;       (with-connection connection
;; 	(apply retrieve-one args)))))

;; (defppan load-resource () (query)
;;   (funcall self :get (resources-text-uri (get-resource self query))))


;; (let (()))resources

;; (resource-cache (make-hash-table :test #'equal :synchronized t))
;; (resource-cache-lock (bt:make-lock))
;; (cleaner-running)
;; (cache-cleaner-thread)
;; (symbol-macrolet ((default-expiration (* 5 60 60))
;; 		  (default-interval (* 10 60)))
;;   (macrolet ((with-locked-cache (&body body)
;; 	       `(bt:with-lock-held (resource-cache-lock) ,@body)))
;;     (labels ((get-resource (uri)
;; 	       (with-locked-cache
;; 		   (aif (the (or cons null) (gethash uri resource-cache))
;; 			(progn (setf (cdr it) (get-universal-time))
;; 			       (car it))
;; 			(load-resource uri))))
;; 	     (load-resource (uri)
;; 	       (with-locked-cache
;; 		   (car (setf (gethash uri resource-cache) (cons (pl:parse (alexandria:read-file-into-string uri))
;; 								 (get-universal-time))))))
;; 	     (cache-cleaner (&key (interval default-interval) (expiration default-expiration))
;; 	       (when cleaner-running
;; 		 (setf cleaner-running nil)
;; 		 (bt:join-thread cache-cleaner-thread))
;; 	       (setf cache-cleaner-thread (bt:make-thread
;; 					   (lambda () (loop while cleaner-running
;; 							    do (sleep interval)
;; 							       (clean-cache expiration))))))
;; 	     (clean-cache (expiration)
;; 	       (with-locked-cache
;; 		   (let ((now (get-universal-time)))
;; 		     (maphash (lambda (key entry)
;; 				(when (> (- now (cdr (the cons entry))) expiration)
;; 				  (remhash key resource-cache)))
;; 			      resource-cache)))))
;;       (cache-cleaner)
;;       (dlambda
;;        (:get (uri) (get-resource uri))
;;        (:clean-cache (&key (expiration default-expiration)) (clean-cache expiration))
;;        (:cache-cleaner (&rest args) (apply cache-cleaner args))
;;        (t (&rest args) (apply resources args))))))


;;; Old web.lisp
;; (defun render-bible-links (start end)
;;   (loop for n from start to end
;; 	do (let ((new-url (build-link "/" (cons "book" n))))
;; 	     (with-html
;; 	       (:li (:a :class (bs btn-block container btn btn-outline-secondary)
;; 			:href new-url
;; 			(jweb.bibles:num-to-name n)))))))

;; (defun render-bible-text (text version)
;;   (with-html
;;     (:section
;;      (let ((num 0))
;;        (loop for chapter in (jweb.bibles:get-verses text version)
;; 	     do (with-html
;; 		 (:div :class "chapter container"
;; 		       (:br)
;; 		       (:h2 :class "chapter-heading"
;; 			    :id (str:concat "ch" (format nil "~A" (incf num)))
;; 			    ("Chapter ~A" num))
;; 		       (:br)
;; 		       (:div :class "verses container"
;; 			     (:ol
;; 			      (loop for verse in chapter
;; 				    do (with-html (:li verse))))))))))))

;; (defun book-list (text)
;;   (with-html
;;     (:li :class (bs nav-item dropdown)
;; 	 (:button :class (bs dropdown-toggle nav-link)
;; 		  :data-bs-toggle "dropdown"
;; 		  (jweb.bibles:book-name text))
;; 	 (:ul :class (bs dropdown-menu)
;; 	      :style "overflow: scroll; max-height: 20em;"
;; 	      (:b "Old Testament")
;; 	      (render-bible-links 1 39)
;; 	      (:b "New Testament")
;; 	      (render-bible-links 40 66)))))

;; (defun version-list (version)
;;   (with-html
;;     (:li :class (bs nav-item dropdown)
;; 	 (:button :class (bs dropdown-toggle nav-link)
;; 		  :data-bs-toggle "dropdown"
;; 		  (symbol-name version))
;; 	 (:ul :class (bs dropdown-menu)
;; 	      :style "overflow: scroll; max-height: 20em;"
;; 	      (let ((even nil))
;; 		(loop for version in (jweb.bibles:available-versions)
;; 		      do (let ((new-url (build-link "/" (cons "version" (symbol-name version)))))
;; 			   (with-html
;; 			     (:li (:a :class (bs btn-block container btn btn-outline-secondary)
;; 				      :href new-url
;; 				      (symbol-name version)))))))))))

;; (defun chapters-list (text)
;;   (with-html
;;     (:li :class (bs nav-item dropdown)
;; 	 (:button :class (bs dropdown-toggle nav-link)
;; 		  :role "button"
;; 		  :data-bs-toggle (bs dropdown)
;; 		  :type "button"
;; 		  "Chapters")
;; 	 (:ul :class (bs dropdown-menu)
;; 	      :style "overflow: scroll; max-height: 20em;"
;; 	      (let ((even nil))
;; 		(loop for n from 1 to (jweb.bibles:num-to-chapters text)
;; 		      do (with-html
;; 			   (:li (:a :class (bs btn-block container btn btn-outline-secondary)
;; 				    :href (format nil "#ch~A" n)
;; 				    ("Chapter ~A" n))))))))))

;; ;;; Routes
;; (defroute ("/") ()
;;   (let ((current-text 1) ;; '(1 (1 . ((0 . 999))))
;; 	(current-version :kjv))
;;     (setf (session-item "current-params") params)
;;     (awhen (get-post-item "book" params)
;;       (setf current-text (parse-integer it)))
;;     (awhen (get-post-item "version" params)
;;       (let ((version (intern it "KEYWORD")))
;; 	(when (member version (jweb.bibles:available-versions))
;; 	  (setf current-version version))))
;;     (with-page (:title "Welcome"
;; 		:nav-items ((chapters-list current-text)
;; 			    (version-list current-version)
;; 			    (book-list current-text)))
;;       (panes (pane (render-bible-text current-text current-version))))))



;; (declaim (type list bible-files))
;; (defparameter bible-files '((:kjv . "../bibles/EnglishKJBible.xml")
;; 			    (:net . "../bibles/EnglishNETBible.xml")
;; 			    (:tyndale-1537 . "../bibles/EnglishTyndale1537Bible.xml")
;; 			    (:darby-bible . "../bibles/EnglishDarbyBible.xml")))

;; (declaim (type list bibles))
;; (defparameter bibles '())

;; (defun bible-url (bible)
;;   (declare (type symbol bible))
;;   (cdr (assoc bible bible-files)))

;; (defun uncache-bibles ()
;;   (declare (optimize (speed 3) (safety 0)))
;;   (setf bibles '()))

;; (defun book-name (text)
;;   (declare (type (or fixnum cons) text))
;;   (num-to-name (if (consp text)
;; 		   (the fixnum (car text))
;; 		   text)))

;; (defun get-memoized-bible (bible)
;;   (declare (type symbol bible))
;;   (let ((bible-fun (the (or function null) (cdr (assoc bible bibles)))))
;;     (if bible-fun
;; 	bible-fun
;; 	(cdar (setf bibles (acons bible (get-bible (bible-url bible)) bibles))))))

;; (defparameter versions (mapcar #'car bible-files))
;; (defun available-versions ()
;;   (declare (optimize (speed 3)))
;;   (the list versions))

;; (defun get-verses (verses version)
;;   (declare (optimize (speed 3)))
;;   (declare (type (or cons fixnum) verses))
;;   (declare (type symbol version))
;;   (let ((selection verses)
;; 	(bible-fun (get-memoized-bible version)))
;;     (declare (type (or list fixnum) selection))
;;     (declare (type function bible-fun))
;;     (if (and (consp selection)
;; 	     (consp (car selection)))
;; 	(mapcar bible-fun selection)
;; 	(funcall bible-fun selection))))


;; (defun find-book (name)
;;   (let ((name-len (length name))
;; 	(book-names (book-names)))
;;     (labels ((binsearch-comp (candidate)
;; 	       (let ((candidate-len (length candidate)))
;; 		 (let ((greatest-len (if (> name-len candidate-len) name-len candidate-len)))
;; 		   (or (loop for i upfrom 0 to greatest-len
;; 			     do (cond ((>= i name-len) 'up)
;; 				      ((>= i candidate-len) 'down)
;; 				      (t (let ((name-c (aref name i))
;; 					       (candidate-c (aref candidate i)))
;; 					   (cond ((char-greaterp name-c candidate-c) (return 'down))
;; 						 ((char-lessp name-c candidate-c) (return 'up)))))))
;; 		       'equal)))))
;;       (let ((lowpoint 0)
;; 	    (highpoint (length book-names)))
;; 	(let ((midpoint 0)
;; 	      (comp-res nil))
;; 	  (tagbody
;; 	   begin
;; 	     (setf midpoint (+ lowpoint (floor (/ 2 (- highpoint lowpoint)))))
;; 	     (setf comp-res (binsearch-comp (car (aref book-names midpoint))))
;; 	     (ecase comp-res
;; 	       (up (setf highpoint midpoint))
;; 	       (down (setf lowpoint midpoint))
;; 	       (equal (return (aref book-names midpoint))))
;; 	     (if (or (equal highpoint midpoint) ;; We have pretty much nowhere else to search.
;; 		     (equal lowpoint midpoint))
;; 		 (error "Book name not found: ~a" name))
;; 	     (go begin)))))))


;; (let ((state :read-ch)
;; 	    (verse-type)
;; 	    (new-ref (make-scrip-ref :book book-name))
;; 	    (verses (make-verse))
;; 	    (left rest)
;; 	    (current (car rest)))
;; 	(labels ((advance-queue ()
;; 		   (setf left (cdr left))
;; 		   (setf current (car left)))
;; 		 (verse-mode () (setf state :read-v))
;; 		 (chapter-mode () (setf state :read-ch))
;; 		 (singular-mode () (setf verse-type :singular))
;; 		 (plural-mode () (setf verse-type :plural)))
;; 	  (declare (inline verse-mode chapter-mode advance-queue singular-mode plural-mode))
;; 	  (tagbody
;; 	   base-cases
;; 	     (case state
;; 	       (:read-ch
;; 		(if (not verse-type)
;; 		    (progn (singular-mode)
;; 			   (with-numeric-current
;; 			       (setf (verse-chapter verses) (parse-integer current))
;; 			     (verse-mode)
;; 			     (advance-queue)
;; 			     (go base-cases)))
;; 		    (progn (plural-mode)
;; 			   (with-numeric-current
;; 			       (setf verses (let ((new (make-verses)))
;; 					      (setf (verses-chapter-start new)
;; 						    (verse-chapter verses))
;; 					      (setf (verses-verse-start new)
;; 						    (verse-verse verses))
;; 					      (setf (verses-chapter-end new)
;; 						    (parse-integer current))
;; 					      new))
;; 			     (verse-mode)
;; 			     (advance-queue)
;; 			     (go base-cases)))))
;; 	       (:read-v
;; 		(case verse-type
;; 		  (:singular (with-numeric-current
;; 				 (setf (verse-verse verses) (parse-integer current))
;; 			       (chapter-mode)
;; 			       (advance-queue)
;; 			       (go base-cases)))
;; 		  (:plural (with-numeric-current
;; 			       ;; The start will have already been set in the pluralization process.
;; 			       (setf (verses-verse-end verses) (parse-integer current)))))))))
;; 	(modf (scrip-ref-verses new-ref) verses))

;; TODO: Reimplement as a recursive descent parser.
;; (t:transduce (t:comp (t:filter λ(not (equal _ #\Space)))
;; 		     (t:group-by λ(equal _ #\;))
;; 		     (t:map #'stringify-seq)
;; 		     (t:map (lambda (citation)
;; 			      (t:transduce (t:comp (t:group-by λ(equal _ #\:))
;; 						   (t:map #'stringify-seq))
;; 					   #'t:cons
;; 					   citation))))
;; 	     #'t:cons
;; 	     (str:substring (length spelled-name) (length passage) passage))

;; (let ((chapter 1))
;;   (labels ((bump-chapter ()
;;              (with-html (close-list)
;;                         (render-chapter-head (incf chapter))
;;                         (open-list)))
;;            (chapter-changed-p (verse)
;;              (not (= (verse-chapter verse) chapter))))
;;     (with-html
;;       (render-chapter-head 1)
;;       (open-list)
;;       ;; TODO: Convert back to using query syntax instead of old model syntax.
;;       (loop for verse in '()
;;             do (progn (when (chapter-changed-p verse) (bump-chapter))
;;                       (render-verse verse)))
;;       (close-list))))))


;; ;; (title source-file)
;; (defrelation Resource
;;   :types (String Pathname))

;; ;; (title compiled-file source-file)
;; (defrelation Section
;;   :types (String Pathname Pathname))

;; ;; (resource-title section-title source-file compiled-file)
;; (defrelation Resource-Section
;;   :definition ((resource-title
;;                 section-title
;;                 source-file
;;                 compiled-file)
;;                s.t. (E(resource-source-file)
;;                       (and (Resource resource-title resource-source-file)
;;                            (Section section-title compiled-file source-file)
;;                            (equal source-file resource-source-file)))))


;; (in-package :jweb)

;; (defparameter resources-module
;;   (defmodule resources-connection
;;       ((versification (id :type integer
;; 			  :autoincrement t
;; 			  :primary-key t)
;; 		      (name :type string
;; 			    :unique t
;; 			    :not-null t))
;;        (resource (id :type integer
;; 		     :autoincrement t
;; 		     :primary-key t)
;; 		 (title :type string
;; 			:not-null t
;; 			:unique t)
;; 		 (uri :type string
;; 		      :unique t
;; 		      :not-null t)
;; 		 (versification :type integer
;; 				:not-null t))
;;        (reference (id :type integer
;; 		      :autoincrement t
;; 		      :primary-key t)
;; 		  (referencer-id :type integer
;; 				 :not-null t)
;; 		  (start-chapter :type integer
;; 				 :not-null t)
;; 		  (start-verse :type integer
;; 			       :not-null t)
;; 		  (end-chapter :type integer
;; 			       :not-null t)
;; 		  (end-verse :type integer
;; 			     :not-null t))
;;        ;; TODO: Make a cleanup process to find and kill orphaned sections
;;        ;; since they don't have a replacement scenario.
;;        (section (id :type integer
;; 		    :autoincrement t
;; 		    :primary-key t)
;; 		(type :type string)
;; 		(tl-ordering :type integer)
;; 		(title :type string
;; 		       :not-null t)
;; 		(contents :type blob)
;; 		(n :type string
;; 		   :not-null t)
;; 		(resource-id :type integer
;; 			     :not-null t)
;; 		(parent :type integer)))
;;       ((add-versification (name) (retrieve-one
;; 				  (insert-into :versification
;; 				    (set= :name name)
;; 				    (returning :*))
;; 				  :as 'versification))
;;        (get-section (id) (retrieve-one (select :*
;; 					 (from :section)
;; 					 (where (:= :id id)))
;; 				       :as 'section))
;;        (add-section (el &key prior tl-ordering)
;; 		    (let* ((section (the section (funcall model :insert :section 
;; 							  `(:resource-id
;; 							    :title
;; 							    :n
;; 							    ,@(when tl-ordering (list :tl-ordering)))
;; 							  `(resource-id
;; 							    ,(gethash "title" (pl:attributes el))
;; 							    ,(gethash "n" (pl:attributes el))
;; 							    ,@(when tl-ordering (list tl-ordering))))))
;; 			   (section-id (section-id section)))
;; 		      ;; Storing a vector of items in the database. It's sort of a tree too, but via database links.
;; 		      (funcall model :update :section
;; 			       (list := :id section-id)
;; 			       `(:contents
;; 				 ,(dump-data
;; 				   (print
;; 				    (t:transduce
;; 				     (t:map (lambda (tag)
;; 					      (if (div-tag-p self tag)
;; 						  ;; Division location for rendering.
;; 						  ;; The keyword ensures that many kinds of special cases
;; 						  ;; can be encodes this way without having to rewrite old code.
;; 						  (cons :section (add-section self tag :prior section-id))
;; 						  tag)))
;; 				     #'t:vector
;; 				     (pl:child-elements el))))
;; 				 ;; If this is nil, it will just terminate the list.
;; 				 ,@(when prior (list :parent prior))))
;; 		      section-id))
;;        (n-tag-p (tag n)
;; 		(format t "~a is ~a? ~a~%" (pl:tag-name tag) n (str:starts-with-p n (pl:tag-name tag)))
;; 		(str:starts-with-p n (pl:tag-name tag)))
;;        (div-tag-p (tag) (n-tag-p self tag "div"))
;;        (body-tag-p (tag) (n-tag-p self tag "ThML.body"))
;;        ((load-resource public) (title uri versification)
;; 	(let* ((resource (funcall model :replace :resource
;; 				  (list :title
;; 					:uri
;; 					:versification)
;; 				  (list title
;; 					uri
;; 					versification)
;; 				  `(:or (:= :title ,title)
;; 					(:= :uri ,uri))))
;; 	       (resource-id (resource-id resource)))
;; 	  (loop for el across (pl:child-elements (t:transduce (t:filter (fn~ #'body-tag-p self))
;; 								      #'t:first
;; 								      (pl:child-elements
;; 								       (pl:first-element
;; 									(pl:parse
;; 									 (alexandria:read-file-into-string
;; 									  (resource-uri resource)))))))
;; 		counting el into order
;; 		do (add-section self el :tl-ordering order))
;; 	  resource-id))
;;        (get-tl-sections (resource-id)
;; 			(retrieve-all (select :*
;; 					(from :section)
;; 					(where (:and (:= :id resource-id)
;; 						     (:not (:is :tl-ordering :null))))
;; 					(order-by :tl-ordering))
;; 				      :as 'section))
;;        (get-resource (title)
;; 		     (retrieve-one (select :*
;; 				     (from :resource)
;; 				     (where (:= :title title)))
;; 				   :as 'resource)))
;;     ;; (("/resource/:title/") ()
;;     ;;  (rdr-to (format nil "/resource/~a/1" (get-req-item :title params))))
;;     (("/resource/:title/*") ()
;;      (block page
;;        (labels ((ret-not-found ()
;; 		  (return-from page (not-found)))
;; 		(section-heading (section)
;; 		  (declare (type section section))
;; 		  (with-html (:header (:h2 (section-title section)))))
;; 		(render-section (section index next-sections)
;; 		  (declare (type section section))
;; 		  (declare (type integer index))
;; 		  (declare (type list next-sections))
;; 		  (let ((children (restore-data (section-contents section))))
;; 		    (with-html
;; 		      (:div (section-heading section)
;; 			    (let ((section-num 0) (next-section (car next-sections)))
;; 			      (loop for child in children
;; 				    when (and (consp child)
;; 					      (eq (car child) :section)
;; 					      (or (null next-sections)
;; 						  (= (incf section-num) next-section)))
;; 				      do (render-section (get-section (cdr child)))
;; 				    else
;; 				      ;; ThML uses HTML tags for most things, and this is trusted data.
;; 				      do (:raw child)))))))
;; 		(render-sections (path resource)
;; 		  (declare (type list path))
;; 		  (declare (type resource resource))
;; 		  (let ((sections (get-tl-sections model (resource-id resource)))
;; 			(section-num (car path))
;; 			(next-sections (cdr path)))
;; 		    (if (null section-num)
;; 			(loop for section in sections
;; 			      counting section
;; 				into i
;; 			      do (render-section section i next-sections))
;; 			(render-section (nth section-num sections) section-num nil)))))
;; 	 (let ((title (get-req-item :title params)))
;; 	   (let ((sections (mapcar (lambda (x)
;; 				     (aif (ignore-errors (parse-integer x))
;; 					  it
;; 					  ;; Returns from the whole handler prematurely.
;; 					  (ret-not-found)))
;; 				   (str:split "/" (get-req-item :splat params))))
;; 		 (resource (get-resource title)))
;; 	     (unless resource
;; 	       (ret-not-found))
;; 	     (with-page (:title title)
;; 	       (:h1 title)
;; 	       (render-sections sections resource)))))))))

;; (defun init-resources ()
;;   (funcall resources-module))

;; (defun load-resource (title uri versification)
;;   (funcall resources-module :load-resource title uri versification))

;; (in-package :jweb)

;; (declaim (type list bible-files))
;; (defparameter bible-files '((:kjv "../bibles/EnglishKJBible.xml" :standard)
;; 			                      (:net "../bibles/EnglishNETBible.xml" :standard)
;; 			                      (:tyndale-1537 "../bibles/EnglishTyndale1537Bible.xml" :standard)
;; 			                      (:darby-bible "../bibles/EnglishDarbyBible.xml" :standard)))

;; (declaim (type list versions))
;; (defparameter versions (mapcar #'car bible-files))

;; (declaim (inline bible-url))
;; (defun bible-url (bible)
;;   (declare (type symbol bible))
;;   (the string (cdr (assoc bible bible-files))))

;; (declaim (inline book-name))
;; (defun book-name (text)
;;   (declare (type (or fixnum cons) text))
;;   (the string (num-to-name (if (consp text)
;; 			                         (the fixnum (car text))
;; 			                         text))))

;; (defparameter bible-module
;;   (defmodule resources-connection
;;       ((bible (id :type integer
;; 		              :autoincrement t
;; 		              :primary-key t)
;; 	            (uri :type string
;; 		               :unique t
;; 		               :not-null t)
;; 	            (name :type string
;; 		                :unique t
;; 		                :not-null t)
;; 	            (versification :type integer
;; 			                       :not-null t))
;;        (verse (id :type integer
;; 		              :autoincrement t
;; 		              :primary-key t)
;; 	            (version :type integer
;; 		                   :not-null t)
;; 	            (book :type integer
;; 		                :not-null t)
;; 	            (chapter :type integer
;; 		                   :not-null t)
;; 	            (verse :type integer
;; 		                 :not-null t)
;; 	            (contents :type text
;; 			                  :not-null t
;; 			                  :unique t)))
;;     ((add-verse (version book chapter verse contents)
;; 		            (funcall model :replace :verse
;; 			                   (list :version 
;; 				                       :book    
;; 				                       :chapter 
;; 				                       :verse   
;; 				                       :contents)
;; 			                   (list version
;; 				                       book
;; 				                       chapter
;; 				                       verse
;; 				                       contents)
;; 			                   `(:and (:= :version ,version)
;; 				                        (:= :book ,book)
;; 				                        (:= :chapter ,chapter)
;; 				                        (:= :verse ,verse))))
;;      (add-bible (uri name versification)
;; 		            (the bible (funcall model :replace :bible
;; 				                            (list :uri
;; 					                                :name
;; 					                                :versification)
;; 				                            (list uri
;; 					                                name
;; 					                                versification)
;; 				                            `(:= :name ,name))))
;;      ((load-bible public) (uri name versification)
;; 	    (labels ((children (el)
;; 		             (pl:child-elements el))
;; 		           (document-books (document)
;; 		             (let ((testaments (children (pl:first-element document))))
;; 		               (let ((old-testament (aref testaments 0))
;; 			                   (new-testament (aref testaments 1)))
;; 		                 (concatenate 'vector
;; 				                          (children old-testament)
;; 				                          (children new-testament)))))
;; 		           (load-document (uri)
;; 		             (pl:parse (alexandria:read-file-into-string uri)))
;; 		           (el-num (el)
;; 		             (parse-integer (gethash "number" (pl:attributes el))))
;; 		           (dump-text (el)
;; 		             (dump-data (pl:text el))))
;; 	      (declare (inline document-books
;; 			                   load-document
;; 			                   children
;; 			                   el-num
;; 			                   dump-text))
;; 	      (let ((bible (add-bible self uri name versification)))
;; 	        (loop for book across (document-books (load-document (bible-uri bible)))
;; 		            do (loop for chapter across (children book)
;; 			                   do (loop for verse across (children chapter)
;; 				                          do (let ((book-num (el-num book))
;; 					                                 (chapter-num (el-num chapter))
;; 					                                 (verse-num (el-num verse)))
;; 					                             (add-verse self
;; 						                                      (bible-id bible)
;; 						                                      book-num
;; 						                                      chapter-num
;; 						                                      verse-num
;; 						                                      (dump-text verse)))))))))
;;      (get-bible (name)
;; 		            (the (or bible null)
;; 		                 (retrieve-one (select :*
;; 				                             (from :bible)
;; 				                             (where (:= :name name)))
;; 				                           :as 'bible)))
;;      (get-book-verses (text book-num)
;; 			                (the list
;; 			                     (retrieve-all (select :*
;; 					                                 (from :verse)
;; 					                                 (where (:and (:= :book book-num)
;; 							                                          (:= :version (bible-id text)))))
;; 					                               :as 'verse))))
;;     (("/bible/:version") ()
;;      (rdr-to (format nil "/bible/~a/1" (get-req-item :version params))))
;;     (("/bible/:version/:book") ()
;;      (labels ((render-verse (verse)
;; 		            (with-html (:li (restore-data (verse-contents verse)))))
;; 	            (render-chapter-head (num)
;; 		            (with-html (:h2 ("Chapter ~a" num))))
;; 	            (open-list ()
;; 		            (with-html (:raw "<ol>")))
;; 	            (close-list ()
;; 		            (with-html (:raw "</ol>")))
;; 	            (render-verses (text book)
;; 		            (let ((chapter 1))
;; 		              (labels ((bump-chapter ()
;; 			                       (with-html (close-list)
;; 					                              (render-chapter-head (incf chapter))
;; 					                              (open-list)))
;; 			                     (chapter-changed-p (verse)
;; 			                       (not (= (verse-chapter verse) chapter))))
;; 		                (with-html
;; 		                  (render-chapter-head 1)
;; 		                  (open-list)
;; 		                  (loop for verse in (get-book-verses model text book)
;; 			                      do (progn (when (chapter-changed-p verse) (bump-chapter))
;; 				                              (render-verse verse)))
;; 		                  (close-list))))))
;;        (let ((version (get-req-item :version params))
;; 	           (book (or (ignore-errors (parse-integer (get-req-item :book params))) 1)))
;; 	       (let ((text (get-bible model version)))
;; 	         (if (not text)
;; 	             ;; Gates against arbitrary strings in "version".
;; 	             (not-found)
;; 	             (with-page (:title (format nil "~a - ~a" (book-name book) version)
;; 			                     :nav-items ((book-list version book)
;; 				                               (chapters-list book)
;; 				                               (version-list version book)))
;; 		             (:h1 (book-name book))
;; 		             (render-verses text book)))))))))

;; (defun init-bibles-db ()
;;   (funcall bible-module)
;;   (loop for bible in bible-files
;; 	      do (funcall bible-module :load-bible
;; 		                (cadr bible)
;; 		                (symbol-name (car bible))
;; 		                (symbol-name (caddr bible)))))

;; (defmemo book-names ()
;;   (t:transduce
;;    (t:map (lambda (line)
;; 	          (let ((els (str:split #\Tab line)))
;; 	            (cons (cadr els)
;;                     (car els)))))
;;    #'t:cons
;;    #p"../Bible-Passage-Reference-Parser/src/en/book_names.txt"))

;; (let ((actions '())
;;       (cur filename))
;;   (handler-case
;;       (loop do (multiple-value-bind (title parent)
;;                    (any (title parent)
;;                         s.t. (and (section-parent cur parent)
;;                                   (section-title parent title)))
;;                  (setf actions (cons (lambda ()
;;                                        (with-html
;;                                          (:li
;;                                           (:a :class (bs btn btn-secondary)
;;                                               :href (format nil "/resource/~a" (pathname-name parent))
;;                                               (if (str:emptyp title)
;;                                                   (any (title) s.t. (e(resource)
;;                                                                       (and (resource-sections resource parent)
;;                                                                            (resource-title resource title))))
;;                                                   title)))))
;;                                      actions))
;;                  (setf cur parent)))
;;     (ap5:no-data () '()))
;;   (with-html
;;     (:li :class (bs nav-item dropdown)
;; 	       (:button :class (bs dropdown-toggle nav-link)
;; 		              :data-bs-toggle "dropdown"
;; 		              (any (title) s.t. (section-title filename title)))
;; 	       (:ul :class (bs dropdown-menu)
;; 	            :style "overflow: scroll; max-height: 20em;"
;;               (loop for action in actions do (funcall action))))))


;; ;; The users table and related functions.
;; (defparameter users (defmodel (create-sqlite "users.sqlite")
;; 		      (users (id :type integer
;; 				 :autoincrement t
;; 				 :primary-key t)
;; 			     (email :type string
;; 				    :not-null t)
;; 			     (password :type string
;; 				       :not-null t))))

;; (defun authorize (email password)
;;   (with-pandoric (connection) users
;;     "Check if an email/password pair is in the DB. If so, return the user id."
;;     (awhen (retrieve-one
;; 	    (select :*
;; 	      (from :users)
;; 	      (where (:= :email email)))
;; 	    :as 'users
;; 	    :*connection* connection)
;;       (when (pbkdf2-check-password
;; 	     (ascii-string-to-byte-array password)
;; 	     (users-password it))
;; 	it))))

;; (defun add-user (email password)
;;   (with-pandoric (connection) users
;;     "Add a new user into the DB."
;;     (retrieve-one
;;      (insert-into :users
;;        (set= :email email
;; 	     :password (pbkdf2-hash-password-to-combined-string
;; 			(ascii-string-to-byte-array password)))
;;        (returning :*))
;;      :as 'users
;;      :*connection* connection)))

;; (funcall users)

;; (defroute ("/login") ()
;;   (with-page (:title "Login")
;;     (:section :class (bs container)
;; 	      (:aside (:p "No account? " (:a :href "/register" "Register") " and join us!"))
;; 	      (:form
;; 	       :method "POST"
;; 	       :action (make-temp-route (lambda (_)
;; 					  (aif (authorize (get-post-item "email" _)
;; 							  (get-post-item "password" _))
;; 					       (progn (setf (cur-user) (users-id it))
;; 						      (rdr-to "/"))
;; 					       (rdr-to "/" :code 401))))
;; 	       (:div :class (bs mb-3)
;; 		     (:label :for "email" :class (bs form-label) "Email")
;; 		     (:input :type "email" :name "email" :class (bs form-control) :id "loginEmail"))
;; 	       (:div :class (bs mb-3)
;; 		     (:label :for "password" :class (bs form-label) "Password")
;; 		     (:input :type "password" :name "password" :class (bs form-control) :id "loginPassword"))
;; 	       (:button :type "submit" :class (bs btn btn-primary) "Submit"))
;; 	      (toast-widget :title "Login Error"
;; 			    :message "Login failed. Please ensure credentials are correct and try again."))))

;; (defroute ("/register") ()
;;   (with-page (:title "Register")
;;     (:section :class (bs container)
;; 	      (:aside (:p "Already have an account? " (:a :href "/login" "Log in") " and use your existing account."))
;; 	      (:form
;; 	       :id "registerForm"
;; 	       :method "POST"
;; 	       :action (make-temp-route
;; 			(lambda (_)
;; 			  (aif (add-user (get-post-item "email" _)
;; 					 (get-post-item "password" _))
;; 			       (progn (setf (cur-user) (users-id it))
;; 				      (rdr-to "/"))
;; 			       (rdr-to "/" :code 401))))
;; 	       (:div :class (bs mb-3)
;; 		     (:label :for "email" :class (bs form-label) "Email")
;; 		     (:input :type "email" :name "email" :class (bs form-control) :id "registerEmail"))
;; 	       (:div :class (bs mb-3)
;; 		     (:label :for "password" :class (bs form-label) "Password")
;; 		     (:input :type "password" :name "password" :class (bs form-control) :id "registerPassword"))
;; 	       (:div :class (bs mb-3)
;; 		     (:label :for "confirm-password" :class (bs form-label) "Password")
;; 		     (:input :type "password" :name "confirm-password" :class (bs form-control) :id "registerConfirmPassword"))
;; 	       (:button :type "submit" :class (bs btn btn-primary) "Submit"))
;; 	      (toast-widget :title "Registration Error"
;; 			    :message "Registration failed. Please contact support."))))

;; (defroute ("/logout") ()
;;   (setf (cur-user) nil)
;;   (rdr-to "/"))

;; (deftag attr-put-form (target
;; 		       attrs
;; 		       &key table attr id
;; 		       (submit-label "Change")
;; 		       pre-submit-transform (show t))
;;   (let ((input-name (symbol-name (gensym))))
;;     `(:form
;;       ,@(when show
;; 	  `(:hx-swap "textContent"
;; 	    :hx-target ,target))
;;       :hx-put (make-temp-route
;; 	       (lambda* ((args association-list))
;; 		 (retrieve-one-value
;; 		  (update ,table
;; 		    (set= ,attr
;; 			  ,(if pre-submit-transform
;; 			       `(funcall ,pre-submit-transform (getf args ,input-name))
;; 			       `(getf args ,input-name)))
;; 		    (where (:= :id ,id))
;; 		    ,(when show `(returning ,attr)))))
;; 	       :prefix "/user/"
;; 	       :method :PUT)
;;       (:input :type "text"
;; 	      :name ,input-name)
;;       (:input :type "submit"
;; 	      :value ,submit-label))))

;; (defparameter dbname "login.sqlite")

;; ;; The users table and related functions.
;; (funcall
;;  (defmodel users (create-sqlite dbname)
;; 	   ((id :type 'integer
;; 		:autoincrement t
;; 		:primary-key t)
;; 	    (username :type 'string
;; 		      :not-null t)
;; 	    (favorite-color :type 'string))
;; 	   (authorize ((username string) (password string))
;; 		      "Check if a username/password pair is in the DB. If so, return the user id."
;; 		      (awhen (retrieve-one
;; 			      (select :*
;; 				(from :user)
;; 				(where (:= :username username)))
;; 			      :as users-model
;; 			      :*connection* *connection*)
;; 			(when (pbkdf2-check-password
;; 			       (ascii-string-to-byte-array password)
;; 			       (ascii-string-to-byte-array (users-model-password it)))
;; 			  it)))
;; 	   (add-user ((username string) (password string))
;; 		     "Add a new user into the DB."
;; 		     (users-model-id (retrieve-one
;; 				      (insert-into :user
;; 					(set= :username username
;; 					      :password (pbkdf2-hash-password-to-combined-string
;; 							 (ascii-string-to-byte-array password)))
;; 					(returning :id))
;; 				      :*connection* *connection*)))))

;; ;; (defparameter login
;; ;;   (with-db  ((authorize) (add-user) (initialize))
;; ;;     (setf authorize (lambda* ((username string) (password string))
;; ;; 		      "Check if a username/password pair is in the DB. If so, return the user id."
;; ;; 		      (awhen (retrieve-one
;; ;; 			      (select :*
;; ;; 				(from :user)
;; ;; 				(where (:= :username username)))
;; ;; 			      :*connection* *connection*)
;; ;; 			(when (pbkdf2-check-password
;; ;; 			       (ascii-string-to-byte-array password)
;; ;; 			       (ascii-string-to-byte-array (getf it :password)))
;; ;; 			  it))))

;; ;;     (setf add-user (lambda* ((username string) (password string))
;; ;; 		     "Add a new user into the DB."
;; ;; 		     (getf (retrieve-one
;; ;; 			    (insert-into :user
;; ;; 			      (set= :username username
;; ;; 				    :password (pbkdf2-hash-password-to-combined-string
;; ;; 					       (ascii-string-to-byte-array password)))
;; ;; 			      (returning :id))
;; ;; 			    :*connection* *connection*)
;; ;; 		     :id)))
;; ;;     (setf initialize (lambda ()
;; ;; 		       "Initialize the DB."
;; ;; 		       (execute
;; ;; 			(create-table (:user :if-not-exists t)
;; ;; 			    ((id :type 'integer
;; ;; 				 :autoincrement t
;; ;; 				 :primary-key t)
;; ;; 			     (username :type 'string
;; ;; 				       :not-null t)
;; ;; 			     (favorite-color :type 'string)))
;; ;; 			:*connection* *connection*)))

;; (defun* login ((prefix string))
;;   (with-pandoric (authorize add-user) users
;;     (salet ()
;;       (alet-fsm
;;        (login (params)
;; 	      "Default state: present the user with a login screen."
;; 	      (declare (type association-list params))
;; 	      (if (gethash "user" *session*)
;; 		  ;; Send logged-in users to the status screen.
;; 		  (progn (state status)
;; 			 (rdr-to (make-temp-route this :prefix prefix)))
;; 		  (with-html-string
;; 		    (:section
;; 		     :id "user-widget-target"
;; 		     (:header (:h2 "Log In"))
;; 		     (:button :hx-get (make-temp-route
;; 				       (lambda (_)
;; 					 (declare (ignore _))
;; 					 (state register)
;; 					 (rdr-to (make-temp-route this :prefix prefix)))
;; 				       :prefix prefix)
;; 			      :hx-target "#user-widget-target"
;; 			      :hx-swap "outerHTML"
;; 			      "Register")
;; 		     (:form :hx-target "#user-widget-target"
;; 			    :hx-swap "outerHTML"
;; 			    :hx-post (make-temp-route
;; 				      λ(aif (funcall authorize
;; 						     (get-post-item "username" _)
;; 						     (get-post-item "password" _))
;; 					    (progn
;; 					      (setf (gethash "user" *session*)
;; 						    (getf it :id))
;; 					      (state status)
;; 					      (rdr-to (make-temp-route this :prefix prefix)))
;; 					    (rdr-to (make-temp-route this :prefix prefix)))
;; 				      :prefix prefix
;; 				      :method :POST)
;; 			    (:label :for "username" "Username: "
;; 				    (:input :type "text" :name "username"))
;; 			    (:br)
;; 			    (:label :for "password" "Password: "
;; 				    (:input :type "password" :name "password"))
;; 			    (:br)
;; 			    (:input :type "submit"
;; 				    :value "Log in"))))))
;;        (register (params)
;; 		 (declare (type association-list params))
;; 		 "Present the user with a registration screen."
;; 		 (if (gethash "user" *session*)
;; 		     ;; Logged-in users head to status instead.
;; 		     (progn (state status)
;; 			    (rdr-to (make-temp-route this :prefix prefix)))
;; 		     (with-html-string
;; 		       (:section
;; 			:id "user-widget-target"
;; 			(:header (:h2 "Register"))
;; 			(:button :hx-get (make-temp-route
;; 					  (lambda (_)
;; 					    (declare (ignore _))
;; 					    (state login)
;; 					    (rdr-to (make-temp-route this :prefix prefix)))
;; 					  :prefix prefix)
;; 				 :hx-swap "outerHTML"
;; 				 :hx-target "#user-widget-target"
;; 				 "Log In")
;; 			(:form :hx-swap "outerHTML"
;; 			       :hx-target "#user-widget-target"
;; 			       :hx-post (make-temp-route
;; 					 λ(let ((username (get-post-item "username" _))
;; 						(password (get-post-item "password" _))
;; 						(confirm-password (get-post-item "confirm-password" _)))
;; 					    (if (and username password (string= password confirm-password))
;; 						(progn
;; 						  (setf (gethash "user" *session*)
;; 							(funcall add-user username password))
;; 						  (state status)
;; 						  (rdr-to (make-temp-route this :prefix prefix)))
;; 						'(400 prefix)))
;; 					 :prefix prefix
;; 					 :method :POST)
;; 			       (:label :for "username" "Username: "
;; 				       (:input :type "text" :name "username"))
;; 			       (:br)
;; 			       (:label :for "password" "Password: "
;; 				       (:input :type "password" :name "password"))
;; 			       (:br)
;; 			       (:label :for "confirm-password" "Confirm Password: "
;; 				       (:input :type "password" :name "confirm-password"))
;; 			       (:br)
;; 			       (:input :type "submit"
;; 				       :value "Register"))))))
;;        (status (params)
;; 	       "Check the status of the current user."
;; 	       (if (not (gethash "user" *session*))
;; 		   (progn (state login)
;; 			  '(303 (make-temp-route this :prefix prefix)))
;; 		   (let ((cur-user
;; 			   (retrieve-one
;; 			    (select :*
;; 			      (from :user)
;; 			      (where
;; 			       (:= :id (gethash "user" *session*))))))
;; 			 (username-field-id (gensym))
;; 			 (favorite-color-field-id (gensym)))
;; 		     (with-html-string
;; 		       (:section
;; 			:id "user-widget-target"
;; 			(:header (:h2 "User Status"))
;; 			(:button :hx-get (make-temp-route
;; 					  (lambda (_)
;; 					    (declare (ignore _))
;; 					    (setf (gethash "user" *session*) nil)
;; 					    (state login)
;; 					    (rdr-to (make-temp-route this :prefix prefix)))
;; 					  :prefix prefix)
;; 				 :hx-swap "outerHTML"
;; 				 :hx-target "#user-widget-target"
;; 				 "Log Out")
;; 			(:table
;; 			 (:tr (:th "Username")
;; 			      (:th "Password")
;; 			      (:th "Favorite Color"))
;; 			 (:tr (:td :id username-field-id
;; 				   (getf cur-user :username))
;; 			      (:td "[redacted]")
;; 			      (:td :id favorite-color-field-id
;; 				   (getf cur-user :favorite-color)))
;; 			 (:tr (:td (attr-put-form
;; 				     :table :user
;; 				     :attr :username
;; 				     :id (getf cur-user :id)
;; 				     username-field-id))
;; 			      (:td (attr-put-form
;; 				     :table :user
;; 				     :attr :password
;; 				     :id (getf cur-user :id)
;; 				     :pre-submit-transform
;; 				     (lambda* ((pass string))
;; 				       (pbkdf2-hash-password-to-combined-string
;; 					(ascii-string-to-byte-array pass)))
;; 				     :show nil))
;; 			      (:td (attr-put-form
;; 				     :table :user
;; 				     :attr :favorite-color
;; 				     :id (getf cur-user :id)
;; 				     favorite-color-field-id)))))))))))))

;; (deftag user-manager (contents attrs &key user-route)
;;   "A wrapper tag around the users widget."
;;   `(:div :hx-trigger "load"
;; 	 :hx-target "this"
;; 	 :hx-swap "outerHTML"
;; 	 :hx-get ,user-route))

;; (filename)
;; s.t. (e(chap-start
;;         chap-end
;;         verse-start
;;         verse-end)
;;        (and (scrip-ref book-sym
;;                        chap-start
;;                        verse-start
;;                        chap-end
;;                        verse-end
;;                        filename)
;;             (or (and (<= chap-start cnum)
;;                      (>= chap-end cnum)
;;                      (<= verse-start vnum)
;;                      (>= verse-end vnum))
;;                 (and (= chap-start cnum)
;;                      (= chap-end 0)
;;                      (= verse-start vnum)
;;                      (= verse-end 0)))))


;; (with-html
;;   (:li
;;    (:a :href (str:concat "/resource/"
;;                          (pathname-name filename))
;;        (section-res-title filename)
;;        (let ((parents '()))
;;          (handler-case
;;              (nlet recur ((cur filename))
;;                (multiple-value-bind (parent title)
;;                    (any (parent title)
;;                         s.t. (and (section-parent cur parent)
;;                                   (section-title parent title)))
;;                  (unless (str:emptyp title)
;;                    (setf parents (cons title parents)))
;;                  (recur parent)))
;;            (ap5:no-data () '()))
;;          (when parents
;;            (princ " - " *html*))
;;          (loop for parent in parents
;;                do (format *html* "~a|" parent))
;;          (any (title) s.t. (section-title filename title))))))
