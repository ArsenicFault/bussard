(let (fail-conditions (lambda (power)
                        (cond (> (distance) ship.status.portal_range)
                              "Out of range."
                              (> 0 (- ship.status.battery power))
                              "Insufficient power."))
      activate (lambda ()
                 (set_beams 0)
                 (print "Portal opening.")
                 (portal_activate))
      fail (lambda (message)
             (print message)
             (set_beams nil)
             (print failure))
      init-time (os.time)
      looper (lambda (last-time looper)
               (coroutine.yield)
               (let (time-since (- (os.time) init-time)
                     power (* 0.02 (- (os.time) last-time))
                     failure (fail-conditions power))
                 (if failure
                     (fail failure)
                   ;; using a lambda here since sandbox interferes with do macro
                   ((lambda ()
                      (draw_power power)
                      (set_beams time-since)
                      (if (> time-since ship.status.portal_time)
                          (activate)
                        (looper (os.time) looper))))))))
  (if (no_trip_clearance)
      (fail (no_trip_clearance))
    ((lambda ()
       (print "Cleared for portal; standby for activation...")
       (disconnect)
       (looper (os.time) looper)))))
