import CoreLocation
import SwiftUI

final class CompassModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var heading: Double?
    @Published private(set) var dialRotation: Double = 0
    @Published private(set) var accuracy: Double = -1
    @Published private(set) var location: CLLocation?
    @Published private(set) var authorization: CLAuthorizationStatus = .notDetermined
    @Published private(set) var locationError: String?
    @Published private(set) var locationRequested = false
    @Published private(set) var usesTrueNorth = false
    @Published private(set) var trueNorthAvailable = false
    @Published private(set) var lockedBearing: Double?
    @Published private(set) var headingAvailable = CLLocationManager.headingAvailable()
    @Published private(set) var calibrationNeeded = false
    private let manager = CLLocationManager()
    private var latestHeading: CLHeading?
    private var active = false
    private var previouslyAligned = false

    override init() {
        super.init()
        manager.delegate = self
        manager.headingFilter = kCLHeadingFilterNone
        manager.headingOrientation = .portrait
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 10
        authorization = manager.authorizationStatus
        locationRequested = authorization == .authorizedWhenInUse || authorization == .authorizedAlways
    }

    var hasLocationPermission: Bool {
        authorization == .authorizedWhenInUse || authorization == .authorizedAlways
    }

    var locationDenied: Bool { authorization == .denied || authorization == .restricted }
    var usingTrueNorth: Bool { usesTrueNorth && trueNorthAvailable }
    var referenceName: String { usingTrueNorth ? "真北" : "磁北" }
    var deviation: Double? {
        guard let heading, let lockedBearing else { return nil }
        return CompassMath.delta(from: heading, to: lockedBearing)
    }
    var guidance: String {
        guard let deviation else { return "锁定方向后，查看偏离角度" }
        if abs(deviation) < 3 { return "方向已对准" }
        return "向\(deviation > 0 ? "右" : "左")转 \(Int(abs(deviation).rounded()))°"
    }
    var status: String {
        if !headingAvailable { return "此设备不支持指南针" }
        if calibrationNeeded { return "需要校准 · 请远离磁场干扰" }
        guard heading != nil else { return "正在读取方向…" }
        if accuracy > 20 { return "精度较低 · 请远离磁场干扰" }
        return "\(referenceName) · 精度 ±\(Int(accuracy.rounded()))°"
    }

    func start() {
        guard !active else { return }
        active = true
        headingAvailable = CLLocationManager.headingAvailable()
        if headingAvailable { manager.startUpdatingHeading() }
        if locationRequested && hasLocationPermission { manager.startUpdatingLocation() }
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--preview-heading") {
            headingAvailable = true
            heading = 32
            dialRotation = 32
            accuracy = 8
        }
        #endif
    }

    func stop() {
        active = false
        manager.stopUpdatingHeading()
        manager.stopUpdatingLocation()
        heading = nil
        latestHeading = nil
        trueNorthAvailable = false
        calibrationNeeded = false
        lockedBearing = nil
    }

    func requestLocation() {
        locationRequested = true
        locationError = nil
        if authorization == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if hasLocationPermission && active {
            manager.startUpdatingLocation()
        }
    }

    func selectTrueNorth(_ enabled: Bool) {
        usesTrueNorth = enabled
        lockedBearing = nil
        if enabled { requestLocation() }
        refreshHeading()
    }

    func toggleLock() {
        if lockedBearing != nil {
            lockedBearing = nil
        } else if let heading {
            lockedBearing = heading
        }
        previouslyAligned = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorization = manager.authorizationStatus
        if hasLocationPermission && active && locationRequested {
            manager.startUpdatingLocation()
        } else if locationDenied {
            manager.stopUpdatingLocation()
            location = nil
            lockedBearing = nil
            refreshHeading()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard active else { return }
        guard newHeading.headingAccuracy >= 0 else {
            calibrationNeeded = true
            heading = nil
            trueNorthAvailable = false
            latestHeading = nil
            return
        }
        calibrationNeeded = false
        latestHeading = newHeading
        accuracy = newHeading.headingAccuracy
        refreshHeading()
    }

    private func refreshHeading() {
        guard let latestHeading else { return }
        let previousReference = usingTrueNorth
        trueNorthAvailable = latestHeading.trueHeading >= 0 && hasLocationPermission && location != nil
        if previousReference != usingTrueNorth { lockedBearing = nil }
        let value = usingTrueNorth ? latestHeading.trueHeading : latestHeading.magneticHeading
        if heading == nil {
            dialRotation = value
        } else {
            dialRotation += CompassMath.delta(from: dialRotation, to: value)
        }
        heading = value
        if let deviation {
            let aligned = abs(deviation) < 3
            if aligned && !previouslyAligned { UISelectionFeedbackGenerator().selectionChanged() }
            previouslyAligned = aligned
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard active, let latest = locations.last, latest.horizontalAccuracy >= 0,
              abs(latest.timestamp.timeIntervalSinceNow) < 30 else { return }
        location = latest
        locationError = nil
        refreshHeading()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let error = error as? CLError, error.code == .headingFailure {
            heading = nil
            latestHeading = nil
            trueNorthAvailable = false
            calibrationNeeded = true
        } else {
            locationError = "暂时无法定位，请到开阔处重试"
        }
    }

    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool { true }
}
