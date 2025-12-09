(in-package :jweb.thml)

(defstruct thml-options
  (processed-dir (asdf:system-relative-pathname :jweb "compiled-resources/"))
  (source-dir (asdf:system-relative-pathname :jweb "resources/")))


;; (defrelation resource-scrip-refs
;;   :definition ((source-file book chapter-start verse-start chapter-end verse-end compiled-file)
;;                s.t. (and (resource source-file)
;;                          (section compiled-file)
;;                          (scrip-ref book
;;                                     chapter-start verse-start
;;                                     chapter-end verse-end
;;                                     compiled-file)
;;                          (resource-sections source-file compiled-file))))

(atomic (defcategories '((commentary . "Commentary")
                         (ante-nicene-fathers . "Ante-Nicene Fathers")
                         (post-nicene-fathers . "Post-Nicene Fathers")))
        (defresources (comptime
                        (with-open-file (s (asdf:system-relative-pathname
                                            :jweb
                                            "src/resources.lisp"))
                          (read s)))))

(defparameter* (thml-options thml-options) (make-thml-options))

(defparameter* (current-section pathname) #P"")

(defparameter* (source-file pathname) #P"")

(defparameter* (current-header string) "")

(defun* get-document ((source-name pathname))
  (pl:parse (alexandria:read-file-into-string source-name)))

(defun* (get-tag -> (or pl:node null)) ((node pl:node) (name string))
  (car (pl:get-elements-by-tag-name node name)))

(defun* (get-title -> pl:node) ((node pl:node))
  (or (get-tag node "title")
      (get-tag node "DC.Title")))

(defun* (get-head -> pl:node) ((document pl:node))
  (or (get-tag document "ThML.head")
      (error "ThML.head is missing!")))

(defun* (get-body -> pl:node) ((document pl:node))
  (or (get-tag document "ThML.body")
      (error "ThML.body is missing!")))

(defun* (process-scrip-ref -> list) ((node pl:node))
  (aif (gethash "parsed" (pl:attributes node))
    (let ((refs (str:split "[;,]" it :omit-nulls t :regex t)))
      (loop for ref in refs
            collect (let ((ref (str:split #\| ref :omit-nulls t))
                          (filename current-section))
                      ;; Trim the version out since that is always user-set.
                      (when (> (length ref) 5) (setf ref (cdr ref)))
                      (destructuring-bind (book chapter-start verse-start chapter-end verse-end) ref
                        ;; TODO: Ensure the book is pared down to the canonical shortened name.
                        (add-scrip-ref (intern book "KEYWORD")
                                       (parse-integer chapter-start)
                                       (parse-integer verse-start)
                                       (parse-integer chapter-end)
                                       (parse-integer verse-end)
                                       filename))
                      ref)))
    ;; TODO: Parse unparsed refs
    (progn (format t "~%Unparsed Reference: ~a~%" (gethash "passage" (pl:attributes node)))
           nil)))

(defun* (recurse-children -> list) ((node pl:node))
  (loop for node across (pl:children node)
        counting node into i
        collecting (node-recurse node i)))

(defun* (new-filename -> pathname) ((i fixnum))
  (merge-pathnames (str:concat (pathname-name current-section)
                               ":"
                               (write-to-string i))
                   (thml-options-processed-dir thml-options)))

(defun* (plain-tag -> list) ((node pl:node))
  (list :tag
        (cons :tag-name (pl:tag-name node))
        (cons :attrs (pl:attributes node))
        (cons :children (recurse-children node))))

(defun* (node-recurse -> (or list string)) ((node pl:node) (i fixnum))
  (cond ((pl:comment-p node) '())
        ((pl:text-node-p node)
         (pl:text node))
        ((str:starts-with-p "DIV" (str:upcase (pl:tag-name node)))
         (let ((prior-section current-section)
               (current-section (new-filename i))
               (current-header ""))
           (atomic
            (add-cur-section current-section source-file prior-section)
            (break-sections node)
            (set-section-title current-section current-header))
           (list :div
                 (cons :attrs (pl:attributes node))
                 (cons :filename current-section))))
        ((string= (str:upcase (pl:tag-name node)) "SCRIPREF")
         (list :scrip-refs
               (cons :refs (process-scrip-ref node))
               (cons :attrs (pl:attributes node))
               (cons :children (recurse-children node))))
        ((and (str:starts-with-p "H" (str:upcase (pl:tag-name node)))
              (= (length (pl:tag-name node)) 2))
         (if (string= current-header "")
             (setf current-header (pl:text node))
             (setf current-header (str:concat current-header " "
                                              (pl:text node))))
         (plain-tag node))
        (t (plain-tag node))))

(defun* (break-sections -> pathname) ((parent pl:node))
  (let ((section-nodes (pl:children parent)))
    (cl-binary-store:store
     current-section
     (loop for node across section-nodes
           counting node into i
           ;; Names of things should be in the ThML specification on CCEL.
           collect (node-recurse node i))))
  current-section)

(defun* process-document ((name pathname))
  (*let ((current-section pathname (merge-pathnames (pathname-name name) (thml-options-processed-dir thml-options)))
         (source-file pathname (merge-pathnames name (thml-options-source-dir thml-options)))
         (document pl:node (get-document source-file))
         (body pl:node (get-body document))
         (head pl:node (get-head document))
         (title string (pl:text (get-title head)))
         (current-header string ""))
    (atomic
     (create-resource source-file title)
     (add-cur-section current-section source-file)
     (break-sections body)
     (set-section-title current-section current-header)
     (set-resource-prim-section source-file current-section)
     (jweb.model::find-and-set-resource-category name source-file))
    source-file))

(defun* (load-standard-docs -> null) ()
  (ref-tree::initialize-files)
  (withwriteaccess
    (map-over-pre-resources #'process-document)))

;; (defvar loaded-docs (progn (load-standard-docs) t))
