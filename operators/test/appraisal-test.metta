!(import! &self ../space)
!(import! &self ../appraisal)
!(import! &self ../action)
!(import! &self ../decision)
!(import! &self ../../main/main-loop)
!(import! &self ../../utils/general-helper)

; --------------- adding state and parameters to the space ---------------
!(bind! &space (new-space))
!(addAlpha &space (alpha))
!(addContexts &space (context))

!(addState &space (state (turn 0) (default-goals) (default-mods) (default-anti-goals) (alpha)))
; !(match  &space (state $x $y $z) (state $x $y $z))

; --------------- adding actions to the space -----------------------------
; !(let $x (goalWeight &space) $x)
!(addActions &space (Actions &space))
; !(update-goal &space kcnowledge 0.7)
; ── example usage ───────────────────────────────────────────
; !(selectAction ((act_think 0.7) (act_search 0.72)) factual 0.35 0.44 0.03)
; !(getGoal &space over_honesty)
; !(let $x (goalWeight &space) $x)
; !(match  &space (AG $action $params) (AG $action $params))
; !(getGoals &space)
!(update-goal &space over_honesty 0.99997)
; !(getGoal &space over_honesty)
; !(goalWeight &space)
!(appraisalModulator &space)
