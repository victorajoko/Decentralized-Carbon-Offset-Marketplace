;; Carbon Offset Marketplace Contract

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))

(define-map projects
  uint
  {
    owner: principal,
    name: (string-utf8 100),
    description: (string-utf8 500),
    location: (string-utf8 100),
    total-offsets: uint,
    available-offsets: uint,
    price-per-token: uint,
    verification-status: (string-ascii 20)
  }
)

(define-map offset-usage
  { project-id: uint, user: principal }
  { amount: uint, retirement-block: uint }
)

(define-data-var project-id-nonce uint u0)

(define-public (create-project (name (string-utf8 100)) (description (string-utf8 500)) (location (string-utf8 100)) (total-offsets uint) (price-per-token uint))
  (let
    (
      (project-id (+ (var-get project-id-nonce) u1))
    )
    (map-set projects project-id
      {
        owner: tx-sender,
        name: name,
        description: description,
        location: location,
        total-offsets: total-offsets,
        available-offsets: total-offsets,
        price-per-token: price-per-token,
        verification-status: "PENDING"
      }
    )
    (var-set project-id-nonce project-id)
    (ok project-id)
  )
)

(define-public (verify-project (project-id uint) (status (string-ascii 20)))
  (let
    (
      (project (unwrap! (map-get? projects project-id) err-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (map-set projects project-id (merge project { verification-status: status })))
  )
)

(define-public (buy-offset (project-id uint) (amount uint))
  (let
    (
      (project (unwrap! (map-get? projects project-id) err-not-found))
      (total-cost (* amount (get price-per-token project)))
    )
    (asserts! (is-eq (get verification-status project) "VERIFIED") err-unauthorized)
    (asserts! (<= amount (get available-offsets project)) err-unauthorized)
    (try! (stx-transfer? total-cost tx-sender (get owner project)))
    (map-set projects project-id
      (merge project { available-offsets: (- (get available-offsets project) amount) })
    )
    (map-set offset-usage { project-id: project-id, user: tx-sender }
      (merge (default-to { amount: u0, retirement-block: u0 }
                        (map-get? offset-usage { project-id: project-id, user: tx-sender }))
             { amount: (+ amount (get amount (default-to { amount: u0, retirement-block: u0 }
                                                          (map-get? offset-usage { project-id: project-id, user: tx-sender })))) })
    )
    (ok true)
  )
)

(define-public (retire-offset (project-id uint) (amount uint))
  (let
    (
      (project (unwrap! (map-get? projects project-id) err-not-found))
      (current-usage (default-to { amount: u0, retirement-block: u0 }
                                 (map-get? offset-usage { project-id: project-id, user: tx-sender })))
    )
    (asserts! (>= (get amount current-usage) amount) err-unauthorized)
    (map-set offset-usage { project-id: project-id, user: tx-sender }
      { amount: (- (get amount current-usage) amount), retirement-block: block-height }
    )
    (ok true)
  )
)

(define-read-only (get-project (project-id uint))
  (ok (unwrap! (map-get? projects project-id) err-not-found))
)

(define-read-only (get-offset-usage (project-id uint) (user principal))
  (ok (default-to { amount: u0, retirement-block: u0 }
                 (map-get? offset-usage { project-id: project-id, user: user })))
)

