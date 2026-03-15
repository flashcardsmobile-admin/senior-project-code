(in-package :jweb)


(defun* (string-or-pathname -> string) ((thing (or pathname string cons)))
  (etypecase thing
    (cons (string-or-pathname (car thing)))
    (string thing)
    (pathname (pathname-name thing))))


;; Come and take it.
(deftag marquee (body attrs &key)
  `(:span (:raw "<marquee>")
	  ,@body
	  (:raw "</marquee>")))


(defroute ("/") ()
  (with-page () (jweb.views::index (get-resources) versions)))


(defroute ("/bible/:version") ()
  (rdr-to (format nil "/bible/~a/1" (get-req-item :version params))))


(defroute ("/bible/:version/:book") ()
  (rdr-to (format nil "/bible/~a/~a/1"
                  (get-req-item :version params)
                  (get-req-item :book params))))


(defroute ("/bible/:version/:book/:chapter") ()
  (*let ((version string (str:upcase (get-req-item :version params)))
         (text (or function null) (get-bible (intern version "KEYWORD")))
	       (book fixnum (or (ignore-errors (parse-integer (get-req-item :book params))) 1))
         (book-sym (or symbol null) (num-to-bcv-book book))
         (chapter fixnum (or (ignore-errors (parse-integer (get-req-item :chapter params))) 1)))
    (if (or (null text) (null book-sym))
        (not-found)
        (with-page (:title (format nil "~a - ~a" (num-to-name book) version)
			              :nav-items ((book-list version book)
				                        (chapters-list version book)
				                        (version-list version book chapter)))
          (jweb.views::render-bible version text book chapter)))))


(defroute ("/refs/:book/:chapter/:verse") ()
  (*let ((book-num (ignore-errors (parse-integer (get-req-item :book params))))
         (book-sym (or symbol null) (num-to-bcv-book book-num))
         (cnum (or null fixnum) (ignore-errors (parse-integer (get-req-item :chapter params))))
         (vnum (or null fixnum) (ignore-errors (parse-integer (get-req-item :verse params))))
         (search (or null string) (ignore-errors (get-req-item "search" params))))
    (if (or (null cnum) (null vnum))
        (not-found)
        (with-html-stream
          (jweb.views::render-refs book-num book-sym cnum vnum search)))))


(defroute ("/resource/:name") ()
  (*let ((name string (get-req-item :name params))
         (filename pathname (merge-pathnames name (jweb.thml::thml-options-processed-dir
                                                   jweb.thml::thml-options)))
         (title string (section-res-title filename)))
    (with-page (:title title
                :nav-items ((jweb.views::render-section-nav filename))
                ;; ((handler-case
                ;;      (with-html
                ;;        (:li :class (bs nav-item)
                ;;             (:a :href (format nil "/resource/~a"
                ;;                               (string-or-pathname (get-section-parent filename)))
                ;;                 :class (bs nav-link)
                ;;                 "Go Up")))
                ;;    (ap5:no-data () '())))
                )
      (jweb.views::render-resource filename))))


;; (defroute ("/resource/:name/noheader") ()
;;   (*let ((name string (get-req-item :name params))
;;          (filename pathname
;;                    (merge-pathnames
;;                     name
;;                     (jweb.thml::thml-options-processed-dir
;;                      jweb.thml::thml-options))))
;;     (with-html-stream
;;       (jweb.views::render-resource filename))))


;; (defroute ("/node/:book") ()
;;   (with-page ()
;;     (jweb.views::node-explorer
;;      (map 'vector
;;           #'cl-binary-store:restore
;;           (jweb.ref-tree::get-book-node
;;            (num-to-bcv-book (or (ignore-errors
;;                                  (parse-integer
;;                                   (get-req-item :book
;;                                                 params)))
;;                                 1)))))))

(defroute ("/login" :method :GET) ()
  (with-page ()
    (jweb.views::login)))

(defroute ("/login" :method :POST) ()
  (*let ((email string (get-req-item "email" params))
         (password string (get-req-item "password" params))
         (user (or string null)
               (ap5:theonly user s.t. (jweb.model::user-email user email) ifnone nil)))
        (if (and user (ironclad:pbkdf2-check-password
                       (ironclad:ascii-string-to-byte-array password)
                       (ap5:theonly password s.t. (jweb.model::user-password user password))))
            (progn (setf (jweb.framework::cur-user) user)
                   (rdr-to "/"))
            (rdr-to "/login"))))

(defroute ("/register" :method :GET) ()
  (with-page ()
    (jweb.views::register)))


;; TODO: Add message flashing somehow.
(defroute ("/register" :method :POST) ()
  (*let ((email string (get-req-item "email" params))
         (password string (get-req-item "password" params))
         (confirm-password string (get-req-item "confirm-password" params)))
    (block nil
      (tagbody
         (unless (string= password confirm-password)
           (go fail))
         (when (theonly user s.t. (jweb.model::user-email user email) ifnone nil)
           (go fail))
         ;; Validate actual email.
         (*let ((uid string (fuuid:to-string (fuuid:make-v4)))
                (notes pathname (asdf:system-relative-pathname
                                 :jweb
                                 (make-pathname :directory '(:relative "notes")
                                                :name uid))))
           (ap5:atomic
            (++ jweb.model::user uid)
            (++ jweb.model::user-email uid email)
            (++ jweb.model::user-password uid
                (ironclad:pbkdf2-hash-password-to-combined-string
                 (ironclad:ascii-string-to-byte-array password))))
           (setf (jweb.framework::cur-user) uid)
           (return (rdr-to "/")))
       fail
         (rdr-to "/register")))))

(defroute ("/logout" :method :POST) (#'jweb.framework::auth-or-bail)
  (setf (jweb.framework::cur-user) nil)
  (rdr-to "/"))


(defroute ("/notes/:book/:chapter/:verse") (#'jweb.framework::auth-or-bail)
  (*let ((book fixnum (parse-integer (get-req-item :book params)))
         (chapter fixnum (parse-integer (get-req-item :chapter params)))
         (verse fixnum (parse-integer (get-req-item :verse params)))
         (user string (jweb.framework::cur-user)))
    (with-html-stream
      (jweb.views::show-notes book chapter verse user))))

(defroute ("/notes/:book/:chapter/:verse/compose" :method :GET) (#'jweb.framework::auth-or-bail)
  (*let ((book string (get-req-item :book params))
         (chapter string (get-req-item :chapter params))
         (verse string (get-req-item :verse params)))
    (with-html-stream
      (jweb.views::compose-note book chapter verse))))

(defroute ("/notes/:book/:chapter/:verse/compose" :method :POST) (#'jweb.framework::auth-or-bail)
  (*let ((book fixnum (parse-integer (get-req-item :book params)))
         (chapter fixnum (parse-integer (get-req-item :chapter params)))
         (verse fixnum (parse-integer (get-req-item :verse params)))
         (note string (get-req-item "note" params))
         (user string (jweb.framework::cur-user)))
    (unless (str:emptyp note)
      (atomic
       (let ((note-id (fuuid:to-string (fuuid:make-v4))))
         (++ jweb.model::note note-id)
         (++ jweb.model::note-text note-id note)
         (++ jweb.model::user-note user book chapter verse note-id))))
    (rdr-to (format nil "/notes/~a/~a/~a" book chapter verse))))

(defroute ("/notes/:book/:chapter/:verse/:note/delete" :method :POST) (#'jweb.framework::auth-or-bail)
  (*let ((book fixnum (parse-integer (get-req-item :book params)))
         (chapter fixnum (parse-integer (get-req-item :chapter params)))
         (verse fixnum (parse-integer (get-req-item :verse params)))
         (note string (get-req-item :note params))
         (user string (jweb.framework::cur-user)))
    (atomic
     (-- jweb.model::note-text note (theonly
                                     text s.t.
                                     (jweb.model::user-note-text
                                      user
                                      book chapter verse
                                      text)))
     (-- jweb.model::user-note user book chapter verse note)
     (-- jweb.model::note note))
    ""))

(defroute ("/settings") (#'jweb.framework::auth-or-bail)
  (*let ((user string (jweb.framework::cur-user)))
    (with-page (:title "Settings") (jweb.views::settings user))))

(defroute ("/settings/target" :method :POST) (#'jweb.framework::auth-or-bail)
  (atomic
   (*let ((user string (jweb.framework::cur-user))
          (cur-target jweb.model::target
                      (theonly target s.t. (jweb.model::user-target user target) ifnone :new-tab))
          (new-target jweb.model::target
                      (let ((target (get-req-item "target" params)))
                        (cond ((string= target "new-tab") :new-tab)
                              ((string= target "side-frame") :side-frame)
                              ((string= target "float-frame") :float-frame)
                              ((string= target "popup") :popup)
                              (t (error "Invalid target: ~a" target))))))
     (-- jweb.model::user-target user cur-target)
     (++ jweb.model::user-target user new-target)))
  (rdr-to "/settings"))

(defroute ("/settings/dark-mode" :method :POST) (#'jweb.framework::auth-or-bail)
  (atomic
   (*let ((user string (jweb.framework::cur-user))
          (cur-mode boolean (theonly mode s.t. (jweb.model::user-dark-mode user mode) ifnone nil))
          (new-mode boolean (when (get-req-item "dark-mode" params) t)))
         (-- jweb.model::user-dark-mode user cur-mode)
         (++ jweb.model::user-dark-mode user new-mode)))
  (rdr-to "/settings"))

(defroute ("/default-iframe-page") ()
  (with-page (:hide-banner t) (:h1 "Documents will be loaded into this frame.")))
