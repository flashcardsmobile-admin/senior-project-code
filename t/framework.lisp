(in-package :jweb-test)

(def-suite framework
  :description "Test the framework code"
  :in jweb-test)

(in-suite framework)

(defmacro make-middleware (&body body)
  `(macrolet ((next () `(apply fn args)))
     (lambda (fn)
       (lambda (&rest args)
         ,@body))))

(test make-id-string
  (let ((result (jweb::make-id-string "example")))
    (is (string= "#example" result))))

(test apply-middleware-basic
  (let ((fun (lambda (x) (+ x x)))
        (middleware (make-middleware (1+ (next)))))
    (let ((result (jweb::apply-middleware fun middleware)))
      (is (= 5 (funcall result 2))))))

(test apply-middleware-chain
  (let* ((side-effects 0)
         (fun (lambda (x) (+ x x)))
         (incrementer (make-middleware
                       (incf side-effects)
                       (next)))
         (middleware-chain (list incrementer
                                 incrementer
                                 incrementer
                                 incrementer))
         (result (jweb::apply-middleware fun middleware-chain)))
    (is (= (funcall result 1) 2))
    (is (= side-effects 4))))
