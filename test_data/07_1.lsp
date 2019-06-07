(print-num ((fun () 2)))

(print-num
  ((fun (x) (+ x 1)) 3))

(print-num
  ((fun (a b) (- a b)) 4 5))

