;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; operators/routing.metta
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!(import! &self ../utils/general-helper)
!(import! &self ../utils/utils)
!(import! &self ../../utils/constants)

;; ============================================================
;; 2. CORE UTILITIES
;; Score list shape:  ((Score act_search 10.0) (Score act_think 8.0) ...)
;; Context list shape: ((key value) (key value) ...)
;; ============================================================

;; -- Score lookup --
(= (get-action-score () $act)
   (ACTION-BLOCKED-SCORE))
(= (get-action-score $scores $act)
   (let* ((($head $rest) (decons $scores))
          ((Score $a $v) $head))
     (if (== $a $act) $v (get-action-score $rest $act))))

;; -- Score set (returns new list) --
(= (set-action-score () $act $new)
   ((Score $act $new)))
(= (set-action-score $scores $act $new)
   (let* ((($head $rest) (decons $scores))
          ((Score $a $v) $head))
     (if (== $a $act)
         (cons (Score $act $new) $rest)
         (cons $head (set-action-score $rest $act $new)))))

;; -- Score delta adjust --
(= (adjust-action-score $scores $act $delta)
   (let $current (get-action-score $scores $act)
     (if (== $current (ACTION-BLOCKED-SCORE))
         $scores
         (set-action-score $scores $act (+ $current $delta)))))

;; -- Context lookup --
(= (ctx-val () $key) 0.0)
(= (ctx-val $ctx $key)
   (let* ((($head $rest) (decons $ctx))
          (($k $v) $head))
     (if (== $k $key) $v (ctx-val $rest $key))))

;; ============================================================
;; 3. GUARD FUNCTIONS
;; ============================================================

;; GUARD: DECOMPOSE
;; Takes alpha params from $ctx (decompose_min_complexity etc.)
;; so it works both with a real $space and with inline ctx in tests.
(= (guard-decompose $scores $ctx $space)
   (let* (($cx      (ctx-val $ctx complexity))
          ($amb     (ctx-val $ctx ambiguity))
          ($urgent  (ctx-val $ctx urgent_flag))
          ($min     (ctx-val $ctx decompose_min_complexity))
          ($u_min   (ctx-val $ctx decompose_urgent_min_complexity))
          ($max_amb (ctx-val $ctx decompose_max_ambiguity))
          ($thr     (if (== $urgent true) $u_min $min))
          ($s1      (if (or (< $cx $thr) (>= $amb $max_amb))
                       (set-action-score $scores act_decompose (ACTION-BLOCKED-SCORE))
                       $scores))
          ($curr    (get-action-score $s1 act_decompose)))
     (if (== $curr (ACTION-BLOCKED-SCORE)) $s1
         (let* (($task (ctx-val $ctx needs_task_plan))
                ($refl (ctx-val $ctx reflective_intent))
                ($ext  (ctx-val $ctx needs_external_evidence)))
           (if (and (< $task 0.45)
                    (not (and (and (>= $cx 0.78) (<= $amb 0.35)) (>= $refl 0.75))))
               (set-action-score $s1 act_decompose (ACTION-BLOCKED-SCORE))
               (let* (($s2 (if (and (>= $ext 0.75) (<= $task 0.55))
                               (adjust-action-score $s1 act_decompose -0.30) $s1))
                      ($s3 (if (>= $task 0.60)
                               (adjust-action-score $s2 act_decompose 0.10) $s2)))
                 (if (and (<= $task 0.18) (< $cx 0.55))
                     (adjust-action-score $s3 act_decompose -0.30)
                     $s3)))))))

;; GUARD: SEARCH & SYNTHESIZE
(= (guard-search-synth $scores $ctx)
   (let* (($ext    (ctx-val $ctx needs_external_evidence))
          ($task   (ctx-val $ctx needs_task_plan))
          ($multi  (ctx-val $ctx needs_multi_source_integration))
          ($verify (ctx-val $ctx verify_request))
          ($s1 (if (>= $ext 0.60)
                   (let* (($b1    (adjust-action-score $scores act_search 0.30))
                          ($bonus (if (<= $task 0.45) 0.12 0.0)))
                     (adjust-action-score $b1 act_search $bonus))
                   (if (and (<= $ext 0.22) (== $verify 0))
                       (adjust-action-score $scores act_search -0.18)
                       $scores)))
          ($s2 (if (>= $multi 0.65)
                   (adjust-action-score $s1 act_synthesize 0.20)
                   (if (and (< $multi 0.65) (== $verify 0))
                       (set-action-score $s1 act_synthesize (ACTION-BLOCKED-SCORE))
                       $s1)))
          ($s3 (if (and (>= $task 0.70) (>= $task $multi))
                   (adjust-action-score $s2 act_synthesize -0.22)
                   $s2)))
     (if (and (>= $ext 0.85) (<= $task 0.45))
         (adjust-action-score $s3 act_synthesize -0.15)
         $s3)))

;; GUARD: SEARCH/DECOMPOSE ARBITRATION
(= (guard-search-arb $scores $ctx)
   (let* (($ext   (ctx-val $ctx needs_external_evidence))
          ($task  (ctx-val $ctx needs_task_plan))
          ($multi (ctx-val $ctx needs_multi_source_integration))
          ($s_v   (get-action-score $scores act_search))
          ($d_v   (get-action-score $scores act_decompose))
          ($z_v   (get-action-score $scores act_synthesize)))
     (if (and (> $s_v (ACTION-BLOCKED-SCORE)) (> $d_v (ACTION-BLOCKED-SCORE)))
         (if (and (>= $ext 0.70)
                  (and (>= $ext (+ $task 0.15)) (>= $ext (- $multi 0.02))))
             (let* (($b1      (adjust-action-score $scores act_search 0.26))
                    ($b2      (adjust-action-score $b1 act_decompose -0.26))
                    ($z_bonus (if (> $z_v (ACTION-BLOCKED-SCORE)) -0.12 0.0)))
               (adjust-action-score $b2 act_synthesize $z_bonus))
             (if (and (>= $task 0.72)
                      (and (>= $task (+ $ext 0.18)) (>= $task (+ $multi 0.12))))
                 (let* (($b1      (adjust-action-score $scores act_decompose 0.18))
                        ($b2      (adjust-action-score $b1 act_search -0.12))
                        ($z_bonus (if (> $z_v (ACTION-BLOCKED-SCORE)) -0.10 0.0)))
                   (adjust-action-score $b2 act_synthesize $z_bonus))
                 (if (and (> $z_v (ACTION-ACTIVE-FLOOR))
                          (and (>= $multi 0.72) (>= $multi (+ $task 0.15))))
                     (let* (($b1 (adjust-action-score $scores act_synthesize 0.16)))
                       (adjust-action-score $b1 act_decompose -0.16))
                     $scores)))
         $scores)))

;; GUARD: VERIFY
;; Uses $space only for getMod; ctx carries everything else.
(= (guard-verify $scores $ctx $space)
   (let* (($amb    (ctx-val $ctx ambiguity))
          ($thr    (ctx-val $ctx threshold))
          ($low    (- 1.0 $thr))
          ($fw     (ctx-val $ctx failure_wariness))
          ($verify (ctx-val $ctx verify_request))
          ($cx     (ctx-val $ctx complexity))
          ($intent (ctx-val $ctx intent_type))
          ($s1 (if (>= $amb 0.85)
                   (set-action-score $scores act_verify (ACTION-BLOCKED-SCORE))
                   (if (not (or (== $verify 1)
                                (or (and (>= $thr 0.55) (>= $low 0.40))
                                    (>= $fw 0.45))))
                       (set-action-score $scores act_verify (ACTION-BLOCKED-SCORE))
                       $scores)))
          ($curr (get-action-score $s1 act_verify)))
     (if (== $curr (ACTION-BLOCKED-SCORE)) $s1
         (let* (($s2 (if (== $verify 1)
                         (let* (($b1 (adjust-action-score $s1 act_verify 0.45)))
                           (adjust-action-score $b1 act_synthesize -0.35))
                         $s1)))
           (if (and (and (== $verify 0) (>= $cx 0.70))
                    (and (<= $amb 0.65)
                         (or (== $intent mixed) (== $intent reflective))))
               (adjust-action-score $s2 act_verify -0.20)
               $s2)))))

;; GUARD: FAST LANE
;; Uses $space only for getGoal; ctx carries everything else.
(= (guard-fast-lane $scores $ctx $space)
   (let* (($cx     (ctx-val $ctx complexity))
          ($amb    (ctx-val $ctx ambiguity))
          ($th_s   (ctx-val $ctx threshold_signal))
          ($fail_s (ctx-val $ctx failure_signal))
          ($fam_s  (ctx-val $ctx familiarity_signal))
          ($low    (- 1.0 (ctx-val $ctx threshold)))
          ($verify (ctx-val $ctx verify_request))
          ($s1 (if (and (and (<= $cx 0.30)
                             (and (<= $amb 0.30) (<= $th_s 0.25)))
                        (and (and (<= $fail_s 0.25) (>= $fam_s 0.70))
                             (and (<= $low 0.35) (== $verify 0))))
                   (let* (($b1 (set-action-score $scores  act_verify  (ACTION-BLOCKED-SCORE)))
                          ($b2 (set-action-score $b1      act_search  (ACTION-BLOCKED-SCORE)))
                          ($b3 (set-action-score $b2      act_clarify (ACTION-BLOCKED-SCORE)))
                          ($b4 (set-action-score $b3      act_think   (ACTION-BLOCKED-SCORE))))
                     (adjust-action-score $b4 act_respond 0.60))
                   $scores))
          ($help (let $h (ctx-val $ctx help_short)
                   (if (== $h 0.0)
                       (let $g (getGoal $space help_short) $g)
                       $h))))
     (if (and (and (<= $cx 0.45)
                   (and (<= $amb 0.35) (<= $th_s 0.20)))
              (and (and (<= $low 0.30) (>= $fam_s 0.80))
                   (and (>= $help 0.55) (== $verify 0))))
         (let* (($b1 (set-action-score $s1 act_clarify (ACTION-BLOCKED-SCORE)))
                ($b2 (set-action-score $b1 act_search  (ACTION-BLOCKED-SCORE))))
           (adjust-action-score $b2 act_respond 0.40))
         $s1)))

;; ============================================================
;; 4. SELECTION ENGINE
;; ============================================================

(= (get-preferred factual $low_conf $threshold) act_search)
(= (get-preferred reflective $low_conf $threshold) act_think)
(= (get-preferred $intent $low_conf $threshold)
   (if (and (not (== $intent factual))
            (not (== $intent reflective)))
       (if (or (>= $low_conf 0.40) (>= $threshold 0.45))
           act_search
           act_think)))

(= (get-best-score ($head)) $head)
(= (get-best-score $scores)
   (let* ((($head $rest) (decons $scores))
          ((Score $a1 $v1) $head)
          ((Score $a2 $v2) (get-best-score $rest)))
     (if (> $v1 $v2) (Score $a1 $v1) (Score $a2 $v2))))

(= (select-action $scores $ctx $margin)
   (let* (($s_v    (get-action-score $scores act_search))
          ($t_v    (get-action-score $scores act_think))
          ($intent (ctx-val $ctx intent_type))
          ($low    (ctx-val $ctx low_confidence))
          ($th     (ctx-val $ctx threshold))
          ($is_tie (and (> $s_v (ACTION-BLOCKED-SCORE))
                        (and (> $t_v (ACTION-BLOCKED-SCORE))
                             (<= (abs-math (- $s_v $t_v)) $margin)))))
     (if $is_tie
         (let* (($pref         (get-preferred $intent $low $th))
                ($max_v        (if (> $s_v $t_v) $s_v $t_v))
                ($new_v        (+ $max_v (+ $margin 0.0001)))
                ($final_scores (set-action-score $scores $pref $new_v)))
           (Result (get-best-score $final_scores) $final_scores))
         (Result (get-best-score $scores) $scores))))

(= (apply-routing-guards $initial_scores $ctx $space)
   (guard-fast-lane
     (guard-verify
       (guard-search-arb
         (guard-search-synth
           (guard-decompose $initial_scores $ctx $space)
           $ctx)
         $ctx)
       $ctx $space)
     $ctx $space))
