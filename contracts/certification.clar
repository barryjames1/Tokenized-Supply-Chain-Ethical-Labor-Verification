;; Certification Contract
;; Issues and manages ethical labor certifications

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u500))
(define-constant err-not-found (err u501))
(define-constant err-unauthorized (err u502))
(define-constant err-insufficient-score (err u503))
(define-constant err-already-certified (err u504))

;; Certification data structure
(define-map certifications
  { cert-id: uint }
  {
    supplier-id: uint,
    certification-type: (string-ascii 50),
    issued-by: principal,
    issued-at: uint,
    expires-at: uint,
    compliance-score: uint,
    audit-id: uint,
    active: bool
  }
)

;; Certification counter
(define-data-var cert-counter uint u0)

;; Certification authorities
(define-map cert-authorities principal bool)

;; Minimum scores for certification types
(define-map cert-requirements (string-ascii 50) uint)

;; Issue certification
(define-public (issue-certification
  (supplier-id uint)
  (certification-type (string-ascii 50))
  (compliance-score uint)
  (audit-id uint)
  (validity-period uint)
)
  (begin
    (asserts! (default-to false (map-get? cert-authorities tx-sender)) err-unauthorized)
    (let
      (
        (min-score (default-to u70 (map-get? cert-requirements certification-type)))
        (cert-id (+ (var-get cert-counter) u1))
        (expires-at (+ block-height validity-period))
      )
      (asserts! (>= compliance-score min-score) err-insufficient-score)
      (map-set certifications
        { cert-id: cert-id }
        {
          supplier-id: supplier-id,
          certification-type: certification-type,
          issued-by: tx-sender,
          issued-at: block-height,
          expires-at: expires-at,
          compliance-score: compliance-score,
          audit-id: audit-id,
          active: true
        }
      )
      (var-set cert-counter cert-id)
      (ok cert-id)
    )
  )
)

;; Revoke certification
(define-public (revoke-certification (cert-id uint))
  (begin
    (match (map-get? certifications { cert-id: cert-id })
      cert-data
      (begin
        (asserts! (or
          (is-eq (get issued-by cert-data) tx-sender)
          (is-eq tx-sender contract-owner)
        ) err-unauthorized)
        (map-set certifications
          { cert-id: cert-id }
          (merge cert-data { active: false })
        )
        (ok true)
      )
      err-not-found
    )
  )
)

;; Add certification authority (owner only)
(define-public (add-cert-authority (authority principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set cert-authorities authority true)
    (ok true)
  )
)

;; Set certification requirements (owner only)
(define-public (set-cert-requirement (cert-type (string-ascii 50)) (min-score uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set cert-requirements cert-type min-score)
    (ok true)
  )
)

;; Get certification
(define-read-only (get-certification (cert-id uint))
  (map-get? certifications { cert-id: cert-id })
)

;; Get certifications count
(define-read-only (get-certifications-count)
  (var-get cert-counter)
)

;; Check if certification is valid
(define-read-only (is-certification-valid (cert-id uint))
  (match (map-get? certifications { cert-id: cert-id })
    cert-data
    (and
      (get active cert-data)
      (> (get expires-at cert-data) block-height)
    )
    false
  )
)

;; Check if authority is authorized
(define-read-only (is-cert-authority (authority principal))
  (default-to false (map-get? cert-authorities authority))
)
