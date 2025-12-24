(defn d/deprintf
  [fmt & args]
  (when (dyn :ij-debug)
    (eprintf fmt ;args)))

(defn d/deprint
  [msg]
  (when (dyn :ij-debug)
    (eprint msg)))
