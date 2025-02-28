;; Define token for rewards
(define-fungible-token fit-token)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-activity (err u101))
(define-constant err-invalid-duration (err u102))

;; Data variables
(define-map user-activities principal 
  {
    total-activities: uint,
    total-duration: uint,
    total-calories: uint
  }
)

(define-map user-goals principal 
  {
    activity-type: (string-ascii 20),
    target-duration: uint,
    completed: bool
  }
)

;; Activity logging function
(define-public (log-activity (user principal) (activity-type (string-ascii 20)) (duration uint) (calories uint))
  (let (
    (current-stats (default-to
      { total-activities: u0, total-duration: u0, total-calories: u0 }
      (map-get? user-activities user)
    ))
  )
    (if (> duration u0)
      (begin
        (try! (map-set user-activities user
          {
            total-activities: (+ (get total-activities current-stats) u1),
            total-duration: (+ (get total-duration current-stats) duration),
            total-calories: (+ (get total-calories current-stats) calories)
          }
        ))
        (try! (check-and-reward user duration calories))
        (ok true)
      )
      err-invalid-duration
    )
  )
)

;; Reward calculation and distribution
(define-private (check-and-reward (user principal) (duration uint) (calories uint))
  (let ((reward-amount (/ (+ duration calories) u100)))
    (ft-mint? fit-token reward-amount user)
  )
)

;; Set fitness goal
(define-public (set-goal (user principal) (activity-type (string-ascii 20)) (target-duration uint))
  (begin
    (try! (map-set user-goals user
      {
        activity-type: activity-type,
        target-duration: target-duration,
        completed: false
      }
    ))
    (ok true)
  )
)

;; Get user stats
(define-read-only (get-user-stats (user principal))
  (ok (map-get? user-activities user))
)

;; Get user goals
(define-read-only (get-user-goals (user principal))
  (ok (map-get? user-goals user))
)

;; Get reward balance
(define-read-only (get-reward-balance (user principal))
  (ok (ft-get-balance fit-token user))
)

;; Transfer tokens
(define-public (transfer-rewards (amount uint) (sender principal) (recipient principal))
  (ft-transfer? fit-token amount sender recipient)
)
