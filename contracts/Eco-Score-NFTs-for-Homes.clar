

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
(define-constant err-achievement-claimed (err u111))
(define-constant err-score-not-reached (err u112))
(define-constant err-maintenance-too-soon (err u113))
(define-constant err-invalid-maintenance-type (err u114))
(define-constant err-invalid-carbon-data (err u115))
(define-constant err-carbon-tracking-disabled (err u116))
(define-constant err-report-too-soon (err u117))
(define-constant err-already-on-leaderboard (err u118))
(define-constant err-not-on-leaderboard (err u119))
(define-constant err-leaderboard-full (err u120))

(define-constant achievement-eco-warrior u100)
(define-constant achievement-green-champion u150)
(define-constant achievement-sustainability-expert u200)
(define-constant achievement-eco-master u250)

(define-constant blocks-per-month u4380)
(define-constant blocks-per-year u52560)
(define-constant decay-rate-per-month u2)
(define-constant maintenance-cooldown-blocks u1095)
(define-constant carbon-report-cooldown u2190) ;; ~30 days between reports
(define-constant carbon-reduction-threshold u10) ;; 10% reduction for bonus
(define-constant max-leaderboard-size u50)

(define-data-var last-token-id uint u0)
(define-data-var total-eco-credits uint u0)
(define-data-var leaderboard-count uint u0)

(map-set maintenance-types "solar-cleaning" {score-boost: u5, credit-reward: u10})
(map-set maintenance-types "insulation-check" {score-boost: u3, credit-reward: u8})
(map-set maintenance-types "energy-audit" {score-boost: u8, credit-reward: u15})
(map-set maintenance-types "system-upgrade" {score-boost: u12, credit-reward: u25})

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

(define-map claimed-achievements {user: principal, level: uint} {claimed-at: uint, bonus-credits: uint})

(define-map maintenance-records uint 
  {
    last-maintenance: uint,
    maintenance-count: uint,
    last-decay-calculation: uint
  })

(define-map maintenance-types (string-ascii 30)
  {
    score-boost: uint,
    credit-reward: uint
  })

;; Carbon footprint tracking maps
(define-map carbon-footprint-data uint
  {
    monthly-kwh-usage: uint,
    monthly-gas-usage: uint,
    monthly-water-usage: uint,
    monthly-waste-produced: uint,
    calculated-co2-tons: uint,
    last-report-block: uint,
    tracking-enabled: bool,
    baseline-co2: uint,
    total-reports: uint
  })

(define-map carbon-reduction-achievements {token-id: uint, period: uint}
  {
    reduction-percentage: uint,
    co2-saved: uint,
    bonus-credits: uint,
    achieved-at: uint
  })

(define-map leaderboard-entries uint
  {
    token-id: uint,
    score: uint,
    owner: principal,
    rank: uint,
    last-updated: uint
  })

(define-map token-leaderboard-position uint uint)

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

(define-read-only (has-achievement (user principal) (level uint))
  (is-some (map-get? claimed-achievements {user: user, level: level})))

(define-read-only (get-achievement-info (user principal) (level uint))
  (map-get? claimed-achievements {user: user, level: level}))

(define-read-only (get-maintenance-record (token-id uint))
  (map-get? maintenance-records token-id))

(define-read-only (get-maintenance-type-info (maintenance-type (string-ascii 30)))
  (map-get? maintenance-types maintenance-type))

;; Carbon footprint read-only functions
(define-read-only (get-carbon-footprint-data (token-id uint))
  (map-get? carbon-footprint-data token-id))

(define-read-only (get-carbon-reduction-achievement (token-id uint) (period uint))
  (map-get? carbon-reduction-achievements {token-id: token-id, period: period}))

(define-read-only (get-leaderboard-entry (position uint))
  (map-get? leaderboard-entries position))

(define-read-only (get-token-rank (token-id uint))
  (let
    (
      (position (map-get? token-leaderboard-position token-id))
    )
    (if (is-some position)
      (ok (unwrap-panic position))
      err-not-on-leaderboard)))

(define-read-only (get-leaderboard-size)
  (var-get leaderboard-count))

(define-read-only (get-top-homes (count uint))
  (ok (map get-leaderboard-entry (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10))))

(define-read-only (calculate-co2-emissions (kwh-usage uint) (gas-usage uint) (water-usage uint) (waste-kg uint))
  (let
    (
      ;; CO2 factors (simplified): kWh * 0.4kg, gas * 2kg, water * 0.3kg, waste * 0.5kg
      (electricity-co2 (/ (* kwh-usage u4) u10)) ;; 0.4kg per kWh
      (gas-co2 (* gas-usage u2)) ;; 2kg per unit
      (water-co2 (/ (* water-usage u3) u10)) ;; 0.3kg per unit
      (waste-co2 (/ (* waste-kg u5) u10)) ;; 0.5kg per kg
      (total-kg (+ electricity-co2 (+ gas-co2 (+ water-co2 waste-co2))))
    )
    (ok (/ total-kg u1000)))) ;; Convert to tons

(define-read-only (get-carbon-reduction-percentage (token-id uint))
  (let
    (
      (carbon-data (unwrap! (get-carbon-footprint-data token-id) err-carbon-tracking-disabled))
      (current-co2 (get calculated-co2-tons carbon-data))
      (baseline-co2 (get baseline-co2 carbon-data))
    )
    (if (and (> baseline-co2 u0) (< current-co2 baseline-co2))
      (ok (/ (* (- baseline-co2 current-co2) u100) baseline-co2))
      (ok u0))))

(define-read-only (calculate-score-decay (token-id uint))
  (let 
    (
      (maintenance-record (default-to {last-maintenance: u0, maintenance-count: u0, last-decay-calculation: u0} (map-get? maintenance-records token-id)))
      (last-decay (get last-decay-calculation maintenance-record))
      (last-update (if (> last-decay u0) last-decay stacks-block-height))
      (blocks-passed (- stacks-block-height last-update))
      (months-passed (/ blocks-passed blocks-per-month))
      (decay-amount (* months-passed decay-rate-per-month))
    )
    (ok {blocks-passed: blocks-passed, months-passed: months-passed, decay-amount: decay-amount})))

(define-read-only (get-current-effective-score (token-id uint))
  (let 
    (
      (score-data (unwrap! (get-eco-score token-id) err-token-not-found))
      (decay-info (unwrap! (calculate-score-decay token-id) err-token-not-found))
      (raw-total (get total-score score-data))
      (decay-amount (get decay-amount decay-info))
      (effective-score (if (> raw-total decay-amount) (- raw-total decay-amount) u0))
    )
    (ok {raw-score: raw-total, decay-amount: decay-amount, effective-score: effective-score})))

(define-read-only (check-achievement-eligibility (token-id uint))
  (let 
    (
      (score-data (unwrap! (get-eco-score token-id) err-token-not-found))
      (total-score (get total-score score-data))
      (owner (unwrap! (nft-get-owner? eco-home token-id) err-token-not-found))
    )
    (ok {
      eco-warrior: (and (>= total-score achievement-eco-warrior) (not (has-achievement owner achievement-eco-warrior))),
      green-champion: (and (>= total-score achievement-green-champion) (not (has-achievement owner achievement-green-champion))),
      sustainability-expert: (and (>= total-score achievement-sustainability-expert) (not (has-achievement owner achievement-sustainability-expert))),
      eco-master: (and (>= total-score achievement-eco-master) (not (has-achievement owner achievement-eco-master))),
      total-score: total-score
    })))

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
    (map-set maintenance-records token-id {last-maintenance: stacks-block-height, maintenance-count: u0, last-decay-calculation: stacks-block-height})
    ;; Initialize carbon footprint tracking (disabled by default)
    (map-set carbon-footprint-data token-id
      {
        monthly-kwh-usage: u0,
        monthly-gas-usage: u0,
        monthly-water-usage: u0,
        monthly-waste-produced: u0,
        calculated-co2-tons: u0,
        last-report-block: stacks-block-height,
        tracking-enabled: false,
        baseline-co2: u0,
        total-reports: u0
      })
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

(define-private (get-achievement-reward (level uint))
  (if (is-eq level achievement-eco-warrior) u50
    (if (is-eq level achievement-green-champion) u100
      (if (is-eq level achievement-sustainability-expert) u200
        (if (is-eq level achievement-eco-master) u500 u0)))))

(define-public (perform-maintenance (token-id uint) (maintenance-type (string-ascii 30)))
  (let 
    (
      (owner (unwrap! (nft-get-owner? eco-home token-id) err-token-not-found))
      (maintenance-info (unwrap! (get-maintenance-type-info maintenance-type) err-invalid-maintenance-type))
      (maintenance-record (default-to {last-maintenance: u0, maintenance-count: u0, last-decay-calculation: u0} (get-maintenance-record token-id)))
      (score-data (unwrap! (get-eco-score token-id) err-token-not-found))
      (score-boost (get score-boost maintenance-info))
      (credit-reward (get credit-reward maintenance-info))
      (last-maintenance (get last-maintenance maintenance-record))
    )
    (asserts! (is-eq tx-sender owner) err-not-token-owner)
    (asserts! (>= (- stacks-block-height last-maintenance) maintenance-cooldown-blocks) err-maintenance-too-soon)
    (map-set token-eco-scores token-id 
      (merge score-data 
        {
          upgrade-score: (+ (get upgrade-score score-data) score-boost),
          total-score: (+ (get total-score score-data) score-boost),
          last-updated: stacks-block-height
        }))
    (map-set maintenance-records token-id
      {
        last-maintenance: stacks-block-height,
        maintenance-count: (+ (get maintenance-count maintenance-record) u1),
        last-decay-calculation: stacks-block-height
      })
    (map-set eco-credits-balance owner (+ (get-eco-credits owner) credit-reward))
    (var-set total-eco-credits (+ (var-get total-eco-credits) credit-reward))
    (ok {score-boost: score-boost, credit-reward: credit-reward})))

(define-public (apply-score-decay (token-id uint))
  (let 
    (
      (score-data (unwrap! (get-eco-score token-id) err-token-not-found))
      (decay-info (unwrap! (calculate-score-decay token-id) err-token-not-found))
      (decay-amount (get decay-amount decay-info))
      (maintenance-record (default-to {last-maintenance: u0, maintenance-count: u0, last-decay-calculation: u0} (get-maintenance-record token-id)))
      (current-total (get total-score score-data))
      (new-total (if (> current-total decay-amount) (- current-total decay-amount) u0))
    )
    (asserts! (> decay-amount u0) err-invalid-score)
    (map-set token-eco-scores token-id 
      (merge score-data 
        {
          total-score: new-total,
          last-updated: stacks-block-height
        }))
    (map-set maintenance-records token-id
      (merge maintenance-record {last-decay-calculation: stacks-block-height}))
    (ok {decay-applied: decay-amount, new-score: new-total})))

(define-public (claim-achievement (token-id uint) (achievement-level uint))
  (let 
    (
      (owner (unwrap! (nft-get-owner? eco-home token-id) err-token-not-found))
      (score-data (unwrap! (get-eco-score token-id) err-token-not-found))
      (total-score (get total-score score-data))
      (reward-amount (get-achievement-reward achievement-level))
    )
    (asserts! (is-eq tx-sender owner) err-not-token-owner)
    (asserts! (not (has-achievement owner achievement-level)) err-achievement-claimed)
    (asserts! (>= total-score achievement-level) err-score-not-reached)
    (asserts! (> reward-amount u0) err-invalid-score)
    (map-set claimed-achievements {user: owner, level: achievement-level} {claimed-at: stacks-block-height, bonus-credits: reward-amount})
    (try! (award-eco-credits owner reward-amount))
    (ok achievement-level)))

;; Carbon footprint tracking functions
(define-public (enable-carbon-tracking (token-id uint))
  (let
    (
      (owner (unwrap! (nft-get-owner? eco-home token-id) err-token-not-found))
      (carbon-data (unwrap! (get-carbon-footprint-data token-id) err-token-not-found))
    )
    (asserts! (is-eq tx-sender owner) err-not-token-owner)
    (map-set carbon-footprint-data token-id (merge carbon-data {tracking-enabled: true}))
    (ok true)))

(define-public (report-monthly-usage
  (token-id uint)
  (kwh-usage uint)
  (gas-usage uint)
  (water-usage uint)
  (waste-kg uint))
  (let
    (
      (owner (unwrap! (nft-get-owner? eco-home token-id) err-token-not-found))
      (carbon-data (unwrap! (get-carbon-footprint-data token-id) err-token-not-found))
      (calculated-co2 (unwrap! (calculate-co2-emissions kwh-usage gas-usage water-usage waste-kg) err-invalid-carbon-data))
      (last-report (get last-report-block carbon-data))
      (reports-count (get total-reports carbon-data))
      (current-baseline (get baseline-co2 carbon-data))
    )
    (asserts! (is-eq tx-sender owner) err-not-token-owner)
    (asserts! (get tracking-enabled carbon-data) err-carbon-tracking-disabled)
    (asserts! (>= (- stacks-block-height last-report) carbon-report-cooldown) err-report-too-soon)
    (asserts! (and (> kwh-usage u0) (> calculated-co2 u0)) err-invalid-carbon-data)
    
    ;; Set baseline on first report
    (let
      (
        (new-baseline (if (is-eq reports-count u0) calculated-co2 current-baseline))
      )
      (map-set carbon-footprint-data token-id
        {
          monthly-kwh-usage: kwh-usage,
          monthly-gas-usage: gas-usage,
          monthly-water-usage: water-usage,
          monthly-waste-produced: waste-kg,
          calculated-co2-tons: calculated-co2,
          last-report-block: stacks-block-height,
          tracking-enabled: true,
          baseline-co2: new-baseline,
          total-reports: (+ reports-count u1)
        })
      ;; Award eco credits for tracking (small bonus)
      (try! (award-eco-credits owner u5))
      (ok {co2-calculated: calculated-co2, baseline-set: new-baseline}))))

(define-public (claim-carbon-reduction-achievement (token-id uint))
  (let
    (
      (owner (unwrap! (nft-get-owner? eco-home token-id) err-token-not-found))
      (carbon-data (unwrap! (get-carbon-footprint-data token-id) err-token-not-found))
      (reduction-pct (unwrap! (get-carbon-reduction-percentage token-id) err-carbon-tracking-disabled))
      (reports-count (get total-reports carbon-data))
      (period reports-count)
      (existing-achievement (get-carbon-reduction-achievement token-id period))
      (co2-saved (if (> (get baseline-co2 carbon-data) u0) 
                   (- (get baseline-co2 carbon-data) (get calculated-co2-tons carbon-data))
                   u0))
      (bonus-credits (* reduction-pct u2)) ;; 2 credits per % reduction
    )
    (asserts! (is-eq tx-sender owner) err-not-token-owner)
    (asserts! (get tracking-enabled carbon-data) err-carbon-tracking-disabled)
    (asserts! (>= reduction-pct carbon-reduction-threshold) err-score-not-reached)
    (asserts! (> reports-count u1) err-invalid-carbon-data) ;; Need at least 2 reports
    (asserts! (is-none existing-achievement) err-achievement-claimed)
    
    (map-set carbon-reduction-achievements {token-id: token-id, period: period}
      {
        reduction-percentage: reduction-pct,
        co2-saved: co2-saved,
        bonus-credits: bonus-credits,
        achieved-at: stacks-block-height
      })
    (try! (award-eco-credits owner bonus-credits))
    (ok {reduction: reduction-pct, credits-earned: bonus-credits, co2-saved: co2-saved})))

(define-public (join-leaderboard (token-id uint))
  (let
    (
      (owner (unwrap! (nft-get-owner? eco-home token-id) err-token-not-found))
      (score-data (unwrap! (get-eco-score token-id) err-token-not-found))
      (current-score (get total-score score-data))
      (existing-position (map-get? token-leaderboard-position token-id))
      (current-count (var-get leaderboard-count))
    )
    (asserts! (is-eq tx-sender owner) err-not-token-owner)
    (asserts! (is-none existing-position) err-already-on-leaderboard)
    (asserts! (< current-count max-leaderboard-size) err-leaderboard-full)
    
    (let
      (
        (new-position (+ current-count u1))
      )
      (map-set leaderboard-entries new-position
        {
          token-id: token-id,
          score: current-score,
          owner: owner,
          rank: new-position,
          last-updated: stacks-block-height
        })
      (map-set token-leaderboard-position token-id new-position)
      (var-set leaderboard-count new-position)
      (ok new-position))))

(define-public (update-leaderboard-score (token-id uint))
  (let
    (
      (owner (unwrap! (nft-get-owner? eco-home token-id) err-token-not-found))
      (score-data (unwrap! (get-eco-score token-id) err-token-not-found))
      (current-score (get total-score score-data))
      (position (unwrap! (map-get? token-leaderboard-position token-id) err-not-on-leaderboard))
      (entry (unwrap! (get-leaderboard-entry position) err-not-on-leaderboard))
    )
    (asserts! (is-eq tx-sender owner) err-not-token-owner)
    
    (map-set leaderboard-entries position
      (merge entry
        {
          score: current-score,
          last-updated: stacks-block-height
        }))
    (ok current-score)))

(define-public (leave-leaderboard (token-id uint))
  (let
    (
      (owner (unwrap! (nft-get-owner? eco-home token-id) err-token-not-found))
      (position (unwrap! (map-get? token-leaderboard-position token-id) err-not-on-leaderboard))
      (current-count (var-get leaderboard-count))
      (last-position current-count)
    )
    (asserts! (is-eq tx-sender owner) err-not-token-owner)
    
    (if (is-eq position last-position)
      (begin
        (map-delete leaderboard-entries position)
        (map-delete token-leaderboard-position token-id)
        (var-set leaderboard-count (- current-count u1))
        (ok true))
      (let
        (
          (last-entry (unwrap! (get-leaderboard-entry last-position) err-not-on-leaderboard))
          (swapped-token-id (get token-id last-entry))
        )
        (map-set leaderboard-entries position last-entry)
        (map-set token-leaderboard-position swapped-token-id position)
        (map-delete leaderboard-entries last-position)
        (map-delete token-leaderboard-position token-id)
        (var-set leaderboard-count (- current-count u1))
        (ok true)))))
