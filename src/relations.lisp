(in-package :jweb.model)

(eval-when (:compile-toplevel :execute)
  (defun rel-filename (rel-sym)
    (asdf:system-relative-pathname
     "jweb"
     (make-pathname
      :directory '(:relative "db")
      :name (symbol-name rel-sym)))))

(defvar persistence-funs '())

(defmacro persist-rel (relname)
  "Create a persistence chassis for a relation and return an object with
load/save functionality."
  (let ((filename (rel-filename relname)))
    `(setf persistence-funs
           (nconc persistence-funs
                  (list (dlambda
                         (:save () (with-open-file (s ,filename :direction :output :if-exists :supersede)
                                     (print (listof ,relname) s)))
                         (:load () (block nil
                                     (with-open-file (s ,filename)
                                       (set-listof ,relname (read s)))))))))))

(defun load-db-state ()
  (atomic
   (mapcar (lambda (f) (funcall f :load)) persistence-funs)))

(defun save-db-state ()
  (mapcar (lambda (f) (funcall f :save)) persistence-funs)
  '())

(defrelation pre-resource
  :types (pathname))

(persist-rel pre-resource)

(defrelation category
  :types (symbol))

(persist-rel category)

(defrelation category-title
  :types (category string))

(persist-rel category-title)

(defrelation pre-resource-category
  :types (pre-resource category))

(persist-rel pre-resource-category)

;; Indexed by compiled file.
(defrelation section
  :types (pathname))

(persist-rel section)

;; Indexed by source file.
(defrelation resource
  :types (pathname))

(persist-rel resource)

(defrelation resource-category
  :types (resource category))

(persist-rel resource-category)

;; (book chapter-start verse-start chapter-end verse-end compiled-file)
(defrelation scrip-ref
  :representation individual
  :arity 6
  :adder (lambda (&rest ignore)
           (declare (ignore ignore))
           `(lambda (rel book ch-start v-start ch-end v-end file)
              (declare (ignore rel))
              (ignore-errors (ref-tree:add-ref book ch-start v-start ch-end v-end file))))
  :tester (lambda (&rest ignore)
            (declare (ignore ignore))
            `(lambda (rel book ch-start v-start ch-end v-end file)
               (declare (ignore rel))
               (awhen (ignore-errors (ref-tree:get-ref book ch-start v-start ch-end v-end))
                 (loop for ref across it
                       when (eq ref file)
                         return t))))
  :generator ((simpleGenerator
               (book ch-start v-start ch-end v-end output)
               (loop for i across (ref-tree:get-ref book ch-start v-start ch-end v-end)
                     collect i))
              (simpleMultipleGenerator
               (book ch-start output ch-end output output)
               (loop for cnum from ch-start to ch-end
                     with l = nil
                     do (loop for ref across (ref-tree::get-chapter-node (ref-tree::get-book-node book) cnum)
                              do (loop for section across (ref-tree::scrip-ref-sections)
                                       do (setf l (cons (list ref-tree::scrip-ref-start
                                                              ref-tree::scrip-ref-end
                                                              section)
                                                        l))))
                     finally return l))))

(defrelation resource-title
  :types (resource string))

(persist-rel resource-title)

(defrelation resource-sections
  :types (resource section))

(persist-rel resource-sections)

(defrelation resource-prim-section
  :types (resource section))

(persist-rel resource-prim-section)

(defrelation section-parent
  :types (section section))

(persist-rel section-parent)

(defrelation section-title
  :types (section string))

(persist-rel section-title)

(defrelation section-ccel
  :types (section string))

(persist-rel section-ccel)

(defrelation resource-ccel
  :types (resource string))

(persist-rel resource-ccel)

;; Use frugal-uuid to create the uuid strings.
(defrelation user
  :types (string))

(persist-rel user)

(defrelation user-email
  :types (user string))

(persist-rel user-email)

(defrelation user-password
  :types (user string))

(persist-rel user-password)

;; Use frugal-uuid
(defrelation note
  :types (string))

(persist-rel note)

(defrelation note-text
  :types (note string))

(persist-rel note-text)

;; user book chapter verse note
(defrelation user-note
  :types (user integer integer integer note))

(persist-rel user-note)

(defrelation user-note-text
  :definition ((user book chapter verse note)
               s.t.
               (e(note-id) (and (user-note user book chapter verse note-id)
                                (note-text note-id note)))))

(deftype target () '(member :new-tab :side-frame :float-frame :popup))

(defrelation user-target
  :types (user symbol))

(persist-rel user-target)

(defrelation user-dark-mode
  :types (user symbol))

(persist-rel user-dark-mode)
