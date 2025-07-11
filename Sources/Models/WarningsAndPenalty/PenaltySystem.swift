import Foundation

// TODO: Add positive signal:
//CSP header
//strict, uses nonce/SRI, no unsafe-inline
//+5 +15 ?
//TLS certificate

//EV certificate
//maybe +3 if from highly trusted CA and domain logic aligns
//Consistent domain across redirects
//if no other bad signals present
//-> this is the hardest, EV with *.domain.com maybe, but for now only letsencrypt make sense for the DNS challenge, not sure for other issuer
//small X ?
//Short cookie lifespan + low entropy, or no cookie? But this is tricky lot of scam have no cookies.......
//may indicate session handling, not tracking ? But this is a CLEAN GET i do not need a session ???????
//+2
//all inline locked with nonce / sha or no inline, no external JS, all scripts via HTTPS + SRI
//real trust signal ?

struct PenaltySystem {
    public enum Penalty {
        //POSITIVE SIGNAL
        static let allScripttNonced                    = 15
        
        
        // CRITICAL ISSUES
        static let critical                            = -100
        
        // HOST-RELATED PENALTIES
        static let highEntropyDomain                   = -30
        static let exactBrandImpersonation             = -25
        static let phishingWordsInHost                 = -20
        static let scamWordsInHost                     = -20
        static let tooManyHyphensInDomain              = -20
        static let userInfoInHost                      = -20
        static let subdomainUnderscore                 = -20
        static let brandImpersonation                  = -15
        static let brandInSubdomain                    = -10
        static let brandLookaLike                      = -10
        static let underScoreInSubdomain               = -10
        static let highEntropySubDomain                = -10
        static let domainNonASCII                      = -10
        
        // REDIRECTION & OBFUSCATION
        //        static let hiddenRedirectFragment              = -40
        static let hiddenRedirectQuery                 = -30
        //        static let phpRedirect                         = -25
        //        static let suspiciousRedirect                  = -10
        
        // PATH-RELATED PENALTIES
        static let executableInPath                    = -20
        static let nonalpahaNumericInPath              = -15
        static let pathHasExecutable                   = -10
        static let pathIsEndpointLike                  = -10
        static let highEntropyPathComponent            = -10
        static let scamWordsInPath                     = -10
        static let phishingWordsInPath                 = -10
        static let suspiciousPathSegment               = -10
        static let containBrandInPath                  = -5
        static let brandLookaLikeInPath                = -5
        
        // QUERIES & fragment ... Need granularity see lamai todo
        static let malformedQueryPair                  = -40
        static let highEntropyQuery                    = -10
        static let queryKeyForbiddenCharacters         = -20
        static let valueForbiddenCharacters            = -20
        static let scamWordsInQuery                    = -20
        static let phishingWordsInQuery                = -20
        static let IpAddressInQuery                    = -20
        static let emailInQuery                        = -20
        static let exactBrandInQuery                   = -10
        static let keyIsHighEntropy                    = -15
        static let queryContainsBrand                  = -10
        static let brandLookAlikeInQuery               = -5
        static let uuidInQuery                         = -10
        static let jsonInQuery                         = -10
        static let emptyQuery                          = -5
        
        // Fragment
        static let forbiddenChar                       = -20
        static let malformedFragmentPair               = -20
        static let malformedFragment                   = -15
        
        //JAVASCRIPT & SECURITY ISSUES
        static let javascriptXSS                       = -30
        
        static let deepObfuscation                     = -20
        static let suspiciousPattern                   = -15
        static let base64Url                           = -10
        
        
        
        /////////////////////ONLINE ///////////////////////////////////////////
        ///Body
        static let extHttpScriptSrc                    = -40
        static let scriptIs80Percent                   = -30
        static let scriptDataURI                       = -40
        static let jsEvalInBody                        = -30
        static let badJSCallInline                     = -30
        static let jsFingerPrinting                    = -30
        static let hotdogWaterDev                      = -30
        static let unusualScritSrcFormat               = -30
        static let unclosedHTMLTag                     = -30
        static let atobJSONparserCombo                 = -25
        static let bomboclotScript                     = -25
        static let metaRefreshInBody                   = -25
        static let scriptMalformed                     = -20
        static let scriptIsMoreThan512                 = -20
        static let scriptUnknownOrigin                 = -20
        static let jsWindowsRedirect                   = -20
        static let jsWebAssembly                       = -20
        static let extScriptSrc                        = -20
        static let highScriptDensity20                 = -20
        static let missingMalformedHEadTag             = -15
        static let missingMalformedBodyTag             = -5
        static let scriptIs70Percent                   = -10
        static let smallHTMLless896                    = -10
        static let highScriptDensity                   = -10
        static let sameDomainCookie                    = -10
        static let jsStorageAccess                     = -10
        static let jsSetItemAccess                     = -10
        static let protocolRelativeScriptSrc           = -10
        static let jsCookieAccess                      = -5
        static let metaCSP                             = -5
        static let mediumScritpDensity                 = -5
        static let scriptIs5070Percent                 = -5
        static let smallhtmllessthan1408               = -5
        static let protocolRelativeScriptSRI           = -5
        
        
        
        //InlineSpecific & JS penalty
        static let hightPenaltyForInlineJS             = -20
        static let jsSetEditCookie                     = -15
        static let inlineMore100kB                     = -30
        static let mediumPenaltyForInlineJS            = -10
        static let moduleCrossoriginUnknownValue       = -5 // Same penalty different reasons?
        static let moduleCrossoriginMalformed          = -5 // Need a specific bitflag maybe... but for what??
        static let lowPenaltyForInlineJS               = -5
        static let jsReadsCookie                       = -5
        
        ///Cookie////
        static let cookiesOnNon200                     = -15
        static let moreThan64BofCookie                 = -15
        static let moreThan16BofCookie                 = -5
        ///TLS///
        static let tksWeakKey                          = -20
        static let reusedTLS1FDQN                      = -20
        static let hotDogwaterCN                       = -10 //unused need more digging into CNs
        static let tlsWillExpireSoon                   = -10
        static let tlsIsNew7days                       = -10
        static let tlsShortLifespan                    = -10
        
        
        //RESPONSE HEADER ISSUE
        static let blockedByFirewall                   = -100
        static let serverError                         = -100
        static let missConfiguredOrScam                = -40
        static let suspiciousStatusCode                = -35
        static let hidden200Redirect                   = -20
        
        //HEADERS
        static let missingHSTS                         = -30
        static let fakeCSP                             = -40
        static let inccorectLogic                      = -5
        static let lowHSTSValue                        = -5
        static let weakReferrerPolicy                  = -5
        
        //CSP
        static let missingCSP                          = -50 //HARD LIMIT FOR CSP penalty! Missing CSP cannot be less than a missconfig CSP. Though a "fake" CSP might be worse
        static let CSPReportOnly                       = -40
        static let wildcardScriptSrc                   = -20
        static let wildcardScriptSrcStrictDyn          = -10
        static let nonceInCSPNoInline                  = -5
        static let nonceValueIsWeak                    = -5
        static let nonceMissMatch                      = -5 // very unsure because this is harmless, but there is a problem. This does not point to a scam, or a pretty bad one. Still a signal ?
        
        //unsafe not "contained"
        static let unsafeEvalScriptSrc                 = -25 // higher than inlinescript used to be 30 and 20 ? make no sense between volontary unsafe and missing, max penalty cap at 40 when both are present
        static let unsafeInlineScriptSrc               = -15
        
        //unsafe "nonce'd or hashed + dynamic"
//        static let unsafeEvalScriptContained           = -30 // Alwasys bad
//        static let unsafeInlineStrictDynAndNonce       = -12 // unused strict-dynamic nullifies unsafe-inline, for lvl3 browser
        
        //  unsafe-inline "containe'd"
//        static let unsafeInlineHash                    = -20 // most "secure" still bad because inline, hash i

        static let serverLeakNameAndVersion            = -5
        static let malformedIncompleteCSP              = -5
            
        
        // Redirect
        static let silentRedirect                     = -20
        static let malformedRedirect                  = -20
        static let redirectToDifferentTLD             = -20
        static let redirectRelative                   = -20
        static let redirectToDifferentDomain          = -10
        
        // INFORMATIVE (No penalty)
        static let informational                       = 0
    }
    
    // Suspicious TLDs and their penalties
//    TODO: Replaced with a normalized source of real data and not random findings on te web
    static let suspiciousTLDs: [String: Int] = [
        ".tk":          -20,
        ".ml":          -20,
        ".ga":          -20,
        ".cf":          -20,
        ".gq":          -20,
        ".top":         -20,
        ".xyz":         -20,
        ".ru":          -20,
        ".cn":          -20,
        ".cc":          -20,
        ".pw":          -20,
        ".biz":         -20,
        ".ws":          -20,
        ".info":        -20,
        ".review":      -20,
        ".loan":        -20,
        ".download":    -20,
        ".trade":       -20,
        ".party":       -20,
        ".click":       -20,
        ".country":     -20,
        ".kim":         -20,
        ".men":         -20,
        ".date":        -20,
        ".gdn":         -20,
        ".stream":      -20,
        ".cam":         -20,
        ".cricket":     -20,
        ".space":       -20,
        ".fun":         -20,
        ".site":        -20,
        ".best":        -20,
        ".world":       -20,
        ".shop":        -20,
        ".gifts":       -20,
        ".beauty":      -20,
        ".zip":         -20,
        ".mov":         -20,
        ".live":        -20
    ]
    static func penaltyForCookieBitFlags(_ flags: CookieFlagBits) -> Int {
        // MARK: - Cookie Scoring Pyramid Initial logic
        //
        // Group 1 — BENIGN (Score: 0)
        // - Expired token:
        //     .expired + .httpOnly, without .highEntropyValue → harmless cleanup
        // - Secure session ID:
        //     .session + .smallValue + .secure + .httpOnly
        // - Short-lived token:
        //     .shortLivedPersistent + .smallValue + .secure + .httpOnly
        // - SameSite strict/lax with low entropy → conservative setup
        //
        // Group 2 — TRACKING (Score: -5 to -10)
        // - Secure persistent tracking:
        //     .persistent + .highEntropyValue + .secure + .httpOnly
        // - Clean medium cookie:
        //     .mediumValue + .secure + .httpOnly
        // - Redirect reuse:
        //     .reusedAcrossRedirect + .smallValue
        // - 3rd party tracking with protection:
        //     .sameSiteNone + .secure + .httpOnly
        //
        // Group 3 — SUSPICIOUS (Score: -10 to -15)
        // - Leaky persistent tracking:
        //     .persistent + .highEntropyValue + (missing .httpOnly || missing .secure)
        // - Fingerprint-style token:
        //     .shortLivedPersistent + .largeValue + .highEntropyValue + missing .httpOnly
        // - Redirect behavior:
        //     .setOnRedirect + .reusedAcrossRedirect
        // - Inconsistent session:
        //     .session + .largeValue
        // - SameSite=None + missing Secure flag
        //
        // Group 4 — DANGEROUS (Score: -15 to -20)
        // - Full fingerprint blob:
        //     .largeValue + .shortLivedPersistent + .highEntropyValue + missing .httpOnly
        // - Cross-redirect ID recycling:
        //     .persistent + .reusedAcrossRedirect + .highEntropyValue
        // - Cloaked redirect injection:
        //     .setOnRedirect + .highEntropyValue
        // - Conflicting lifespan indicators:
        //     .persistent + .shortLivedPersistent → malformed config, possibly intentional abuse
        var penalty = 0
        let fullSecured = flags.contains([.httpOnly, .secure])
        let fingerPrintStyle = flags.contains([. largeValue, .persistent])
        let isSameSiteNone = flags.contains(.sameSiteNone)
        
        // Group 1: Harmless, bad practice not dangerous,  reused on redirect
        if flags.contains([.expired, .httpOnly]) {
            return 0
        }
        if flags.contains(.reusedAcrossRedirect) && !flags.contains(.setOnRedirect) {
            return 0
        }
        if flags.contains(.verySmall) {return 0}
        
        
        // Suspicious misuse: session + SameSite=None small value
        if flags.contains(.session) && flags.contains(.sameSiteNone) && flags.contains(.smallValue) {
            return -5  // Indicates tracking intent with fake session scope
        }
        
        // Suspicious misuse: session + SameSite=None
        if flags.contains(.session) && flags.contains(.sameSiteNone) {
            return -10  // Indicates tracking intent with fake session scope
        }

        // Invalid combo: SameSite=None without Secure
        if flags.contains(.sameSiteNone) && !flags.contains(.secure) {
            return -15  // Rejected by modern browsers but still a strong red flag
        }
        
        // Conflicting lifespan — possibly intentional cloaking
        if flags.contains([.persistent, .shortLivedPersistent]) {
            return -15
        }
        
        if flags.contains(.setOnRedirect) && flags.contains(.reusedAcrossRedirect) {
            if flags.contains(.highEntropyValue) {
                return -15  // Likely fingerprint injected mid-redirect
            } else {
                return -10  // Behavioral tracking across hops
            }
        }
        
        // Group 1: Benign cookie combinations
        if flags.contains(.smallValue) && fullSecured {
            return 0
        }
        if flags.contains(.smallValue) && !fullSecured { return -3}
        
        // Group 2: Suspicious secure tracker potential
        if flags.contains(.mediumValue) && flags.contains(.session) {
            if fullSecured {
                return -2
            } else if !flags.contains(.secure) && flags.contains(.httpOnly) {
                return -4
            } else if flags.contains(.secure) && !flags.contains(.httpOnly) {
                return -6
            } else {
                return -7
            }
        }
        
        if flags.contains(.largeValue) && flags.contains(.session) {
            if fullSecured {
                return -3
            } else if flags.contains(.httpOnly) && !flags.contains(.secure) {
                return -5
            } else if flags.contains(.secure) && !flags.contains(.httpOnly) {
                return -6
            } else {
                return -8
            }
        }
        
        if fingerPrintStyle {
            if fullSecured && !isSameSiteNone {
                return -5
            } else if fullSecured && isSameSiteNone {
                return -7
            } else if flags.contains(.httpOnly) && !flags.contains(.secure) {
                return -8
            } else if flags.contains(.secure) && !flags.contains(.httpOnly) {
                return isSameSiteNone ? -10 : -8
            } else {
                return -15
            }
        }
        
        if flags.contains(.setOnRedirect) && flags.contains(.reusedAcrossRedirect) {
            if flags.contains(.highEntropyValue) {
                return -15  // Likely fingerprint injected mid-redirect
            } else {
                return -10  // Behavioral tracking across hops
            }
        }

        
        // MARK: - Atomic signal-based accumulation
        
        // Exposure
        if !flags.contains(.httpOnly)            { penalty += -5 } // More dangerous: JS can access
        if !flags.contains(.secure)              { penalty += -2 } // Less dangerous, more like different kind of dangerous : sent over HTTP
        if flags.contains(.domainOverlyBroad)    { penalty += -2 }
        if flags.contains(.pathOverlyBroad)      { penalty += -2 }
        
        // Payload intent
        if flags.contains(.persistent)           { penalty += -2 }
        if flags.contains(.shortLivedPersistent) { penalty += -1 }
        if flags.contains(.highEntropyValue)     { penalty += -3 }
        if flags.contains(.largeValue)           { penalty += -5 }
        if flags.contains(.wayTooLarge)          { penalty += -3 }
        
        // Configuration quirks
        if flags.contains(.sameSiteNone)         { penalty += -5 }
        if flags.contains(.expired) &&
            !flags.contains(.httpOnly) &&
            flags.contains(.highEntropyValue)    { penalty += -5 }
        if flags.contains(.setOnRedirect)        { penalty += -2}
        
        return max(penalty, -100)
    }
    
    static func getPenaltyAndSeverity(name: String) -> (penalty: Int, severity: SecurityWarning.SeverityLevel) {
        switch name {
        case "eval", "window[\"eval\"]", "Function":
            return (PenaltySystem.Penalty.critical, .critical)
        case "cookie":
            return (PenaltySystem.Penalty.jsCookieAccess, .suspicious)
        case "WebAssembly", "innerhtml", "outerhtml":
            return (PenaltySystem.Penalty.jsWebAssembly, .dangerous)
        case "atob", "btoa", "window.open", "document.write":
            return (PenaltySystem.Penalty.mediumPenaltyForInlineJS, .suspicious)
        case "location.href":
            return (PenaltySystem.Penalty.hightPenaltyForInlineJS, .dangerous)
        case "location.replace", "location.assign", "getElementById":
            return (PenaltySystem.Penalty.mediumPenaltyForInlineJS, .suspicious)
        case "unescape", "escape":
            return (PenaltySystem.Penalty.mediumPenaltyForInlineJS, .suspicious)
        case "localStorage":
            return (PenaltySystem.Penalty.jsStorageAccess, .suspicious)
        case "setItem":
            return (PenaltySystem.Penalty.jsSetItemAccess, .suspicious)
        case "console.log", "fetch", "xmlhttprequest", "websocket", "import":
            return (PenaltySystem.Penalty.informational, .info)
        default:
            return (-10, .suspicious)
        }
    }
}
