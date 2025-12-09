(defsystem "jweb-test"
  :author "Peter Jackson Link, III"
  :license "ISC"
  :depends-on (:jweb
               ;;; Testing Framework
               :fiveam)
  :components ((:module "t"
                :serial t
                :components ((:file "package")
                             (:file "framework"))))
  :perform (test-op (op c)
                    (symbol-call :fiveam :run!
                                 (find-symbol* :jweb-test :jweb-test))))
