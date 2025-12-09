(in-package :jweb.model)

(defrelation pre-resource
  :types (pathname))

(defrelation category
  :types (symbol))

(defrelation category-title
  :types (category string))

(defrelation pre-resource-category
  :types (pre-resource category))

;; Indexed by compiled file.
(defrelation section
  :types (pathname))

;; Indexed by source file.
(defrelation resource
  :types (pathname))

(defrelation resource-category
  :types (resource category))

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

;; :types (symbol integer integer integer integer section)

(defrelation resource-title
  :types (resource string))

(defrelation resource-sections
  :types (resource section))

(defrelation resource-prim-section
  :types (resource section))

(defrelation section-parent
  :types (section section))

(defrelation section-title
  :types (section string))
