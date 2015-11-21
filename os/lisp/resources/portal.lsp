(let (fail-conditions (lambda (power)
                        (cond (> (distance) ship.status.portal_range) "Out of range."
                              (> 0 (- ship.status.battery power)) "Insufficient power."))
      activate (lambda ()
                 (set_beam 0)
                 (print "Portal opening.")
                 (portal_activate)
                 (print nil))
      fail (lambda (message)
             (print message)
             (set_beam_count nil)
             (print failure)
             (print nil))
      init-time (os.time)
      looper (lambda (last-time looper)
               (coroutine.yield)
               (let (time-since (- (os.time) init-time)
                     power (* 2 (- (os.time) last-time))
                     failure (fail-conditions power))
                 (if failure
                     (fail failure)
                   ((lambda ()
                      (draw_power power)
                      (print time-since)
                      (print ship.status.portal_time)
                      (set_beam time-since)
                      (if (> time-since ship.status.portal_time)
                          (activate)
                        (looper (os.time) looper))))))))
  (if (trip_cleared)
      (or (print "Cleared for portal; standby for activation...")
          (looper (os.time) looper))
    (fail "Not cleared for departure.")))