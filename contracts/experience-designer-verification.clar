;; Experience Designer Verification Contract
;; Validates and manages customer experience designers

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_VERIFIED (err u101))
(define-constant ERR_NOT_VERIFIED (err u102))
(define-constant ERR_INVALID_CREDENTIALS (err u103))

;; Data structures
(define-map verified-designers principal
  {
    verified-at: uint,
    certification-level: (string-ascii 20),
    specialization: (string-ascii 50),
    reputation-score: uint,
    active: bool
  })

(define-map designer-credentials principal
  {
    years-experience: uint,
    portfolio-hash: (string-ascii 64),
    certifications: (list 10 (string-ascii 30)),
    endorsements: uint
  })

(define-data-var total-verified-designers uint u0)

;; Public functions
(define-public (verify-designer
  (designer principal)
  (certification-level (string-ascii 20))
  (specialization (string-ascii 50))
  (years-experience uint)
  (portfolio-hash (string-ascii 64)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? verified-designers designer)) ERR_ALREADY_VERIFIED)
    (asserts! (>= years-experience u2) ERR_INVALID_CREDENTIALS)

    (map-set verified-designers designer
      {
        verified-at: block-height,
        certification-level: certification-level,
        specialization: specialization,
        reputation-score: u100,
        active: true
      })

    (map-set designer-credentials designer
      {
        years-experience: years-experience,
        portfolio-hash: portfolio-hash,
        certifications: (list),
        endorsements: u0
      })

    (var-set total-verified-designers (+ (var-get total-verified-designers) u1))
    (ok true)))

(define-public (update-reputation (designer principal) (new-score uint))
  (begin
    (asserts! (is-some (map-get? verified-designers designer)) ERR_NOT_VERIFIED)
    (let ((current-data (unwrap! (map-get? verified-designers designer) ERR_NOT_VERIFIED)))
      (map-set verified-designers designer
        (merge current-data { reputation-score: new-score }))
      (ok true))))

(define-public (deactivate-designer (designer principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? verified-designers designer)) ERR_NOT_VERIFIED)
    (let ((current-data (unwrap! (map-get? verified-designers designer) ERR_NOT_VERIFIED)))
      (map-set verified-designers designer
        (merge current-data { active: false }))
      (ok true))))

;; Read-only functions
(define-read-only (is-verified-designer (designer principal))
  (match (map-get? verified-designers designer)
    designer-data (get active designer-data)
    false))

(define-read-only (get-designer-info (designer principal))
  (map-get? verified-designers designer))

(define-read-only (get-total-verified-designers)
  (var-get total-verified-designers))
