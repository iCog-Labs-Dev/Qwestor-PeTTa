(= (get-sessions)
   (let* (
      ($raw (py-call (run_sessions.load_queries)))
      ($sessions (parse $raw))
   )
   $sessions
   )
)
 

(= (run-session $space $session)
   (case $session
     (
       (()  ())
       ((Cons $q $rest)
        (let $result (full-step $space $q)
             (Cons $result (run-session $space $rest))))
     )
   )
)

(= (run-all-sessions $space $sessions)
   (case $sessions
     (
       (() ())
       ((Cons $s $rest)
        (let $session-results (run-session $space $s)
             (Cons $session-results (run-all-sessions $space $rest))))
     )
   )
)
