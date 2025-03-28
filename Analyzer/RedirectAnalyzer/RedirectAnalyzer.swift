//
//  RedirectAnalyzer.swift
//  URLChecker
//
//  Created by Chief Hakka on 25/03/2025.
//

import Foundation

struct RedirectAnalyzer {
    
    static func analyzeRedirect(fromInfo: URLInfo, toInfo: inout URLInfo, responseCode: Int? = nil) {
        let urlOrigin = toInfo.components.host ?? ""
        guard let originalDomain = fromInfo.domain?.lowercased(),
              let targetDomain = toInfo.domain?.lowercased(),
              let originalTLD = fromInfo.tld,
              let targetTLD = toInfo.tld,
              let originalHost = fromInfo.host?.lowercased(),
              let targetHost = toInfo.host?.lowercased(),
              let source: SecurityWarning.SourceType = responseCode != nil ? .onlineAnalysis : .offlineAnalysis
        else {
            toInfo.warnings.append(SecurityWarning(
                message: "❌ Missing domain, TLD, or host information for redirect analysis.",
                severity: .critical,
                url: urlOrigin,
                source: responseCode != nil ? .onlineAnalysis : .offlineAnalysis
            ))
            URLQueue.shared.LegitScore += PenaltySystem.Penalty.malformedRedirect
            return
        }

        if originalDomain.lowercased() != targetDomain.lowercased() {
            toInfo.warnings.append(SecurityWarning(
                message: "🚨 Redirect goes to a different domain: was \(originalDomain) now is \(targetDomain)",
                severity: .suspicious,
                url: urlOrigin,
                source: source
            ))
            URLQueue.shared.LegitScore += PenaltySystem.Penalty.redirectToDifferentDomain
            
        } else if originalTLD != targetTLD && originalDomain == targetDomain {
            toInfo.warnings.append(SecurityWarning(
                message: "🚨 Redirect to a different TLD, was \(originalTLD) now is:\(targetTLD)",
                severity: .suspicious,
                url: urlOrigin,
                source: source
            ))
            URLQueue.shared.LegitScore += PenaltySystem.Penalty.redirectToDifferentTLD
            
        } else if originalHost != targetHost && originalDomain == targetDomain {
            toInfo.warnings.append(SecurityWarning(
                message: "🔄 Internal redirect to different subdomain: \(targetHost)",
                severity: .info,
                url: urlOrigin,
                source: source
            ))
        }
        else {
            toInfo.warnings.append(SecurityWarning(
                message: "🔄 Internal redirect to same domain: \(targetHost)",
                severity: .info,
                url: urlOrigin,
                source: source
            ))
        }
    }
}
