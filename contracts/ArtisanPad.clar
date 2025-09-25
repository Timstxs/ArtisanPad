;; ArtisanPad - Digital Art Provenance & Marketplace
;; A comprehensive platform for digital art creation, verification, and trading
;; Now with Multi-Edition NFT support and Auction System

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
(define-constant err-auction-not-found (err u112))
(define-constant err-auction-not-active (err u113))
(define-constant err-bid-too-low (err u114))
(define-constant err-auction-ended (err u115))
(define-constant err-auction-not-ended (err u116))
(define-constant err-no-bids (err u117))
(define-constant err-auction-already-settled (err u118))
(define-constant err-invalid-auction-duration (err u119))

;; Data Variables
(define-data-var next-artwork-id uint u1)
(define-data-var next-edition-id uint u1)
(define-data-var next-auction-id uint u1)
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

(define-map auctions
  uint
  {
    artwork-id: uint,
    seller: principal,
    start-price: uint,
    reserve-price: uint,
    current-bid: uint,
    highest-bidder: (optional principal),
    start-block: uint,
    end-block: uint,
    settled: bool,
    active: bool
  }
)

(define-map auction-bids
  {auction-id: uint, bidder: principal}
  uint
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

;; Create auction for artwork
(define-public (create-auction 
  (artwork-id uint) 
  (start-price uint) 
  (reserve-price uint) 
  (duration-blocks uint)
)
  (let
    (
      (artwork-data (unwrap! (map-get? artworks artwork-id) err-artwork-not-found))
      (auction-id (var-get next-auction-id))
      (caller tx-sender)
      (current-block stacks-block-height)
      (end-block (+ current-block duration-blocks))
    )
    (asserts! (is-eq caller (get owner artwork-data)) err-not-authorized)
    (asserts! (> start-price u0) err-invalid-price)
    (asserts! (>= reserve-price start-price) err-invalid-price)
    (asserts! (and (>= duration-blocks u144) (<= duration-blocks u4320)) err-invalid-auction-duration) ;; 1-30 days
    (asserts! (not (get for-sale artwork-data)) err-artwork-not-for-sale)
    
    ;; Create auction
    (map-set auctions auction-id {
      artwork-id: artwork-id,
      seller: caller,
      start-price: start-price,
      reserve-price: reserve-price,
      current-bid: u0,
      highest-bidder: none,
      start-block: current-block,
      end-block: end-block,
      settled: false,
      active: true
    })
    
    ;; Mark artwork as not for regular sale
    (map-set artworks artwork-id (merge artwork-data {
      for-sale: false
    }))
    
    ;; Increment auction counter
    (var-set next-auction-id (+ auction-id u1))
    (ok auction-id)
  )
)

;; Place bid on auction
(define-public (place-bid (auction-id uint) (bid-amount uint))
  (let
    (
      (auction-data (unwrap! (map-get? auctions auction-id) err-auction-not-found))
      (bidder tx-sender)
      (current-block stacks-block-height)
      (current-bid (get current-bid auction-data))
      (highest-bidder (get highest-bidder auction-data))
      (seller (get seller auction-data))
      (start-price (get start-price auction-data))
      (end-block (get end-block auction-data))
    )
    (asserts! (get active auction-data) err-auction-not-active)
    (asserts! (not (get settled auction-data)) err-auction-already-settled)
    (asserts! (<= current-block end-block) err-auction-ended)
    (asserts! (not (is-eq bidder seller)) err-not-authorized)
    (asserts! (>= bid-amount start-price) err-bid-too-low)
    (asserts! (> bid-amount current-bid) err-bid-too-low)
    
    ;; Refund previous highest bidder if exists
    (match highest-bidder
      previous-bidder
      (let
        (
          (previous-bid (unwrap! (map-get? auction-bids {auction-id: auction-id, bidder: previous-bidder}) err-auction-not-found))
        )
        (try! (stx-transfer? previous-bid tx-sender previous-bidder))
      )
      true
    )
    
    ;; Transfer bid amount from new bidder
    (try! (stx-transfer? bid-amount bidder tx-sender))
    
    ;; Update auction with new highest bid
    (map-set auctions auction-id (merge auction-data {
      current-bid: bid-amount,
      highest-bidder: (some bidder)
    }))
    
    ;; Record bid
    (map-set auction-bids {auction-id: auction-id, bidder: bidder} bid-amount)
    
    (ok true)
  )
)

;; Settle auction
(define-public (settle-auction (auction-id uint))
  (let
    (
      (auction-data (unwrap! (map-get? auctions auction-id) err-auction-not-found))
      (current-block stacks-block-height)
      (end-block (get end-block auction-data))
      (settled (get settled auction-data))
      (current-bid (get current-bid auction-data))
      (reserve-price (get reserve-price auction-data))
      (highest-bidder (get highest-bidder auction-data))
      (seller (get seller auction-data))
      (artwork-id (get artwork-id auction-data))
      (artwork-data (unwrap! (map-get? artworks artwork-id) err-artwork-not-found))
      (creator (get creator artwork-data))
      (royalty-percentage (get royalty-percentage artwork-data))
    )
    (asserts! (not settled) err-auction-already-settled)
    (asserts! (> current-block end-block) err-auction-not-ended)
    
    ;; Check if auction had bids and met reserve price
    (match highest-bidder
      winner
      (begin
        (asserts! (>= current-bid reserve-price) err-no-bids)
        
        ;; Calculate fees and amounts
        (let
          (
            (platform-fee (/ (* current-bid (var-get platform-fee-percentage)) u10000))
            (royalty-amount (if (is-eq creator seller) u0 (/ (* current-bid royalty-percentage) u10000)))
            (seller-amount (- (- current-bid platform-fee) royalty-amount))
          )
          
          ;; Transfer payment to seller
          (try! (stx-transfer? seller-amount tx-sender seller))
          
          ;; Transfer royalty to creator if different from seller
          (if (and (> royalty-amount u0) (not (is-eq creator seller)))
            (try! (stx-transfer? royalty-amount tx-sender creator))
            true
          )
          
          ;; Transfer platform fee to contract owner
          (try! (stx-transfer? platform-fee tx-sender contract-owner))
          
          ;; Update artwork ownership
          (map-set artworks artwork-id (merge artwork-data {
            owner: winner,
            last-sale-price: current-bid
          }))
          
          ;; Update collections
          (map-delete user-collections {user: seller, artwork-id: artwork-id})
          (map-set user-collections {user: winner, artwork-id: artwork-id} true)
          
          ;; Record provenance
          (map-set artwork-provenance artwork-id {
            previous-owner: seller,
            sale-price: current-bid,
            sale-date: current-block,
            transaction-hash: ""
          })
          
          ;; Update seller's profile
          (match (map-get? artist-profiles seller)
            seller-profile
            (map-set artist-profiles seller (merge seller-profile {
              total-sales: (+ (get total-sales seller-profile) u1)
            }))
            true
          )
        )
      )
      ;; No winner - refund not needed as no successful bids
      (begin
        ;; Return artwork to regular sale if desired
        (map-set artworks artwork-id (merge artwork-data {
          for-sale: false
        }))
      )
    )
    
    ;; Mark auction as settled
    (map-set auctions auction-id (merge auction-data {
      settled: true,
      active: false
    }))
    
    (ok true)
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

;; Cancel auction (only if no bids)
(define-public (cancel-auction (auction-id uint))
  (let
    (
      (auction-data (unwrap! (map-get? auctions auction-id) err-auction-not-found))
      (caller tx-sender)
      (seller (get seller auction-data))
      (current-bid (get current-bid auction-data))
      (artwork-id (get artwork-id auction-data))
      (artwork-data (unwrap! (map-get? artworks artwork-id) err-artwork-not-found))
    )
    (asserts! (is-eq caller seller) err-not-authorized)
    (asserts! (get active auction-data) err-auction-not-active)
    (asserts! (not (get settled auction-data)) err-auction-already-settled)
    (asserts! (is-eq current-bid u0) err-no-bids) ;; Can only cancel if no bids
    
    ;; Deactivate auction
    (map-set auctions auction-id (merge auction-data {
      active: false
    }))
    
    ;; Return artwork to owner control
    (map-set artworks artwork-id (merge artwork-data {
      for-sale: false
    }))
    
    (ok true)
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

;; Get auction details
(define-read-only (get-auction (auction-id uint))
  (map-get? auctions auction-id)
)

;; Get auction bid for specific bidder
(define-read-only (get-auction-bid (auction-id uint) (bidder principal))
  (map-get? auction-bids {auction-id: auction-id, bidder: bidder})
)

;; Check if auction is active
(define-read-only (is-auction-active (auction-id uint))
  (match (map-get? auctions auction-id)
    auction-data
    (and 
      (get active auction-data)
      (not (get settled auction-data))
      (<= stacks-block-height (get end-block auction-data))
    )
    false
  )
)

;; Check if auction can be settled
(define-read-only (can-settle-auction (auction-id uint))
  (match (map-get? auctions auction-id)
    auction-data
    (and 
      (not (get settled auction-data))
      (> stacks-block-height (get end-block auction-data))
    )
    false
  )
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

;; Get next auction ID
(define-read-only (get-next-auction-id)
  (var-get next-auction-id)
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