//
//  GoogleAutocomplete.swift
//  Radius
//
//  Created by Ryan Schoen on 7/3/24.
//

import Foundation
import UIKit
import SwiftUI
@preconcurrency import GooglePlaces

@MainActor
class AutocompleteViewController: UIViewController {
    @Binding var isPresented: Bool
    var completionHandler: (_ address: String, _ latitude: Double, _ longitude: Double) async -> ()
    private let delegateProxy = AutocompleteDelegate()
    
    init(isPresented: Binding<Bool>, completionHandler: @escaping (_ address: String, _ latitude: Double, _ longitude: Double) async -> ()) {
        self._isPresented = isPresented
        self.completionHandler = completionHandler
        super.init(nibName: nil, bundle: nil)
        self.delegateProxy.owner = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showAutocomplete()
    }
    

  // Present the Autocomplete view controller when the button is pressed.
  @objc func showAutocomplete() {
    let autocompleteController = GMSAutocompleteViewController()
    autocompleteController.delegate = delegateProxy

    // Specify the place data types to return.
    let fields: GMSPlaceField = [.name, .placeID, .formattedAddress, .coordinate]
    autocompleteController.placeFields = fields

    // Specify a filter.
    let filter = GMSAutocompleteFilter()
    filter.types = ["address"]
    autocompleteController.autocompleteFilter = filter

    // Display the autocomplete view controller.
    present(autocompleteController, animated: true, completion: nil)
  }

}

final class AutocompleteDelegate: NSObject, GMSAutocompleteViewControllerDelegate {
    weak var owner: AutocompleteViewController?

    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        let owner = self.owner
        let address = place.formattedAddress ?? ""
        let lat = place.coordinate.latitude
        let lng = place.coordinate.longitude
        Task { @MainActor in
            guard let owner else { return }
            await owner.completionHandler(address, lat, lng)
            owner.dismiss(animated: true) {
                owner.isPresented = false
            }
        }
    }

    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        let owner = self.owner
        Task { @MainActor in
            guard let owner else { return }
            print("Error: ", error.localizedDescription, error)
            owner.dismiss(animated: true) {
                owner.isPresented = false
            }
        }
    }

    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        let owner = self.owner
        Task { @MainActor in
            guard let owner else { return }
            owner.dismiss(animated: true) {
                owner.isPresented = false
            }
        }
    }
}

@MainActor
struct MyPlacePicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var completionHandler: (_ address: String, _ latitude: Double, _ longitude: Double) async -> ()
    
    
    func makeUIViewController(context: Context) -> AutocompleteViewController {
        return AutocompleteViewController(isPresented: $isPresented, completionHandler: completionHandler)
    }
    
    func updateUIViewController(_ uiViewController: AutocompleteViewController, context: Context) {
    }
}

