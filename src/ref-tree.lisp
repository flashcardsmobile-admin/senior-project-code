(in-package :jweb.ref-tree)

(defmacro awhen (test &body body)
  `(let ((it ,test))
     (when it
       ,@body)))

;;; Node types.
;; These can be mapped 1-1.
(deftype node () '(vector pathname))

;; If range extends to the prior or next, use most-positive-fixnum and most-negative-fixnum.
(defstruct scrip-ref
  "A tree node for a particular verse range."
  (start 0 :type fixnum)
  (end 0 :type fixnum)
  (sections #() :type (vector pathname)))

(defparameter* (books (vector pathname))
    (map 'vector
         (lambda* ((book symbol))
           (asdf:system-relative-pathname :jweb (str:concat "refs/" (symbol-name book))))
         jweb::bcv-names)
    "The list of files that contain scripture references.")

(defparameter* (block-size fixnum) 512
    "The block size of the disk.")

(defun* (process-chapter -> pathname) ((book-symbol symbol) (i fixnum))
  (*let ((chapter-filename pathname (asdf:system-relative-pathname
                                     :jweb
                                     (str:concat "refs/" (symbol-name book-symbol)
                                                 ":" (write-to-string (1+ i)))))
         (chapter-node (vector scrip-ref) (make-array 0 :element-type 'scrip-ref
                                                        :adjustable t
                                                        :fill-pointer t)))
    (store chapter-filename chapter-node)))

(defun* (process-book -> pathname) ((book pathname) (i fixnum))
  (*let ((chapters fixnum (jweb::num-to-chapters i))
         (book-symbol symbol (aref jweb::bcv-names (1- i)))
         (book-filename pathname (asdf:system-relative-pathname
                                  :jweb
                                  (str:concat "refs/" (symbol-name book-symbol))))
         (book-node node (make-array chapters
                                     :element-type 'pathname
                                     :adjustable nil
                                     :fill-pointer nil)))
    (loop for i from 0 to (1- chapters)
          do (setf (aref book-node i)
                   (process-chapter book-symbol i)))
    (store book-filename book-node)))

(defun* (initialize-files -> null) ()
  (loop for book across books
        counting book into i
        do (process-book book i)))

(defun* array-member (item (arr array) &key ((test function) #'eql))
  (loop for i across array
        when (funcall test i item)
          return i))

(defun* (get-book-node -> node) ((book symbol))
  (restore (asdf:system-relative-pathname
            :jweb
            (str:concat "refs/" (symbol-name book)))))

(defun* (get-chapter-node -> (vector scrip-ref)) ((book-node node) (chapter fixnum))
  (restore (aref book-node chapter)))

(defun* (ref-p -> (or pathname null)) ((book symbol)
                                       (chapter-start fixnum) (verse-start fixnum)
                                       (chapter-end fixnum) (verse-end fixnum)
                                       (ref-path pathname))
  "Check if a reference exists exactly in the tree."
  (*let ((book-node node (get-book-node book))
         (chapter-start fixnum (1- chapter-start))
         (chapter-end fixnum (1- chapter-end)))
    (labels* (((find-ref -> (or pathname null)) ((chapter (vector scrip-ref))
                                                 (verse-start fixnum)
                                                 (verse-end fixnum))
               (loop for ref across chapter
                     when (and (eq verse-start (scrip-ref-start ref))
                               (eq verse-end (scrip-ref-end ref))
                               (array-member ref-path (scrip-ref-sections ref)))
                       return ref))
              ((get-chapter -> (vector scrip-ref)) ((chapter fixnum))
               (get-chapter-node book-node chapter)))
      (if (= chapter-end -1)
          (find-ref (get-chapter chapter-start)
                    verse-start
                    verse-end)
          (nlet process-chapter ((chapter fixnum chapter-start))
            (cond ((= chapter chapter-start)
                   (when (find-ref (get-chapter chapter)
                                   verse-start
                                   most-positive-fixnum)
                     (process-chapter (1+ chapter))))
                  ((= chapter chapter-end)
                   (find-ref (get-chapter chapter)
                             most-negative-fixnum
                             verse-end))
                  (t (when (find-ref (get-chapter chapter)
                                     most-negative-fixnum
                                     most-positive-fixnum)
                       (process-chapter (1+ chapter))))))))))

(defun* (get-ref -> (or (vector pathname) null)) ((book symbol)
                                                  (chapter-start fixnum) (verse-start fixnum)
                                                  (chapter-end fixnum) (verse-end fixnum))
  "Grab a reference by verses."
  (when (loop for i across books
              when (eq i book)
                return t)
    (*let ((book-node node (get-book-node book))
           (chapter-start fixnum (1- chapter-start))
           (chapter-end fixnum (1- chapter-end))
           (retval (vector pathname) (make-array 0 :element-type 'pathname :adjustable t :fill-pointer t)))
      (when (= verse-end 0)
        (setf verse-end verse-start))
      (labels* (((get-ref -> (or (vector pathname) null)) ((cnode (vector scrip-ref))
                                                           (vstart fixnum)
                                                           (vend fixnum))
                 (loop for ref across cnode
                       when (and (= (scrip-ref-start ref) vstart)
                                 (= (scrip-ref-end ref) vend))
                         return (scrip-ref-sections ref))))
        (if (or (= chapter-end -1))
            (get-ref (get-chapter-node book-node chapter-start)
                     verse-start
                     verse-end)
            (nlet process-chapter ((chapter fixnum chapter-start))
              (cond ((= chapter chapter-start)
                     (awhen (get-ref (get-chapter-node book-node chapter)
                                     verse-start
                                     most-positive-fixnum)
                       (loop for i across it
                             do (vector-push-extend i retval))
                       (process-chapter (1+ chapter))))
                    ((= chapter chapter-end)
                     (awhen (get-ref (get-chapter-node book-node chapter)
                                     most-negative-fixnum
                                     verse-end)
                       (loop for i across it
                             do (vector-push-extend i retval))))
                    ((> chapter chapter-end)
                     nil)
                    (t (awhen (get-ref (get-chapter-node book-node chapter)
                                       most-negative-fixnum
                                       most-positive-fixnum)
                         (loop for i across it
                               do (vector-push-extend i retval))
                         (process-chapter (1+ chapter)))))))))))

(defun* (insert-ref -> pathname) ((book-node node)
                                  (chapter-num fixnum)
                                  (verse-start fixnum)
                                  (verse-end fixnum)
                                  (ref pathname))
  (when (= verse-end 0)
    (setf verse-end verse-start))
  (*let ((chapter (vector scrip-ref) (get-chapter-node book-node chapter-num)))
    (loop for scrip-ref across chapter
          when (and (= (scrip-ref-start scrip-ref)
                       verse-start)
                    (= (scrip-ref-end scrip-ref)
                       verse-end))
            return (vector-push-extend ref (scrip-ref-sections scrip-ref))
          finally
             (vector-push-extend (make-scrip-ref :start verse-start
                                                 :end verse-end
                                                 :sections (make-array 1 :element-type 'pathname
                                                                         :initial-element ref
                                                                         :adjustable t
                                                                         :fill-pointer t))
                                 chapter))
    (store (aref book-node chapter-num) chapter)))

(defun* (add-ref -> pathname) ((book symbol)
                               (chapter-start fixnum) (verse-start fixnum)
                               (chapter-end fixnum) (verse-end fixnum)
                               (ref pathname))
  "Add a reference to the tree."
  (declare (optimize (debug 0) (speed 3) (space 3)))
  (*let ((book-node node (get-book-node book))
         (chapter-start fixnum (1- chapter-start))
         (chapter-end fixnum (1- chapter-end)))
    (if (or (= chapter-end -1) (= chapter-end chapter-start))
        (progn
          (insert-ref book-node
                      chapter-start
                      verse-start
                      verse-end
                      ref))
        (nlet insert-chapter ((chapter fixnum chapter-start))
          (cond ((and (= chapter chapter-start) (= chapter chapter-end))
                 (insert-ref book-node
                             chapter
                             verse-start
                             verse-end
                             ref))
                ((= chapter chapter-start)
                 (insert-ref book-node
                             chapter
                             verse-start
                             most-positive-fixnum
                             ref)
                 (insert-chapter (1+ chapter)))
                ((= chapter chapter-end)
                 (insert-ref book-node
                             chapter
                             most-negative-fixnum
                             verse-end
                             ref))
                ((> chapter chapter-end) nil)
                ((< chapter chapter-start)
                 (insert-chapter (1+ chapter)))
                (t (insert-ref book-node
                               chapter
                               most-negative-fixnum
                               most-positive-fixnum
                               ref)
                   (insert-chapter (1+ chapter))))))))

(defun* (verse-refs -> (vector pathname)) ((book symbol) (chapter fixnum) (verse fixnum))
  "Map a verse to all references that cover it."
  (*let ((book node (get-book-node book))
         (chapter fixnum (1- chapter)))
    ;; Transducers just fit better here.
    (t:transduce (t:comp (t:filter (lambda (ref)
                                     (and (<= (scrip-ref-start ref) verse)
                                          (>= (scrip-ref-end ref) verse))))
                         (t:map (lambda (ref)
                                  (format t "Ref: <~a - ~a> | ~a | ~a~%"
                                          (scrip-ref-start ref)
                                          (scrip-ref-end ref)
                                          (scrip-ref-sections ref)
                                          verse)
                                  ref))
                         (t:map #'scrip-ref-sections)
                         #'t:flatten)
                 #'t:vector
                 (get-chapter-node book chapter))))

(defun view-book-node (book)
  (get-book-node book))

(defun view-chapter-node (book chapter)
  (get-chapter-node book chapter))
