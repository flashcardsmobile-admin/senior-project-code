(in-package :jweb.thml)

(defun render-file (filename)
  ;; Ignore errors to prevent 404's from breaking the server.
  ;; (ignore-errors
   (mapcar #'render (cl-binary-store:restore filename))
  ;; )
  "")

(defun ht-to-plist (ht)
  (t:transduce
   #'t:uncons
   #'t:cons
   ht))

(defun get-attrs (exp)
  (mapcar (lambda (el)
            (etypecase el
              (symbol el)
              (string (intern el "KEYWORD"))))
          (ht-to-plist (cdr (assoc :attrs (cdr exp))))))

(defun get-children (exp)
  (cdr (assoc :children (cdr exp))))

(defun get-filename (exp)
  (cdr (assoc :filename (cdr exp))))

(defun get-name (exp)
  (cdr (assoc :tag-name (cdr exp))))

(defun render-div (exp)
  (*let ((section pathname (get-filename exp))
         ;; (name string (pathname-name section))
         )
    (spinneret:with-html (:div :attrs (get-attrs exp)
                               (render-file section)))
    ;; (with-html
    ;;   (:div :attrs (get-attrs exp)
    ;;         :hx-get (format nil "/resource/~a/noheader" name)
    ;;         :hx-swap "innerHTML"
    ;;         :hx-trigger "load"

    ;;         ;; Fallback
    ;;         (:a :href (format nil "/resource/~a" name)
    ;;             (get-section-title section))))
    ))

(defun render-scrip-refs (exp)
  (labels ((render-ref (ref)
             (destructuring-bind (book chapter verse &rest _) ref
               (aif (jweb.bibles::bcv-book-to-num (intern book "KEYWORD"))
                    (let ((href (str:concat "/bible/" "KJV"
                                            "/" (write-to-string it)
                                            "/" chapter)))
                      (spinneret:with-html
                          (:a :href href
                              :attrs (get-attrs exp)
                              (mapcar #'render (get-children exp)))))
                    (spinneret:with-html
                        (:p (mapcar #'render (get-children exp))))))))
    (let ((refs (cdr (assoc :refs (cdr exp)))))
      (typecase (car refs)
        (list (mapcar #'render-ref refs))
        (t (render-ref refs))))))

(defun render-tag (exp)
  (let ((tag-name (get-name exp)))
    (handler-case
        (spinneret:with-html
            (:tag :name tag-name
                  :attrs (get-attrs exp)
                  (mapcar #'render (get-children exp))))
      (spinneret:no-such-tag ()
        (let ((spinneret::*unvalidated-attribute-prefixes* '("thml-")))
          (spinneret:with-html (:tag :name (str:concat "thml-" tag-name)
                                     :attrs (get-attrs exp)
                                     (mapcar #'render (get-children exp)))))))))

(defun* render ((exp (or string list)))
  (typecase exp
    (string (princ exp spinneret:*html*))
    (t (case (car exp)
         (:div (render-div exp))
         (:scrip-refs (render-scrip-refs exp))
         (:tag (render-tag exp))))))
