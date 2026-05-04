import Flutter
import UIKit
import MarfeelSDK_iOS

public class MarfeelSdkPlugin: NSObject, FlutterPlugin {
    private var experienceCache: [String: Experience] = [:]
    private let cacheLock = NSLock()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.marfeel.sdk/compass", binaryMessenger: registrar.messenger())
        let instance = MarfeelSdkPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]

        switch call.method {
        case "initialize":
            let accountId = args?["accountId"] as? String ?? ""
            let accountIdInt = Int(accountId) ?? 0
            if let pageTechnology = args?["pageTechnology"] as? Int {
                CompassTracker.initialize(accountId: accountIdInt, pageTechnology: pageTechnology)
            } else {
                CompassTracker.initialize(accountId: accountIdInt)
            }
            result(nil)

        case "trackNewPage":
            let url = args?["url"] as? String ?? ""
            let rs = args?["rs"] as? String
            guard let pageUrl = URL(string: url) else {
                result(nil)
                return
            }
            CompassTracker.shared.trackNewPage(url: pageUrl, scrollView: nil, rs: rs)
            result(nil)

        case "trackScreen":
            let screen = args?["screen"] as? String ?? ""
            let rs = args?["rs"] as? String
            CompassTracker.shared.trackScreen(name: screen, scrollView: nil, rs: rs)
            result(nil)

        case "stopTracking":
            CompassTracker.shared.stopTracking()
            result(nil)

        case "setLandingPage":
            let landingPage = args?["landingPage"] as? String ?? ""
            CompassTracker.shared.setLandingPage(landingPage)
            result(nil)

        case "setSiteUserId":
            let userId = args?["userId"] as? String ?? ""
            CompassTracker.shared.setSiteUserId(userId)
            result(nil)

        case "getUserId":
            let userId = CompassTracker.shared.getUserId()
            result(userId)

        case "setUserType":
            let userType = args?["userType"] as? Int ?? 1
            let type: UserType
            switch userType {
            case 1: type = .anonymous
            case 2: type = .logged
            case 3: type = .paid
            default: type = .custom(userType)
            }
            CompassTracker.shared.setUserType(type)
            result(nil)

        case "getRFV":
            CompassTracker.shared.getRFV { rfv in
                if let rfv = rfv {
                    let json: [String: Any] = [
                        "rfv": rfv.rfv,
                        "r": rfv.r,
                        "f": rfv.f,
                        "v": rfv.v
                    ]
                    if let data = try? JSONSerialization.data(withJSONObject: json),
                       let jsonString = String(data: data, encoding: .utf8) {
                        result(jsonString)
                    } else {
                        result(nil)
                    }
                } else {
                    result(nil)
                }
            }

        case "setPageVar":
            let name = args?["name"] as? String ?? ""
            let value = args?["value"] as? String ?? ""
            CompassTracker.shared.setPageVar(name: name, value: value)
            result(nil)

        case "setPageMetric":
            let name = args?["name"] as? String ?? ""
            let value = args?["value"] as? Int ?? 0
            CompassTracker.shared.setPageMetric(name: name, value: value)
            result(nil)

        case "setSessionVar":
            let name = args?["name"] as? String ?? ""
            let value = args?["value"] as? String ?? ""
            CompassTracker.shared.setSessionVar(name: name, value: value)
            result(nil)

        case "setUserVar":
            let name = args?["name"] as? String ?? ""
            let value = args?["value"] as? String ?? ""
            CompassTracker.shared.setUserVar(name: name, value: value)
            result(nil)

        case "addUserSegment":
            let segment = args?["segment"] as? String ?? ""
            CompassTracker.shared.addUserSegment(segment)
            result(nil)

        case "setUserSegments":
            let segments = args?["segments"] as? [String] ?? []
            CompassTracker.shared.setUserSegments(segments)
            result(nil)

        case "removeUserSegment":
            let segment = args?["segment"] as? String ?? ""
            CompassTracker.shared.removeUserSegment(segment)
            result(nil)

        case "clearUserSegments":
            CompassTracker.shared.clearUserSegments()
            result(nil)

        case "trackConversion":
            let conversion = args?["conversion"] as? String ?? ""
            let initiator = args?["initiator"] as? String
            let id = args?["id"] as? String
            let value = args?["value"] as? String
            let meta = args?["meta"] as? [String: String]
            let scope = args?["scope"] as? String

            let conversionScope: ConversionScope?
            switch scope {
            case "user": conversionScope = .user
            case "session": conversionScope = .session
            case "page": conversionScope = .page
            default: conversionScope = nil
            }

            if initiator == nil && id == nil && value == nil && meta == nil && conversionScope == nil {
                CompassTracker.shared.trackConversion(conversion: conversion)
            } else {
                let options = ConversionOptions(
                    initiator: initiator,
                    id: id,
                    value: value,
                    meta: meta,
                    scope: conversionScope
                )
                CompassTracker.shared.trackConversion(conversion: conversion, options: options)
            }
            result(nil)

        case "setConsent":
            let hasConsent = args?["hasConsent"] as? Bool ?? false
            CompassTracker.shared.setConsent(hasConsent)
            result(nil)

        case "updateScrollPercentage":
            let percentage = args?["percentage"] as? Int ?? 0
            CompassTracker.shared.updateScrollPercentage(Float(percentage))
            result(nil)

        case "initializeMultimediaItem":
            let id = args?["id"] as? String ?? ""
            let provider = args?["provider"] as? String ?? ""
            let providerId = args?["providerId"] as? String ?? ""
            let type = args?["type"] as? String ?? "video"
            let metadataStr = args?["metadata"] as? String ?? "{}"

            let mediaType: MarfeelSDK_iOS.`Type` = type == "audio" ? .AUDIO : .VIDEO

            var multimediaMetadata = MultimediaMetadata()
            if let data = metadataStr.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                multimediaMetadata = MultimediaMetadata(
                    isLive: json["isLive"] as? Bool ?? false,
                    title: json["title"] as? String,
                    description: json["description"] as? String,
                    url: (json["url"] as? String).flatMap { URL(string: $0) },
                    thumbnail: (json["thumbnail"] as? String).flatMap { URL(string: $0) },
                    authors: json["authors"] as? String,
                    publishTime: (json["publishTime"] as? Int64).flatMap { Date(timeIntervalSince1970: TimeInterval($0) / 1000) },
                    duration: json["duration"] as? Int
                )
            }

            CompassTrackerMultimedia.shared.initializeItem(
                id: id,
                provider: provider,
                providerId: providerId,
                type: mediaType,
                metadata: multimediaMetadata
            )
            result(nil)

        case "registerMultimediaEvent":
            let id = args?["id"] as? String ?? ""
            let event = args?["event"] as? String ?? ""
            let eventTime = args?["eventTime"] as? Int ?? 0

            let mediaEvent: Event
            switch event {
            case "play": mediaEvent = .PLAY
            case "pause": mediaEvent = .PAUSE
            case "end": mediaEvent = .END
            case "updateCurrentTime": mediaEvent = .UPDATE_CURRENT_TIME
            case "adPlay": mediaEvent = .AD_PLAY
            case "mute": mediaEvent = .MUTE
            case "unmute": mediaEvent = .UNMUTE
            case "fullscreen": mediaEvent = .FULL_SCREEN
            case "backscreen": mediaEvent = .BACK_SCREEN
            case "enterViewport": mediaEvent = .ENTER_VIEWPORT
            case "leaveViewport": mediaEvent = .LEAVE_VIEWPORT
            default:
                result(FlutterError(code: "INVALID_EVENT", message: "Unknown event: \(event)", details: nil))
                return
            }

            CompassTrackerMultimedia.shared.registerEvent(id: id, event: mediaEvent, eventTime: eventTime)
            result(nil)

        case "recirculation.trackEligible":
            let name = args?["name"] as? String ?? ""
            let links = parseLinks(args?["links"])
            Recirculation.shared.trackEligible(name: name, links: links)
            result(nil)

        case "recirculation.trackImpression":
            let name = args?["name"] as? String ?? ""
            let links = parseLinks(args?["links"])
            Recirculation.shared.trackImpression(name: name, links: links)
            result(nil)

        case "recirculation.trackImpressionLink":
            let name = args?["name"] as? String ?? ""
            let link = parseLink(args?["link"])
            Recirculation.shared.trackImpression(name: name, link: link)
            result(nil)

        case "recirculation.trackClick":
            let name = args?["name"] as? String ?? ""
            let link = parseLink(args?["link"])
            Recirculation.shared.trackClick(name: name, link: link)
            result(nil)

        case "experiences.addTargeting":
            let key = args?["key"] as? String ?? ""
            let value = args?["value"] as? String ?? ""
            Experiences.shared.addTargeting(key: key, value: value)
            result(nil)

        case "experiences.fetch":
            let filterByType = (args?["filterByType"] as? String).flatMap { ExperienceType(rawValue: $0) }
            let filterByFamily = (args?["filterByFamily"] as? String).flatMap { ExperienceFamily(rawValue: $0) }
            let resolve = args?["resolve"] as? Bool ?? false
            let url = args?["url"] as? String
            Experiences.shared.fetchExperiences(
                filterByType: filterByType,
                filterByFamily: filterByFamily,
                resolve: resolve,
                url: url
            ) { [weak self] experiences in
                guard let self = self else {
                    result([])
                    return
                }
                self.cacheLock.lock()
                self.experienceCache.removeAll()
                for exp in experiences {
                    self.experienceCache[exp.id] = exp
                }
                self.cacheLock.unlock()
                let payload = experiences.map { Self.encodeExperience($0) }
                result(payload)
            }

        case "experiences.trackEligible":
            let id = args?["experienceId"] as? String ?? ""
            let name = args?["experienceName"] as? String ?? ""
            let links = parseLinks(args?["links"])
            if let exp = lookupExperience(id: id) {
                Experiences.shared.trackEligible(experience: exp, links: links)
            } else {
                Recirculation.shared.trackEligible(name: name, links: links)
            }
            result(nil)

        case "experiences.trackImpression":
            let id = args?["experienceId"] as? String ?? ""
            let name = args?["experienceName"] as? String ?? ""
            let links = parseLinks(args?["links"])
            if let exp = lookupExperience(id: id) {
                Experiences.shared.trackImpression(experience: exp, links: links)
            } else {
                Recirculation.shared.trackImpression(name: name, links: links)
            }
            result(nil)

        case "experiences.trackImpressionLink":
            let id = args?["experienceId"] as? String ?? ""
            let name = args?["experienceName"] as? String ?? ""
            let link = parseLink(args?["link"])
            if let exp = lookupExperience(id: id) {
                Experiences.shared.trackImpression(experience: exp, link: link)
            } else {
                Recirculation.shared.trackImpression(name: name, link: link)
            }
            result(nil)

        case "experiences.trackClick":
            let id = args?["experienceId"] as? String ?? ""
            let name = args?["experienceName"] as? String ?? ""
            let link = parseLink(args?["link"])
            if let exp = lookupExperience(id: id) {
                Experiences.shared.trackClick(experience: exp, link: link)
            } else {
                Recirculation.shared.trackClick(name: name, link: link)
            }
            result(nil)

        case "experiences.trackClose":
            let id = args?["experienceId"] as? String ?? ""
            if let exp = lookupExperience(id: id) {
                Experiences.shared.trackClose(experience: exp)
            }
            result(nil)

        case "experiences.resolve":
            let id = args?["experienceId"] as? String ?? ""
            guard let exp = lookupExperience(id: id) else {
                result(nil)
                return
            }
            exp.resolve { content in
                result(content)
            }

        case "experiences.clearFrequencyCaps":
            Experiences.shared.clearFrequencyCaps()
            result(nil)

        case "experiences.getFrequencyCapCounts":
            let id = args?["experienceId"] as? String ?? ""
            result(Experiences.shared.getFrequencyCapCounts(experienceId: id))

        case "experiences.getFrequencyCapConfig":
            result(Experiences.shared.getFrequencyCapConfig())

        case "experiences.clearReadEditorials":
            Experiences.shared.clearReadEditorials()
            result(nil)

        case "experiences.getReadEditorials":
            result(Experiences.shared.getReadEditorials())

        case "experiences.getExperimentAssignments":
            result(Experiences.shared.getExperimentAssignments())

        case "experiences.setExperimentAssignment":
            let groupId = args?["groupId"] as? String ?? ""
            let variantId = args?["variantId"] as? String ?? ""
            Experiences.shared.setExperimentAssignment(groupId: groupId, variantId: variantId)
            result(nil)

        case "experiences.clearExperimentAssignments":
            Experiences.shared.clearExperimentAssignments()
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func lookupExperience(id: String) -> Experience? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return experienceCache[id]
    }

    private func parseLink(_ raw: Any?) -> RecirculationLink {
        let m = raw as? [String: Any] ?? [:]
        return RecirculationLink(
            url: m["url"] as? String ?? "",
            position: m["position"] as? Int ?? 0
        )
    }

    private func parseLinks(_ raw: Any?) -> [RecirculationLink] {
        let arr = raw as? [[String: Any]] ?? []
        return arr.map {
            RecirculationLink(
                url: $0["url"] as? String ?? "",
                position: $0["position"] as? Int ?? 0
            )
        }
    }

    private static func encodeExperience(_ e: Experience) -> [String: Any?] {
        return [
            "id": e.id,
            "name": e.name,
            "type": e.type.rawValue,
            "family": e.family?.rawValue,
            "placement": e.placement,
            "contentUrl": e.contentUrl,
            "contentType": e.contentType.rawValue,
            "features": e.features,
            "strategy": e.strategy,
            "selectors": e.selectors?.map { ["selector": $0.selector, "strategy": $0.strategy] as [String: Any] },
            "filters": e.filters?.map { ["key": $0.key, "operator": $0.`operator`.key, "values": $0.values] as [String: Any] },
            "rawJson": e.rawJson,
            "resolvedContent": e.resolvedContent,
        ]
    }
}
