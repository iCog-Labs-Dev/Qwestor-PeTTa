; ─────────────────────────────────────────────
;
; Tests for all functions defined in utils/general-helper.metta.
; Run via PeTTa: sh $PETTA_DIR/run.sh utils/test/general-helper-test.metta
;
; Coverage:
;   _clamp01, _clamp11, remove-state,
;   replaceByIndex, find_by_key, add-reduct, _blend
; ─────────────────────────────────────────────

!(import! &self ../general-helper)

; ── Shared test space ────────────────────────────────────────
; Used by remove-state and add-reduct tests.
; Example: (bind! &TestSpace (new-space))
!(bind! &TestSpace (new-space))


; ─────────────────────────────────────────────
; _clamp01 — clamp a value to [0, 1]
;
; Example:
;   !(_clamp01 0.5)  ; => 0.5
;   !(_clamp01 -9)   ; => 0
;   !(_clamp01 3)    ; => 1
; ─────────────────────────────────────────────
!(test (_clamp01 0.5) 0.5)
!(test (_clamp01 -9)  0)
!(test (_clamp01 3)   1)
!(test (_clamp01 1)   1)
!(test (_clamp01 0)   0)


; ─────────────────────────────────────────────
; _clamp11 — clamp a value to [-1, 1]
;
; Example:
;   !(_clamp11 0.5)  ; => 0.5
;   !(_clamp11 -9)   ; => -1
;   !(_clamp11 3)    ; => 1
; ─────────────────────────────────────────────
!(test (_clamp11 0)    0)
!(test (_clamp11 0.5)  0.5)
!(test (_clamp11 -9)   -1)
!(test (_clamp11 3)    1)
!(test (_clamp11 1)    1)
!(test (_clamp11 -1)   -1)


; ─────────────────────────────────────────────
; remove-state — removes a (state $x $y) atom from a space
;
; Example:
;   !(add-atom &TestSpace (state 1 2))
;   !(remove-state &TestSpace)  ; => true  (atom removed)
; ─────────────────────────────────────────────
!(add-atom &TestSpace (state 1 2))
!(get-atoms &TestSpace)
!(test (remove-state &TestSpace) true)


; ─────────────────────────────────────────────
; replaceByIndex — replace element at position $index in $expr
;
; Example:
;   !(replaceByIndex (a b c) 1 x)  ; => (a x c)
;   !(replaceByIndex (a b c) 0 x)  ; => (x b c)
;   !(replaceByIndex () 0 x)       ; => ()   (empty list unchanged)
; ─────────────────────────────────────────────
!(test (replaceByIndex (a b c) 1 x)  (a x c))
!(test (replaceByIndex (a b c) 0 x)  (x b c))
!(test (replaceByIndex (a b c) 2 x)  (a b x))
!(test (replaceByIndex (a) 0 x)      (x))
!(test (replaceByIndex () 0 x)       ())
; Index out of bounds — list returned unchanged
!(test (replaceByIndex (a b c) 3 x)  (a b c))
!(test (replaceByIndex (a b c) -1 x) (a b c))


; ─────────────────────────────────────────────
; find_by_key — look up the value for a key in an association list
;
; Example:
;   !(find_by_key a ((a 1) (b 2)))  ; => 1
;   !(find_by_key c ((a 1) (b 2)))  ; => ()  (not found)
; ─────────────────────────────────────────────
!(test (find_by_key a ((a 1) (b 2))) 1)
!(test (find_by_key b ((a 1) (b 2))) 2)
!(test (find_by_key c ((a 1) (b 2))) ())


; ─────────────────────────────────────────────
; add-reduct — reduce the body of a definition and add it to a space
;
; Example:
;   !(add-reduct &TestSpace (= x (+ 1 2)))
;   ; adds (= x 3) to &TestSpace
; ─────────────────────────────────────────────
!(test (add-reduct &TestSpace (= x (+ 1 2))) ())
!(get-atoms &TestSpace)


; ─────────────────────────────────────────────
; _blend — exponential moving average: (1-α)·prev + α·target
;          result is clamped to [0, 1]
;
; Example:
;   !(_blend 0 1 0.5)   ; => 0.5
;   !(_blend 0 1 0.25)  ; => 0.25
; ─────────────────────────────────────────────
; Boundary cases
!(test (_blend 0 0 0) 0)
!(test (_blend 0 0 1) 0)
!(test (_blend 1 1 0) 1)
!(test (_blend 1 1 1) 1)

; Mid-range blending
!(test (_blend 0 1 0.5)  0.5)
!(test (_blend 0 1 0.25) 0.25)
!(test (_blend 0 1 0.75) 0.75)
