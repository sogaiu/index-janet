(defn get-first-lines-and-offsets!
  [src-str filtered key-name]
  (var cur-line 1)
  (var pos 0)
  # XXX: will \n work on all platforms?
  (def eol "\n")
  (def eol-len (length eol))
  (each entry filtered
    (def {key-name name} entry)
    (def [_ attrs _] name)
    (def line-no (get attrs :bl))
    (def line-diff
      (- line-no cur-line))
    (repeat line-diff
      (set pos
           (+ (string/find eol src-str pos)
              eol-len)))
    (put entry
         :offset pos)
    (def end-pos
      (+ (string/find eol src-str pos)
         eol-len))
    (put entry
         :first-line
         (string/slice src-str
                       pos (- end-pos eol-len)))
    (set pos end-pos)
    (set cur-line (inc line-no)))
  #
  filtered)

(defn index-file!
  [src path tags-fn out-buf]
  (def form-feed
    (string/from-bytes 0x0C))
  (def start-of-heading
    (string/from-bytes 0x01))
  (def delete
    (string/from-bytes 0x7F))
  # XXX
  #(def start (os/clock))
  (def tags
    (tags-fn src))
  #(printf "tags-fn: %p" (- (os/clock) start))
  (when (not (empty? tags))
    # XXX: will this eol always be "\n" on every platform?
    (def eol "\n")
    (var tags-byte-count 0)
    (+= tags-byte-count
        (reduce (fn [acc [first-line id line-no file-offset]]
                  (+ acc
                     (length first-line)
                     # delete
                     1
                     (length id)
                     # start of heading
                     1
                     (length line-no)
                     # comma
                     1
                     (length file-offset)
                     # XXX: eol
                     1))
                0
                tags))
    #
    (buffer/push out-buf
                 form-feed eol)
    (buffer/push out-buf
                 path ","
                 # total size of what follows -- assumes eol is one byte?
                 (string tags-byte-count)
                 eol)
    (each [first-line id line-no file-offset] tags
      (buffer/push out-buf
                   # first line of text without line-ending
                   first-line
                   delete
                   # identifier name
                   id
                   start-of-heading
                   # line
                   line-no
                   ","
                   # offset from start of file
                   file-offset
                   eol)))
  #
  out-buf)
