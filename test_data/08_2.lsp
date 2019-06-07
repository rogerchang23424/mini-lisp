(define x 87)

(define test-one (fun (x) (+ x 24)))

(print-num (test-one (* x 100)))


(define bar (fun (x) (+ x 1)))

(define bar-z (fun () 4))

(print-num (bar (bar-z)))

(define averagenum (fun (na nb nc nd)
   (/ ( + na nb nc nd) (bar-z)))
)
(print-num(averagenum 10 20 30 40))

(define square (fun (x)
   (* x x)))

(print-num (square 90))

(print-num (bar 101))

(print-num (bar 1932))

(print-num (averagenum 1000 2000 3000 4000))

(define max (fun (a b c) (if (> a b) (if (> c a) c a) (if (> c b) c b))))
(define min (fun (a b) (if (< a b) a b)))

(print-num (+ (max 5 (min 90 x) 22) (+ 45 (min (bar-z) 4) 15)))

(define test-ast-node (fun (a b c d e f) (- (* (+ a b) (+ c d)) (mod e f))))

(define orange (test-ast-node 1 2 (bar 2) 4 5 6))

(print-num orange)

(define guava bar-z)

(print-num (guava))