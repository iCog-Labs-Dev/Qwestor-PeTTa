; ─────────────────────────────────────────────
; operators/test/routing-test.metta
; ─────────────────────────────────────────────

!(import! &self ../routing)

; ── get-action-score ─────────────────────────
!(test (get-action-score ((Score act-search 10) (Score act-attack 5)) act-search) 10)
!(test (get-action-score ((Score act-search 10)) act-search) 10)
!(test (get-action-score ((Score act-search 10) (Score act-attack 5)) act-attack) 5)
!(test (get-action-score ((Score act-search 10) (Score act-attack 5)) act-defend) (ACTION-BLOCKED-SCORE))
!(test (get-action-score () act-search) (ACTION-BLOCKED-SCORE))
!(test (get-action-score ((Score act-search 10) (Score act-search 20)) act-search) 10)
!(test (get-action-score ((Score act-search 10.5) (Score act-attack 5.2)) act-search) 10.5)
!(test (get-action-score ((Score act-search 10.5) (Score act-attack 5.2)) act-attack) 5.2)

; ── set-action-score ─────────────────────────
!(test (set-action-score () act-search 10) ((Score act-search 10)))
!(test (set-action-score ((Score act-search 10) (Score act-attack 5)) act-search 15) ((Score act-search 15) (Score act-attack 5)))
!(test (set-action-score ((Score act-search 10) (Score act-attack 5)) act-attack 8)  ((Score act-search 10) (Score act-attack 8)))
!(test (set-action-score ((Score act-search 10) (Score act-attack 5)) act-defend 12) ((Score act-search 10) (Score act-attack 5) (Score act-defend 12)))
!(test (set-action-score ((Score act-search 10) (Score act-search 20)) act-search 15) ((Score act-search 15) (Score act-search 20)))

; ── adjust-action-score ──────────────────────
!(test (adjust-action-score ((Score act-search 10) (Score act-attack 5)) act-search 5)   ((Score act-search 15) (Score act-attack 5)))
!(test (adjust-action-score ((Score act-search 10) (Score act-attack 5)) act-attack -2)  ((Score act-search 10) (Score act-attack 3)))
!(test (adjust-action-score ((Score act-search 10) (Score act-attack 5)) act-defend 3)   ((Score act-search 10) (Score act-attack 5)))
!(test (adjust-action-score () act-search 5) ())
!(test (adjust-action-score ((Score act-search 10) (Score act-search 20)) act-search 5)  ((Score act-search 15) (Score act-search 20)))

; ── ctx-val ──────────────────────────────────
!(test (ctx-val () act-search) 0.0)
!(test (ctx-val ((act-search 10) (act-attack 5)) act-search) 10)
!(test (ctx-val ((act-search 10) (act-attack 5)) act-attack) 5)
!(test (ctx-val ((act-search 10) (act-attack 5)) act-defend) 0.0)
!(test (ctx-val ((act-search 10) (act-search 20)) act-search) 10)

; ── guard-decompose ──────────────────────────
!(test (guard-decompose ((Score act_decompose 10))
  ((complexity 0.5) (ambiguity 0.2) (urgent_flag true) (needs_task_plan 0.3)
   (reflective_intent 0.8) (needs_external_evidence 0.4)
   (decompose_min_complexity 0.4) (decompose_urgent_min_complexity 0.7)
   (decompose_max_ambiguity 0.8)) ())
  ((Score act_decompose (ACTION-BLOCKED-SCORE))))

!(test (guard-decompose ((Score act_decompose 10))
  ((complexity 0.3) (ambiguity 0.2) (urgent_flag true) (needs_task_plan 0.3)
   (reflective_intent 0.8) (needs_external_evidence 0.4)
   (decompose_min_complexity 0.4) (decompose_urgent_min_complexity 0.7)
   (decompose_max_ambiguity 0.8)) ())
  ((Score act_decompose (ACTION-BLOCKED-SCORE))))

!(test (guard-decompose ((Score act_decompose 10))
  ((complexity 0.5) (ambiguity 0.9) (urgent_flag true) (needs_task_plan 0.3)
   (reflective_intent 0.8) (needs_external_evidence 0.4)
   (decompose_min_complexity 0.4) (decompose_urgent_min_complexity 0.7)
   (decompose_max_ambiguity 0.8)) ())
  ((Score act_decompose (ACTION-BLOCKED-SCORE))))

!(test (guard-decompose ((Score act_decompose 10))
  ((complexity 0.5) (ambiguity 0.2) (urgent_flag true) (needs_task_plan 0.3)
   (reflective_intent 0.8) (needs_external_evidence 0.4)
   (decompose_min_complexity 0.6) (decompose_urgent_min_complexity 0.7)
   (decompose_max_ambiguity 0.8)) ())
  ((Score act_decompose (ACTION-BLOCKED-SCORE))))

!(test (guard-decompose ((Score act_decompose 10))
  ((complexity 0.5) (ambiguity 0.2) (urgent_flag true) (needs_task_plan 0.3)
   (reflective_intent 0.8) (needs_external_evidence 0.4)
   (decompose_min_complexity 0.4) (decompose_urgent_min_complexity 0.8)
   (decompose_max_ambiguity 0.8)) ())
  ((Score act_decompose (ACTION-BLOCKED-SCORE))))

!(test (guard-decompose ((Score act_decompose 10))
  ((complexity 0.8) (ambiguity 0.2) (urgent_flag false) (needs_task_plan 0.50)
   (reflective_intent 0.8) (needs_external_evidence 0.4)
   (decompose_min_complexity 0.4) (decompose_urgent_min_complexity 0.7)
   (decompose_max_ambiguity 0.8)) ())
  ((Score act_decompose 10)))

!(test (guard-decompose ((Score act_decompose 10))
  ((complexity 0.8) (ambiguity 0.2) (urgent_flag false) (needs_task_plan 0.65)
   (reflective_intent 0.8) (needs_external_evidence 0.4)
   (decompose_min_complexity 0.4) (decompose_urgent_min_complexity 0.7)
   (decompose_max_ambiguity 0.8)) ())
  ((Score act_decompose 10.1)))

!(test (guard-decompose ((Score act_decompose 10))
  ((complexity 0.8) (ambiguity 0.2) (urgent_flag false) (needs_task_plan 0.50)
   (reflective_intent 0.8) (needs_external_evidence 0.8)
   (decompose_min_complexity 0.4) (decompose_urgent_min_complexity 0.7)
   (decompose_max_ambiguity 0.8)) ())
  ((Score act_decompose 9.7)))

; ── guard-search-synth ───────────────────────
!(test (guard-search-synth
  ((Score act_search 10) (Score act_synthesize 10))
  ((needs_external_evidence 0.70) (needs_task_plan 0.40)
   (needs_multi_source_integration 0.80) (verify_request 0)))
  ((Score act_search 10.42) (Score act_synthesize 10.2)))

!(test (guard-search-synth
  ((Score act_search 10) (Score act_synthesize 10))
  ((needs_external_evidence 0.20) (needs_task_plan 0.50)
   (needs_multi_source_integration 0.40) (verify_request 0)))
  ((Score act_search 9.82) (Score act_synthesize (ACTION-BLOCKED-SCORE))))

!(test (guard-search-synth
  ((Score act_search 10) (Score act_synthesize 10))
  ((needs_external_evidence 0.20) (needs_task_plan 0.50)
   (needs_multi_source_integration 0.40) (verify_request 1)))
  ((Score act_search 10) (Score act_synthesize 10)))

!(test (guard-search-synth
  ((Score act_search 10) (Score act_synthesize 10))
  ((needs_external_evidence 0.40) (needs_task_plan 0.50)
   (needs_multi_source_integration 0.80) (verify_request 1)))
  ((Score act_search 10) (Score act_synthesize 10.2)))

!(test (guard-search-synth
  ((Score act_search 10) (Score act_synthesize 10))
  ((needs_external_evidence 0.40) (needs_task_plan 0.50)
   (needs_multi_source_integration 0.50) (verify_request 0)))
  ((Score act_search 10) (Score act_synthesize (ACTION-BLOCKED-SCORE))))

!(test (guard-search-synth
  ((Score act_search 10) (Score act_synthesize 10))
  ((needs_external_evidence 0.70) (needs_task_plan 0.75)
   (needs_multi_source_integration 0.70) (verify_request 0)))
  ((Score act_search 10.3) (Score act_synthesize 9.979999999999999)))

; ── guard-search-arb ─────────────────────────
!(test (guard-search-arb
  ((Score act_search 10) (Score act_decompose 10) (Score act_synthesize 10))
  ((needs_external_evidence 0.20) (needs_task_plan 0.50) (needs_multi_source_integration 0.40)))
  ((Score act_search 10) (Score act_decompose 10) (Score act_synthesize 10)))

!(test (guard-search-arb
  ((Score act_search 10) (Score act_decompose 10) (Score act_synthesize 10))
  ((needs_external_evidence 0.90) (needs_task_plan 0.50) (needs_multi_source_integration 0.80)))
  ((Score act_search 10.26) (Score act_decompose 9.74) (Score act_synthesize 9.88)))

!(test (guard-search-arb
  ((Score act_search 5) (Score act_decompose 5) (Score act_synthesize 5))
  ((needs_external_evidence 0.40) (needs_task_plan 0.75) (needs_multi_source_integration 0.50)))
  ((Score act_search 4.88) (Score act_decompose 5.18) (Score act_synthesize 4.9)))

!(test (guard-search-arb
  ((Score act_search 7) (Score act_decompose 7) (Score act_synthesize 7))
  ((needs_external_evidence 0.50) (needs_task_plan 0.40) (needs_multi_source_integration 0.72)))
  ((Score act_search 7) (Score act_decompose 6.84) (Score act_synthesize 7.16)))

!(test (guard-search-arb
  ((Score act_search 10) (Score act_decompose 10) (Score act_synthesize (ACTION-BLOCKED-SCORE)))
  ((needs_external_evidence 0.90) (needs_task_plan 0.50) (needs_multi_source_integration 0.80)))
  ((Score act_search 10.26) (Score act_decompose 9.74) (Score act_synthesize (ACTION-BLOCKED-SCORE))))

; ── guard-verify ─────────────────────────────
!(test (guard-verify
  ((Score act_verify 10) (Score act_synthesize 10))
  ((ambiguity 0.90) (threshold 0.60) (low_confidence 0.50) (failure_wariness 0.40)
   (verify_request 1) (complexity 0.80) (intent_type mixed)) ())
  ((Score act_verify (ACTION-BLOCKED-SCORE)) (Score act_synthesize 10)))

!(test (guard-verify
  ((Score act_verify 10))
  ((ambiguity 0.40) (threshold 0.50) (low_confidence 0.30) (failure_wariness 0.40)
   (verify_request 0) (complexity 0.60) (intent_type reflective)) ())
  ((Score act_verify (ACTION-BLOCKED-SCORE))))

!(test (guard-verify
  ((Score act_verify 10) (Score act_synthesize 10))
  ((ambiguity 0.50) (threshold 0.60) (low_confidence 0.50) (failure_wariness 0.40)
   (verify_request 1) (complexity 0.60) (intent_type mixed)) ())
  ((Score act_verify 10.45) (Score act_synthesize 9.65)))

!(test (guard-verify
  ((Score act_verify 10))
  ((ambiguity 0.50) (threshold 0.60) (low_confidence 0.50) (failure_wariness 0.40)
   (verify_request 0) (complexity 0.80) (intent_type reflective)) ())
  ((Score act_verify 9.8)))

!(test (guard-verify
  ((Score act_verify 10))
  ((ambiguity 0.50) (threshold 0.60) (low_confidence 0.50) (failure_wariness 0.40)
   (verify_request 1) (complexity 0.60) (intent_type mixed)) ())
  ((Score act_verify 10.45)))

; ── guard-fast-lane ──────────────────────────
!(test (guard-fast-lane
  ((Score act_verify 10) (Score act_search 10) (Score act_clarify 10)
   (Score act_think 10) (Score act_respond 10))
  ((complexity 0.20) (ambiguity 0.20) (threshold_signal 0.20) (failure_signal 0.20)
   (familiarity_signal 0.80) (threshold 0.65) (low_confidence 0.20)
   (verify_request 0) (help_short 0.50)) ())
  ((Score act_verify (ACTION-BLOCKED-SCORE)) (Score act_search (ACTION-BLOCKED-SCORE)) (Score act_clarify (ACTION-BLOCKED-SCORE))
   (Score act_think (ACTION-BLOCKED-SCORE)) (Score act_respond 10.60)))

!(test (guard-fast-lane
  ((Score act_verify 10) (Score act_search 10) (Score act_clarify 10)
   (Score act_think 10) (Score act_respond 10))
  ((complexity 0.40) (ambiguity 0.30) (threshold_signal 0.20) (failure_signal 0.20)
   (familiarity_signal 0.85) (threshold 0.75) (low_confidence 0.25)
   (verify_request 0) (help_short 0.60)) ())
  ((Score act_verify 10) (Score act_search (ACTION-BLOCKED-SCORE)) (Score act_clarify (ACTION-BLOCKED-SCORE))
   (Score act_think 10) (Score act_respond 10.40)))

!(test (guard-fast-lane
  ((Score act_verify 10) (Score act_search 10) (Score act_clarify 10)
   (Score act_think 10) (Score act_respond 10))
  ((complexity 0.60) (ambiguity 0.20) (threshold_signal 0.20) (failure_signal 0.20)
   (familiarity_signal 0.90) (threshold 0.80) (low_confidence 0.20)
   (verify_request 0) (help_short 0.80)) ())
  ((Score act_verify 10) (Score act_search 10) (Score act_clarify 10)
   (Score act_think 10) (Score act_respond 10)))

!(test (guard-fast-lane
  ((Score act_verify 10) (Score act_search 10) (Score act_clarify 10)
   (Score act_think 10) (Score act_respond 10))
  ((complexity 0.10) (ambiguity 0.10) (threshold_signal 0.10) (failure_signal 0.10)
   (familiarity_signal 0.90) (threshold 0.90) (low_confidence 0.10)
   (verify_request 1) (help_short 0.80)) ())
  ((Score act_verify 10) (Score act_search 10) (Score act_clarify 10)
   (Score act_think 10) (Score act_respond 10)))

; ── get-preferred ────────────────────────────
!(test (get-preferred factual 0.10 0.10)    act_search)
!(test (get-preferred reflective 0.10 0.10) act_think)
!(test (get-preferred exploratory 0.40 0.10) act_search)
!(test (get-preferred exploratory 0.39 0.44) act_think)

; ── get-best-score ───────────────────────────
!(test (get-best-score ((Score act_search 10) (Score act_think 5)))   (Score act_search 10))
!(test (get-best-score ((Score act_search 3)  (Score act_think 12) (Score act_decompose 7))) (Score act_think 12))
!(test (get-best-score ((Score act_search 8)  (Score act_think 8)))   (Score act_think 8))

; ── select-action ────────────────────────────
!(test (select-action
  ((Score act_search 15) (Score act_think 10))
  ((intent_type factual) (low_confidence 0.20) (threshold 0.30)) 0.10)
  (Result (Score act_search 15) ((Score act_search 15) (Score act_think 10))))

!(test (select-action
  ((Score act_search 10) (Score act_think 10))
  ((intent_type reflective) (low_confidence 0.30) (threshold 0.40)) 0.20)
  (Result (Score act_think 10.2001) ((Score act_search 10) (Score act_think 10.2001))))

!(test (select-action
  ((Score act_search 12) (Score act_think 12))
  ((intent_type factual) (low_confidence 0.30) (threshold 0.40)) 0.10)
  (Result (Score act_search 12.1001) ((Score act_search 12.1001) (Score act_think 12))))

!(test (select-action
  ((Score act_search 20) (Score act_think 10))
  ((intent_type reflective) (low_confidence 0.50) (threshold 0.50)) 0.10)
  (Result (Score act_search 20) ((Score act_search 20) (Score act_think 10))))

; ── apply-routing-guards ─────────────────────
!(test (apply-routing-guards
  ((Score act_search 10) (Score act_decompose 10)
   (Score act_synthesize 10) (Score act_verify 10))
  ((needs_external_evidence 0.90) (needs_task_plan 0.50)
   (needs_multi_source_integration 0.80) (ambiguity 0.50)
   (threshold 0.60) (low_confidence 0.50) (failure_wariness 0.40)
   (verify_request 1) (complexity 0.70) (intent_type mixed)
   (cx 0.60) (threshold_signal 0.30) (failure_signal 0.30)
   (familiarity_signal 0.60) (help_short 0.40)
   (decompose_min_complexity 0.40) (decompose_urgent_min_complexity 0.70)
   (decompose_max_ambiguity 0.80) (urgent_flag false)) ())
  ((Score act_search 10.56) (Score act_decompose 9.44)
   (Score act_synthesize 9.73) (Score act_verify 10.45)))

!(test (apply-routing-guards
  ((Score act_search 8) (Score act_decompose 8)
   (Score act_synthesize 8) (Score act_verify 8))
  ((needs_external_evidence 0.30) (needs_task_plan 0.70)
   (needs_multi_source_integration 0.40) (ambiguity 0.40)
   (threshold 0.50) (low_confidence 0.30) (failure_wariness 0.30)
   (verify_request 0) (complexity 0.60) (intent_type factual)
   (cx 0.50) (threshold_signal 0.20) (failure_signal 0.20)
   (familiarity_signal 0.50) (help_short 0.30)
   (decompose_min_complexity 0.40) (decompose_urgent_min_complexity 0.70)
   (decompose_max_ambiguity 0.80) (urgent_flag false)) ())
  ((Score act_search 8) (Score act_decompose 8.1)
   (Score act_synthesize (ACTION-BLOCKED-SCORE)) (Score act_verify (ACTION-BLOCKED-SCORE))))
