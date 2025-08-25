;; eip-identity
;; A decentralized identity and reputation management system using EIP-based verification
;;
;; This contract enables secure user identity management with:
;; - Decentralized profile creation
;; - Identity verification mechanisms
;; - Reputation tracking and tiering
;; - Enhanced trust scoring

;; Error constants for identity management
(define-constant ERR-NOT-FOUND (err u200))
(define-constant ERR-IDENTITY-EXISTS (err u201))
(define-constant ERR-UNAUTHORIZED (err u202))
(define-constant ERR-INVALID-REPUTATION (err u203))
(define-constant ERR-NOT-VERIFIED (err u204))
(define-constant ERR-INVALID-INPUT (err u205))
(define-constant ERR-SELF-REVIEW (err u206))
(define-constant ERR-MAX-REPUTATION (err u207))

;; System constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant MAX-REPUTATION u1000)
(define-constant MIN-REPUTATION u1)
(define-constant INITIAL-REPUTATION u100)
(define-constant VERIFICATION-WEIGHT u2)

;; Reputation tier definitions
(define-constant TIER-1-THRESHOLD u100)  ;; Novice
(define-constant TIER-2-THRESHOLD u300)  ;; Emerging
(define-constant TIER-3-THRESHOLD u600)  ;; Proficient
(define-constant TIER-4-THRESHOLD u900)  ;; Expert

;; Identity profile map
(define-map identity-profiles
  { user: principal }
  {
    handle: (string-utf8 64),
    description: (string-utf8 256),
    reputation: uint,
    verified: bool,
    registered-at: uint,
    tier: uint,
    review-count: uint
  }
)

;; User review tracking
(define-map identity-reviews
  { reviewer: principal, reviewee: principal }
  {
    rating: uint,
    feedback: (string-utf8 256),
    timestamp: uint
  }
)

;; Authorized verifiers management
(define-map authorized-attestors
  { attestor: principal }
  { active: bool }
)

;; Global user tracking
(define-data-var total-identities uint u0)
(define-data-var total-verified-identities uint u0)

;; Private helper functions

;; Compute reputation tier based on score
(define-private (calculate-reputation-tier (reputation uint))
  (if (>= reputation TIER-4-THRESHOLD)
    u4
    (if (>= reputation TIER-3-THRESHOLD)
      u3
      (if (>= reputation TIER-2-THRESHOLD)
        u2
        u1
      )
    )
  )
)

;; Verify attestor authorization
(define-private (is-authorized-attestor (attestor principal))
  (default-to false (get active (map-get? authorized-attestors { attestor: attestor })))
)

;; Public functions

;; Create a new identity profile
(define-public (create-identity (handle (string-utf8 64)) (description (string-utf8 256)))
  (let (
    (user tx-sender)
    (current-block-height block-height)
  )
    ;; Prevent duplicate profiles
    (asserts! (is-none (map-get? identity-profiles { user: user })) ERR-IDENTITY-EXISTS)
    
    ;; Input validation
    (asserts! (> (len handle) u0) ERR-INVALID-INPUT)
    
    ;; Initialize profile
    (map-set identity-profiles
      { user: user }
      {
        handle: handle,
        description: description,
        reputation: INITIAL-REPUTATION,
        verified: false,
        registered-at: current-block-height,
        tier: u1,
        review-count: u0
      }
    )
    
    ;; Update total identities
    (var-set total-identities (+ (var-get total-identities) u1))
    
    (ok true)
  )
)

;; Update existing identity details
(define-public (update-identity (handle (string-utf8 64)) (description (string-utf8 256)))
  (let (
    (user tx-sender)
    (existing-profile (unwrap! (map-get? identity-profiles { user: user }) ERR-NOT-FOUND))
  )
    ;; Input validation
    (asserts! (> (len handle) u0) ERR-INVALID-INPUT)
    
    ;; Profile update
    (map-set identity-profiles
      { user: user }
      (merge existing-profile {
        handle: handle,
        description: description
      })
    )
    
    (ok true)
  )
)

;; Add an identity attestor
(define-public (add-attestor (attestor principal))
  (begin
    ;; Owner authorization check
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    
    ;; Register attestor
    (map-set authorized-attestors
      { attestor: attestor }
      { active: true }
    )
    
    (ok true)
  )
)

;; Remove an identity attestor
(define-public (remove-attestor (attestor principal))
  (begin
    ;; Owner authorization check
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    
    ;; Deactivate attestor
    (map-set authorized-attestors
      { attestor: attestor }
      { active: false }
    )
    
    (ok true)
  )
)

;; Read-only query functions

;; Retrieve identity profile
(define-read-only (get-identity (user principal))
  (map-get? identity-profiles { user: user })
)

;; Check specific review details
(define-read-only (get-identity-review (reviewer principal) (reviewee principal))
  (map-get? identity-reviews { reviewer: reviewer, reviewee: reviewee })
)

;; Verify identity status
(define-read-only (is-identity-verified (user principal))
  (match (map-get? identity-profiles { user: user })
    profile (get verified profile)
    false
  )
)

;; Get current reputation tier
(define-read-only (get-identity-tier (user principal))
  (match (map-get? identity-profiles { user: user })
    profile (get tier profile)
    u0
  )
)

;; Total identities count
(define-read-only (get-total-identities)
  (var-get total-identities)
)

;; Total verified identities
(define-read-only (get-total-verified-identities)
  (var-get total-verified-identities)
)

;; Check identity existence
(define-read-only (identity-exists (user principal))
  (is-some (map-get? identity-profiles { user: user }))
)