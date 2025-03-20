//
//  URLGetAnalyzer.swift
//  URLChecker
//
//  Created by Chief Hakka on 18/03/2025.
//

import Foundation

struct URLGetAnalyzer {
    static func analyze(urlInfo: inout URLInfo) {
        let originalURL = urlInfo.components.fullURL ?? ""
        
        // ✅ Retrieve OnlineURLInfo using the ID
        guard let onlineInfo = URLQueue.shared.onlineQueue.first(where: { $0.id == urlInfo.id }) else {
            urlInfo.warnings.append(SecurityWarning(
                message: "⚠️ No online analysis found for this URL. Skipping further checks.",
                severity: .info
            ))
            return
        }
        
        let finalURL = onlineInfo.finalRedirectURL ?? originalURL
        let headers = onlineInfo.normalizedHeaders ?? [:]

        //  Analyze headers for security
        let headerWarnings = HeadersAnalyzer.analyze(responseHeaders: headers)
        urlInfo.warnings.append(contentsOf: headerWarnings)

        //  Detect silent redirect (200 OK but URL changed)
        let normalizedOriginalURL = originalURL.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let normalizedFinalURL = finalURL.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        // This shouldnt happen anymore, but in case it happens it's VERY BAD???
        if onlineInfo.serverResponseCode == 200, normalizedFinalURL != normalizedOriginalURL {
            urlInfo.warnings.append(SecurityWarning(
                message: "🚨 Hidden / Silent redirect detected.\nOriginal URL: \(originalURL)\nFinal URL: \(finalURL)\nThis is either bad practice or a scam attempt.",
                severity: .suspicious
            ))
        }
    }
}
