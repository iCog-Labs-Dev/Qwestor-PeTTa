; ─────────────────────────────────────────────
; operators/test/appraisal-test.metta
;
; Tests for space accessors and modulator helpers defined in
; operators/appraisal.metta.
; Run via PeTTa: sh $PETTA_DIR/run.sh operators/test/appraisal-test.metta
;
; Coverage:
;   getMods, getMod, getContext, getAlpha,
;   get-goals, get_state, remove-state, addState, update-mods,
;   getAntiGoals
; ─────────────────────────────────────────────

!(import! &self ../space)
!(import! &self ../appraisal)
!(import! &self ../action)
!(import! &self ../decision)
!(import! &self ../../main/main-loop)
!(import! &self ../../utils/general-helper)

; ── Set up shared space ──────────────────────────────────────
; Bind a fresh space and populate it with default state,
; alpha hyper-parameters, and context signals.
;
; Example: !(bind! &space (new-space))
!(bind! &space (new-space))
!(addAlpha    &space (alpha))
!(addContexts &space (context))
!(addState    &space (state (turn 0) (default-goals) (default-mods) (default-anti-goals) (alpha)))


; ─────────────────────────────────────────────
; getMods — retrieve the whole modulator vector from the space
;
; Example:
;   !(getMods &space)  ; => (default-mods)
; ─────────────────────────────────────────────
!(test (getMods &space) (default-mods))


; ─────────────────────────────────────────────
; getMod — retrieve a single modulator value by name
;
; Example:
;   !(getMod &space m_urgency)          ; => 0.20
;   !(getMod &space m_failure_wariness) ; => 0.10
; ─────────────────────────────────────────────
!(test (getMod &space m_urgency)          0.20)
!(test (getMod &space m_failure_wariness) 0.1)
!(test (getMod &space m_error_tolerance)  0.45)


; ─────────────────────────────────────────────
; get-goals — retrieve the goal vector from the space
;
; Example:
;   !(get-goals &space)  ; => (default-goals)
; ─────────────────────────────────────────────
!(test (get-goals &space) (default-goals))


; ─────────────────────────────────────────────
; get_state — retrieve the full state atom from the space
;
; Example:
;   !(get_state &space)
;   ; => (state (turn 0) (default-goals) (default-mods)
;   ;           (default-anti-goals) (alpha))
; ─────────────────────────────────────────────
!(test (get_state &space)
       (state (turn 0) (default-goals) (default-mods) (default-anti-goals) (alpha)))


; ─────────────────────────────────────────────
; remove-state / addState — round-trip: remove then re-add state
;
; After (remove-state &space), (get_state &space) returns ()
; indicating the state atom was removed.
;
; Example:
;   !(let* (($_ (remove-state &space)) ($s (get_state &space))) $s)
;   ; => ()
; ─────────────────────────────────────────────
!(test (let* (($_ (remove-state &space))
              ($state (get_state &space)))
         $state)
       ())

; Restore state for subsequent tests
!(addState &space (state (turn 0) (default-goals) (default-mods) (default-anti-goals) (alpha)))


; ─────────────────────────────────────────────
; getContext — retrieve a single context signal by name
;
; Example:
;   !(getContext &space complexity)       ; => 0.30
;   !(getContext &space intent_type)      ; => mixed
;   !(getContext &space reflective_intent); => 0.50
; ─────────────────────────────────────────────
!(test (getContext &space complexity)        0.30)
!(test (getContext &space intent_type)       mixed)
!(test (getContext &space reflective_intent) 0.50)


; ─────────────────────────────────────────────
; getAlpha — retrieve a single alpha hyper-parameter by name
;
; Example:
;   !(getAlpha &space urgency_alpha)  ; => 0.60
;   !(getAlpha &space valence_alpha)  ; => 0.40
;   !(getAlpha &space intent_margin)  ; => 0.12
; ─────────────────────────────────────────────
!(test (getAlpha &space urgency_alpha) 0.60)
!(test (getAlpha &space valence_alpha) 0.40)
!(test (getAlpha &space intent_margin) 0.12)


; ─────────────────────────────────────────────
; update-mods — replace the whole modulator vector in the space
;
; After calling update-mods with a new vector,
; getMods should return exactly that new vector.
;
; Example:
;   !(update-mods &space ((m_urgency 0.10) ...))
;   !(getMods &space)  ; => (modulator-vector (m_urgency 0.10) ...)
; ─────────────────────────────────────────────
!(test
  (let* (($_ (update-mods &space (
               (m_urgency           0.10)
               (m_resolution        0.40)
               (m_user_expertise    0.50)
               (m_threshold         0.30)
               (m_topic_familiarity 0.60)
               (m_failure_wariness  0.10)
               (m_securing          0.10)
               (m_approach          0.40)
               (m_arousal           0.40)
               (m_risk_aversion     0.20)
               (m_error_tolerance   0.45)
               (m_creativity        0.45)
               (m_valence           0.13)
             )))
         ($new_mods (getMods &space)))
    $new_mods)
  (modulator-vector
    (m_urgency           0.10)
    (m_resolution        0.40)
    (m_user_expertise    0.50)
    (m_threshold         0.30)
    (m_topic_familiarity 0.60)
    (m_failure_wariness  0.10)
    (m_securing          0.10)
    (m_approach          0.40)
    (m_arousal           0.40)
    (m_risk_aversion     0.20)
    (m_error_tolerance   0.45)
    (m_creativity        0.45)
    (m_valence           0.13)
  ))


; ─────────────────────────────────────────────
; getAntiGoals — retrieve the anti-goal vector from the space
;
; Example:
;   !(getAntiGoals &space)  ; => (default-anti-goals)
; ─────────────────────────────────────────────
!(test (getAntiGoals &space) (default-anti-goals))
