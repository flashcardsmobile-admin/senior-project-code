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
    (:li :class (bs nav-item ;; dropdown
                    )
	       (:button :class (bs dropdown-toggle nav-link)
		              ;; :data-bs-toggle "dropdown"
                  :command "show-modal"
                  :commandfor "book-list"
		              (num-to-name text))
         (:dialog :id "book-list"
                  (:button :command "close"
                           :commandfor "book-list"
                           "Close")
	                (:ul :is "filter-ul"
                       :style "overflow: scroll; max-height: 20em;list-style: none;"
                       (:br)
	                     (:b "Old Testament")
	                     (render-bible-links version 1 39)
	                     (:b "New Testament")
	                     (render-bible-links version 40 66))))))

(defun version-list (version text chapter)
  (with-html
    (:li :class (bs nav-item ;; dropdown
                    )
	       (:button :class (bs dropdown-toggle
                           nav-link)
		              ;; :data-bs-toggle "dropdown"
                  :command "show-modal"
                  :commandfor "version-list"
		              version)
         (:dialog :id "version-list"
                  (:button :command "close"
                           :commandfor "version-list"
                           "Close")
	                (:ul :is "filter-ul"
	                     :style "overflow: scroll; max-height: 20em;list-style: none;"
	                     (loop for version in versions
		                         do (let* ((version-name (symbol-name version))
			                                 (new-url (str:concat "/bible/" version-name
                                                            "/" (write-to-string text)
                                                            "/" (write-to-string chapter))))
			                            (with-html
			                              (:li (:a :class (bs btn-block container btn btn-outline-secondary)
				                                     :href new-url
				                                     version-name))))))))))

(defun chapters-list (version book)
  (with-html
    (:li :class (bs nav-item dropdown)
	       (:button :class (bs dropdown-toggle nav-link)
		              :role "button"
		              ;; :data-bs-toggle (bs dropdown)
		              :type "button"
                  :command "show-modal"
                  :commandfor "chapters-list"
		              "Chapters")
         (:dialog :id "chapters-list"
                  (:button :command "close"
                           :commandfor "chapters-list"
                           "Close")
	                (:ul :is "filter-ul"
                       :style "overflow: scroll; max-height: 20em;list-style: none;"
	                     (loop for n from 1 to (num-to-chapters book)
		                         do (with-html
			                            (:li (:a :class (bs btn-block container btn btn-outline-secondary)
				                                   :href (format nil "/bible/~a/~a/~a" version book n)
				                                   ("Chapter ~A" n))))))))))
