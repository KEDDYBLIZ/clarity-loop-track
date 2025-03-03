;; Define token for rewards
(define-fungible-token fit-token)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-activity (err u101))
(define-constant err-invalid-duration (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-calories (err u104))

;; Activity type constants
(define-constant valid-activities (list "running" "cycling" "swimming" "walking"))
(define-constant max-daily-reward u1000)
(define-constant max-calories-per-hour u1000)

;; Data variables
(define-map user-activities principal 
  {
    total-activities: uint,
    total-duration: uint,
    total-calories: uint,
    last-activity: uint  ;; timestamp
  }
)

(define-map user-goals principal 
  {
    activity-type: (string-ascii 20),
    target-duration: uint,
    completed: bool,
    start-time: uint
  }
)

(define-map daily-rewards {user: principal, day: uint} uint)

;; Helper functions
(define-private (is-valid-activity (activity-type (string-ascii 20)))
  (default-to false (index-of valid-activities activity-type))
)

(define-private (validate-calories (duration uint) (calories uint))
  (let ((hourly-rate (/ (* calories u3600) duration)))
    (<= hourly-rate max-calories-per-hour)
  )
)

;; Activity logging function
(define-public (log-activity (activity-type (string-ascii 20)) (duration uint) (calories uint))
  (let (
    (current-stats (default-to
      { total-activities: u0, total-duration: u0, total-calories: u0, last-activity: u0 }
      (map-get? user-activities tx-sender)
    ))
  )
    (asserts! (is-valid-activity activity-type) err-invalid-activity)
    (asserts! (> duration u0) err-invalid-duration)
    (asserts! (validate-calories duration calories) err-invalid-calories)
    
    (try! (map-set user-activities tx-sender
      {
        total-activities: (+ (get total-activities current-stats) u1),
        total-duration: (+ (get total-duration current-stats) duration),
        total-calories: (+ (get total-calories current-stats) calories),
        last-activity: block-height
      }
    ))
    (try! (check-and-reward tx-sender duration calories activity-type))
    (ok true)
  )
)

;; Enhanced reward calculation
(define-private (check-and-reward (user principal) (duration uint) (calories uint) (activity-type (string-ascii 20)))
  (let (
    (base-reward (/ (+ duration calories) u100))
    (activity-multiplier (if (is-eq activity-type "running") u2 u1))
    (final-reward (* base-reward activity-multiplier))
  )
    (if (<= final-reward max-daily-reward)
      (ft-mint? fit-token final-reward user)
      (ft-mint? fit-token max-daily-reward user)
    )
  )
)

;; Set fitness goal
(define-public (set-goal (activity-type (string-ascii 20)) (target-duration uint))
  (begin
    (asserts! (is-valid-activity activity-type) err-invalid-activity)
    (asserts! (> target-duration u0) err-invalid-duration)
    
    (try! (map-set user-goals tx-sender
      {
        activity-type: activity-type,
        target-duration: target-duration,
        completed: false,
        start-time: block-height
      }
    ))
    (ok true)
  )
)

;; Existing read-only functions remain unchanged
(define-read-only (get-user-stats (user principal))
  (ok (map-get? user-activities user))
)

(define-read-only (get-user-goals (user principal))
  (ok (map-get? user-goals user))
)

(define-read-only (get-reward-balance (user principal))
  (ok (ft-get-balance fit-token user))
)

;; Transfer tokens
(define-public (transfer-rewards (amount uint) (recipient principal))
  (ft-transfer? fit-token amount tx-sender recipient)
)
