import Foundation
import CoreBluetooth
import CoreLocation

class PermissionManager: NSObject, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager?
    
    override init() {
        super.init()
        locationManager = CLLocationManager()
        locationManager?.delegate = self
    }
    
    func getPermissionStatus() -> [String: Any] {
        var locationGranted = false
        if #available(iOS 14.0, *) {
            let status = locationManager?.authorizationStatus ?? .notDetermined
            locationGranted = (status == .authorizedWhenInUse || status == .authorizedAlways)
        } else {
            let status = CLLocationManager.authorizationStatus()
            locationGranted = (status == .authorizedWhenInUse || status == .authorizedAlways)
        }
        
        let btState = CBCentralManager().state
        let bluetoothGranted = (btState != .unauthorized && btState != .unsupported)
        
        return [
            "bluetoothGranted": bluetoothGranted,
            "locationGranted": locationGranted,
            "nearbyDevicesGranted": true
        ]
    }
}
