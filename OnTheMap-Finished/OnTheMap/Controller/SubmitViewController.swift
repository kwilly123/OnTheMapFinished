//
//  SubmitViewController.swift
//  OnTheMap
//
//  Created by Kyle Wilson on 2020-02-11.
//  Copyright © 2020 Xcode Tips. All rights reserved.
//

import UIKit
import MapKit

class SubmitViewController: UIViewController {
    
    @IBOutlet weak var linkTextField: UITextField!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    var locationRetrieved: String!
    var urlRetrieved: String!
    
    var location: String = ""
    var coordinate: CLLocationCoordinate2D?
    
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    
    var student: StudentInformation?
    
    var objectIdHolder: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        submitButton.layer.cornerRadius = 5
        linkTextField.delegate = self
        print(locationRetrieved!)
        search() //geocodes location that was entered in previous view
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    //MARK: GEOCODE LOCATION
    
    func search() {
        
        guard let location = locationRetrieved else { //checks if the location was retrieved
            print("no location")
            let alert = UIAlertController(title: "No Location", message: "Location was not found or entered. Go back to the previous view.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        CLGeocoder().geocodeAddressString(location) { (placemark, error) in
            
            guard error == nil else {
                print("Could not find your location")
                let alert = UIAlertController(title: "No Location", message: "Location was not found or entered. Go back to the previous view.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            self.location = location //assign the location to the global location variable so we can access it
            self.coordinate = placemark!.first!.location!.coordinate
            self.pin(coordinate: self.coordinate!)
            self.latitude = (placemark?.first?.location?.coordinate.latitude)!
            self.longitude = (placemark?.first?.location?.coordinate.longitude)!
        }
    }
    
    //MARK: GET USER INFO
    
    func getUserInfo() {
        UdacityClient.getUser() { (success, error) in
            if success {
                print("success")
                
                DispatchQueue.main.async {
                    self.student = StudentInformation(uniqueKey: UdacityClient.accountKey, firstName: UdacityClient.firstName, lastName: UdacityClient.lastName, latitude: self.latitude, longitude: self.longitude, mapString: self.location, mediaURL: self.urlRetrieved)
                    print(self.student?.firstName ?? "No First Name")
                    print(self.student?.lastName ?? "No First Name")
                    print(self.student?.latitude ?? 0)
                    print(self.student?.longitude ?? 0)
                    print(self.student?.mapString ?? "No Location")
                    print(self.student?.mediaURL ?? "No URL")
                    print(self.student?.uniqueKey ?? "No Key")
                    
                    
                    if UdacityClient.objectId == "" { //check if user has created a pin already and checks objectId
                        self.postLocation() //post
                    } else { //otherwise
                        self.objectIdHolder = UdacityClient.objectId //assign the objectId to a new variable to check if its working
                        self.updateLocation() //update the location
                    }
                }
                
            } else {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Error", message: "Error Getting User Info", preferredStyle: .alert)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    //MARK: POST LOCATION
    
    func postLocation() {
        UdacityClient.postStudentLocation(student: student!) { (success, error) in
            
            if error != nil {
                print(error?.localizedDescription ?? "")
                let errorAlert = UIAlertController(title: "Could not post student location", message: "There was an error trying to post a pin", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(errorAlert, animated: true)
                return
            }
            
            if success {
                print("post success")
                print(self.student?.firstName ?? "")
                print(self.student?.lastName ?? "")
                print(self.student?.latitude ?? 0)
                print(self.student?.longitude ?? 0)
                DispatchQueue.main.async {
                    self.navigationController?.popToRootViewController(animated: true)
                }
            } else {
                let errorAlert = UIAlertController(title: "Could not post student location", message: "There was an error trying to post a pin", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(errorAlert, animated: true)
                print("error")
            }
        }
    }
    
    //MARK: UPDATE LOCATION
    
    func updateLocation() {
        UdacityClient.updateUserLocation(student: student!) { (success, error) in
            
            if error != nil {
                print(error?.localizedDescription ?? "")
                let errorAlert = UIAlertController(title: "Could not update student Location", message: "There was an error trying to update a pin", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                return
            }
            
            if success {
                print("update success")
                print("Object ID: \(self.objectIdHolder)")
                print("New Latitude: \(self.student?.latitude ?? 0)")
                print("New Longitude: \(self.student?.longitude ?? 0)")
                DispatchQueue.main.async {
                    self.navigationController?.popToRootViewController(animated: true)
                }
            } else {
                let errorAlert = UIAlertController(title: "Could not update student Location", message: "There was an error trying to update a pin", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(errorAlert, animated: true)
                print("error")
            }
        }
    }
    
    //MARK: ADDING NEW PIN
    
    func pin(coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = location
        
        let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        DispatchQueue.main.async {
            self.mapView.addAnnotation(annotation)
            self.mapView.setRegion(region, animated: true)
            self.mapView.regionThatFits(region)
        }
    }
    
    //MARK: CANCEL
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    //MARK: SUBMIT
    
    @IBAction func submitTapped(_ sender: Any) {
        urlRetrieved = linkTextField.text
        getUserInfo()
    }
}

extension SubmitViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
