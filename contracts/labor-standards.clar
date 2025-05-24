;; Labor Standards Contract
;; Defines and manages ethical employment requirements

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u200))
(define-constant err-not-found (err u201))
(define-constant err-already-exists (err u202))

;; Labor standard data structure
(define-map labor-standards
  { standard-id: uint }
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    category: (string-ascii 50),
    minimum-score: uint,
    created-by: principal,
    created-at: uint,
    active: bool
  }
)

;; Standard counter
(define-data-var standard-counter uint u0)

;; Industry categories
(define-map industry-categories (string-ascii 50) bool)

;; Create a new labor standard
(define-public (create-standard
  (title (string-ascii 100))
  (description (string-ascii 500))
  (category (string-ascii 50))
  (minimum-score uint)
)
  (let ((standard-id (+ (var-get standard-counter) u1)))
    (map-set labor-standards
      { standard-id: standard-id }
      {
        title: title,
        description: description,
        category: category,
        minimum-score: minimum-score,
        created-by: tx-sender,
        created-at: block-height,
        active: true
      }
    )
    (var-set standard-counter standard-id)
    (ok standard-id)
  )
)

;; Update standard status (owner only)
(define-public (update-standard-status (standard-id uint) (active bool))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (match (map-get? labor-standards { standard-id: standard-id })
      standard-data
      (begin
        (map-set labor-standards
          { standard-id: standard-id }
          (merge standard-data { active: active })
        )
        (ok true)
      )
      err-not-found
    )
  )
)

;; Add industry category
(define-public (add-category (category (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set industry-categories category true)
    (ok true)
  )
)

;; Get labor standard
(define-read-only (get-standard (standard-id uint))
  (map-get? labor-standards { standard-id: standard-id })
)

;; Get standards count
(define-read-only (get-standards-count)
  (var-get standard-counter)
)

;; Check if category exists
(define-read-only (is-valid-category (category (string-ascii 50)))
  (default-to false (map-get? industry-categories category))
)
