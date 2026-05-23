; ─────────────────────────────────────────────
; operators/test/decision_test.metta
; ─────────────────────────────────────────────

!(import! &self ../../utils/general-helper)
!(import! &self ../../utils/utils)
!(import! &self ../appraisal)
!(import! &self ../homeostasis)
!(import! &self ../decision)

!(bind! &space (new-space))
!(bind! &StyleSpace (new-space))

!(addAlpha   &space (alpha))
!(addState   &space (state (turn 0) (default-goals) (default-mods) (default-anti-goals) (alpha)))
!(add-context &space (context))

; ── selectAction ─────────────────────────────
; Score list shape (7 fixed positions):
;   (act_respond act_search act_verify act_clarify act_decompose act_think act_synthesize)

; Test 1: tie (diff=0.02 <= margin=0.03), factual → prefer search → new_score=0.7501
!(test (selectAction ((act_think 0.7) (act_search 0.72)) factual 0.35 0.44 0.03)
  (act_search ((act_search 0.7501) (act_think 0.7))))

!(test (selectAction ((act_think 0.60) (act_search 0.90)) factual 0.35 0.44 0.03)
  (act_search ((act_search 0.9) (act_think 0.6))))

!(test (selectAction ((act_think 0.80) (act_search 0.80)) reflective 0.20 0.40 0.05)
  (act_think ((act_think 0.8501000000000001) (act_search 0.8))))

; ── getGoal ──────────────────────────────────
!(test (getGoal &space efficiency)           0.60)
!(test (getGoal &space accuracy)             0.70)
!(test (getGoal &space success_moderate)     0.62)
!(test (getGoal &space knowledge)            0.52)
!(test (getGoal &space novelty)              0.46)
!(test (getGoal &space success_breakthrough) 0.44)
!(test (getGoal &space coherence)            0.58)
!(test (getGoal &space originality)          0.48)
!(test (getGoal &space social)               0.58)
!(test (getGoal &space help_short)           0.55)
!(test (getGoal &space help_long)            0.45)
!(test (getGoal &space over_beneficial)      0.60)
!(test (getGoal &space over_safety)          0.65)
!(test (getGoal &space over_honesty)         0.65)

; ── goalTarget-get ───────────────────────────
!(test (goalTarget-get
  (goal-vector (efficiency 0.10) (accuracy 0.20) (success_moderate 0.30)
   (knowledge 0.40) (novelty 0.50) (success_breakthrough 0.60) (coherence 0.70)
   (originality 0.80) (social 0.90) (help_short 0.15) (help_long 0.25)
   (over_beneficial 0.35) (over_safety 0.45) (over_honesty 0.55))
  efficiency) (0.10))

!(test (goalTarget-get
  (goal-vector (efficiency 0.10) (accuracy 0.20) (success_moderate 0.30)
   (knowledge 0.40) (novelty 0.50) (success_breakthrough 0.60) (coherence 0.70)
   (originality 0.80) (social 0.90) (help_short 0.15) (help_long 0.25)
   (over_beneficial 0.35) (over_safety 0.45) (over_honesty 0.55))
  accuracy) (0.20))

; ── antiGoal-get ─────────────────────────────
!(test (antiGoal-get
  (anti-goals (hallucinate 0.35) (redundant 0.30) (rabbit_hole 0.28) (premature 0.30))
  hallucinate) (0.35))
!(test (antiGoal-get
  (anti-goals (hallucinate 0.35) (redundant 0.30) (rabbit_hole 0.28) (premature 0.30))
  redundant) (0.30))
!(test (antiGoal-get
  (anti-goals (hallucinate 0.35) (redundant 0.30) (rabbit_hole 0.28) (premature 0.30))
  premature) (0.30))

; ── updateAntiGoals ──────────────────────────
!(test (updateAntiGoals &space 0.10 0.20 0.30 0.40) "anti-goals updated")

; ── determine-respond-style ──────────────────
!(test (determine-respond-style &StyleSpace
  ((urgency 0.95) (complexity 0.10) (ambiguity 0.05) (user_expertise 0.5) (threshold 0.3)
   (failure_wariness 0.2) (low_confidence 0.2) (resolution 0.4) (approach 0.4)
   (creativity 0.3) (risk_aversion 0.2) (verify_request false)))
  style_concise)

!(test (determine-respond-style space
  ((urgency 0.1) (complexity 0.95) (ambiguity 0.4) (user_expertise 0.5) (threshold 0.4)
   (failure_wariness 0.2) (low_confidence 0.3) (resolution 0.9) (approach 0.4)
   (creativity 0.3) (risk_aversion 0.2) (verify_request false)))
  style_thorough)

!(test (determine-respond-style space
  ((urgency 0.2) (complexity 0.6) (ambiguity 0.5) (user_expertise 0.5) (threshold 0.2)
   (failure_wariness 0.1) (low_confidence 0.2) (resolution 0.4) (approach 0.95)
   (creativity 0.95) (risk_aversion 0.05) (verify_request false)))
  style_exploratory)

!(test (determine-respond-style space
  ((urgency 0.3) (complexity 0.4) (ambiguity 0.6) (user_expertise 0.6) (threshold 0.9)
   (failure_wariness 0.9) (low_confidence 0.95) (resolution 0.4) (approach 0.3)
   (creativity 0.3) (risk_aversion 0.9) (verify_request true)))
  style_cautious)

!(test (determine-respond-style space
  ((urgency 0.2) (complexity 0.3) (ambiguity 0.6) (user_expertise 0.05) (threshold 0.3)
   (failure_wariness 0.2) (low_confidence 0.2) (resolution 0.3) (approach 0.3)
   (creativity 0.3) (risk_aversion 0.2) (verify_request false)))
  style_tutorial)

; ── post-update ──────────────────────────────
!(test (post-update &space act_search) "post-update complete")
!(test (match &space (state (turn $t) $g $m $anti $alpha) $t) 1)
