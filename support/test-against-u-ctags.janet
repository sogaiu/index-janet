(import ../index-janet/etags)

(comment

  @{"tuple/brackets"
    @[58 2136 "JANET_CORE_FN(cfun_tuple_brackets," "src/core/tuple.c"]
    "tuple/setmap"
    @[108 4432 "JANET_CORE_FN(cfun_tuple_setmap," "src/core/tuple.c"]
    "tuple/slice"
    @[66 2433 "JANET_CORE_FN(cfun_tuple_slice," "src/core/tuple.c"]
    "tuple/sourcemap"
    @[96 3928 "JANET_CORE_FN(cfun_tuple_sourcemap," "src/core/tuple.c"]
    "tuple/type"
    @[80 3259 "JANET_CORE_FN(cfun_tuple_type," "src/core/tuple.c"]}

  )

(defn make-by-file
  [tags files]
  (def ds @{})
  (each path files
    (assert (nil? (get ds path))
            (string/format "There is already something here for %p" path))
    (put ds path @{})
    (each tag-dict tags
      (def [_ _ _ tag-path]
        # (next tag-dict) is just some key -- doesn't matter which
        # because tag-path should not differ (by construction)
        (get tag-dict (next tag-dict)))
      (when (= path tag-path)
        (eachp [id tag] tag-dict
          (put-in ds 
                  [path id] tag)))))
  #
  ds)

(defn count-tags
  [by-file]
    (reduce (fn [acc dict]
            (+ acc (length dict)))
            0
            by-file))

(defn check-ids
  [left-by-file right-by-file]
  (each path (sort (keys left-by-file))
    (def left-dict (get left-by-file path))
    (printf "path: %s" path)
    (if-let [right-dict (get right-by-file path)]
      (eachp [id _] left-dict
        (when (nil? (get right-dict id))
          (eprintf "Id %s missing" id)))
      (eprintf "Path %s missing" path))))

(defn compare-tags
  [left-by-file right-by-file]
  (print "left -> right?")
  (check-ids left-by-file right-by-file)
  (print)
  (print "right -> left?")
  (check-ids right-by-file left-by-file))

(defn main
  [& argv]

  (def native-tags-path
    "../janet/TAGS")

  (def u-ctags-tags-path
    (string (os/getenv "HOME") "/src/janet-ref/janet/TAGS"))

  (def native-tags-path
    (get argv 1))
  (def u-ctags-tags-path
    (get argv 2))

  (def native-src
    (slurp native-tags-path))

  (def u-ctags-src
    (slurp u-ctags-tags-path))
  
  (def nm-tags
    (->> (peg/match etags/etags-grammar native-src)
         (filter |(not (empty? $)))))

  # sample data before filtering
  '@[@{}
     @{"tuple/brackets"
       @[58 2136 "JANET_CORE_FN(cfun_tuple_brackets," "src/core/tuple.c"]
       "tuple/setmap"
       @[108 4432 "JANET_CORE_FN(cfun_tuple_setmap," "src/core/tuple.c"]
       "tuple/slice"
       @[66 2433 "JANET_CORE_FN(cfun_tuple_slice," "src/core/tuple.c"]
       "tuple/sourcemap"
       @[96 3928 "JANET_CORE_FN(cfun_tuple_sourcemap," "src/core/tuple.c"]
       "tuple/type"
       @[80 3259 "JANET_CORE_FN(cfun_tuple_type," "src/core/tuple.c"]}
     @{}
     @{}]

  (def nm-files
    (->> nm-tags
         (map |(let [a-key (next $)]
                 (get-in $ [a-key 3])))
         distinct
         sort))

  (def um-tags
    (->> (peg/match etags/etags-grammar u-ctags-src)
         (filter |(not (empty? $)))))

  (def um-files
    (->> um-tags
         (map |(let [a-key (next $)]
                 (get-in $ [a-key 3])))
         distinct
         sort))

  (assert (deep= nm-files um-files)
          "Indexed files differ")

  (def nm-by-file
    (make-by-file nm-tags nm-files))

  (printf "Counted %d tags in the natively generated TAGS file."
          (count-tags nm-by-file))

  (def um-by-file
    (make-by-file um-tags um-files))

  (printf "Counted %d tags in the universal-ctags-generated TAGS file."
          (count-tags um-by-file))

  (compare-tags nm-by-file um-by-file)

  )

