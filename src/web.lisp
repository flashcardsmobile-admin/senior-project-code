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


(defroute ("/node/:book") ()
  (with-page ()
    (jweb.views::node-explorer
     (map 'vector
          #'cl-binary-store:restore
          (jweb.ref-tree::get-book-node
           (num-to-bcv-book (or (ignore-errors
                                 (parse-integer
                                  (get-req-item :book
                                                params)))
                                1)))))))
