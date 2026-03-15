(in-package :jweb.bibles)

;; Autogenerate a case statement for each book.
(defmacro book-case (num &body forms)
  (labels ((map-i (func list &optional (iter 1))
	     (if list
		 (cons (funcall func (car list) iter)
		       (map-i func (cdr list) (1+ iter)))
		 nil)))
    `(case ,num
       ,@(map-i (lambda (form i) (list i form)) forms))))

(defparameter bcv-names
  (comptime
		(with-open-file (names (asdf:system-relative-pathname :jweb "src/bcv-names.txt"))
			(read names))))

(defun num-to-name (num)
  (declare (type fixnum num))
  (declare (optimize (speed 3) (safety 0)))
  (the (or string fixnum null)
       (book-case num
	 "Genesis"
	 "Exodus"
	 "Leviticus"
	 "Numbers"
	 "Deuteronomy"
	 "Joshua"
	 "Judges"
	 "Ruth"
	 "1 Samuel"
	 "2 Samuel"
	 "1 Kings"
	 "2 Kings"
	 "1 Chronicles"
	 "2 Chronicles"
	 "Ezra"
	 "Nehemiah"
	 "Esther"
	 "Job"
	 "Psalms"
	 "Proverbs"
	 "Ecclesiastes"
	 "Song of Solomon"
	 "Isaiah"
	 "Jeremiah"
	 "Lamentations"
	 "Ezekiel"
	 "Daniel"
	 "Hosea"
	 "Joel"
	 "Amos"
	 "Obadiah"
	 "Jonah"
	 "Micah"
	 "Nahum"
	 "Habakkuk"
	 "Zephaniah"
	 "Haggai"
	 "Zechariah"
	 "Malachi"
	 "Matthew"
	 "Mark"
	 "Luke"
	 "John"
	 "Acts"
	 "Romans"
	 "1 Corinthians"
	 "2 Corinthians"
	 "Galatians"
	 "Ephesians"
	 "Philippians"
	 "Colossians"
	 "1 Thessalonians"
	 "2 Thessalonians"
	 "1 Timothy"
	 "2 Timothy"
	 "Titus"
	 "Philemon"
	 "Hebrews"
	 "James"
	 "1 Peter"
	 "2 Peter"
	 "1 John"
	 "2 John"
	 "3 John"
	 "Jude"
	 "Revelation")))

(defun num-to-chapters (num)
  (declare (type fixnum num))
  (declare (optimize (speed 3) (safety 0)))
  (the fixnum
       (book-case num
	       50
	       40
	       27
	       36
	       34
	       24
	       21
	       4
	       31
	       24
	       22
	       25
	       29
	       36
	       10
	       13
	       10
	       42
	       150
	       31
	       12
	       8
	       66
	       52
	       5
	       48
	       12
	       14
	       3
	       9
	       1
	       4
	       7
	       3
	       3
	       3
	       2
	       14
	       4
	       28
	       16
	       24
	       21
	       28
	       16
	       16
	       13
	       6
	       6
	       4
	       4
	       5
	       3
	       6
	       4
	       3
	       1
	       13
	       5
	       5
	       3
	       5
	       1
	       1
	       1
	       22)))

(defmacro tnch-file (name)
  (asdf:system-relative-pathname :jweb (str:concat "bibles/Tanach/Books/" name ".xml")))

(defmacro tnch-files (num &body names)
  `(book-case num
     ,@(mapcar (lambda (name) `(tnch-file ,name)) names)))

(defun num-to-tnch-file (num)
  (declare (type fixnum num))
  (declare (optimize (speed 3) (safety 0)))
  (the (or pathname null)
       (tnch-files num
         "Genesis"
         "Exodus"
         "Leviticus"
         "Numbers"
         "Deuteronomy"
         "Joshua"
         "Judges"
         "Ruth"
         "Samuel_1"
         "Samuel_2"
         "Kings_1"
         "Kings_2"
         "Chronicles_1"
         "Chronicles_2"
         "Ezra"
         "Nehemiah"
         "Esther"
         "Job"
         "Psalms"
         "Proverbs"
         "Ecclesiastes"
         "Song_of_Songs"
         "Isaiah"
         "Jeremiah"
         "Lamentations"
         "Ezekiel"
         "Daniel"
         "Amos"
         "Obadiah"
         "Jonah"
         "Micah"
         "Nahum"
         "Habakkuk"
         "Zephaniah"
         "Haggai"
         "Zechariah"
         "Malachi")))
