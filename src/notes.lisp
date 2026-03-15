(in-package :jweb.notes)


(defvar* (locks hash-table) (make-hash-table :test 'eq :synchronized t))


(defvar* (timeout-seconds fixnum) 5)


(defun* make-note-lock ((file pathname))
  (setf (gethash file locks) (bt:make-lock)))


(define-condition note-lock-frozen (error)
  ((file :initarg :file
         :initform nil
         :type (or null pathname)
         :reader file)
   (timeout :initarg :timeout
            :initform timeout-seconds
            :type fixnum
            :reader timeout))
  (:documentation "The lock on the note couldn't be acquired after the timeout."))

(defmacro with-note-lock (file &body body)
  (let ((lock (gensym))
        (file-sym (gensym)))
    `(*let ((,file-sym pathname ,file)
            (,lock bt:lock (gethash ,file-sym locks)))
       (tagbody
        try-locking
          (restart-case
              (progn
                (handler-case
                    (bt:with-timeout (5)
                      (bt:acquire-lock ,lock t))
                  (bt:timeout ()
                    (signal 'note-lock-frozen :file ,file-sym)))
                (unwind-protect
                     (progn ,@body)
                  (bt:release-lock ,lock)))
            (retry-lock ()
              :report "Retry locking"
              (go try-locking))
            (return-nil ()
              :report "Return NIL"
              '()))))))


(defmacro node (file book chapter verse)
  `(aref (cl-binary-store:restore ,file) ,book ,chapter ,verse))


(defun* (query-notes -> list) ((file pathname) (book fixnum) (chapter fixnum) (verse fixnum))
  (with-note-lock file
    (node file book chapter verse)))


(defun* add-note ((file pathname) (book fixnum) (chapter fixnum) (verse fixnum) (note string))
  (with-note-lock file
    (let ((notes (cl-binary-store:restore file)))
      (cl-binary-store:store file (modf (cdr (last (aref notes book chapter verse)))
                                        (cons note nil))))))


(defun* make-note-file ((file pathname))
  (make-note-lock file)
  (with-note-lock file
    (cl-binary-store:store file (make-array '(66 150 176)
                                             :element-type 'list
                                             :initial-element '()))))
