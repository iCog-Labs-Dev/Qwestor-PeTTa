; ─────────────────────────────────────────────
; operators/test/routing-test.metta
;
; Tests for all routing guard functions and the selection engine
; defined in operators/routing.metta.
; Run via PeTTa: sh $PETTA_DIR/run.sh operators/test/routing-test.metta
;
; Coverage:
;   get-action-score, set-action-score, adjust-action-score,
;   ctx-val, guard-decompose, guard-search-synth, guard-search-arb,
;   guard-verify, guard-fast-lane, get-preferred, select-action,
;   get-best-score, apply-routing-guards
; ─────────────────────────────────────────────

!(import! &self ../routing)
!(import! &self ../appraisal)
!(import! &self ../../utils/general-helper)

; ── Routing space ────────────────────────────────────────────
; Guards that access modulator or goal values (guard-decompose,
; guard-verify, guard-fast-lane) require a populated space.
; We bind one here with defaults and add the alpha values that
; the guards look up (decompose thresholds, m_failure_wariness,
; help_short goal).
;
; Example: !(bind! &routeSpace (new-space))
!(bind! &routeSpace (new-space))
!(addAlpha  &routeSpace (alpha))
!(addState  &routeSpace
  (state (turn 0) (default-goals) (default-mods) (default-anti-goals) (alpha)))


; ─────────────────────────────────────────────
; get-action-score — look up score for an action in a list
;
; Returns ACTION_BLOCKED_SCORE when the action is absent.
;
; Example:
;   !(get-action-score ((Score act-search 10) (Score act-attack 5)) act-search)
;   ; => 10
; ─────────────────────────────────────────────
!(test (get-action-score ((Score act-search 10) (Score act-attack 5)) act-search)  10)
!(test (get-action-score ((Score act-search 10))                       act-search)  10)
!(test (get-action-score ((Score act-search 10) (Score act-attack 5)) act-attack)   5)
!(test (get-action-score ((Score act-search 10) (Score act-attack 5)) act-defend)   (ACTION_BLOCKED_SCORE))
!(test (get-action-score ()                                            act-search)   (ACTION_BLOCKED_SCORE))
; First match wins for duplicates
!(test (get-action-score ((Score act-search 10) (Score act-search 20)) act-search)  10)
; Float scores
!(test (get-action-score ((Score act-search 10.5) (Score act-attack 5.2)) act-search) 10.5)
!(test (get-action-score ((Score act-search 10.5) (Score act-attack 5.2)) act-attack)  5.2)


; ─────────────────────────────────────────────
; set-action-score — return new list with updated score for action
;
; If the action is absent it is appended to the list.
;
; Example:
;   !(set-action-score ((Score act-search 10) (Score act-attack 5)) act-search 15)
;   ; => ((Score act-search 15) (Score act-attack 5))
; ─────────────────────────────────────────────
!(test (set-action-score () act-search 10)
       ((Score act-search 10)))
!(test (set-action-score ((Score act-search 10) (Score act-attack 5)) act-search 15)
       ((Score act-search 15) (Score act-attack 5)))
!(test (set-action-score ((Score act-search 10) (Score act-attack 5)) act-attack 8)
       ((Score act-search 10) (Score act-attack 8)))
; Action not found — appended at the end
!(test (set-action-score ((Score act-search 10) (Score act-attack 5)) act-defend 12)
       ((Score act-search 10) (Score act-attack 5) (Score act-defend 12)))
; First occurrence updated only
!(test (set-action-score ((Score act-search 10) (Score act-search 20)) act-search 15)
       ((Score act-search 15) (Score act-search 20)))


; ─────────────────────────────────────────────
; adjust-action-score — add delta to an action's score
;
; No-op when the action is absent (score is BLOCKED).
;
; Example:
;   !(adjust-action-score ((Score act-search 10) ...) act-search 5)
;   ; => ((Score act-search 15) ...)
; ─────────────────────────────────────────────
!(test (adjust-action-score ((Score act-search 10) (Score act-attack 5)) act-search  5)
       ((Score act-search 15) (Score act-attack 5)))
!(test (adjust-action-score ((Score act-search 10) (Score act-attack 5)) act-attack -2)
       ((Score act-search 10) (Score act-attack 3)))
; Absent action — list unchanged
!(test (adjust-action-score ((Score act-search 10) (Score act-attack 5)) act-defend  3)
       ((Score act-search 10) (Score act-attack 5)))
!(test (adjust-action-score ()                                            act-search  5) ())
; First occurrence adjusted only
!(test (adjust-action-score ((Score act-search 10) (Score act-search 20)) act-search 5)
       ((Score act-search 15) (Score act-search 20)))


; ─────────────────────────────────────────────
; ctx-val — look up a value from a flat (key value) context list
;
; Returns 0.0 when the key is absent.
;
; Example:
;   !(ctx-val ((act-search 10) (act-attack 5)) act-search)  ; => 10
;   !(ctx-val () act-search)                                 ; => 0.0
; ─────────────────────────────────────────────
!(test (ctx-val ()                                       act-search) 0.0)
!(test (ctx-val ((act-search 10) (act-attack 5))         act-search) 10)
!(test (ctx-val ((act-search 10) (act-attack 5))         act-attack)  5)
!(test (ctx-val ((act-search 10) (act-attack 5))         act-defend) 0.0)
; First match wins for duplicates
!(test (ctx-val ((act-search 10) (act-search 20))        act-search) 10)


; ─────────────────────────────────────────────
; guard-decompose — block or penalise act_decompose
;
; Blocks when complexity is too low relative to thresholds,
; ambiguity is too high, or task-plan score doesn't justify it.
;
; $space is required for alpha lookup (decompose_min_complexity etc.).
;
; Example (blocked — complexity < urgent threshold):
;   !(guard-decompose ((Score act_decompose 10))
;       ((complexity 0.5) (ambiguity 0.2) (urgent_flag true) ...) &routeSpace)
;   ; => ((Score act_decompose -999.0))
; ─────────────────────────────────────────────
; Blocked: urgent + cx=0.5 < u_min=0.7
!(test (guard-decompose
  ((Score act_decompose 10))
  ((complexity 0.5) (ambiguity 0.2) (urgent_flag true)
   (needs_task_plan 0.3) (reflective_intent 0.8) (needs_external_evidence 0.4)
   (decompose_min_complexity 0.4) (decompose_urgent_min_complexity 0.7) (decompose_max_ambiguity 0.8))
  &routeSpace)
  ((Score act_decompose -999.0)))

; Blocked: cx=0.3 < min=0.4
!(test (guard-decompose
  ((Score act_decompose 10))
  ((complexity 0.3) (ambiguity 0.2) (urgent_flag true)
   (needs_task_plan 0.3) (reflective_intent 0.8) (needs_external_evidence 0.4)
   (decompose_min_complexity 0.4) (decompose_urgent_min_complexity 0.7) (decompose_max_ambiguity 0.8))
  &routeSpace)
  ((Score act_decompose -999.0)))

; Blocked: ambiguity=0.9 >= max_amb=0.8
!(test (guard-decompose
  ((Score act_decompose 10))
  ((complexity 0.5) (ambiguity 0.9) (urgent_flag true)
   (needs_task_plan 0.3) (reflective_intent 0.8) (needs_external_evidence 0.4)
   (decompose_min_complexity 0.4) (decompose_urgent_min_complexity 0.7) (decompose_max_ambiguity 0.8))
  &routeSpace)
  ((Score act_decompose -999.0)))

; Blocked: cx=0.5 < min_complexity=0.6 (non-urgent path)
!(test (guard-decompose
  ((Score act_decompose 10))
  ((complexity 0.5) (ambiguity 0.2) (urgent_flag true)
   (needs_task_plan 0.3) (reflective_intent 0.8) (needs_external_evidence 0.4)
   (decompose_min_complexity 0.6) (decompose_urgent_min_complexity 0.7) (decompose_max_ambiguity 0.8))
  &routeSpace)
  ((Score act_decompose -999.0)))

; Blocked: cx=0.5 < u_min=0.8
!(test (guard-decompose
  ((Score act_decompose 10))
  ((complexity 0.5) (ambiguity 0.2) (urgent_flag true)
   (needs_task_plan 0.3) (reflective_intent 0.8) (needs_external_evidence 0.4)
   (decompose_min_complexity 0.4) (decompose_urgent_min_complexity 0.8) (decompose_max_ambiguity 0.8))
  &routeSpace)
  ((Score act_decompose -999.0)))

; Not blocked: cx=0.8, not urgent, task=0.50 >= 0.45
!(test
  (guard-decompose
    ((Score act_decompose 10))
    ((complexity 0.8) (ambiguity 0.2) (urgent_flag false)
     (needs_task_plan 0.50) (reflective_intent 0.8) (needs_external_evidence 0.4)
     (decompose_min_complexity 0.4) (decompose_urgent_min_complexity 0.7) (decompose_max_ambiguity 0.8))
    &routeSpace)
  ((Score act_decompose 10)))

; Boost: task=0.65 => +0.10
!(test
  (guard-decompose
    ((Score act_decompose 10))
    ((complexity 0.8) (ambiguity 0.2) (urgent_flag false)
     (needs_task_plan 0.65) (reflective_intent 0.8) (needs_external_evidence 0.4)
     (decompose_min_complexity 0.4) (decompose_urgent_min_complexity 0.7) (decompose_max_ambiguity 0.8))
    &routeSpace)
  ((Score act_decompose 10.1)))

; Penalty: ext=0.8 and task=0.50 <= 0.55 => -0.30
!(test
  (guard-decompose
    ((Score act_decompose 10))
    ((complexity 0.8) (ambiguity 0.2) (urgent_flag false)
     (needs_task_plan 0.50) (reflective_intent 0.8) (needs_external_evidence 0.8)
     (decompose_min_complexity 0.4) (decompose_urgent_min_complexity 0.7) (decompose_max_ambiguity 0.8))
    &routeSpace)
  ((Score act_decompose 9.7)))


; ─────────────────────────────────────────────
; guard-search-synth — boost/block search and synthesize actions
;
; High external-evidence boosts search; high multi-source boosts synth.
; Low multi-source + verify=false blocks synth.
;
; Example:
;   High ext + high multi => search and synth both boosted
; ─────────────────────────────────────────────
; High ext + high multi: both boosted
!(test
  (guard-search-synth
    ((Score act_search 10) (Score act_synthesize 10))
    ((needs_external_evidence 0.70) (needs_task_plan 0.40)
     (needs_multi_source_integration 0.80) (verify_request false)))
  ((Score act_search 10.42) (Score act_synthesize 10.2)))

; Duplicate: same as above
!(test
  (guard-search-synth
    ((Score act_search 10) (Score act_synthesize 10))
    ((needs_external_evidence 0.70) (needs_task_plan 0.40)
     (needs_multi_source_integration 0.80) (verify_request false)))
  ((Score act_search 10.42) (Score act_synthesize 10.2)))

; Low ext + low multi + verify=false: search penalised, synth blocked
!(test
  (guard-search-synth
    ((Score act_search 10) (Score act_synthesize 10))
    ((needs_external_evidence 0.20) (needs_task_plan 0.50)
     (needs_multi_source_integration 0.40) (verify_request false)))
  ((Score act_search 9.82) (Score act_synthesize -999.0)))

; Low ext, low multi, but verify=true: no changes
!(test
  (guard-search-synth
    ((Score act_search 10) (Score act_synthesize 10))
    ((needs_external_evidence 0.20) (needs_task_plan 0.50)
     (needs_multi_source_integration 0.40) (verify_request true)))
  ((Score act_search 10) (Score act_synthesize 10)))

; Moderate ext, high multi, verify=true: synth boosted
!(test
  (guard-search-synth
    ((Score act_search 10) (Score act_synthesize 10))
    ((needs_external_evidence 0.40) (needs_task_plan 0.50)
     (needs_multi_source_integration 0.80) (verify_request true)))
  ((Score act_search 10) (Score act_synthesize 10.2)))

; Moderate ext, moderate multi, verify=false: synth blocked
!(test
  (guard-search-synth
    ((Score act_search 10) (Score act_synthesize 10))
    ((needs_external_evidence 0.40) (needs_task_plan 0.50)
     (needs_multi_source_integration 0.50) (verify_request false)))
  ((Score act_search 10) (Score act_synthesize -999.0)))

; High ext + high task: synth penalised by task weight
!(test
  (guard-search-synth
    ((Score act_search 10) (Score act_synthesize 10))
    ((needs_external_evidence 0.70) (needs_task_plan 0.75)
     (needs_multi_source_integration 0.70) (verify_request false)))
  ((Score act_search 10.3) (Score act_synthesize 9.979999999999999)))


; ─────────────────────────────────────────────
; guard-search-arb — arbitrate between search, decompose, synthesize
;
; When external evidence is dominant, boosts search and penalises decompose.
; When task-plan dominates, boosts decompose. When multi-source is high,
; boosts synthesize.
;
; Example:
;   High ext => search up, decompose down, synth slightly down
; ─────────────────────────────────────────────
; Balanced signals — no adjustment
!(test
  (guard-search-arb
    ((Score act_search 10) (Score act_decompose 10) (Score act_synthesize 10))
    ((needs_external_evidence 0.20) (needs_task_plan 0.50) (needs_multi_source_integration 0.40)))
  ((Score act_search 10) (Score act_decompose 10) (Score act_synthesize 10)))

; High ext dominates — search up, decompose down, synth down
!(test
  (guard-search-arb
    ((Score act_search 10) (Score act_decompose 10) (Score act_synthesize 10))
    ((needs_external_evidence 0.90) (needs_task_plan 0.50) (needs_multi_source_integration 0.80)))
  ((Score act_search 10.26) (Score act_decompose 9.74) (Score act_synthesize 9.88)))

; High task dominates — decompose up, search down, synth slightly down
!(test
  (guard-search-arb
    ((Score act_search 5) (Score act_decompose 5) (Score act_synthesize 5))
    ((needs_external_evidence 0.40) (needs_task_plan 0.75) (needs_multi_source_integration 0.50)))
  ((Score act_search 4.88) (Score act_decompose 5.18) (Score act_synthesize 4.9)))

; Multi-source dominates — synth up, decompose down
!(test
  (guard-search-arb
    ((Score act_search 7) (Score act_decompose 7) (Score act_synthesize 7))
    ((needs_external_evidence 0.50) (needs_task_plan 0.40) (needs_multi_source_integration 0.72)))
  ((Score act_search 7) (Score act_decompose 6.84) (Score act_synthesize 7.16)))

; Same balanced test at different base scores
!(test
  (guard-search-arb
    ((Score act_search 10) (Score act_decompose 10) (Score act_synthesize 10))
    ((needs_external_evidence 0.20) (needs_task_plan 0.50) (needs_multi_source_integration 0.40)))
  ((Score act_search 10) (Score act_decompose 10) (Score act_synthesize 10)))

; High ext + moderate multi — synth wins, decompose penalised
!(test
  (guard-search-arb
    ((Score act_search 3) (Score act_decompose 3) (Score act_synthesize 3))
    ((needs_external_evidence 0.70) (needs_task_plan 0.55) (needs_multi_source_integration 0.72)))
  ((Score act_search 3) (Score act_decompose 2.84) (Score act_synthesize 3.16)))

; Synth already blocked — bonus skipped for synth
!(test
  (guard-search-arb
    ((Score act_search 10) (Score act_decompose 10) (Score act_synthesize -1000000000))
    ((needs_external_evidence 0.90) (needs_task_plan 0.50) (needs_multi_source_integration 0.80)))
  ((Score act_search 10.26) (Score act_decompose 9.74) (Score act_synthesize -1000000000.0)))


; ─────────────────────────────────────────────
; guard-verify — block or boost act_verify
;
; Blocked when ambiguity >= 0.85 or verification conditions not met.
; Boosted when verify_request=1 (score +0.45).
;
; $space is required for getMod m_failure_wariness lookup.
;
; Example:
;   Ambiguity too high => verify blocked
; ─────────────────────────────────────────────
; Blocked: ambiguity >= 0.85
!(test
  (guard-verify
    ((Score act_verify 10) (Score act_synthesize 10))
    ((ambiguity 0.90) (threshold 0.60) (low_confidence 0.50) (failure_wariness 0.40)
     (verify_request true) (complexity 0.80) (intent_type mixed))
    &routeSpace)
  ((Score act_verify -999.0) (Score act_synthesize 10)))

; Blocked: conditions not met (low threshold, low fw, verify=false)
!(test
  (guard-verify
    ((Score act_verify 10))
    ((ambiguity 0.40) (threshold 0.50) (low_confidence 0.30) (failure_wariness 0.40)
     (verify_request false) (complexity 0.60) (intent_type reflective))
    &routeSpace)
  ((Score act_verify -999.0)))

; Verify requested: boosted +0.45, synth penalised -0.35
!(test
  (guard-verify
    ((Score act_verify 10) (Score act_synthesize 10))
    ((ambiguity 0.50) (threshold 0.60) (low_confidence 0.50) (failure_wariness 0.40)
     (verify_request true) (complexity 0.60) (intent_type mixed))
    &routeSpace)
  ((Score act_verify 10.45) (Score act_synthesize 9.65)))

; Reflective + high cx + no verify: penalised -0.20
!(test
  (guard-verify
    ((Score act_verify 10))
    ((ambiguity 0.50) (threshold 0.60) (low_confidence 0.50) (failure_wariness 0.40)
     (verify_request false) (complexity 0.80) (intent_type reflective))
    &routeSpace)
  ((Score act_verify 9.8)))

; Verify=true alone: boosted, no synth to penalise
!(test
  (guard-verify
    ((Score act_verify 10))
    ((ambiguity 0.50) (threshold 0.60) (low_confidence 0.50) (failure_wariness 0.40)
     (verify_request true) (complexity 0.60) (intent_type mixed))
    &routeSpace)
  ((Score act_verify 10.45)))


; ─────────────────────────────────────────────
; guard-fast-lane — bypass planning for simple, high-familiarity inputs
;
; Ultra-fast trigger: very low cx/ambiguity/threshold + high familiarity
; => verify, search, clarify, think all blocked; respond boosted +0.60.
;
; Fast-lane trigger: slightly relaxed conditions
; => search and clarify blocked; respond boosted +0.40.
;
; $space is required for getGoal help_short lookup.
;
; Example:
;   Very simple, familiar, no verify => respond fast lane activated
; ─────────────────────────────────────────────
; Ultra-fast: all planning blocked, respond +0.60
!(test
  (guard-fast-lane
    ((Score act_verify 10) (Score act_search 10) (Score act_clarify 10)
     (Score act_think 10) (Score act_respond 10))
    ((complexity 0.20) (ambiguity 0.20) (threshold_signal 0.20) (failure_signal 0.20)
     (familiarity_signal 0.80) (low_confidence 0.20) (verify_request false) (help_short 0.50))
    &routeSpace)
  ((Score act_verify -999.0) (Score act_search -999.0) (Score act_clarify -999.0)
   (Score act_think -999.0) (Score act_respond 10.60)))

; Moderate fast-lane: search + clarify blocked, respond +0.40, think and verify remain
!(test
  (guard-fast-lane
    ((Score act_verify 10) (Score act_search 10) (Score act_clarify 10)
     (Score act_think 10) (Score act_respond 10))
    ((complexity 0.40) (ambiguity 0.30) (threshold_signal 0.20) (failure_signal 0.20)
     (familiarity_signal 0.85) (low_confidence 0.25) (verify_request false) (help_short 0.60))
    &routeSpace)
  ((Score act_verify 10) (Score act_search -999.0) (Score act_clarify -999.0)
   (Score act_think 10) (Score act_respond 10.40)))

; High complexity — fast-lane not triggered, all scores unchanged
!(test
  (guard-fast-lane
    ((Score act_verify 10) (Score act_search 10) (Score act_clarify 10)
     (Score act_think 10) (Score act_respond 10))
    ((complexity 0.60) (ambiguity 0.20) (threshold_signal 0.20) (failure_signal 0.20)
     (familiarity_signal 0.90) (low_confidence 0.20) (verify_request false) (help_short 0.80))
    &routeSpace)
  ((Score act_verify 10) (Score act_search 10) (Score act_clarify 10)
   (Score act_think 10) (Score act_respond 10)))

; verify_request=true — fast-lane suppressed even when other signals qualify
!(test
  (guard-fast-lane
    ((Score act_verify 10) (Score act_search 10) (Score act_clarify 10)
     (Score act_think 10) (Score act_respond 10))
    ((complexity 0.10) (ambiguity 0.10) (threshold_signal 0.10) (failure_signal 0.10)
     (familiarity_signal 0.90) (low_confidence 0.10) (verify_request true) (help_short 0.80))
    &routeSpace)
  ((Score act_verify 10) (Score act_search 10) (Score act_clarify 10)
   (Score act_think 10) (Score act_respond 10)))


; ─────────────────────────────────────────────
; get-preferred — intent-based preferred action for tie-breaking
;
; factual    => act_search
; reflective => act_think
; other      => act_search when low_conf or threshold high; else act_think
;
; Example:
;   !(get-preferred factual 0.10 0.10)  ; => act_search
; ─────────────────────────────────────────────
!(test (get-preferred factual      0.10 0.10) act_search)
!(test (get-preferred reflective   0.10 0.10) act_think)
; exploratory + high low_conf (>= 0.40) => act_search
!(test (get-preferred exploratory  0.40 0.10) act_search)
; exploratory + low low_conf + low threshold => act_think
!(test (get-preferred exploratory  0.39 0.44) act_think)

!(abs-math 99)


; ─────────────────────────────────────────────
; select-action — choose best action with intent-based tie-breaking
;
; Returns (Result best-Score all-scores).
; When search and think are within margin, the preferred action
; for the intent type gets a score bump.
;
; Example:
;   search=15, think=10, margin=0.10 — clear winner, no tie-break
; ─────────────────────────────────────────────
; Clear winner (no tie)
!(test
  (select-action
    ((Score act_search 15) (Score act_think 10))
    ((intent_type factual) (low_confidence 0.20) (threshold 0.30))
    0.10)
  (Result (Score act_search 15)
          ((Score act_search 15) (Score act_think 10))))

; Tied — reflective prefers think, think gets bumped
!(test
  (select-action
    ((Score act_search 10) (Score act_think 10))
    ((intent_type reflective) (low_confidence 0.30) (threshold 0.40))
    0.20)
  (Result (Score act_think 10.2001)
          ((Score act_search 10) (Score act_think 10.2001))))

; Tied — factual prefers search, search gets bumped
!(test
  (select-action
    ((Score act_search 12) (Score act_think 12))
    ((intent_type factual) (low_confidence 0.30) (threshold 0.40))
    0.10)
  (Result (Score act_search 12.1001)
          ((Score act_search 12.1001) (Score act_think 12))))

; Not tied — clear win, reflective but no tie-break applied
!(test
  (select-action
    ((Score act_search 20) (Score act_think 10))
    ((intent_type reflective) (low_confidence 0.50) (threshold 0.50))
    0.10)
  (Result (Score act_search 20)
          ((Score act_search 20) (Score act_think 10))))


; ─────────────────────────────────────────────
; get-best-score — return the Score tuple with the highest value
;
; Example:
;   !(get-best-score ((Score act_search 10) (Score act_think 5)))
;   ; => (Score act_search 10)
; ─────────────────────────────────────────────
!(test
  (get-best-score ((Score act_search 10) (Score act_think 5)))
  (Score act_search 10))

!(test
  (get-best-score ((Score act_search 3) (Score act_think 12) (Score act_decompose 7)))
  (Score act_think 12))

; Tie: last element wins (right-biased)
!(test
  (get-best-score ((Score act_search 8) (Score act_think 8)))
  (Score act_think 8))


; ─────────────────────────────────────────────
; apply-routing-guards — full pipeline: decompose→search-synth→arb→verify→fast-lane
;
; Composes all guards in order and returns final adjusted scores.
;
; Example 1: Strong external evidence + verify requested
;   => search and verify both boosted
; ─────────────────────────────────────────────
; Full activation path
!(test
  (apply-routing-guards
    ((Score act_search 10) (Score act_decompose 10)
     (Score act_synthesize 10) (Score act_verify 10))
    ((needs_external_evidence 0.90) (needs_task_plan 0.50) (needs_multi_source_integration 0.80)
     (ambiguity 0.50) (threshold 0.60) (low_confidence 0.50) (failure_wariness 0.40)
     (verify_request true) (complexity 0.70) (intent_type mixed) (cx 0.60)
     (threshold_signal 0.30) (failure_signal 0.30) (familiarity_signal 0.60) (help_short 0.40))
    &routeSpace)
  ((Score act_search 10.56) (Score act_decompose 9.74)
   (Score act_synthesize 9.73) (Score act_verify 10.45)))

; Weak evidence, high task-plan, low verify — synth and verify blocked
!(test
  (apply-routing-guards
    ((Score act_search 8) (Score act_decompose 8)
     (Score act_synthesize 8) (Score act_verify 8))
    ((needs_external_evidence 0.30) (needs_task_plan 0.70) (needs_multi_source_integration 0.40)
     (ambiguity 0.40) (threshold 0.50) (low_confidence 0.30) (failure_wariness 0.30)
     (verify_request false) (complexity 0.60) (intent_type factual) (cx 0.50)
     (threshold_signal 0.20) (failure_signal 0.20) (familiarity_signal 0.50) (help_short 0.30))
    &routeSpace)
  ((Score act_search 8) (Score act_decompose 8)
   (Score act_synthesize -999.0) (Score act_verify -999.0)))
