(impl-trait .trait-flash-loan-user.flash-loan-user-trait)
(use-trait ft-trait .trait-sip-010.sip-010-trait)

(define-constant math-call-err (err u2010))
(define-constant ERR-GET-EXPIRY-FAIL-ERR (err u2013))

(define-constant ONE_8 (pow u10 u8))

(define-public (execute (token <ft-trait>) (amount uint))
    (let
        (   
            ;; gross amount * ltv / price = amount
            ;; gross amount = amount * price / ltv
            (expiry (unwrap! (contract-call? .yield-usda-51840 get-expiry) ERR-GET-EXPIRY-FAIL-ERR))
            (ltv (try! (contract-call? .collateral-rebalancing-pool get-ltv .token-usda .token-wstx expiry)))
            (price (try! (contract-call? .yield-token-pool get-price .yield-usda-51840)))
            (gross-amount (contract-call? .math-fixed-point mul-up amount (contract-call? .math-fixed-point div-down price ltv)))
            (minted-yield-token (get yield-token (try! (contract-call? .collateral-rebalancing-pool add-to-position .token-usda .token-wstx .yield-usda-51840 .key-usda-51840-wstx gross-amount))))
            (swapped-token (get dx (try! (contract-call? .yield-token-pool swap-y-for-x .yield-usda-51840 .token-usda minted-yield-token none))))
        )
        ;; swap token to collateral so we can return flash-loan
        (if (is-some (contract-call? .fixed-weight-pool get-pool-exists .token-wstx .token-usda u50000000 u50000000))
            (try! (contract-call? .fixed-weight-pool swap-y-for-x .token-wstx .token-usda u50000000 u50000000 swapped-token none))
            (try! (contract-call? .fixed-weight-pool swap-x-for-y .token-usda .token-wstx u50000000 u50000000 swapped-token none))
        )
        
        (print { object: "flash-loan-user-margin-usda-wstx-51840", action: "execute", data: gross-amount })
        (ok true)
    )
)