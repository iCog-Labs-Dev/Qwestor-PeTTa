; ─────────────────────────────────────────────
; utils/general-helper.metta
;
; Primitive helpers: clamps, replaceByIndex,
; find_by_key, _blend, add-reduct.
;
; Also re-exports utils/utils so that any file
; which only imports general-helper still gets
; all state/space accessors.
; ─────────────────────────────────────────────

!(import! &self utils)

; ── Clamp helpers ────────────────────────────
(= (_clamp01 $x)
  (if (and (< $x 1) (> $x 0))
     $x
     (if (>= $x 1) 1 0)))

(= (_clamp11 $x)
  (if (and (< $x 1) (> $x -1))
     $x
     (if (>= $x 1) 1 -1)))

; ── replaceByIndex ───────────────────────────
(= (replaceByIndex $expr $index $new)
    (if (== $expr ())
        $expr
        (let*
            (
                ($first (car-atom $expr))
                ($tail  (cdr-atom $expr))
            )
            (if (== $index 0)
                (if (== $tail ())
                    ($new)
                    (cons-atom $new $tail))
                (let $c (replaceByIndex $tail (- $index 1) $new)
                    (cons-atom $first $c))))))

; ── find_by_key ──────────────────────────────
(= (find_by_key $key $dic_list)
    (if (== $dic_list ())
        ()
        (let* (
                (($pair $next) (decons $dic_list))
                ($k (car-atom $pair))
                ($v (cdr-atom $pair))
            )
            (if (== $k $key)
                (superpose $v)
                (find_by_key $key $next)))))

; ── _blend ───────────────────────────────────
(= (_blend $prev $target $alpha)
   (eval (_clamp01 (+ (* (- 1.0 $alpha) $prev)
                      (* $alpha $target)))))

; ── add-reduct ───────────────────────────────
(= (add-reduct $space $f)
   (let* (($headbody   (cdr-atom $f))
          ($head       (car-atom $headbody))
          ($body       (cdr-atom $headbody))
          ($bodyreduced (eval $body)))
         (add-atom $space (= $head $bodyreduced))))
