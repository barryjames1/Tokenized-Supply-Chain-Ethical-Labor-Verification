;; Audit Verification Contract
;; Manages labor compliance audits and assessments

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u300))
(define-constant err-not-found (err u301))
(define-constant err-unauthorized (err u302))
(define-constant err-invalid-score (err u303))

;; Audit data structure
(define-map audits
  { audit-id: uint }
  {
    supplier-id: uint,
    auditor: principal,
    audit-date: uint,
    compliance-score: uint,
    findings: (string-ascii 1000),
    recommendations: (string-ascii 1000),
    status: (string-ascii 20),
    follow-up-required: bool
  }
)

;; Audit counter
(define-data-var audit-counter uint u0)

;; Authorized auditors
(define-map authorized-auditors principal bool)

;; Conduct an audit
(define-public (conduct-audit
  (supplier-id uint)
  (compliance-score uint)
  (findings (string-ascii 1000))
  (recommendations (string-ascii 1000))
  (follow-up-required bool)
)
  (begin
    (asserts! (default-to false (map-get? authorized-auditors tx-sender)) err-unauthorized)
    (asserts! (<= compliance-score u100) err-invalid-score)
    (let ((audit-id (+ (var-get audit-counter) u1)))
      (map-set audits
        { audit-id: audit-id }
        {
          supplier-id: supplier-id,
          auditor: tx-sender,
          audit-date: block-height,
          compliance-score: compliance-score,
          findings: findings,
          recommendations: recommendations,
          status: "completed",
          follow-up-required: follow-up-required
        }
      )
      (var-set audit-counter audit-id)
      (ok audit-id)
    )
  )
)

;; Update audit status
(define-public (update-audit-status (audit-id uint) (status (string-ascii 20)))
  (begin
    (match (map-get? audits { audit-id: audit-id })
      audit-data
      (begin
        (asserts! (is-eq (get auditor audit-data) tx-sender) err-unauthorized)
        (map-set audits
          { audit-id: audit-id }
          (merge audit-data { status: status })
        )
        (ok true)
      )
      err-not-found
    )
  )
)

;; Add authorized auditor (owner only)
(define-public (add-auditor (auditor principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set authorized-auditors auditor true)
    (ok true)
  )
)

;; Get audit information
(define-read-only (get-audit (audit-id uint))
  (map-get? audits { audit-id: audit-id })
)

;; Get audits count
(define-read-only (get-audits-count)
  (var-get audit-counter)
)

;; Check if auditor is authorized
(define-read-only (is-authorized-auditor (auditor principal))
  (default-to false (map-get? authorized-auditors auditor))
)

;; Get supplier audits (simplified - returns latest audit ID for supplier)
(define-read-only (get-latest-audit-for-supplier (supplier-id uint))
  (let ((total-audits (var-get audit-counter)))
    (get-audit total-audits)
  )
)
