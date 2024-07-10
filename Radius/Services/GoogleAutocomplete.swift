//
//  GoogleAutocomplete.swift
//  Radius
//
//  Created by Ryan Schoen on 7/3/24.
//

import Foundation
import UIKit
import SwiftUI
import GooglePlaces

class AutocompleteViewController: UIViewController {
    @Binding var isPresented: Bool
    var completionHandler: (_ address: String, _ latitude: Double, _ longitude: Double) async -> ()
    
    init(isPresented: Binding<Bool>, completionHandler: @escaping (_ address: String, _ latitude: Double, _ longitude: Double) async -> ()) {
        self._isPresented = isPresented
        self.completionHandler = completionHandler
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        showAutocomplete()
    }
    

  // Present the Autocomplete view controller when the button is pressed.
  @objc func showAutocomplete() {
    let autocompleteController = GMSAutocompleteViewController()
    autocompleteController.delegate = self

    // Specify the place data types to return.
    let fields: GMSPlaceField = GMSPlaceField(rawValue: UInt64(GMSPlaceField.name.rawValue) |
      UInt64(GMSPlaceField.placeID.rawValue))
    autocompleteController.placeFields = fields

    // Specify a filter.
    let filter = GMSAutocompleteFilter()
    filter.types = ["address"]
    autocompleteController.autocompleteFilter = filter

    // Display the autocomplete view controller.
    present(autocompleteController, animated: true, completion: nil)
  }

}

extension AutocompleteViewController: GMSAutocompleteViewControllerDelegate {

  // Handle the user's selection.
  func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
      Task {
          await completionHandler(place.formattedAddress ?? "", place.coordinate.latitude, place.coordinate.longitude)
      }
      dismiss(animated: true) {
          self.isPresented = false
      }
  }

  func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
    // TODO: handle the error.
      print("Error: ", error.localizedDescription, error.self)
      dismiss(animated: true) {
          self.isPresented = false
      }
  }

  // User canceled the operation.
  func wasCancelled(_ viewController: GMSAutocompleteViewController) {
      
      dismiss(animated: true) {
          self.isPresented = false
      }
      
  }

}


struct MyPlacePicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var completionHandler: (_ address: String, _ latitude: Double, _ longitude: Double) async -> ()
    
    
    func makeUIViewController(context: Context) -> AutocompleteViewController {
        return AutocompleteViewController(isPresented: $isPresented, completionHandler: completionHandler)
    }
    
    func updateUIViewController(_ uiViewController: AutocompleteViewController, context: Context) {
    }
}
