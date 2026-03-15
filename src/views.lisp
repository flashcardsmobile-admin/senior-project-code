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
	            (:header :class (bs text-center)
                       (:h2 "Select Document to View"))
	            (:div :class (bs col-sm)
		                (:h3 "Bible Versions")
		                (:ul (clamp:map [clamp:with (version (symbol-name _))
                              (:li (:a :href (str:concat "/bible/" version)
                                       version))]
                              versions)))
              (:div :class (bs col-sm)
                    (:h3 "Other Documents")
                    (:ul :is "filter-ul"
                         (clamp:map [destructuring-bind (title section) _
                                    (:li (:a :href (section-url section) title))]
                                    resources))))))

(def float-script (container-id head-id)
  ;; The following is adapted from: https://www.w3schools.com/howto/howto_js_draggable.asp
  (ps (ps:let ((drag-element
                 (lambda (el)
                   (ps:let* ((pos1 0)
                             (pos2 0)
                             (pos3 0)
                             (pos4 0)
                             (close-drag-element
                               (lambda ()
                                 (setf (chain document onmouseup) nil
                                       (chain document onmousemove) nil)
                                 (return)))
                             (element-drag
                               (lambda (e)
                                 (setf e (or e (chain window event)))
                                 (chain e (prevent-default))
                                 (setf pos1 (- pos3 (chain e client-x))
                                       pos2 (- pos4 (chain e client-y))
                                       pos3 (chain e client-x)
                                       pos4 (chain e client-y)
                                       (chain el style top) (+ (- (chain el offset-top) pos2) "px")
                                       (chain el style left) (+ (- (chain el offset-left) pos1) "px"))
                                 (return)))
                             (drag-mouse-down
                               (lambda (e)
                                 (setf e (or e (chain window event)))
                                 (chain e (prevent-default))
                                 (setf pos3 (chain e client-x)
                                       pos4 (chain e client-y)
                                       (chain document onmouseup) close-drag-element
                                       (chain document onmousemove) element-drag)
                                 (return)))))
                   (setf (chain document (get-element-by-id (lisp head-id)) onmousedown) drag-mouse-down)
                   (return))))
        (drag-element (chain document (get-element-by-id (lisp container-id)))))))


(defparameter float-frame
  (ps:ps
   (ps:let* ((con-callback (lambda ()
                             (ps:let ((box (ps:new
                                            (-win-box "Floating Frame"
                                                      (ps:create
                                                       :html (ps:lisp
                                                              (spinneret:with-html-string
                                                                  (:iframe :name :float-frame
                                                                           :src "/default-iframe-page")))
                                                       :x "center"
                                                       :y "center")))))
                               (ps:chain box
                                         (remove-control "wb-close")
                                         (remove-control "wb-max"))))))
     (jweb.framework::setup-custom-el float-frame)
     (setf (ps:@ float-frame prototype connected-callback) con-callback)
     (ps:chain custom-elements (define "float-frame" float-frame)))))

;; (def float-frame ()
;;   (with (head-id (symbol-name (gensym))
;;                  container-id (symbol-name (gensym)))
;;     (with-html
;;       (:div :style "position: absolute; z-index: 9; border: 1px solid;height: 500px;background-color: white;"
;;             :id container-id
;;             (:div :style "padding: 10px; cursor: move; z-index: 10;background-color: lightgrey;color: black;"
;;                   :id head-id
;;                   "Document")
;;             (:iframe :name :float-frame
;;                      :style "height: 100%;"
;;                      :src "/default-iframe-page")
;;             (:script (:raw (float-script container-id head-id)))))))

(def netwarning ()
  (with-html
      (:p "Scripture quoted by permission. "
          "Quotations designated (NET) are from "
          "the NET Bible"
          (:raw "&reg;")
          "copyright "
          (:raw "&copy;")
          "1996, 2019 by "
          "Biblical Studies Press, L.L.C. "
          (:a :href "http://netbible.com" "http://netbible.com ")
          "All rights reserved")))

(def render-bible (version text book chapter)
  (let target (theonly target
                       s.t. (jweb.model::user-target
                             (jweb.framework::cur-user) target)
                       ifnone :new-tab)
    (with-html
      (when (eq target :float-frame)
        (:script :src "/static/winbox.bundle.min.js")
        (:script (:raw float-frame))
        (:float-frame))
      (:div :class (str:concat "container" (when (eq target :side-frame) " row"))
            (:div :class (bs col)
		              (:h1 (jweb.bibles:num-to-name book))
                  (:h2 ("Chapter ~a" chapter))
                  (:style (:raw ".verse:hover { background-color: DarkGray; cursor: pointer; }"))
                  (when (string= version "NET")
                    (netwarning))
                  (:ol :is "filter-ol"
                       (on verse (funcall text book chapter)
                         (let id (symbol-name (gensym))
                           (:li
                            (:a :href (str:concat "/refs/" (write-to-string book)
                                                  "/" (write-to-string chapter)
                                                  "/" (write-to-string (1+ index))
                                                  "#" id)
                                :target "htmz"
                                verse)
                            (:span :class "ref-parent"
                                   :data-id id
                                   (:span :id id))))))
                  (when (string= version "NET")
                    (netwarning))
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
                            (:span :class (bs col)))))
            (when (eq target :side-frame)
              (:iframe :class (bs col)
                       :src "/default-iframe-page"
                       :style "border-style: solid;"
                       :name :side-frame))))))

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
                id (format nil "res~a~a~a" book-sym cnum vnum)
                container-id (symbol-name (gensym))
                notes-id (symbol-name (gensym))
                target (theonly target
                                s.t. (jweb.model::user-target
                                      (jweb.framework::cur-user)
                                      target)
                                ifnone :new-tab))
      (:ref-container
       :id container-id
       (:orig-lang-verse
        (:p (jweb.lang-verses:lang-verse book-sym cnum vnum)))
       (:nav (when (jweb.framework::cur-user)
               (:a :target "htmz"
                   :href (format nil "/notes/~a/~a/~a#~a" book-num cnum vnum notes-id)
                   "Show Notes"))
             (:button :onclick (ps (let* ((new-span (chain document
                                                           (create-element
                                                            "span")))
                                          (ref-container (chain document
                                                                (query-selector
                                                                 (lisp (str:concat
                                                                        "#"
                                                                        container-id)))))
                                          (parent (chain ref-container (closest ".ref-parent"))))
                                     (setf (ps:@ new-span id) (chain parent dataset id))
                                     (chain ref-container (replace-with new-span))))
                      "Close"))
       (:div :class "row"
             (:ul :is "filter-ul"
                  :id id
                  :style "overflow-y: scroll;max-height: 500px;border-style: solid;margin: 0;padding: 0;"
                  :class "col"
                  (map [:li :style "border-style: solid;list-style: none;"
                       (with (link (loop with greatest-link = "#"
                                       for link s.t. (jweb.model::section-ccel (car _) link)
                                       when (> (length link) (length greatest-link))
                                         do (setf greatest-link link)
                                         finally (return greatest-link))
                                   aux-target (when (eq target :popup)
                                                (symbol-name (gensym))))
                             (:a :href link
                                 :target (cond ((eq target :new-tab) "_blank")
                                               ((eq target :popup) aux-target)
                                               (t target))
                                 :onclick (when aux-target
                                            (ps:ps
                                             (ps:chain window
                                                       (open (ps:lisp link)
                                                             (ps:lisp aux-target)
                                                             "width=600,height=600"))))
                                 (cdr _)))
                       ] refs))
             (:span :id notes-id))))))

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

(defun get-components ()
  (ps-compile-file (asdf:system-relative-pathname
                    "jweb"
                    "src/thml-components.lisp")))

(defvar thml-components (get-components))

(defun reload-components ()
  (setf thml-components (get-components)))

(def render-resource (filename)
  (with-html
      (:div :class (bs container)
            (:script (:raw thml-components))
            (jweb.thml:render-file filename))))

(def render-section-nav (section)
  (awhen (any parent
              s.t. (jweb.model::section-parent section parent)
              ifnone nil)
    (with-html
      (:li :class (bs nav-item)
           (:a :class (bs nav-link)
               :href (section-url it)
               "Go up")))))

(def login ()
  (with-html
      (:main :class "container"
             (:header :class "text-center"
                      (:h1 "Login"))
             (:form :action "/login"
                    :method "POST"
                    (:label :class "form-label" :for "email" "Email: "
                            (:input :class "form-control" :name "email" :type "email"))
                    (:br)
                    (:label :class "form-label" :for "password" "Password: "
                            (:input :class "form-control" :name "password" :type "password"))
                    (:br)
                    (:input :class "form-control" :type "submit" :value "Submit")))))

(def register ()
  (with-html
      (:main :class "container"
             (:header :class "text-center"
                      (:h1 "Register"))
             (:form :action "/register"
                    :method "POST"
                    (:label :class "form-label" :for "email" "Email: "
                            (:input :class "form-control" :name "email" :type "email"))
                    (:br)
                    (:label :class "form-label" :for "password" "Password: "
                            (:input :class "form-control" :name "password" :type "password"))
                    (:br)
                    (:label :class "form-label" :for "confirm-password" "Confirm Password: "
                            (:input :class "form-control" :name "confirm-password" :type "password"))
                    (:br)
                    (:input :class "form-control" :type "submit" :value "Submit")))))

(def compose-note (book chapter verse)
  (with-html
    (:form :method "POST"
           :action (format nil "/notes/~a/~a/~a/compose#v~a-~a-~a"
                           book chapter verse
                           book chapter verse)
           :target "htmz"
           (:label :class "form-label" :for "note" "Note: ")
           (:textarea :name "note" :class "form-control" :rows 3)
           (:div :class "row"
                 (:input :class "col" :type "submit" :value "Save")
                 (:a :class "col"
                     :href (format nil "/notes/~a/~a/~a#v~a-~a-~a"
                                   book chapter verse
                                   book chapter verse)
                     :target "htmz"
                     "Cancel")))))

(def show-note (book chapter verse note)
  (with-html
    (let id (symbol-name (gensym))
      (:li :class "row"
           :id id
           (:span :class "col" (theonly text s.t. (jweb.model::note-text note text)))
           (:div :class "col"
                 (:form :action (format nil "/notes/~a/~a/~a/~a/delete#~a" book chapter verse note id)
                        :target "htmz"
                        :method "POST"
                        (:input :type "submit" :value "Delete")))))))

(def show-notes (book chapter verse user)
  (with-html
    (:div :class "notes col"
          :id (format nil "v~a-~a-~a" book chapter verse)
          (atomic
           (if (?? e (note) (jweb.model::user-note user book chapter verse note))
               (:ul :is "filter-ul"
                    (loop for note s.t. (jweb.model::user-note user book chapter verse note)
                          do (show-note book chapter verse note)))
               (:p "No notes on this verse yet.")))
          (let id (gensym)
            (:a :href (format nil "/notes/~a/~a/~a/compose#~a" book chapter verse id)
                :id id
                :target "htmz"
                "Compose New Note")))))

(def settings (user)
  (with (target (ap5::theonly target s.t. (jweb.model::user-target user target) ifnone :new-tab)
                dark-mode (ap5::theonly mode s.t. (jweb.model::user-dark-mode user mode) ifnone nil))
    (with-html
      (:main :class "container"
             (:header (:h1 "Settings"))
             (:form :action "/settings/target"
                    :method "POST"
                    (:label :for "target"
                            "Open CCEL Links in: "
                            (:select :name "target"
                                     :id "target"
                                     (:option :value "new-tab"
                                              :selected (eq target :new-tab)
                                              "New Tab")
                                     (:option :value "side-frame"
                                              :selected (eq target :side-frame)
                                              "Side Frame")
                                     (:option :value "float-frame"
                                              :selected (eq target :float-frame)
                                              "Floating Frame")
                                     (:option :value "popup"
                                              :selected (eq target :popup)
                                              "Popup Window")))
                    (:input :type "submit" :value "Change"))
             (:form :action "/settings/dark-mode"
                    :method "POST"
                    (:label :for "dark-mode"
                            "Dark Mode: "
                            (:input :type "checkbox"
                                    :id "dark-mode"
                                    :name "dark-mode"
                                    :checked dark-mode))
                    (:input :type "submit" :value "Change"))))))
