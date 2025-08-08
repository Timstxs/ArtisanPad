;; ArtisanPad - Digital Art Provenance & Marketplace
;; A comprehensive platform for digital art creation, verification, and trading
;; Now with Multi-Edition NFT support

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-artwork-not-found (err u101))
(define-constant err-invalid-price (err u102))
(define-constant err-insufficient-funds (err u103))
(define-constant err-artwork-not-for-sale (err u104))
(define-constant err-invalid-royalty (err u105))
(define-constant err-already-exists (err u106))
(define-constant err-invalid-input (err u107))
(define-constant err-edition-sold-out (err u108))
(define-constant err-invalid-edition-size (err u109))
(define-constant err-edition-not-found (err u110))
(define-constant err-invalid-edition-number (err u111))

;; Data Variables
(define-data-var next-artwork-id uint u1)
(define-data-var next-edition-id uint u1)
(define-data-var platform-fee-percentage uint u250) ;; 2.5%

;; Data Maps
(define-map artworks
  uint
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    image-hash: (string-ascii 64),
    creator: principal,
    owner: principal,
    price: uint,
    for-sale: bool,
    royalty-percentage: uint,
    created-at: uint,
    last-sale-price: uint,
    is-edition: bool,
    edition-id: (optional uint)
  }
)

(define-map editions
  uint
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    image-hash: (string-ascii 64),
    creator: principal,
    total-supply: uint,
    minted-count: uint,
    price-per-edition: uint,
    royalty-percentage: uint,
    created-at: uint,
    active: bool
  }
)

(define-map edition-tokens
  {edition-id: uint, token-number: uint}
  {
    owner: principal,
    artwork-id: uint,
    minted-at: uint,
    for-sale: bool,
    sale-price: uint
  }
)

(define-map artist-profiles
  principal
  {
    name: (string-ascii 50),
    bio: (string-ascii 200),
    verified: bool,
    total-artworks: uint,
    total-sales: uint,
    total-editions: uint
  }
)

(define-map artwork-provenance
  uint
  {
    previous-owner: principal,
    sale-price: uint,
    sale-date: uint,
    transaction-hash: (string-ascii 64)
  }
)

(define-map user-collections
  {user: principal, artwork-id: uint}
  bool
)

;; Public Functions

;; Create artist profile
(define-public (create-artist-profile (name (string-ascii 50)) (bio (string-ascii 200)))
  (let
    (
      (caller tx-sender)
      (existing-profile (map-get? artist-profiles caller))
    )
    (asserts! (is-none existing-profile) err-already-exists)
    (asserts! (> (len name) u0) err-invalid-input)
    (asserts! (> (len bio) u0) err-invalid-input)
    (ok (map-set artist-profiles caller {
      name: name,
      bio: bio,
      verified: false,
      total-artworks: u0,
      total-sales: u0,
      total-editions: u0
    }))
  )
)

;; Create new single artwork
(define-public (create-artwork 
  (title (string-ascii 100))
  (description (string-ascii 500))
  (image-hash (string-ascii 64))
  (price uint)
  (royalty-percentage uint)
)
  (let
    (
      (artwork-id (var-get next-artwork-id))
      (creator tx-sender)
      (current-block stacks-block-height)
    )
    (asserts! (> (len title) u0) err-invalid-input)
    (asserts! (> (len description) u0) err-invalid-input)
    (asserts! (> (len image-hash) u0) err-invalid-input)
    (asserts! (>= price u0) err-invalid-price)
    (asserts! (<= royalty-percentage u1000) err-invalid-royalty) ;; Max 10%
    
    ;; Create artwork
    (map-set artworks artwork-id {
      title: title,
      description: description,
      image-hash: image-hash,
      creator: creator,
      owner: creator,
      price: price,
      for-sale: (> price u0),
      royalty-percentage: royalty-percentage,
      created-at: current-block,
      last-sale-price: u0,
      is-edition: false,
      edition-id: none
    })
    
    ;; Add to creator's collection
    (map-set user-collections {user: creator, artwork-id: artwork-id} true)
    
    ;; Update artist profile
    (match (map-get? artist-profiles creator)
      artist-profile
      (map-set artist-profiles creator (merge artist-profile {
        total-artworks: (+ (get total-artworks artist-profile) u1)
      }))
      ;; Create default profile if none exists
      (map-set artist-profiles creator {
        name: "",
        bio: "",
        verified: false,
        total-artworks: u1,
        total-sales: u0,
        total-editions: u0
      })
    )
    
    ;; Increment artwork counter
    (var-set next-artwork-id (+ artwork-id u1))
    (ok artwork-id)
  )
)

;; Create new limited edition series
(define-public (create-edition
  (title (string-ascii 100))
  (description (string-ascii 500))
  (image-hash (string-ascii 64))
  (total-supply uint)
  (price-per-edition uint)
  (royalty-percentage uint)
)
  (let
    (
      (edition-id (var-get next-edition-id))
      (creator tx-sender)
      (current-block stacks-block-height)
    )
    (asserts! (> (len title) u0) err-invalid-input)
    (asserts! (> (len description) u0) err-invalid-input)
    (asserts! (> (len image-hash) u0) err-invalid-input)
    (asserts! (and (> total-supply u0) (<= total-supply u10000)) err-invalid-edition-size)
    (asserts! (> price-per-edition u0) err-invalid-price)
    (asserts! (<= royalty-percentage u1000) err-invalid-royalty)
    
    ;; Create edition
    (map-set editions edition-id {
      title: title,
      description: description,
      image-hash: image-hash,
      creator: creator,
      total-supply: total-supply,
      minted-count: u0,
      price-per-edition: price-per-edition,
      royalty-percentage: royalty-percentage,
      created-at: current-block,
      active: true
    })
    
    ;; Update artist profile
    (match (map-get? artist-profiles creator)
      artist-profile
      (map-set artist-profiles creator (merge artist-profile {
        total-editions: (+ (get total-editions artist-profile) u1)
      }))
      ;; Create default profile if none exists
      (map-set artist-profiles creator {
        name: "",
        bio: "",
        verified: false,
        total-artworks: u0,
        total-sales: u0,
        total-editions: u1
      })
    )
    
    ;; Increment edition counter
    (var-set next-edition-id (+ edition-id u1))
    (ok edition-id)
  )
)

;; Mint edition token
(define-public (mint-edition-token (edition-id uint))
  (let
    (
      (edition-data (unwrap! (map-get? editions edition-id) err-edition-not-found))
      (minter tx-sender)
      (current-minted (get minted-count edition-data))
      (total-supply (get total-supply edition-data))
      (price (get price-per-edition edition-data))
      (creator (get creator edition-data))
      (token-number (+ current-minted u1))
      (artwork-id (var-get next-artwork-id))
      (current-block stacks-block-height)
      (platform-fee (/ (* price (var-get platform-fee-percentage)) u10000))
      (creator-amount (- price platform-fee))
    )
    
    (asserts! (get active edition-data) err-edition-sold-out)
    (asserts! (< current-minted total-supply) err-edition-sold-out)
    
    ;; Transfer payment to creator (minus platform fee)
    (try! (stx-transfer? creator-amount minter creator))
    
    ;; Transfer platform fee to contract owner
    (try! (stx-transfer? platform-fee minter contract-owner))
    
    ;; Create edition token record
    (map-set edition-tokens 
      {edition-id: edition-id, token-number: token-number}
      {
        owner: minter,
        artwork-id: artwork-id,
        minted-at: current-block,
        for-sale: false,
        sale-price: u0
      }
    )
    
    ;; Create corresponding artwork
    (map-set artworks artwork-id {
      title: (get title edition-data),
      description: (get description edition-data),
      image-hash: (get image-hash edition-data),
      creator: creator,
      owner: minter,
      price: u0,
      for-sale: false,
      royalty-percentage: (get royalty-percentage edition-data),
      created-at: current-block,
      last-sale-price: u0,
      is-edition: true,
      edition-id: (some edition-id)
    })
    
    ;; Add to minter's collection
    (map-set user-collections {user: minter, artwork-id: artwork-id} true)
    
    ;; Update edition minted count
    (map-set editions edition-id (merge edition-data {
      minted-count: token-number
    }))
    
    ;; Update creator's profile
    (match (map-get? artist-profiles creator)
      creator-profile
      (map-set artist-profiles creator (merge creator-profile {
        total-sales: (+ (get total-sales creator-profile) u1)
      }))
      true
    )
    
    ;; Increment artwork counter
    (var-set next-artwork-id (+ artwork-id u1))
    
    ;; Check if edition is now sold out
    (if (is-eq token-number total-supply)
      (map-set editions edition-id (merge edition-data {
        minted-count: token-number,
        active: false
      }))
      true
    )
    
    (ok {edition-id: edition-id, token-number: token-number, artwork-id: artwork-id})
  )
)

;; Purchase regular artwork
(define-public (purchase-artwork (artwork-id uint))
  (let
    (
      (artwork-data (unwrap! (map-get? artworks artwork-id) err-artwork-not-found))
      (buyer tx-sender)
      (seller (get owner artwork-data))
      (price (get price artwork-data))
      (creator (get creator artwork-data))
      (royalty-percentage (get royalty-percentage artwork-data))
      (platform-fee (/ (* price (var-get platform-fee-percentage)) u10000))
      (royalty-amount (if (is-eq creator seller) u0 (/ (* price royalty-percentage) u10000)))
      (seller-amount (- (- price platform-fee) royalty-amount))
      (current-block stacks-block-height)
    )
    
    (asserts! (get for-sale artwork-data) err-artwork-not-for-sale)
    (asserts! (not (is-eq buyer seller)) err-not-authorized)
    (asserts! (> price u0) err-invalid-price)
    
    ;; Transfer STX to seller
    (try! (stx-transfer? seller-amount buyer seller))
    
    ;; Transfer royalty to creator if different from seller
    (if (and (> royalty-amount u0) (not (is-eq creator seller)))
      (try! (stx-transfer? royalty-amount buyer creator))
      true
    )
    
    ;; Transfer platform fee to contract owner
    (try! (stx-transfer? platform-fee buyer contract-owner))
    
    ;; Record provenance
    (map-set artwork-provenance artwork-id {
      previous-owner: seller,
      sale-price: price,
      sale-date: current-block,
      transaction-hash: ""
    })
    
    ;; Update artwork ownership
    (map-set artworks artwork-id (merge artwork-data {
      owner: buyer,
      for-sale: false,
      last-sale-price: price
    }))
    
    ;; Update collections
    (map-delete user-collections {user: seller, artwork-id: artwork-id})
    (map-set user-collections {user: buyer, artwork-id: artwork-id} true)
    
    ;; Update seller's profile
    (match (map-get? artist-profiles seller)
      seller-profile
      (map-set artist-profiles seller (merge seller-profile {
        total-sales: (+ (get total-sales seller-profile) u1)
      }))
      true
    )
    
    (ok true)
  )
)

;; Set artwork for sale
(define-public (list-artwork-for-sale (artwork-id uint) (new-price uint))
  (let
    (
      (artwork-data (unwrap! (map-get? artworks artwork-id) err-artwork-not-found))
      (caller tx-sender)
    )
    (asserts! (is-eq caller (get owner artwork-data)) err-not-authorized)
    (asserts! (> new-price u0) err-invalid-price)
    
    (ok (map-set artworks artwork-id (merge artwork-data {
      price: new-price,
      for-sale: true
    })))
  )
)

;; Remove artwork from sale
(define-public (remove-artwork-from-sale (artwork-id uint))
  (let
    (
      (artwork-data (unwrap! (map-get? artworks artwork-id) err-artwork-not-found))
      (caller tx-sender)
    )
    (asserts! (is-eq caller (get owner artwork-data)) err-not-authorized)
    
    (ok (map-set artworks artwork-id (merge artwork-data {
      for-sale: false
    })))
  )
)

;; Verify artist (only contract owner)
(define-public (verify-artist (artist principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
    (asserts! (is-some (map-get? artist-profiles artist)) err-artwork-not-found)
    
    (let
      (
        (current-profile (unwrap-panic (map-get? artist-profiles artist)))
      )
      (ok (map-set artist-profiles artist (merge current-profile {
        verified: true
      })))
    )
  )
)

;; Read-only functions

;; Get artwork details
(define-read-only (get-artwork (artwork-id uint))
  (map-get? artworks artwork-id)
)

;; Get edition details
(define-read-only (get-edition (edition-id uint))
  (map-get? editions edition-id)
)

;; Get edition token details
(define-read-only (get-edition-token (edition-id uint) (token-number uint))
  (map-get? edition-tokens {edition-id: edition-id, token-number: token-number})
)

;; Get artist profile
(define-read-only (get-artist-profile (artist principal))
  (map-get? artist-profiles artist)
)

;; Get artwork provenance
(define-read-only (get-artwork-provenance (artwork-id uint))
  (map-get? artwork-provenance artwork-id)
)

;; Check if user owns artwork
(define-read-only (owns-artwork (user principal) (artwork-id uint))
  (default-to false (map-get? user-collections {user: user, artwork-id: artwork-id}))
)

;; Get next artwork ID
(define-read-only (get-next-artwork-id)
  (var-get next-artwork-id)
)

;; Get next edition ID
(define-read-only (get-next-edition-id)
  (var-get next-edition-id)
)

;; Get platform fee
(define-read-only (get-platform-fee)
  (var-get platform-fee-percentage)
)

;; Get contract owner
(define-read-only (get-contract-owner)
  contract-owner
)

;; Calculate rarity percentage for edition token
(define-read-only (get-edition-rarity (edition-id uint) (token-number uint))
  (match (map-get? editions edition-id)
    edition-data
    (let
      (
        (total-supply (get total-supply edition-data))
        (rarity-score (/ (* u10000 token-number) total-supply))
      )
      (some rarity-score)
    )
    none
  )
)