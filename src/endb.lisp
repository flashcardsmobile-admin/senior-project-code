(in-package :jweb.endb)

(defparameter endb-uri "http://10.10.10.2:3803/sql")

(defun arr1st (arr)
  (unless (< (length arr) 1)
    (aref arr 0)))

(defun create-query-content (query params)
  (let ((ht (make-hash-table)))
    (setf (gethash "q" ht) query)
    (setf (gethash "p" ht) params)
    (jzon:stringify ht)))

(defun endb (query &optional params)
  (let ((query (yield query))
        (content-type (if params "application/json" "application/sql")))
    (jzon:parse (handler-bind ((dexador.error::http-request-bad-request
                                 (lambda (c)
                                   ;; (format t "DB Error: ~a" c)
                                   (return-from endb))))
                  (dex:post endb-uri
                            :headers `(("Content-Type" . ,content-type))
                            :content (if params
                                         (create-query-content query params)
                                         query))))))

(defun add-ref (&key book
                  chapter-start verse-start
                  chapter-end verse-end
                  ref)
  "Add a reference to this exact chapter/verse span"
  (endb (-> (insert-into :refs)
            (set= :book :?
                  :chapter-start :?
                  :verse-start :?
                  :chapter-end :?
                  :verse-end :?
                  :ref :?)
            ;; If it already is logged, no need to have a duplicate entry.
            (on-conflict-do-nothing '(:book
                                      :chapter-start :verse-start
                                      :chapter-end :verse-end
                                      :ref)))
        (list book chapter-start verse-start chapter-end verse-end ref)))

(defun get-ref (&key book chapter-start verse-start chapter-end verse-end)
  "Get all references for this exact chapter/verse span."
  (endb (-> (select :ref)
            (from :refs)
            (where (:= :book :?))
            (where (:= :chapter-start :?))
            (where (:= :verse-start :?))
            (where (:= :chapter-end :?))
            (where (:= :verse-end :?)))
        (list book chapter-start verse-start chapter-end verse-end)))

(defun get-chapter-refs (&key book chapter-start chapter-end)
  "Get all references between these chapters"
  (endb (-> (select :ref)
            (from :refs)
            (where (:= :book :?))
            (where (:= :chapter-start :?))
            (where (:= :chapter-end :?)))
        (list book chapter-start chapter-end)))

(defun get-verse-refs (&key book chapter verse)
  "Get all references whose span includes this book."
  (endb (-> (select :ref)
            (from :refs)
            (where (:= :book :?))
            (where (:< :chapter-start :?))
            (where (:< :verse-start :?))
            (where (:> :chapter-end :?))
            (where (:> :verse-end :?)))
        (list book chapter verse chapter verse)))


(defun section-p (&key section)
  "Check if something is a defined section."
  (uiop:ensure-pathname
   (arr1st
    (endb (-> (select :path)
            (from :section)
            (where (:= :path :?)))
          (list section)))))

(defun add-section (&key section)
  "Add a new section to the database."
  (endb (-> (insert-into :section)
          (set= :path :?)
          (on-conflict-do-nothing '(:path)))
        (list section)))

(defun delete-section (&key section)
  "Delete a section."
  (endb (-> (delete-from :section)
          (where (:= :path :?)))
        (list section)))

(defun get-section-title (&key section)
  "Get the title of a section."
  (endb (-> (select :title)
          (from :section)
          (where (:= :path :?)))
        (list section)))

(defun set-section-title (&key section title)
  "Set the title of a section."
  (endb (-> (insert-into :section)
            (set= :path :? :title :?)
            (on-conflict-do-update '(:path) (set= :title :?)))
        (list section title section title)))

(defun get-section-parent (&key section)
  "Get the parent of a section."
  (uiop:ensure-pathname
   (arr1st (arr1st
            (endb (-> (select :parent)
                      (from :section)
                      (where (:= :path :?)))
                  (list section))))))

(defun set-section-parent (&key section parent)
  "Set the parent of a section."
  (endb (-> (insert-into :section)
            (set= :path :? :parent :?)
            (on-conflict-do-update '(:path) (set= :parent :?)))
        (list section parent section parent)))
