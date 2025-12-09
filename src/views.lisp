(in-package :jweb.views)

(clamp::use-syntax :clamp)

(def section-url (section)
  (format nil "/resource/~a"
          (string-or-pathname section)))

(def string-or-pathname (datum)
     (etypecase datum
       (null nil)
       (cons (string-or-pathname (car datum)))
       (string datum)
       (pathname (pathname-name datum))))

(def index (resources versions)
  (with-html
    (:section :class (bs container-fluid row)
	            (:header :class (bs text-center) (:h2 "Select Document to View"))
	            (:div :class (bs col-sm)
		                (:h3 "Bible Versions")
		                (:ul (map [with (version (symbol-name _))
                              (:li (:a :href (str:concat "/bible/" version)
                                       version))]
                              versions)))
              (:div :class (bs col-sm)
                    (:h3 "Other Documents")
                    (:ul (map [destructuring-bind (title section) _
                              (:li (:a :href (section-url section) title))]
                              resources))))))

(def render-bible (version text book chapter)
  (with-html
    (:div :class (bs container)
		      (:h1 (jweb.bibles:num-to-name book))
          (:h2 ("Chapter ~a" chapter))
          (:ol (on verse (funcall text book chapter)
                 (:li :id (write-to-string index)
                      :hx-target "this"
                      :hx-swap "afterend"
                      :hx-trigger "click once"
                      :hx-get (str:concat "/refs/"
                                          (write-to-string book)
                                          "/"
                                          (write-to-string chapter)
                                          "/"
                                          (write-to-string (1+ index)))
                      verse)))
          (:div :class (bs row)
                (if (> chapter 1)
                    (:a :class (bs col btn btn-secondary)
                        :href (format nil "/bible/~a/~a/~a" version book (1- chapter))
                        "Previous Chapter")
                    (:span :class (bs col)))
                (:span :class (bs col))
                (if (< chapter (jweb.bibles:num-to-chapters book))
                    (:a :class (bs col btn btn-secondary)
                        :href (format nil "/bible/~a/~a/~a" version book (1+ chapter))
                        "Next Chapter")
                    (:span :class (bs col)))))))

(def print-tree (tree)
  (with-html
    (if (listp tree)
        (:ul (map [:li (print-tree _)] tree))
        (:p (write-to-string (jweb.model::get-obj-title tree))))))


(def render-ref (ref)
  (with-html (:a :href (format nil "/resource/~a" (pathname-name ref))
                 (jweb.model::section-res-title ref)
                 (t:transduce (t:comp (t:map #'jweb.model::get-obj-title)
                                      (t:filter #'stringp)
                                      (t:filter [not (string= "" _)])
                                      (t:once "")
                                      (t:intersperse " - ")
                                      #'t:flatten)
                              #'t:string
                              (jweb.model::get-section-parents ref)))))

(def refs-to-tree (refs)
  (typecase refs
    null refs
    cons (t:transduce (t:comp #'t:dedup
                              (t:map #'jweb.model::get-section-parents)
                              (t:group-by #'car)
                              (t:map [cons (caar _) (refs-to-tree (mapcar #'cdr _))]))
          #'t:cons
          refs)
    t refs))


(def render-refs (book-num book-sym cnum vnum search)
  (with-html
    (with (refs (sort #'string< (jweb.model::verse-refs book-sym cnum vnum search) #'cdr)
                id (format nil "res~a~a~a" book-sym cnum vnum))
      (:ref-container
       (:nav (:label :for "search"
                     "Search: "
                     (:input :type "search"
                             :name "search"
                             :value search
                             :hx-get (format nil "/refs/~a/~a/~a" book-num cnum vnum)
                             :hx-trigger "input changed delay:500ms, keyup[key=='Enter']"
                             :hx-select (format nil "#~a" id)
                             :hx-target (format nil "#~a" id)))
             (:button :onclick (ps (chain document (query-selector "ref-container") (remove)))
                      "Close"))
       (:ul :id id :style "overflow-y: scroll;max-height: 500px;border-style: solid;margin: 0;padding: 0;"
            (map [:li :style "border-style: solid;list-style: none;"
                 (:a :href (format nil "/resource/~a" (pathname-name (car _))) (cdr _))
                 ] refs))))))

;; (def render-refs (book-sym cnum vnum)
;;   (declare (optimize (speed 0) (safety 3) (debug 3)))
;;   (with-html
;;     (nlet % ((refs (map #'refs-to-tree (jweb.ref-tree:verse-refs book-sym cnum vnum))))
;;       (if (listp refs)
;;           (:ul
;;            (progn (map [:li
;;                        (:p (jweb.model::get-obj-title (if (listp _) (car _) _)))
;;                        (when (listp _) (% (cdr _)))]
;;                        refs
;;                        ;; (refs-to-tree refs)
;;                        )
;;                   ""))))))

;; (with-html
;;   (:ul
;;    (progn (t:transduce (t:comp #'t:dedup
;;                                (t:map [:li (render-ref _)]))
;;                 #'t:for-each
;;                 (jweb.ref-tree:verse-refs book-sym cnum vnum))
;;           ""))
;; (print-tree
;;  (combine-by-car
;;   (jweb.model::group-sections-by-resource-and-category
;;    (jweb.ref-tree:verse-refs book-sym cnum vnum))))

(def combine-by-car (tree)
  (if (or (null tree)
          (every [not (consp _)] tree))
      tree
      (with (groups (make-hash-table :test #'equal) keys)
        (map (fn (sub)
               (let key (if (listp sub) (car sub) sub)
                 (push sub (gethash key groups))
                 (unless (member key keys :test #'equal)
                   (push key keys))))
             tree)
        (= keys (nreverse keys))
        (map (fn (key)
               (let merged-cdrs
                 (combine-by-car
                  (apply #'append
                           (mapcar #'cdr (nreverse (gethash key groups)))))
                 (let len (length merged-cdrs)
                   (if (eq len 1)
                       (list key (first merged-cdrs))
                       (list key merged-cdrs)))))
             keys))))

(def node-explorer (nodes)
  (with-html
    (:ol
     (loop for chap across nodes
           do (:li (:ul (loop for el across chap
                         do (:li (jweb.ref-tree::scrip-ref-start el) "|" (jweb.ref-tree::scrip-ref-end el)
                                 (print-tree (jweb.model::group-sections-by-resource-and-category (jweb.ref-tree::scrip-ref-sections el)))))))))))


(def render-resource (filename)
  (with-html
    (:div :class (bs container)
          (jweb.thml:render-file (print filename)))))

(def render-section-nav (section)
  (awhen (jweb.model::get-section-parent section)
    (with-html
      (:li :class (bs nav-item)
           (:a :class (bs nav-link)
               :href (section-url it)
               "Go up")))))
