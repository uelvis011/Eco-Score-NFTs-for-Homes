

(define-non-fungible-token eco-home uint)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-listing-exists (err u102))
(define-constant err-wrong-commission (err u103))
(define-constant err-token-not-found (err u104))
(define-constant err-not-listed (err u105))
(define-constant err-already-inspector (err u106))
(define-constant err-not-inspector (err u107))
(define-constant err-invalid-score (err u108))
(define-constant err-invalid-upgrade (err u109))
(define-constant err-insufficient-credits (err u110))

(define-data-var last-token-id uint u0)
(define-data-var total-eco-credits uint u0)

(define-map token-eco-scores uint 
  {
    base-score: uint,
    upgrade-score: uint,
    total-score: uint,
    last-updated: uint,
    inspector-verified: bool
  })

(define-map home-details uint
  {
    address: (string-ascii 100),
    owner: principal,
    creation-block: uint,
    insulation-level: uint,
    solar-panels: bool,
    rainwater-system: bool,
    energy-efficiency: uint,
    waste-management: uint
  })

(define-map approved-inspectors principal bool)

(define-map upgrade-history uint (list 10 {upgrade-type: (string-ascii 50), score-boost: uint, verified-at: uint, inspector: principal}))

(define-map eco-credits-balance principal uint)

(define-map market-listings uint {price: uint, seller: principal})

(define-read-only (get-last-token-id)
  (var-get last-token-id))

(define-read-only (get-token-uri (token-id uint))
  (ok none))

(define-read-only (get-owner (token-id uint))
  (ok (nft-get-owner? eco-home token-id)))

(define-read-only (get-eco-score (token-id uint))
  (map-get? token-eco-scores token-id))

(define-read-only (get-home-details (token-id uint))
  (map-get? home-details token-id))

(define-read-only (is-approved-inspector (inspector principal))
  (default-to false (map-get? approved-inspectors inspector)))

(define-read-only (get-upgrade-history (token-id uint))
  (default-to (list) (map-get? upgrade-history token-id)))

(define-read-only (get-eco-credits (user principal))
  (default-to u0 (map-get? eco-credits-balance user)))

(define-read-only (get-market-listing (token-id uint))
  (map-get? market-listings token-id))

(define-read-only (calculate-base-score (insulation uint) (solar bool) (rainwater bool) (energy uint) (waste uint))
  (let 
    (
      (insulation-score (* insulation u10))
      (solar-score (if solar u20 u0))
      (rainwater-score (if rainwater u15 u0))
      (energy-score (* energy u5))
      (waste-score (* waste u8))
    )
    (+ insulation-score (+ solar-score (+ rainwater-score (+ energy-score waste-score))))
  ))

(define-public (mint-home-nft 
  (address (string-ascii 100))
  (insulation-level uint)
  (solar-panels bool)
  (rainwater-system bool)
  (energy-efficiency uint)
  (waste-management uint))
  (let 
    (
      (token-id (+ (var-get last-token-id) u1))
      (base-score (calculate-base-score insulation-level solar-panels rainwater-system energy-efficiency waste-management))
    )
    (asserts! (and (>= insulation-level u1) (<= insulation-level u10)) err-invalid-score)
    (asserts! (and (>= energy-efficiency u1) (<= energy-efficiency u10)) err-invalid-score)
    (asserts! (and (>= waste-management u1) (<= waste-management u10)) err-invalid-score)
    (try! (nft-mint? eco-home token-id tx-sender))
    (map-set token-eco-scores token-id 
      {
        base-score: base-score,
        upgrade-score: u0,
        total-score: base-score,
        last-updated: stacks-block-height,
        inspector-verified: false
      })
    (map-set home-details token-id
      {
        address: address,
        owner: tx-sender,
        creation-block: stacks-block-height,
        insulation-level: insulation-level,
        solar-panels: solar-panels,
        rainwater-system: rainwater-system,
        energy-efficiency: energy-efficiency,
        waste-management: waste-management
      })
    (var-set last-token-id token-id)
    (ok token-id)))

(define-public (add-inspector (inspector principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (not (is-approved-inspector inspector)) err-already-inspector)
    (map-set approved-inspectors inspector true)
    (ok true)))

(define-public (remove-inspector (inspector principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-approved-inspector inspector) err-not-inspector)
    (map-delete approved-inspectors inspector)
    (ok true)))

(define-public (verify-upgrade 
  (token-id uint)
  (upgrade-type (string-ascii 50))
  (score-boost uint))
  (let 
    (
      (current-score (unwrap! (get-eco-score token-id) err-token-not-found))
      (current-history (get-upgrade-history token-id))
      (new-upgrade {upgrade-type: upgrade-type, score-boost: score-boost, verified-at: stacks-block-height, inspector: tx-sender})
    )
    (asserts! (is-approved-inspector tx-sender) err-not-inspector)
    (asserts! (and (>= score-boost u1) (<= score-boost u50)) err-invalid-upgrade)
    (map-set token-eco-scores token-id 
      (merge current-score 
        {
          upgrade-score: (+ (get upgrade-score current-score) score-boost),
          total-score: (+ (get total-score current-score) score-boost),
          last-updated: stacks-block-height,
          inspector-verified: true
        }))
    (map-set upgrade-history token-id (unwrap! (as-max-len? (append current-history new-upgrade) u10) err-invalid-upgrade))
    (try! (award-eco-credits (unwrap! (nft-get-owner? eco-home token-id) err-token-not-found) score-boost))
    (ok true)))

(define-public (award-eco-credits (recipient principal) (amount uint))
  (let 
    (
      (current-balance (get-eco-credits recipient))
    )
    (asserts! (is-approved-inspector tx-sender) err-not-inspector)
    (map-set eco-credits-balance recipient (+ current-balance amount))
    (var-set total-eco-credits (+ (var-get total-eco-credits) amount))
    (ok true)))

(define-public (transfer-eco-credits (recipient principal) (amount uint))
  (let 
    (
      (sender-balance (get-eco-credits tx-sender))
      (recipient-balance (get-eco-credits recipient))
    )
    (asserts! (>= sender-balance amount) err-insufficient-credits)
    (map-set eco-credits-balance tx-sender (- sender-balance amount))
    (map-set eco-credits-balance recipient (+ recipient-balance amount))
    (ok true)))

(define-public (list-for-sale (token-id uint) (price uint))
  (let 
    (
      (owner (unwrap! (nft-get-owner? eco-home token-id) err-token-not-found))
    )
    (asserts! (is-eq owner tx-sender) err-not-token-owner)
    (asserts! (is-none (map-get? market-listings token-id)) err-listing-exists)
    (map-set market-listings token-id {price: price, seller: tx-sender})
    (ok true)))

(define-public (unlist-from-sale (token-id uint))
  (let 
    (
      (listing (unwrap! (map-get? market-listings token-id) err-not-listed))
    )
    (asserts! (is-eq (get seller listing) tx-sender) err-not-token-owner)
    (map-delete market-listings token-id)
    (ok true)))

(define-public (purchase-home (token-id uint))
  (let 
    (
      (listing (unwrap! (map-get? market-listings token-id) err-not-listed))
      (price (get price listing))
      (seller (get seller listing))
    )
    (try! (stx-transfer? price tx-sender seller))
    (try! (nft-transfer? eco-home token-id seller tx-sender))
    (map-delete market-listings token-id)
    (map-set home-details token-id 
      (merge (unwrap! (get-home-details token-id) err-token-not-found) {owner: tx-sender}))
    (ok true)))

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) err-not-token-owner)
    (try! (nft-transfer? eco-home token-id sender recipient))
    (map-set home-details token-id 
      (merge (unwrap! (get-home-details token-id) err-token-not-found) {owner: recipient}))
    (ok true)))

(define-public (burn (token-id uint))
  (let 
    (
      (owner (unwrap! (nft-get-owner? eco-home token-id) err-token-not-found))
    )
    (asserts! (is-eq owner tx-sender) err-not-token-owner)
    (try! (nft-burn? eco-home token-id tx-sender))
    (map-delete token-eco-scores token-id)
    (map-delete home-details token-id)
    (map-delete upgrade-history token-id)
    (ok true)))

(define-read-only (get-total-supply)
  (ok (var-get last-token-id)))

(define-read-only (get-total-eco-credits)
  (var-get total-eco-credits))

(define-read-only (get-home-score-breakdown (token-id uint))
  (let 
    (
      (details (unwrap! (get-home-details token-id) err-token-not-found))
      (scores (unwrap! (get-eco-score token-id) err-token-not-found))
    )
    (ok {
      insulation-score: (* (get insulation-level details) u10),
      solar-score: (if (get solar-panels details) u20 u0),
      rainwater-score: (if (get rainwater-system details) u15 u0),
      energy-score: (* (get energy-efficiency details) u5),
      waste-score: (* (get waste-management details) u8),
      upgrade-score: (get upgrade-score scores),
      total-score: (get total-score scores)
    })))
