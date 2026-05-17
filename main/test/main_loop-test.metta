; ─────────────────────────────────────────────
; main/test/main_loop-test.metta
;
; Scratchpad for exploring the main-loop space accessors.
; These snippets are reference examples, not executable assertions.
; Run via PeTTa: sh $PETTA_DIR/run.sh main/test/main_loop-test.metta
;
; Uncomment individual lines to inspect values interactively.
; ─────────────────────────────────────────────

; !(import! &self ../main-loop)
; !(import! &self ../../utils/general-helper)

; ── Space accessor explorations ──────────────────────────────
; !(bind! &sp (new-space))
; !(addAlpha &sp (alpha))
; !(addState &sp (state (turn 0) (default-goals) (default-mods) (default-anti-goals) (alpha)))

; Retrieve context signal:
; !(addContext (context))
; !(+ (* (- 1.0 (get-alpha resolution_alpha)) (getMod m_resolution))
;     (* (getAlpha resolution_alpha) (getContext complexity)))
; !(_clamp01 (+ (* (- 1.0 (get-alpha resolution_alpha)) (getMod m_resolution))
;               (* (getAlpha resolution_alpha) (getContext complexity))))

; ── Modulator inspection ─────────────────────────────────────
; !(getMods &sp)

; ── Batch modulator update ───────────────────────────────────
; !(update-mods &sp ((m_urgency 0.0) (m_resolution 0.9) (m_user_expertise 0.5)
;                    (m_threshold 0.3) (m_topic_familiarity 0.5) (m_failure_wariness 0.1)
;                    (m_securing 0.1) (m_approach 0.4) (m_arousal 0.4)
;                    (m_risk_aversion 0.4) (m_error_tolerance 0.45)
;                    (m_creativity 0.45) (m_valence 0)))
; !(get_state &sp)
