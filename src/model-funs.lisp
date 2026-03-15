(in-package :jweb.model)

(defun defcategories (categories)
  (atomic (mapcar (lambda (exp)
                    (destructuring-bind (c . ti) exp
                      (++ category c)
                      (++ category-title c ti)))
                  categories)))

(defun defresources (resources)
  (mapcar (lambda (resource)
            (destructuring-bind (resource &key category) resource
              (++ pre-resource resource)
              (when category
                (etypecase category
                  (symbol (++ pre-resource-category resource category))
                  (list (loop for c in category
                              do (++ pre-resource-category resource category)))))))
          resources))

(defun add-scrip-ref (book chapter-start verse-start chapter-end verse-end filename)
  (++ scrip-ref
      book
      chapter-start
      verse-start
      chapter-end
      verse-end
      filename))


(defun get-section-title (section)
  (any (title) s.t. (section-title section title)))

(defun section-res-title (section-path)
  (any (title) s.t. (e (resource section)
                       (and (equal section section-path)
                            (resource-sections resource section)
                            (resource-title resource title)))))

(defun get-section-parent (section)
  )

(defun get-section-parent-title (cur)
  (any (parent title)
       s.t. (and (section-parent cur parent)
                 (section-title parent title))))

(defun get-resources ()
  (listof (title section)
          s.t. (e (resource)
                  (and
                   (resource-title resource title)
                   (resource-prim-section resource section)))))

(defun group-sections-by-resource-and-category (sections)
  ;; (t:transduce (t:comp (t:group-by #'car))
  ;;              #'t:snoc
  ;;                (sort 
                  (t:transduce
                        (t:comp (t:map #'get-section-parents)
                                (t:group-by #'car)
                                (t:map (lambda (group)
                                         (cons (caar group)
                                               (mapcar #'cdr group))))
                                (t:map (lambda (group)
                                         (multiple-value-bind (resource title)
                                             (any resource title
                                                      s.t. (and (resource-sections resource
                                                                                   (car group))
                                                                (resource-title resource
                                                                                title)))
                                           (cons (list resource title) group))))
                                (t:group-by #'caar)
                                ;; (t:map (lambda (group)
                                ;;          (cons (caar group)
                                ;;                (cons (cadar group)
                                ;;                      (mapcar #'cddr group)))))
                                ;; (t:map (lambda (group)
                                ;;          (multiple-value-bind (category title)
                                ;;              (theonly category title
                                ;;                       s.t. (and (resource-category (cadr group) category)
                                ;;                                 (category-title category title))
                                ;;                       ifnone "Uncategorized")
                                ;;            (cons title
                                ;;                  (cons category
                                ;;                        group)))))
                                )
                        #'t:snoc
                        sections)
                       ;; #'string>
                        ;; :key #'car))
  )

(defun get-section-parents (section &optional accum)
  (aif (any parent
            s.t. (section-parent section parent)
            ifnone nil)
       (get-section-parents it (cons section accum))
       (cons section accum)))

(defun get-obj-title (obj)
  (cond ((?? section obj)
         (any title s.t. (section-title obj title)))
        ((?? resource obj)
         (resource-title obj))
        ((?? category obj)
         (category-title obj))
        (t obj)))

(defun get-section-category (section)
  (any category s.t. (e(resource) (and (resource-sections resource section)
                                           (resource-category resource category)))))

(defun get-section-resource (section)
  (any resource s.t. (resource-sections resource section)))

(defun expand-section-parents (section)
  (let ((section-titles (t:transduce (t:comp (t:map
                                              (lambda (section)
                                                (get-obj-title section)))
                                             (t:filter
                                              (lambda (s) (not (str:emptyp s))))
                                             (t:intersperse " - ")
                                             #'t:flatten)
                                     #'t:string
                                     (get-section-parents section))))
  (cons section
        (if section-titles
            (str:concat (section-res-title section)
                        " - "
                        section-titles)
            (section-res-title section)))))

(defun verse-refs (book chapter verse search)
  (t:transduce (t:comp #'t:dedup
                       (t:map
                        (lambda (section)
                          (expand-section-parents section)))
                       ;; (t:filter
                       ;;  (lambda (section)
                       ;;    (not (str:emptyp (any title s.t. (section-title section title))))))
                       (if search
                           (t:filter
                            (lambda (section)
                              (ignore-errors (cl-ppcre:scan (str:upcase search) (str:upcase (cdr section))))))
                           #'t:pass))
               #'t:vector
               (jweb.ref-tree:verse-refs book chapter verse)))

(defun ref-categories (refs)
  (t:transduce (t:filter
                (lambda (category)
                  (loop for ref across refs
                        when (?? e(resource) (and (resource-sections resource ref)
                                                  (resource-category resource category)))
                          return category
                        finally nil)))
               #'t:vector
               refs))
