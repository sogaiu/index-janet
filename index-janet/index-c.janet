(import ./index :as idx)
(import ./c-cursor :as cc)
(import ./c-query :as cq)

########################################################################

(defn find-math-c-tags
  [src]

  '(def src
    (slurp
      (string (os/getenv "HOME") "/src/janet/src/core/math.c")))

  # JANET_DEFINE_MATHOP(acos, "Returns the arccosine of x.")
  # ...
  # JANET_DEFINE_NAMED_MATHOP("log-gamma", lgamma, "Returns log-gamma(x).")
  # ...
  # JANET_DEFINE_MATH2OP(pow, pow, "(math/pow a x)", "Returns a to the power of x.")
  # ...

  (def query-str
    ``
    <::name
     ~[sequence [drop [sequence [look -1 "\n"]
                                [choice "JANET_DEFINE_NAMED_MATHOP"
                                        "JANET_DEFINE_MATH2OP"
                                        "JANET_DEFINE_MATHOP"]]]
                [cmt :dl/round
                     ,(fn [caps]
                        # :dl/round attrs blob ws str/dq
                        (if (and (= (+ 2 1 1 1)
                                    (length caps))
                                 (= :blob (get-in caps [2 0])))
                           (get caps 2)
                           (find (fn [elt]
                                   (def [the-type _ _] elt)
                                   (= :str/dq the-type))
                                 caps)))]]>
    ``)

  # XXX
  (def start (os/clock))
  (def [q-results _ loc->node]
    (cq/query query-str src {:blank-delims [`<` `>`]}))
  (printf "cq/query: %p" (- (os/clock) start))

  (idx/get-first-lines-and-offsets! src q-results ::name)

  (def results
    (seq [tbl :in q-results
          :let [first-line (get tbl :first-line)
                [_ attrs value] (get tbl ::name)
                line-no (get attrs :bl)
                offset (get tbl :offset)]]
      # strip off surrounding bits from value to get id
      # add math/ if necessary
      (def id
        (if (not (string/has-prefix? `"` value))
          # value is :blob content - remove trailing comma
          (string "math/" (string/slice value 0 (dec (- 1))))
          # value is :str/dq content - starts with " and ends with "
          (let [stripped (string/slice value 1 (dec (- 1))) # drop " and "
                space-pos (string/find " " stripped)]
            (if space-pos
              # skip ( stop before space
              (string/slice stripped 1 space-pos)
              # prepend math/
              (string "math/" stripped)))))
      [first-line
       id
       (string line-no)
       (string offset)]))

  results)

(defn find-specials-c-tags
  [src]

  '(def src
    (slurp
      (string (os/getenv "HOME") "/src/janet/src/core/specials.c")))

  # static JanetSlot janetc_quote(JanetFopts opts, int32_t argn, const Janet *argv) {
  # ...
  # static JanetSlot janetc_varset(JanetFopts opts, int32_t argn, const Janet *argv) {
  # ...

  (def query-str
    ``
    <::name
     ~[sequence [drop [look -1 "\n"]]
                "static JanetSlot"
                [drop [some :ws]]
                [cmt :blob
                     ,(fn [name-node]
                        (def [the-type attrs name] name-node)
                        (def prefix "janetc_")
                        (when (string/has-prefix? prefix name)
                          (def short-name
                            (string/slice name (length prefix)))
                          (def real-name
                            (if (= "varset" short-name)
                              "set"
                              short-name))
                          [the-type attrs real-name]))]]>
    ``)

  # XXX
  (def start (os/clock))
  (def [q-results _ loc->node]
    (cq/query query-str src {:blank-delims [`<` `>`]}))
  (printf "cq/query: %p" (- (os/clock) start))

  (idx/get-first-lines-and-offsets! src q-results ::name)

  (def results
    (seq [tbl :in q-results
          :let [first-line (get tbl :first-line)
                [_ attrs id] (get tbl ::name)
                line-no (get attrs :bl)
                offset (get tbl :offset)]]
      [first-line
       id
       (string line-no)
       (string offset)]))

  results)

(defn find-corelib-c-tags
  [src]

  '(def src
    (slurp
      (string (os/getenv "HOME") "/src/janet/src/core/corelib.c")))

  # janet_quick_asm(env, JANET_FUN_MODULO,
  #                 "mod", 2, 2, 2, 2, modulo_asm, sizeof(modulo_asm),
  #                 JDOC("(mod dividend divisor)\n\n"
  #                      "Returns the modulo of dividend / divisor."));
  # ...
  # templatize_varop(env, JANET_FUN_MULTIPLY, "*", 1, 1, JOP_MULTIPLY,
  #                  JDOC("(* & xs)\n\n"
  #                       "Returns the product ... returns 1."));
  # ...
  # templatize_comparator(env, JANET_FUN_GT, ">", 0, JOP_GREATER_THAN,
  #                       JDOC("(> & xs)\n\n"
  #                       "Check if xs is in ... Returns a boolean."));
  # ...
  # janet_def(env, "janet/version", janet_cstringv(JANET_VERSION),
  #           JDOC("The version number of the running janet program."));

  # * the comment part is for getting +, >, janet/version, root-env
  (def query-str
    ``
    <::name
     ~[sequence [drop [sequence ";\n"
                                [choice [sequence [some :ws]
                                                  :cmt
                                                  [some :ws]]
                                        [some :ws]]
                                [choice "janet_quick_asm"
                                        "templatize_varop"
                                        "templatize_comparator"
                                        "janet_def"]]]
                [cmt :dl/round
                     ,(fn [caps]
                        (find (fn [elt]
                                (def [the-type _ _] elt)
                                (= :str/dq the-type))
                              caps))]]>
    ``)

  # XXX
  (def start (os/clock))
  (def [q-results _ loc->node]
    (cq/query query-str src {:blank-delims [`<` `>`]}))
  (printf "cq/query: %p" (- (os/clock) start))

  (idx/get-first-lines-and-offsets! src q-results ::name)

  (def results
    (seq [tbl :in q-results
          :let [first-line (get tbl :first-line)
                [_ attrs id] (get tbl ::name)
                line-no (get attrs :bl)
                offset (get tbl :offset)]]
      [first-line
       (string/slice id 1 (dec (- 1))) # strip surrounding double quotes
       (string line-no)
       (string offset)]))

  results)

# JANET_CORE_DEF
# * io.c
# * math.c
(defn find-janet-core-def-tags
  [src]

  '(def src
    (slurp
      (string (os/getenv "HOME") "/src/janet/src/core/io.c")))

  '(def src
    (slurp
      (string (os/getenv "HOME") "/src/janet/src/core/math.c")))

  # note that leading whitespace is elided from sample of io.c below
  #
  # int default_flags = JANET_FILE_NOT_CLOSEABLE | JANET_FILE_SERIALIZABLE;
  # /* stdout */
  # JANET_CORE_DEF(env, "stdout",
  #                ...);
  # /* stderr */
  # JANET_CORE_DEF(env, "stderr",
  #                ...);

  (def query-str
    ``
    <::name
     ~[sequence [drop [sequence :blob
                                "\n"
                                [choice [sequence [some :ws]
                                                  :cmt
                                                  [some :ws]]
                                        [some :ws]]]]
                "JANET_CORE_DEF"
                [cmt :dl/round
                     ,(fn [caps]
                        (find (fn [elt]
                                (def [the-type _ _] elt)
                                (= :str/dq the-type))
                              caps))]]>
    ``)

  # XXX
  (def start (os/clock))
  (def [q-results _ loc->node]
    (cq/query query-str src {:blank-delims [`<` `>`]}))
  (printf "cq/query: %p" (- (os/clock) start))

  (idx/get-first-lines-and-offsets! src q-results ::name)

  (def results
    (seq [tbl :in q-results
          :let [first-line (get tbl :first-line)
                [_ attrs id] (get tbl ::name)
                line-no (get attrs :bl)
                offset (get tbl :offset)]]
      [first-line
       (string/slice id 1 (dec (- 1))) # strip surrounding double quotes
       (string line-no)
       (string offset)]))

  results)

# JANET_CORE_FN
# * many
(defn find-janet-core-fn-tags
  [src]

  '(def src
     (slurp
       (string (os/getenv "HOME") "/src/janet/src/core/ffi.c")))

  '(def src
     (slurp
       (string (os/getenv "HOME") "/src/janet/src/core/math.c")))

  # JANET_CORE_FN(cfun_peg_compile,
  #              "(peg/compile peg)", ...)

  # [choice ... :blob] picks up ffi/signature and ffi/jitfn
  # [choice :dl/round ...] picks up not, math/random, math/seedrandom
  (def query-str
    ``
    <::name
     ~[sequence [drop [sequence [choice :dl/round :dl/curly :blob]
                                [choice [sequence [some :ws]
                                                  :cmt
                                                  [some :ws]]
                                        [some :ws]]]]
                "JANET_CORE_FN"
                [cmt :dl/round
                     ,(fn [caps]
                        (find (fn [elt]
                                (def [the-type _ _] elt)
                                (= :str/dq the-type))
                              caps))]]>
    ``)

  # XXX
  (def start (os/clock))
  (def [q-results _ loc->node]
    (cq/query query-str src {:blank-delims [`<` `>`]}))
  (printf "cq/query: %p" (- (os/clock) start))

  (idx/get-first-lines-and-offsets! src q-results ::name)

  (def results
    (seq [tbl :in q-results
          :let [first-line (get tbl :first-line)
                [_ attrs value] (get tbl ::name)
                line-no (get attrs :bl)
                offset (get tbl :offset)]]
      # strip off surrounding bits from value to get id
      (def id
        (let [space-pos (string/find " " value)]
          # "(print ...)" or "(file/temp)"
          (if space-pos
            (string/slice value 2 space-pos)
            (string/slice value 2 (dec (- 2))))))
      [first-line
       id
       (string line-no)
       (string offset)]))

  results)

# const JanetAbstractType janet... = {
# * many
(defn find-janet-abstract-type-tags
  [src]

  '(def src
     (slurp
       (string (os/getenv "HOME") "/src/janet/src/core/ev.c")))

  '(def src
     (slurp
       (string (os/getenv "HOME") "/src/janet/src/core/ffi.c")))

  # const JanetAbstractType janet... = {
  #     "core/file",
  #     ...
  # };

  (def query-str
    ``
    <::name
     ~[sequence [drop [sequence "const" [some :ws]
                                "JanetAbstractType" [some :ws]
                                :blob [some :ws] "="
                                [some :ws]]]
                [cmt :dl/curly
                     ,(fn [caps]
                        (find (fn [elt]
                                (def [the-type _ _] elt)
                                (= :str/dq the-type))
                              caps))]]>
    ``)

  # XXX
  (def start (os/clock))
  (def [q-results _ loc->node]
    (cq/query query-str src {:blank-delims [`<` `>`]}))
  (printf "cq/query: %p" (- (os/clock) start))

  (idx/get-first-lines-and-offsets! src q-results ::name)

  (def results
    (seq [tbl :in q-results
          :let [first-line (get tbl :first-line)
                [_ attrs id] (get tbl ::name)
                line-no (get attrs :bl)
                offset (get tbl :offset)]]
      [first-line
       (string/slice id 1 (dec (- 1))) # strip surrounding double quotes
       (string line-no)
       (string offset)]))

  results)


########################################################################

(defn index-math-c!
  [src path out-buf]
  (idx/index-file! src path find-math-c-tags out-buf))

(defn index-specials-c!
  [src path out-buf]
  (idx/index-file! src path find-specials-c-tags out-buf))

(defn index-corelib-c!
  [src path out-buf]
  (idx/index-file! src path find-corelib-c-tags out-buf))

(defn index-janet-core-def-c!
  [src path out-buf]
  (idx/index-file! src path find-janet-core-def-tags out-buf))

(defn index-generic-c!
  [src path out-buf]
  (try
    (idx/index-file! src path find-janet-abstract-type-tags out-buf)
    ([e]
      (eprintf "%s: abstract - %p" path e)))
  (try
    (idx/index-file! src path find-janet-core-fn-tags out-buf)
    ([e]
      (eprintf "%s: core-fn - %p" path e))))

