import Foundation

// Certificate Chain:
//All certificates in the chain are issued and signed by the same organization.
//This is common in large corporations (e.g. Google, Apple).
//While technically valid, it reduces third-party trust diversity. => not needed for now
//Chain depth / issuer-to-CN overlap
//Custom certificate policies (logged, they’ll be useful down the line)
//Certificate transparency / OCSP (not offline friendly but ... ?)

//Because TLS Certificate is both highly important and not important, its easy to get a "good" certificate, with with strong keys.
//Signals: the fresh certificate, the CN that is distributing certificate without seconds thoughts and
//the wildcard san where user can create content sharing the certificate and the SAN flood
import Punycode


struct TLSCertificateAnalyzer {
    //    tract tls accross the redirect chain to confirm heuristics or correct them
    
    // Track TLS chains
    static var tlsSANReusedMemory: [String: (domain: String, fingerprint: String, wasFlooded: Bool)] = [:]
    // Track EV OV bonus bonus 1 time per redirect chain
    static var hasIssuedEVorOVBonus: Bool = false
    static func resetMemory() {
        tlsSANReusedMemory.removeAll()
        hasIssuedEVorOVBonus = false
    }
    
    private static func sanBelongsToCurrentDomain(san: String, legitDomain: String) -> Bool {
        let sanParts = san.lowercased().split(separator: ".")
        let legitParts = legitDomain.lowercased().split(separator: ".")
        
        guard sanParts.count >= legitParts.count else { return false }

        return sanParts.suffix(legitParts.count) == legitParts
    }
    
    static func analyze(certificate: ParsedCertificate,
                        host: String,
                        domain: String,
                        warnings: inout [SecurityWarning],
                        responseCode: Int, origin: String) {
        
        // move to a static
        func addWarning(_ message: String, _ severity: SecurityWarning.SeverityLevel, penalty: Int, bitFlags: WarningFlags? = nil) {
            warnings.append(SecurityWarning(
                message: message,
                severity: severity,
                penalty: penalty,
                url: origin,
                source: .tls,
                bitFlags: bitFlags
            ))
        }
        
        let domainIdna: String = domain.idnaEncoded ?? ""
        let hostIdna: String = host.idnaEncoded ?? ""
        
        if tlsSANReusedMemory.contains(where: {
            $0.value.domain == domain &&
            $0.value.fingerprint == certificate.fingerprintSHA256
        }) {
            addWarning("TLS certificate with the same fingerprint. Skipping TLS checks.", .info, penalty: 0, bitFlags: WarningFlags.TLS_REUSE_IN_CHAIN)
            return
        }
        
        // Store the certificate fingerprint for potential comparison
        if let fingerprint = certificate.fingerprintSHA256 {
            tlsSANReusedMemory[hostIdna] = (domain: domainIdna, fingerprint: fingerprint, wasFlooded: false)
        }
        
        // 1. Domain Coverage via SANs
        guard let sans = certificate.subjectAlternativeNames, !sans.isEmpty else {
            addWarning("TLS certificate has no Subject Alternative Names", .critical, penalty: PenaltySystem.Penalty.critical)
            return
        }
        
        guard TLSHeuristics.domainIsCoveredBySANs(domain: domainIdna.lowercased(), host: hostIdna.lowercased(), sans: sans) else {
            addWarning("TLS Certificate does not cover domain \(domain) or host \(host)", .critical, penalty: PenaltySystem.Penalty.critical)
            return
        }
        
        
        // 2. Trust Anchor (Self-signed)
        if certificate.isSelfSigned {
            addWarning("TLS Certificate is self-signed (not issued by a trusted Certificate Authority)", .critical, penalty: PenaltySystem.Penalty.critical)
        }
        
        // 3. Expiry Window
        // Real usage not a timer !
        let now = Date()
        if let notAfter = certificate.notAfter {
            if notAfter < now {
                addWarning("TLS Certificate expired on \(TLSHeuristics.formattedDate(notAfter))", .critical, penalty: PenaltySystem.Penalty.critical)
            } else if Calendar.current.dateComponents([.day], from: now, to: notAfter).day ?? 0 <= 7 {
            } else if Calendar.current.dateComponents([.year], from: now, to: notAfter).year ?? 0 > 3 {
                addWarning("TLS Certificate expiry is more than 3 years away — unusual for DV certs", .suspicious, penalty: PenaltySystem.Penalty.suspiciousStatusCode)
            }
        }
        
        if let notBefore = certificate.notBefore {
            if let daysOld = Calendar.current.dateComponents([.day], from: notBefore, to: now).day {
                if daysOld <= 7 {
                    let isEVorOV = certificate.inferredValidationLevel == .ev || certificate.inferredValidationLevel == .ov
                    if !isEVorOV {
                        addWarning("TLS Certificate was issued very recently (\(daysOld) days ago) on \(TLSHeuristics.formattedDate(notBefore))", .suspicious, penalty: PenaltySystem.Penalty.tlsIsNew7days, bitFlags: WarningFlags.TLS_IS_FRESH)
                    } else {
                        addWarning("EV/OV certificate is fresh (\(daysOld) days) — no penalty applied", .info, penalty: 0)
                    }
                } else if daysOld <= 30 {
                    addWarning("TLS Certificate was issued recently (\(daysOld) days ago) on \(TLSHeuristics.formattedDate(notBefore))", .info, penalty: PenaltySystem.Penalty.informational, bitFlags: WarningFlags.TLS_IS_FRESH)
                }
            }
            
            if let notAfter = certificate.notAfter {
                if let lifespan = Calendar.current.dateComponents([.day], from: notBefore, to: notAfter).day, lifespan <= 30 {
                    addWarning("TLS Certificate has an unusually short lifespan of \(lifespan) days", .suspicious, penalty: PenaltySystem.Penalty.tlsShortLifespan)
                }
            }
        }
        
        // 4. Key Strength
        if let keyBits = certificate.publicKeyBits,
           let algorithm = certificate.publicKeyAlgorithm?.lowercased() {
            
            if algorithm.contains("rsa") {
                if keyBits < 2048 {
                    addWarning("TLS Certificate uses a weak RSA key size of \(keyBits) bits", .dangerous, penalty: PenaltySystem.Penalty.tksWeakKey)
                } /*else if keyBits >= 4096 {*/
                //                    addWarning("TLS Certificate uses a strong RSA key size of \(keyBits) bits", .info, penalty: 0)
                //                }
                //            } else if algorithm.contains("ec") || algorithm.contains("ecdsa") {
                //                if keyBits < 256 {
                //                    addWarning("TLS Certificate uses a weak EC key (less than 256 bits)", .info, penalty: 0)
                //                } else if keyBits < 384 {
                //                    addWarning("TLS Certificate uses an EC key of \(keyBits) bits", .info, penalty: 0)
                //                } else {
                //                    addWarning("TLS Certificate uses a strong EC key of \(keyBits) bits", .info, penalty: 0)
                //                }
            }
        }
        
        // 5. Extended Key Usage
        if let ekuRaw = certificate.extendedKeyUsageOID {
            let ekuList = parseEKUs(from: ekuRaw)
            for eku in ekuList {
                let penalty: Int = eku.severity == .info ? 0 : PenaltySystem.Penalty.suspiciousPattern
                if penalty > 0 {
                    addWarning("Extended Key Usage: \(eku.description)", eku.severity, penalty: penalty)
                }
            }
        }
        
        // 5.1 Simplified trust bonus based on EV/OV and wildcard presence
        let hasWildcardSAN = sans.contains { $0.hasPrefix("*.") }

        switch certificate.inferredValidationLevel {
        case .ev, .ov:
                //TODO: Need more test with wildcard subdomain on EV in a redirect chain starting or ending with aEV / OV no wildcard
            if !hasIssuedEVorOVBonus {
                let bonus = (certificate.inferredValidationLevel == .ev ? 30 : 20)
                let adjustedBonus = hasWildcardSAN ? 10 : bonus
                let label = certificate.inferredValidationLevel == .ev ? "Extended Validation (EV)" : "Organization Validated (OV)"
                addWarning("Certificate is \(label)\(hasWildcardSAN ? " with wildcard SANs" : "")", .good, penalty: adjustedBonus, bitFlags: [.TLS_IS_EV_OR_OV])
                hasIssuedEVorOVBonus = true
            } else {
                addWarning("Additional \(certificate.inferredValidationLevel == .ev ? "EV" : "OV") certificate detected, but EV/OV bonus already applied for this chain", .info, penalty: 0)
            }
        case .dv:
            addWarning("Certificate is Domain Validated (DV)", .info, penalty: 0)
        case .unknown:
            addWarning("Certificate is not EV, OV or DV", .suspicious, penalty: -10)
        }
        
        
        // 6. SAN Quality Checks
        if let sans = certificate.subjectAlternativeNames {
            for entry in sans {
                let lower = entry.lowercased()
                if lower.hasSuffix(".local") ||
                    lower.hasPrefix("127.") ||
                    lower.hasPrefix("192.168.") ||
                    lower.hasPrefix("10.") ||
                    lower.hasPrefix("::1") ||
                    lower == "localhost" {
                    addWarning("SAN includes private/internal address: \(entry)", .suspicious, penalty: PenaltySystem.Penalty.suspiciousStatusCode)
                }
            }
        }
        
        // 7. SAN Overload Heuristic
        //        Could parsed SANs for typosquatting in LegitURL V658642.1
        let hasWildcard = sans.contains { $0.hasPrefix("*.")}
        if !hasWildcard {
            var matchedSANCount = 0
            var totalSANCount = 0

            for san in sans {
                if san.contains(":") { continue } // skip IP
                totalSANCount += 1
                if sanBelongsToCurrentDomain(san: san, legitDomain: domainIdna) {
                    matchedSANCount += 1
                }
            }
            print("------------SANS CHECK")
            print("Number of san: ", totalSANCount , "matched:" , matchedSANCount)
            if totalSANCount > 20 {
                let ratio = Double(matchedSANCount) / Double(totalSANCount)

                switch ratio {
                case 1.0:
                    addWarning("All \(totalSANCount) SANs match the current domain", .info, penalty: 0)

                case 0.5..<1.0:
                    addWarning("\(matchedSANCount)/\(totalSANCount) SANs match the current domain", .info, penalty: 0)
                        
                case 0.1..<0.5:
                    addWarning("Only \(matchedSANCount) of \(totalSANCount) SANs match the current domain — certificate may be reused", .suspicious, penalty: PenaltySystem.Penalty.reusedTLS1FDQN / 2, bitFlags: WarningFlags.TLS_SANS_FLOOD)
                        if let fingerprint = certificate.fingerprintSHA256 {
                            tlsSANReusedMemory[hostIdna] = (domain: domainIdna, fingerprint: fingerprint, wasFlooded: true)
                        }
                        
                case ..<0.1:
                    addWarning("Less than 10% of SANs match the current domain — likely reused across unrelated infrastructure", .dangerous, penalty: PenaltySystem.Penalty.reusedTLS1FDQN, bitFlags: WarningFlags.TLS_SANS_FLOOD)
                    if let fingerprint = certificate.fingerprintSHA256 {
                        tlsSANReusedMemory[hostIdna] = (domain: domainIdna, fingerprint: fingerprint, wasFlooded: true)
                    }

                default:
                    break
                }
            }
        }
        
        // 8. Retroactive SAN Heuristic Reversal
        //        print("SANS FLOOD WAIVER MEMORY: ", tlsSANReusedMemory)
        if (certificate.inferredValidationLevel == .ev || certificate.inferredValidationLevel == .ov),
           let previousEntry = tlsSANReusedMemory.first(where: {
               $0.value.domain == domain &&
               $0.value.fingerprint != certificate.fingerprintSHA256 &&
               $0.value.wasFlooded
           }) {
            addWarning("Previously flagged TLS certificate on this domain appeared suspicious, but was followed by a clean certificate (EV or OV). Penalty waived.", .good, penalty: 25)
            tlsSANReusedMemory.removeValue(forKey: previousEntry.key)
        }
    }
}
