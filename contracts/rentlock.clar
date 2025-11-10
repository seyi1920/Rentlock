;; RentLock - On-Chain Rental Escrow Agreements
;; Version: v1.0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CONSTANTS AND ERRORS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-constant ERR-NOT-OWNER (err u100))
(define-constant ERR-NOT-RENTER (err u101))
(define-constant ERR-NO-AGREEMENT (err u102))
(define-constant ERR-INVALID-STATE (err u103))
(define-constant ERR-ZERO-AMOUNT (err u104))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DATA STRUCTURES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-map rentals
  {rental-id: uint}
  {
    owner: principal,
    renter: (optional principal),
    rent-amount: uint,
    start-block: uint,
    end-block: uint,
    is-active: bool,
    is-complete: bool,
    is-disputed: bool
  }
)

(define-data-var rental-counter uint u0)
(define-data-var arbitrator principal tx-sender)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ADMIN / ARBITRATOR CONTROLS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-public (set-arbitrator (new-arb principal))
  (begin
    (asserts! (is-eq tx-sender (var-get arbitrator)) ERR-NOT-OWNER)
    (var-set arbitrator new-arb)
    (print {event: "arbitrator-updated", new: new-arb})
    (ok new-arb)
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; RENTAL FLOW FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; 1. Owner creates a rental listing
(define-public (create-rental (rent-amount uint) (duration uint))
  (begin
    (asserts! (> rent-amount u0) ERR-ZERO-AMOUNT)
    (let ((id (+ (var-get rental-counter) u1)))
      (begin
        (map-set rentals {rental-id: id}
          {
            owner: tx-sender,
            renter: none,
            rent-amount: rent-amount,
            start-block: u0,
            end-block: (+ stacks-block-height duration),
            is-active: false,
            is-complete: false,
            is-disputed: false
          })
        (var-set rental-counter id)
        (print {event: "rental-created", id: id, owner: tx-sender})
        (ok id)
      )
    )
  )
)

;; 2. Renter funds the rental
(define-public (fund-rental (rental-id uint))
  (let ((rental (unwrap! (map-get? rentals {rental-id: rental-id}) ERR-NO-AGREEMENT)))
    (begin
      (asserts! (is-eq (get renter rental) none) ERR-INVALID-STATE)
      (try! (stx-transfer? (get rent-amount rental) tx-sender (as-contract tx-sender)))
      (map-set rentals {rental-id: rental-id}
        (merge rental {renter: (some tx-sender)}))
      (print {event: "rental-funded", id: rental-id, renter: tx-sender})
      (ok rental-id)
    )
  )
)

;; 3. Start rental (both must call)
(define-public (confirm-start (rental-id uint))
  (let ((rental (unwrap! (map-get? rentals {rental-id: rental-id}) ERR-NO-AGREEMENT)))
    (if (and (is-eq tx-sender (get owner rental))
             (not (get is-active rental)))
        (begin
          (map-set rentals {rental-id: rental-id}
            (merge rental {is-active: true, start-block: stacks-block-height}))
          (print {event: "rental-started", id: rental-id})
          (ok rental-id)
        )
        (err u400)
    )
  )
)

;; 4. End or terminate rental
(define-public (end-rental (rental-id uint))
  (let ((rental (unwrap! (map-get? rentals {rental-id: rental-id}) ERR-NO-AGREEMENT)))
    (if (and (get is-active rental) (>= stacks-block-height (get end-block rental)))
        (begin
          (try! (stx-transfer? (get rent-amount rental)
                               (as-contract tx-sender)
                               (get owner rental)))
          (map-set rentals {rental-id: rental-id}
            (merge rental {is-active: false, is-complete: true}))
          (print {event: "rental-completed", id: rental-id})
          (ok true)
        )
        (err u401)
    )
  )
)

;; 5. Raise a dispute (either party)
(define-public (raise-dispute (rental-id uint))
  (let ((rental (unwrap! (map-get? rentals {rental-id: rental-id}) ERR-NO-AGREEMENT)))
    (if (or (and (is-some (get renter rental)) (is-eq tx-sender (unwrap! (get renter rental) ERR-NO-AGREEMENT)))
            (is-eq tx-sender (get owner rental)))
        (begin
          (map-set rentals {rental-id: rental-id}
            (merge rental {is-disputed: true}))
          (print {event: "dispute-raised", id: rental-id})
          (ok true)
        )
        (err u402)
    )
  )
)

;; 6. Arbitrator resolves dispute
(define-public (resolve-dispute (rental-id uint) (winner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get arbitrator)) ERR-NOT-OWNER)
    (let ((rental (unwrap! (map-get? rentals {rental-id: rental-id}) ERR-NO-AGREEMENT)))
      (if (get is-disputed rental)
          (begin
            (try! (stx-transfer? (get rent-amount rental) (as-contract tx-sender) winner))
            (map-set rentals {rental-id: rental-id}
              (merge rental {is-active: false, is-complete: true, is-disputed: false}))
            (print {event: "dispute-resolved", id: rental-id, winner: winner})
            (ok true)
          )
          (err u403)
      )
    )
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; READ-ONLY FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-read-only (get-rental (rental-id uint))
  (map-get? rentals {rental-id: rental-id})
)

(define-read-only (get-total-rentals)
  (var-get rental-counter)
)
