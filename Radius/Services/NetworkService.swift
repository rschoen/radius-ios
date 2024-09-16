//
//  NetworkService.swift
//  Radius
//
//  Created by Ryan Schoen on 6/27/24.
//

import Foundation


struct RadiusAPIResult: Codable {
    let metadata: RadiusAPIMetadata
    let venues: Array<NetworkVenue>
}

struct RadiusAPIMetadata: Codable {
    let queryId: String
    let resultsComplete: Bool
}

struct NetworkVenue: Identifiable, Codable {
    var id: String
    let name: String
    let imageUrl: String?
    let reviews: Int?
    let rating: Double?
    let latitude: Double
    let longitude: Double
    private enum CodingKeys: String, CodingKey {
        case id, name, imageUrl, reviews, rating, latitude, longitude
    }
}


enum NetworkError: Error {
    case badUrl
    case invalidRequest
    case badResponse
    case badStatus(statusCode: Int, error: String)
    case failedToDecodeResponse
}

class WebService: Codable {
    
    static let resultsPerQuery = 20
    static let queries = 3
    
    func getVenuesAroundLatLng(_ lat: Double, _ lng: Double) async -> [NetworkVenue] {
        
        let apiKey = getSecret(withKey: "RADIUS_API_KEY")
        var venues: [NetworkVenue] = []
        var addedVenues = Set<String>()
        
        let url = "https://fellyeah.duckdns.org:3491/nearby" +
            "?latitude=\(lat)" +
            "&longitude=\(lng)" +
            "&key=\(apiKey)"
                
        if let results: RadiusAPIResult = await downloadData(fromURL: url) {
            for venue in results.venues {
                if !addedVenues.contains(venue.id) {
                    venues.append(venue)
                    addedVenues.insert(venue.id)
                }
            }
        }
        print("Returned \(venues.count) venues")
        return venues
    }
    
    func downloadData<T: Codable>(fromURL: String) async -> T? {
        do {
            guard let url = URL(string: fromURL) else { throw NetworkError.badUrl }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            print(request)
            let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)
            guard let response = response as? HTTPURLResponse else { throw NetworkError.badResponse }
            guard response.statusCode >= 200 && response.statusCode < 300 else {
                //print(response)
                throw NetworkError.badStatus(statusCode: response.statusCode, error: String(data: data, encoding: .utf8)!)
            }
            var decodedResponse: T? = nil
            do {
                decodedResponse = try JSONDecoder().decode(T.self, from: data)
            }
            catch {
                print(error)
                throw NetworkError.failedToDecodeResponse
            }
            
            return decodedResponse
        } catch NetworkError.badUrl {
            print("There was an error creating the URL")
        } catch NetworkError.badResponse {
            print("Did not get a valid response")
        } catch NetworkError.badStatus(let statusCode, let error) {
            print("Returned status code \(statusCode): \(error)")
        } catch NetworkError.failedToDecodeResponse {
            print("Failed to decode response into the given type")
        } catch {
            print("An error occured downloading the data: \(error)")
        }
        
        return nil
    }
}



/*
 
 
 NEW GOOGLE PLACES API
 ONLY RETURNS 20 RESULTS MAX :(
 
 
 struct GooglePlacesRequest: Encodable {
     init(latitude: Double, longitude: Double) {
         locationRestriction = GoogleLocationRestriction(latitude: latitude, longitude: longitude)
     }
     let includedTypes: Array<String> = ["restaurant", "bar"]
     let maxResultCount: Int = 20
     let rankPreference: String = "DISTANCE"
     let locationRestriction: GoogleLocationRestriction
 }

 struct GoogleLocationRestriction: Encodable {
     init(latitude: Double, longitude: Double) {
         circle = GoogleCircle(latitude: latitude, longitude: longitude)
     }
     let circle: GoogleCircle
 }

 struct GoogleCircle: Encodable {
     init(latitude: Double, longitude: Double) {
         center = GoogleLocation(latitude: latitude, longitude: longitude)
     }
     let center: GoogleLocation
     let radius: Double = 500.0
 }

 struct GoogleLocation: Codable {
     let latitude: Double
     let longitude: Double
 }

 struct GooglePlacesResult: Codable {
     let places: Array<NetworkVenue>
 }

 struct NetworkVenue: Identifiable, Codable {
     let id: String
     let displayName: GoogleDisplayName
     let googleMapsUri: String
     //let image_url: String
     let userRatingCount: Int
     let rating: Double
     let location: GoogleLocation
 }

 struct GoogleDisplayName: Codable {
     let text: String
     let languageCode: String
 }


 enum NetworkError: Error {
     case badUrl
     case invalidRequest
     case badResponse
     case badStatus(statusCode: Int, error: String)
     case failedToDecodeResponse
 }

 class WebService: Codable {
     
     static let resultsPerQuery = 50
     static let queries = 2
     
     func getVenuesAroundLatLng(_ lat: Double, _ lng: Double) async -> [NetworkVenue] {
         let url = URL(string: "https://places.googleapis.com/v1/places:searchNearby")!
         var request = URLRequest(url: url)
         request.setValue("application/json", forHTTPHeaderField: "Content-Type")
         request.setValue(getSecret(withKey: "GOOGLE_MAPS_API_KEY"), forHTTPHeaderField: "X-Goog-Api-Key")
         request.setValue("places.id,places.displayName,places.location,places.userRatingCount,places.rating,places.googleMapsUri", forHTTPHeaderField: "X-Goog-FieldMask")
         request.httpMethod = "POST"
         let encoder = JSONEncoder()
         let jsonRequest = GooglePlacesRequest(latitude: lat, longitude: lng)
         
         do {
             let data = try encoder.encode(jsonRequest)
             request.httpBody = data
         } catch {
             print("Error encoding JSON for Google Places API request: \(error)")
             return Array<NetworkVenue>()
         }
         
         if let results: GooglePlacesResult = await downloadData(for: request) {
             return results.places
         } else {
             return Array<NetworkVenue>()
         }
     }
     
     func downloadData<T: Codable>(for request: URLRequest) async -> T? {
         do {
             //print(request)
             //print(request.allHTTPHeaderFields)
             //print(String(data: request.httpBody!, encoding: .utf8))
             let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)
             guard let response = response as? HTTPURLResponse else { throw NetworkError.badResponse }
             guard response.statusCode >= 200 && response.statusCode < 300 else {
                 //print(response)
                 throw NetworkError.badStatus(statusCode: response.statusCode, error: String(data: data, encoding: .utf8)!)
             }
             var decodedResponse: T? = nil
             do {
                 decodedResponse = try JSONDecoder().decode(T.self, from: data)
             }
             catch {
                 print(error)
                 throw NetworkError.failedToDecodeResponse
             }
             
             return decodedResponse
         } catch NetworkError.badUrl {
             print("There was an error creating the URL")
         } catch NetworkError.badResponse {
             print("Did not get a valid response")
         } catch NetworkError.badStatus(let statusCode, let error) {
             print("Returned status code \(statusCode): \(error)")
         } catch NetworkError.failedToDecodeResponse {
             print("Failed to decode response into the given type")
         } catch {
             print("An error occured downloading the data")
         }
         
         return nil
     }
 }

 
 */
