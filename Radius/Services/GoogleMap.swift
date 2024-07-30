/*
 *   Copyright 2020 Google Inc. All rights reserved.
 *
 *
 *   Licensed under the Apache License, Version 2.0 (the "License"); you may not use this
 *   file except in compliance with the License. You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 *   Unless required by applicable law or agreed to in writing, software distributed under
 *   the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
 *   ANY KIND, either express or implied. See the License for the specific language governing
 *   permissions and limitations under the License.
 */

import UIKit
import GoogleMaps

class GoogleMap: UIViewController, GMSMapViewDelegate {
    
    var map: GMSMapView?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // Create a GMSCameraPosition that tells the map to display the
        // coordinate -33.86,151.20 at zoom level 6.

        let options = GMSMapViewOptions()
        options.camera = GMSCameraPosition.camera(withLatitude: 37.774, longitude: -122.419, zoom: 7.0)
        options.frame = self.view.bounds

        map = GMSMapView(options: options)
        map?.delegate = self
        self.view.addSubview(map!)

    }
    /*nonisolated func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
      if let title = marker.title {
        if let snippet = marker.snippet {
          print("marker title: \(title): snippet: \(snippet)")
        }
      }
      return true
    }*/
    
    
}
