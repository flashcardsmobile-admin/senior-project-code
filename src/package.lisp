(defpackage :jweb.framework
  (:use :cl :trivial-types :defstar)
  (:local-nicknames (#:t #:transducers))
  (:import-from :ningle #:*session*)
  (:import-from :modf #:modf)
  (:import-from :lack.util.writer-stream #:make-writer-stream)
  (:import-from :parenscript
		            #:ps
		            #:ps-inline
		            #:defpsmacro
		            #:defmacro+ps
		            #:@
		            #:chain
		            #:ps-html
		            #:new
		            #:lisp
                #:alambda
		            #:var
		            #:values
		            #:getprop)
  (:import-from :spinneret
		            #:with-html
		            #:with-html-string
		            #:deftag
                #:*unvalidated-attribute-prefixes*
		            #:*html*)
  (:import-from :fn
		            #:fn* ;; Lambda
		            #:fn~ ;; Partial application to function
		            #:fn~r
		            #:fn+) ;; Compose functions together
  (:export #:deftag
           #:defroute
           #:make-temp-route
           #:with-page
           #:with-html-stream
           #:*html*
           #:with-html
           #:awhen
           #:aif
           #:it
           #:make-server
           #:params
           #:get-req-item
           #:comptime
           #:rdr-to
           #:bs
           ;; Reexport things that ought to be universal
           #:fn*
           #:fn~
           #:fn~r
           #:fn+))

(defpackage :jweb.ref-tree
  (:use :cl :defstar)
  (:local-nicknames (#:t #:transducers))
  (:import-from :cl-binary-store
                #:store
                #:restore)
  (:import-from :modf #:modf)
  (:export #:add-ref
           #:get-ref
           #:verse-refs))

(defpackage :jweb.model
  (:use :cl :trivial-types
        :defstar :modf
        :ap5)
  (:shadowing-import-from "AP5" :compile
                          :defmethod :defun
                          :loop :++
                          :abort :type)
  (:local-nicknames (#:ref-tree #:jweb.ref-tree)
                    (#:t #:transducers))
  (:import-from :jweb.framework
                #:awhen
                #:aif
                #:comptime
                #:it)
  (:export #:defcategories
           #:defresources
           #:add-scrip-ref
           #:add-cur-section
           #:set-section-title
           #:create-resource
           #:set-resource-prim-section
           #:map-over-pre-resources
           #:get-section-title
           #:get-section-parent
           #:get-section-parent-title
           #:get-resources
           #:section-res-title))

(defpackage :jweb.thml
  (:use :cl :trivial-types
        :defstar :modf
        :ap5 :jweb.model)
  (:shadowing-import-from "AP5" :compile
                          :defmethod :defun
                          :loop :++
                          :abort :type)
  (:local-nicknames (#:pl #:plump)
		                (#:t #:transducers)
                    (#:ref-tree #:jweb.ref-tree))
  (:import-from :jweb.framework
                #:awhen
                #:aif
                #:comptime
                #:it)
  (:export #:render-file
           #:load-standard-docs))

(defpackage :jweb.bibles
  (:use :cl :trivial-types
        :defstar :modf
        :jweb.framework)
  (:local-nicknames (#:pl #:plump)
		                (#:t #:transducers))
  (:export #:get-bible
           #:bcv-names
           #:bcv-book-to-num
           #:num-to-bcv-book
           #:versions
           #:num-to-name
           #:num-to-chapters))

(defpackage :jweb.lang-verses
  (:use #:cl #:defstar
        #:jweb.bibles
        #:jweb.framework)
  (:local-nicknames (#:t #:transducers)
                    (#:pl #:plump))
  (:export #:lang-verse))

(defpackage :jweb.views
  (:use #:clamp #:spinneret)
  (:local-nicknames (#:t #:transducers)
                    (#:ref-tree #:jweb.ref-tree))
  (:import-from #:jweb.framework #:bs)
  (:import-from #:defstar #:nlet)
  (:import-from #:ps
                #:ps
                #:chain))

(defpackage :jweb
  (:use :cl :trivial-types
        :defstar :modf
        :jweb.thml :jweb.framework
        :jweb.bibles :ap5 :jweb.model)
  (:local-nicknames (#:pl #:plump)
		                (#:t #:transducers)
                    (#:ref-tree #:jweb.ref-tree))
  ;; (:import-from :datafly
	;; 	            #:retrieve-one-value
	;; 	            #:retrieve-one
	;; 	            #:retrieve-all
	;; 	            #:execute)
  (:shadowing-import-from "AP5" :compile
                          :defmethod :defun
                          :loop :++
                          :abort :type)
  (:import-from :ironclad
		            #:pbkdf2-hash-password
		            #:pbkdf2-hash-password-to-combined-string
		            #:pbkdf2-check-password
		            #:ascii-string-to-byte-array)
  (:export #:make-server))
