; ─────────────────────────────────────────────
; operators/appraisal.metta
; ─────────────────────────────────────────────

!(import! &self ../utils/general-helper)
!(import! &self ../utils/utils)

; ── Bulk atom loader ─────────────────────────
(= (addItems $baseCase $space $items)
   (if (== $items ())
        $baseCase
        (let* (
               ($h (car-atom $items))
               ($t (cdr-atom $items))
               ($_ (add-atom $space $h))
               )
          (addItems $baseCase $space $t))))

(= (addAlpha    $space $list) (addItems () $space $list))
(= (add-context $space $list) (addItems () $space $list))

; ── Alpha hyper-parameters ───────────────────
(= (alpha)
  (
    (urgency_alpha              0.60)
    (resolution_alpha           0.45)
    (expertise_alpha            0.45)
    (threshold_alpha            0.40)
    (familiarity_alpha          0.35)
    (failure_alpha              0.55)
    (failure_decay              0.20)
    (securing_alpha             0.45)
    (approach_alpha             0.40)
    (arousal_alpha              0.40)
    (risk_aversion_alpha        0.45)
    (error_tolerance_alpha      0.40)
    (creativity_alpha           0.40)
    (valence_alpha              0.40)
    (goal_alpha                 0.18)
    (anti_goal_alpha            0.16)
    (cold_start_horizon         2.0)
    (cold_start_strength        0.70)
    (decompose_min_complexity   0.60)
    (decompose_urgent_min_complexity 0.70)
    (decompose_max_ambiguity    0.70)
    (reflective_think_bonus     0.14)
    (reflective_search_penalty  0.10)
    (intent_margin              0.12)
    (enable_homeostasis         0)
    (homeostasis_theta_safe     0.55)
    (homeostasis_eta            0.05)
    (homeostasis_alpha_near     0.10)
  )
)

; ── Default modulator vector ─────────────────
(= (default-mods) (modulator-vector
    (m_urgency           0.20)
    (m_resolution        0.40)
    (m_user_expertise    0.50)
    (m_threshold         0.30)
    (m_topic_familiarity 0.50)
    (m_failure_wariness  0.10)
    (m_securing          0.10)
    (m_approach          0.40)
    (m_arousal           0.40)
    (m_risk_aversion     0.40)
    (m_error_tolerance   0.45)
    (m_creativity        0.45)
    (m_valence           0.00)
))

; ── Default context ──────────────────────────
(= (context) (
   (complexity              0.30)
   (threshold               0.30)
   (ambiguity               0.00)
   (urgent                  0.00)
   (intent_type             mixed)
   (expertise               0.50)
   (topic_familiarity       0.50)
   (failure_signal          0.30)
   (verify_request          False)
   (reflective_intent       0.50)
   (needs_external_evidence 0.30)
   (needs_task_plan         0.20)
   (needs_multi_source_integration 0.30)
   (valence                 0.00)
))

; ── Default goal vector ──────────────────────
(= (default-goals) (goal-vector
    (efficiency           0.60)
    (accuracy             0.70)
    (success_moderate     0.62)
    (knowledge            0.52)
    (novelty              0.46)
    (success_breakthrough 0.44)
    (coherence            0.58)
    (originality          0.48)
    (social               0.58)
    (help_short           0.55)
    (help_long            0.45)
    (over_beneficial      0.60)
    (over_safety          0.65)
    (over_honesty         0.65)
))

; ── Default anti-goal vector ─────────────────
(= (default-anti-goals) (anti-goals
    (hallucinate 0.35)
    (redundant   0.30)
    (rabbit_hole 0.28)
    (premature   0.30)
))

; ── _effective — cold-start blending ─────────
(= (_effective $smoothed $rawSignal $coldWeight)
    (eval (_clamp01
        (+ (* (- 1.0 $coldWeight) $smoothed)
           (* $coldWeight $rawSignal)))))

; ── appraisalModulator ───────────────────────
(= (appraisalModulator $space)
    (let*
      (
        ($cx  (getContext $space complexity))
        ($amb (getContext $space ambiguity))
        ($exp (getContext $space expertise))
        ($thr (getContext $space threshold))
        ($fs  (getContext $space failure_signal))
        ($fam (getContext $space topic_familiarity))
        ($ri  (getContext $space reflective_intent))
        ($vr  (getContext $space verify_request))
        ($urg (getContext $space urgent))
        ($val (getContext $space valence))
        ($target_u (if (== $urg 1) 1.0 0.0))

        ; 1. m_urgency
        ($m_urgency
          (eval (_clamp01 (+
            (* (- 1.0 (getAlpha $space urgency_alpha))   (getMod $space m_urgency))
            (* (getAlpha $space urgency_alpha)           $target_u)))))

        ; 2. m_resolution
        ($m_resolution
          (eval (_clamp01 (+
            (* (- 1.0 (getAlpha $space resolution_alpha)) (getMod $space m_resolution))
            (* (getAlpha $space resolution_alpha)         $cx)))))

        ; 3. m_user_expertise
        ($m_user_expertise
          (eval (_clamp01 (+
            (* (- 1.0 (getAlpha $space expertise_alpha)) (getMod $space m_user_expertise))
            (* (getAlpha $space expertise_alpha)         $exp)))))

        ; 4. m_threshold
        ($m_threshold
          (eval (_clamp01 (+
            (* (- 1.0 (getAlpha $space threshold_alpha)) (getMod $space m_threshold))
            (* (getAlpha $space threshold_alpha)         $thr)))))

        ; 5. m_topic_familiarity
        ($m_topic_familiarity
          (eval (_clamp01 (+
            (* (- 1.0 (getAlpha $space familiarity_alpha)) (getMod $space m_topic_familiarity))
            (* (getAlpha $space familiarity_alpha)         $fam)))))

        ; 6. m_failure_wariness
        ($m_failure_wariness
          (eval (_clamp01 (+
            (* (- 1.0 (getAlpha $space failure_decay)) (getMod $space m_failure_wariness))
            (* (getAlpha $space failure_decay)         $fs)))))

        ; 7. m_securing
        ($securing_target
          (eval (_clamp01 (+
            (* 0.50 $thr)
            (+ (* 0.30 $fs) (* 0.20 $amb))))))
        ($m_securing
          (eval (_clamp01 (+
            (* (- 1.0 (getAlpha $space securing_alpha)) (getMod $space m_securing))
            (* (getAlpha $space securing_alpha)         $securing_target)))))

        ; 8. m_approach
        ($approach_target
          (eval (_clamp01 (+
            (* 0.45 $cx)
            (+ (* 0.25 (- 1.0 $amb))
               (+ (* 0.20 (- 1.0 $thr))
                  (* 0.10 (- 1.0 $fs))))))))
        ($m_approach
          (eval (_clamp01 (+
            (* (- 1.0 (getAlpha $space approach_alpha)) (getMod $space m_approach))
            (* (getAlpha $space approach_alpha)         $approach_target)))))

        ; 9. m_arousal
        ($novelty_signal
          (eval (_clamp01 (+
            (* 0.35 $cx)
            (+ (* 0.35 (- 1.0 $fam))
               (+ (* 0.20 $ri) (* 0.10 $amb)))))))
        ($arousal_target
          (eval (_clamp01 (+
            0.25
            (+ (* 0.40 $m_urgency)
               (+ (* 0.35 $novelty_signal)
                  (* 0.20 $cx)))))))
        ($m_arousal
          (eval (_clamp01 (+
            (* (- 1.0 (getAlpha $space arousal_alpha)) (getMod $space m_arousal))
            (* (getAlpha $space arousal_alpha)         $arousal_target)))))

        ; 10. m_risk_aversion
        ($risk_aversion_target
          (eval (_clamp01 (+
            (* 0.40 $thr)
            (+ (* 0.30 $fs)
               (+ (* 0.20 $amb)
                  (* 0.10 (if (== $urg 1) 1 0))))))))
        ($m_risk_aversion
          (eval (_clamp01 (+
            (* (- 1.0 (getAlpha $space risk_aversion_alpha)) (getMod $space m_risk_aversion))
            (* (getAlpha $space risk_aversion_alpha)         $risk_aversion_target)))))

        ; 11. m_error_tolerance
        ($error_tolerance_target
          (eval (_clamp01 (+
            0.45
            (+ (* 0.25 (- 1.0 $thr))
               (+ (* 0.20 $fam)
                  (+ (* 0.15 (- 1.0 $fs))
                     (- (* -0.20 $amb)
                        (* 0.10 (if (== $urg 1) 1 0))))))))))
        ($m_error_tolerance
          (eval (_clamp01 (+
            (* (- 1.0 (getAlpha $space error_tolerance_alpha)) (getMod $space m_error_tolerance))
            (* (getAlpha $space error_tolerance_alpha)         $error_tolerance_target)))))

        ; 12. m_creativity
        ($creativity_target
          (eval (_clamp01 (+
            0.30
            (+ (* 0.30 (- 1.0 $fam))
               (+ (* 0.20 $cx)
                  (+ (* 0.15 (- 1.0 $thr))
                     (- (* 0.20 $ri) (* 0.10 $fs)))))))))
        ($m_creativity
          (eval (_clamp01 (+
            (* (- 1.0 (getAlpha $space creativity_alpha)) (getMod $space m_creativity))
            (* (getAlpha $space creativity_alpha)         $creativity_target)))))

        ; 13. m_valence
        ($valence_target
          (eval (_clamp11 (- $val (* 0.10 $fs)))))
        ($m_valence
          (eval (_clamp11 (+
            (* (- 1.0 (getAlpha $space valence_alpha)) (getMod $space m_valence))
            (* (getAlpha $space valence_alpha)         $valence_target)))))

        ; ── cold-start weight ────────────────
        ($cold_start_horizon  (getAlpha $space cold_start_horizon))
        ($cold_start_strength (getAlpha $space cold_start_strength))
        ($turn_count (match $space (state (turn $n) $g $m $ag $al) $n))
        ($cold_phase  (/ (- $cold_start_horizon $turn_count) $cold_start_horizon))
        ($coldWeight  (if (and (> $cold_start_horizon 0.0) (> $cold_start_strength $turn_count))
                         (eval (_clamp01 (* $cold_start_strength $cold_phase)))
                         0.0))

        ; ── effective (cold-blended) signals ─
        ($u               (_effective $m_urgency           $target_u             $coldWeight))
        ($res             (_effective $m_resolution        $cx                   $coldWeight))
        ($ux              (_effective $m_user_expertise    $exp                  $coldWeight))
        ($threshold       (_effective $m_threshold         $thr                  $coldWeight))
        ($securing        (_effective $m_securing          $securing_target      $coldWeight))
        ($approach        (_effective $m_approach          $approach_target      $coldWeight))
        ($arousal         (_effective $m_arousal           $arousal_target       $coldWeight))
        ($risk_aversion   (_effective $m_risk_aversion     $risk_aversion_target $coldWeight))
        ($error_tolerance (_effective $m_error_tolerance   $error_tolerance_target $coldWeight))
        ($creativity      (_effective $m_creativity        $creativity_target    $coldWeight))
        ($valence         (eval (_clamp11 (* (- 1.0 $coldWeight)
                                            (* (+ (getContext $space valence) $coldWeight)
                                               (getContext $space valence))))))

        ; ── persist updated modulators ───────
        ($updatedMods (
            (m_urgency           $m_urgency)
            (m_resolution        $m_resolution)
            (m_user_expertise    $m_user_expertise)
            (m_threshold         $m_threshold)
            (m_topic_familiarity $m_topic_familiarity)
            (m_failure_wariness  $m_failure_wariness)
            (m_securing          $m_securing)
            (m_approach          $m_approach)
            (m_arousal           $m_arousal)
            (m_risk_aversion     $m_risk_aversion)
            (m_error_tolerance   $m_error_tolerance)
            (m_creativity        $m_creativity)
            (m_valence           $m_valence)))
        ($_ (update-mods $space $updatedMods))

        ($intentType              (getContext $space intent_type))
        ($needsExternalEvidence   (getContext $space needs_external_evidence))
        ($needsTaskPlan           (getContext $space needs_task_plan))
        ($needsMultiSourceIntegration (getContext $space needs_multi_source_integration))

        ($results (
            (turn              $turn_count)
            (cold_weight       $coldWeight)
            (complexity        $cx)
            (ambiguity         $amb)
            (expertise         $exp)
            (threshold_signal  $thr)
            (familiarity_signal $fam)
            (failure_signal    $fs)
            (urgent_flag       $urg)
            (intent_type       $intentType)
            (verify_request    $vr)
            (reflective_intent $ri)
            (needs_external_evidence $needsExternalEvidence)
            (needs_task_plan   $needsTaskPlan)
            (needs_multi_source_integration $needsMultiSourceIntegration)
            (urgency           $u)
            (resolution        $res)
            (user_expertise    $ux)
            (threshold         $threshold)
            (securing          $securing)
            (approach          $approach)
            (arousal           $arousal)
            (risk_aversion     $risk_aversion)
            (error_tolerance   $error_tolerance)
            (creativity        $creativity)
            (valence           $valence)))
      )
      $results
    )
)
