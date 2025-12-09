(in-package :jweb)

(defun render-bible-links (version start end)
  (loop for n from start to end
	do (let ((new-url (str:concat "/bible/" version "/" (write-to-string n))))
	     (with-html
	       (:li (:a :class (bs btn-block container btn btn-outline-secondary)
			:href new-url
			(num-to-name n)))))))

;; Navigation buttons for bible texts.
(defun book-list (version text)
  (with-html
    (:li :class (bs nav-item dropdown)
	       (:button :class (bs dropdown-toggle nav-link)
		              :data-bs-toggle "dropdown"
		              (num-to-name text))
	       (:ul :class (bs dropdown-menu)
	            :style "overflow: scroll; max-height: 20em;"
	            (:b "Old Testament")
	            (render-bible-links version 1 39)
	            (:b "New Testament")
	            (render-bible-links version 40 66)))))

(defun version-list (version text chapter)
  (with-html
    (:li :class (bs nav-item dropdown)
	 (:button :class (bs dropdown-toggle nav-link)
		  :data-bs-toggle "dropdown"
		  version)
	 (:ul :class (bs dropdown-menu)
	      :style "overflow: scroll; max-height: 20em;"
	      (loop for version in versions
		    do (let* ((version-name (symbol-name version))
			      (new-url (str:concat "/bible/" version-name
                                 "/" (write-to-string text)
                                 "/" (write-to-string chapter))))
			 (with-html
			   (:li (:a :class (bs btn-block container btn btn-outline-secondary)
				    :href new-url
				    version-name)))))))))

(defun chapters-list (version book)
  (with-html
    (:li :class (bs nav-item dropdown)
	       (:button :class (bs dropdown-toggle nav-link)
		              :role "button"
		              :data-bs-toggle (bs dropdown)
		              :type "button"
		              "Chapters")
	       (:ul :class (bs dropdown-menu)
	            :style "overflow: scroll; max-height: 20em;"
	            (loop for n from 1 to (num-to-chapters book)
		                do (with-html
			                   (:li (:a :class (bs btn-block container btn btn-outline-secondary)
				                          :href (format nil "/bible/~a/~a/~a" version book n)
				                          ("Chapter ~A" n)))))))))
