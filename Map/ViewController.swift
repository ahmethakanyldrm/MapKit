//
//  ViewController.swift
//  Map
//
//  Created by AHMET HAKAN YILDIRIM on 5.10.2023.
//

import UIKit
import MapKit

class ViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    let locationManager = CLLocationManager()
    let regionMeters: Double = 120000
    var routes: [MKDirections] = []
    
    
    var previousLocation: CLLocation?
    @IBOutlet weak var lblAddress: UILabel!
    
    
    @IBOutlet weak var btnGo: UIButton!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationServiceControl()
        btnGo.layer.cornerRadius = 20
    }
    
    private func locationServiceControl() {
        
        if CLLocationManager.locationServicesEnabled() {
            // konum servisi açıldıysa
            setLocationManager()
            permissionControl()
            
        }else {
            
        }
    }
    
    private func setLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
    }
    
    private func permissionControl() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways:
            // kullanıcı konum bilgisi için daima izin vermiştir
            break
        case .authorizedWhenInUse:
            // uygulama kullanım esnasında konum bilgisine erişebilir
           userTracking()
            break
        case .denied:
            // kullanıcı izin isteğimizi reddetmiştir veya henüz izin vermemiştir
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            // kullanıcı henüz karar vermemiştir
            break
        case .restricted:
            // uygulamanın durumu kısıtlanmıştır
            break
        }
    }
    
    private func userTracking() {
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .followWithHeading
        locationFocus()
        previousLocation = getCoordinateCenterLocations(mapView: mapView)
    }
    
    private func locationFocus() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionMeters, longitudinalMeters: regionMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    private func getCoordinateCenterLocations(mapView: MKMapView) -> CLLocation {
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    
    @IBAction func btnGoTapped(_ sender: UIButton) {
        setRoute()
    }
    
    private func setRoute() {
        guard let startingCoordinate = locationManager.location?.coordinate else {return}
        let request = createRequest(startingCoordinate: startingCoordinate)
        let routes = MKDirections(request: request)
        mapViewClear(newRoute: routes)
        
        routes.calculate { response, error in
            guard let response = response else {return}
            
            for route in response.routes {
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
           
           
        
        }
    }
    
    private func createRequest(startingCoordinate: CLLocationCoordinate2D) -> MKDirections.Request {
        let destinationCoordinate = getCoordinateCenterLocations(mapView: mapView).coordinate
        let startingLocation = MKPlacemark(coordinate: startingCoordinate)
        let destination = MKPlacemark(coordinate: destinationCoordinate)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startingLocation)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        
        return request
    }
    
    private func mapViewClear(newRoute: MKDirections) {
        mapView.removeOverlays(mapView.overlays)
        routes.append(newRoute)
        
        let _ = routes.map { $0.cancel() }
        
    }
    
    
}

extension ViewController:  CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Konum Güncellenirse tetiklenir
        guard let location = locations.last else {return}
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion.init(center: center, latitudinalMeters: regionMeters, longitudinalMeters: regionMeters)
        mapView.setRegion(region, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // Konuma verilen izin değiştirilirse
        permissionControl()
    }
}


extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = getCoordinateCenterLocations(mapView: mapView)
        
        guard let previousLocation = self.previousLocation else {return}
        
        if center.distance(from: previousLocation) < 50 {
            return
        }
        
        self.previousLocation = center
        
        let geoCoder = CLGeocoder()
        geoCoder.cancelGeocode()
        
        geoCoder.reverseGeocodeLocation(center) { (placeMark, error) in
            if let error = error {
                print("Hata: \(error.localizedDescription)")
                return
            }
            
            guard let placeMark = placeMark?.first else {return}
            
            let streetNumber = placeMark.subThoroughfare ?? "Yok"
            let streetName = placeMark.thoroughfare ?? "Yok"
            let country = placeMark.country ?? "Yok"
            let city = placeMark.administrativeArea ?? "Yok"
            let town = placeMark.locality ?? "Yok"
            
            DispatchQueue.main.async {
                self.lblAddress.text = "\(streetName) \(town)/\(city)/\(country))"
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .blue
        renderer.lineWidth = 5
        renderer.lineCap = .square
        return renderer
    }
}

