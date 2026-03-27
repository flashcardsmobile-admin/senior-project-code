(defsystem "jweb"
  :description "Jackson's Web Framework"
  :version "0.0.1"
  :author "Peter Jackson Link, III <peter.link@flashcardsmobile.com>"
  :license "BSD"
  ;; NOTE: Also depends on AP5, but it must be compiled into the image separately from ASDF.
  :depends-on (;;; Core web guts I don't want to mess with unless necessary.
               "clack"
	             "lack"
	             "lack-util-writer-stream"
	             "ningle"
               ;;; Lisp->language compilers (JS, HTML, CSS)
	             "parenscript"
	             "spinneret"
	             "spinneret/ps"
	             "css-lite"
               ;;; Cryptography
	             "ironclad"
	             "frugal-uuid"
               ;;; Syntax niceties
	             "arrow-macros"
	             "fn"
	             "fset"
	             "defstar"
	             "reader"
	             "trivia"
	             "transducers"
               "clamp"
               ;;; Extra Types
	             "trivial-types"
               ;;; Extra parts of the MOP
	             "closer-mop"
               ;;; XML Parsing
	             "plump"
               ;;; Portable Perl-compatible regular expressions
	             "cl-ppcre"
               ;;; Serialization
	             "cl-binary-store"
               ;;; Utilities
	             "alexandria"
	             "serapeum"
	             "modf"
               "woo"
	             "str")
  :components ((:module "src"
                :serial t
                :components ((:file "package")
	                           (:file "helpers")
	                           (:file "framework")
	                           ;; (:file "persist")
	                           (:file "bible-static-facts")
                             (:file "ref-tree")
                             (:file "relations")
                             (:file "model-funs")
                             (:module "components"
                              :serial t
                              :components ((:file "bootstrap")
	                                         (:file "bible-nav")))
	                           (:file "bibles")
                             (:file "thml-preprocessor")
                             (:file "thml-renderer")
                             (:file "lang-verses")
                             (:file "notes")
                             (:file "views")
	                           (:file "web"))))
  :in-order-to ((test-op (test-op jweb-test))))
