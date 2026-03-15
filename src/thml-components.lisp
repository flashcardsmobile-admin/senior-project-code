(defmacro tag (sym)
  `(ps:@ van tags ,sym))

(defmacro defel (name fun &body options)
  `(ps:chain van-e (define ,name ,fun
                     ,@(when options (list (cons 'obj options))))))

(defmacro state (init)
  `(ps:chain van (state ,init)))

(defmacro get-state (state)
  `(ps:@ ,state val))

(defmacro derive (f)
  `(ps:chain van (derive ,f)))

(defmacro obj (&body r)
  `(ps:create ,@r))

(let* ((hr (tag hr))
       (sup (tag sup))
       (dialog (tag dialog))
       (slot (tag slot))
       (form (tag form))
       (button (tag button))
       (span (tag span))
       (div (tag div)))

  (defel "thml-pb"
      (lambda ()
        (funcall hr)))

  (defel "thml-helper-modal"
      (lambda ()
        (let (modal)
          (setf modal
                (funcall dialog
                         (funcall div (funcall slot))
                         (funcall div
                                  (funcall button
                                           (obj :onclick
                                                (lambda ()
                                                  (ps:chain modal (close))))
                                           "Close"))))
          (array (funcall slot
                          (obj :name "trigger"
                               :onclick (lambda ()
                                          (ps:chain modal (show-modal)))))
                 modal))))

  (let ((fn-count 0))
    (defel "thml-note"
        (lambda (ops)
          (let* ((attr (ps:getprop ops 'attr))
                 (count (funcall attr "n" false)))
            (unless count (setf count (incf fn-count)))
            (funcall (tag "thml-helper-modal")
                     (funcall sup
                              (obj :slot "trigger")
                              (funcall button
                                       (obj :onclick
                                            (lambda ()
                                              (ps:chain modal (show-modal))))
                                       count))
                     (funcall slot "Footnote content missing."))))))
  (defel "thml-thml"
    (lambda ()
      (funcall span))))
