(in-package :jweb.lang-verses)


(defun* (lang-verse -> string) ((book symbol) (chapter fixnum) (verse fixnum))
  (if (> (bcv-book-to-num book) 39)
      (greek-verse book chapter verse)
      (hebrew-verse book chapter verse)))

(defun* (greek-verse-query -> string) ((book symbol) (chapter fixnum) (verse fixnum))
  (format nil "B~2,DK~DV~D" (bcv-book-to-num book) chapter verse))

(defun* (greek-file -> string) ()
  (alexandria:read-file-into-string
   (asdf:system-relative-pathname :jweb
                                  "bibles/sblgnt_tei_capitains.xml")))

(defun* (nth-el -> pl:element) ((el pl:node) (n fixnum))
  (aref (pl:child-elements el) n))

(defun* (nth-node -> pl:node) ((el pl:node) (n fixnum))
  (aref (pl:children el) n))

(defvar* (greek-bible (vector pl:node))
    (pl:child-elements (nth-el (nth-el (nth-el (pl:parse (greek-file)) 0) 1) 0)))

(defun* (greek-verse -> string) ((book symbol) (chapter fixnum) (verse fixnum))
  (*let ((book-num fixnum (- (bcv-book-to-num book) 39)))
    (t:transduce (t:comp (t:filter (lambda* ((el pl:element))
                                     (string= (xml-id el)
                                              (format nil "B~2,'0D" book-num))))
                         (t:map #'pl:child-elements)
                         #'t:flatten
                         (t:filter (lambda (el)
                                     (string= (xml-id el)
                                              (format nil "B~2,'0DK~D"
                                                      book-num
                                                      chapter))))
                         (t:map #'pl:child-elements)
                         #'t:flatten
                         (t:filter (lambda (el)
                                     (string= (xml-id el)
                                              (format nil "B~2,'0DK~DV~D"
                                                      book-num
                                                      chapter
                                                      verse))))
                         (t:map #'pl:child-elements)
                         #'t:flatten
                         (t:map #'pl:child-elements)
                         #'t:flatten
                         (t:map (lambda (el)
                                  (if (string= (pl:tag-name el) "app")
                                      (car (pl:get-elements-by-tag-name el "w"))
                                      el)))
                         (t:map #'pl:text)
                         (t:intersperse " ")
                         #'t:flatten)
                 #'t:string
                 greek-bible)))

(defun* (xml-id -> string) ((el pl:element))
  (gethash "xml:id" (pl:attributes el) ""))

(defun* (hebrew-book -> (vector pl:node)) ((book pathname))
  (pl:child-elements (nth-el (nth-el (nth-el (pl:parse book) 0) 1) 0)))

(defun* (hebrew-verse -> string) ((book symbol) (chapter fixnum) (verse fixnum))
  (*let ((book-num fixnum (bcv-book-to-num book))
         (book-file pathname (jweb.bibles::num-to-tnch-file book-num)))
    (t:transduce (t:comp
                  (t:filter (fn+ (fn~ #'string= "c") #'pl:tag-name))
                  (t:filter (fn+ (fn~ #'= chapter)
                                 #'parse-integer
                                 (fn~r #'pl:attribute "n")))
                  (t:map #'pl:children)
                  #'t:flatten
                  (t:filter #'pl:element-p)
                  (t:filter (fn+ (fn~ #'string= "v") #'pl:tag-name))
                  (t:filter (fn+ (fn~ #'= verse)
                                 #'parse-integer
                                 (fn~r #'pl:attribute "n")))
                  (t:map #'pl:children)
                  #'t:flatten
                  (t:map #'pl:text)
                  #'t:flatten)
                 #'t:string
                 (hebrew-book book-file))))
