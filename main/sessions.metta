(= (get-sessions)
   (let* (
      ($raw (py-call (run_sessions.load_queries)))
      ($sessions (parse $raw))
   )
   $sessions
   )
)
 

(= (run-session $space $session)
   (if (== $session ())
       ()
       (let* (
           ($q (car-atom $session))
           ($rest (cdr-atom $session))
           ($result (full-step $space $q))
       )
       (cons-atom $result (run-session $space $rest))
       )
   )
)

(= (run-all-sessions $space $sessions)
   (if (== $sessions ())
       ()
       (let* (
           ($s (car-atom $sessions))
           ($rest (cdr-atom $sessions))
           ($session-results (run-session $space $s))
       )
       (cons-atom $session-results (run-all-sessions $space $rest))
       )
   )
)

