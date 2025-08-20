(ns app.core
  (:require 
    [app.foo :as foo]
    [clojure.string :as str]))

(defn my-fn 
  "This is a docstring"
  [a b]
  (println a b))

; (my-fn 1 2)
