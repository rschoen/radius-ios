//
//  YelpService.swift
//  Radius
//
//  Created by Ryan Schoen on 6/27/24.
//

import Foundation

struct Post: Codable {
    let businesses: Array<NetworkVenue>
}

struct NetworkVenue: Identifiable, Codable {
    let id: String
    let name: String
    let url: String
    let image_url: String
    let review_count: Int
    let rating: Double
    let distance: Double
    let coordinates: YelpCoordinates
    
    private enum CodingKeys: String, CodingKey {
        case id,name,url,image_url,review_count,rating,distance,coordinates
    }
}

struct YelpCoordinates: Codable {
    let latitude: Double
    let longitude: Double
    private enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }
}

enum NetworkError: Error {
    case badUrl
    case invalidRequest
    case badResponse
    case badStatus
    case failedToDecodeResponse
}

class WebService: Codable {
    func downloadData<T: Codable>(fromURL: String) async -> T? {
        do {
            guard let url = URL(string: fromURL) else { throw NetworkError.badUrl }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(getSecret(withKey: "YELP_API_KEY"))", forHTTPHeaderField: "Authorization")
            //print(request)
            let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)
            guard let response = response as? HTTPURLResponse else { throw NetworkError.badResponse }
            guard response.statusCode >= 200 && response.statusCode < 300 else {
                //print(response)
                throw NetworkError.badStatus
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
        } catch NetworkError.badStatus {
            print("Did not get a 2xx status code from the response")
        } catch NetworkError.failedToDecodeResponse {
            print("Failed to decode response into the given type")
        } catch {
            print("An error occured downloading the data")
        }
        
        return nil
    }
}

/*
class PostViewModel: ObservableObject {
    @Published var postData = [Post]()
    
    func fetchData() async {
        guard let downloadedPosts: [Post] = await WebService().downloadData(fromURL: "https://jsonplaceholder.typicode.com/posts") else {return}
        postData = downloadedPosts
    }
}

struct ContentView: View {
    @StateObject var vm = PostViewModel()
    
    var body: some View {
        List(vm.postData) { post in
            HStack {
                Text("\(post.userId)")
                    .padding()
                    .overlay(Circle().stroke(.blue))
                
                VStack(alignment: .leading) {
                    Text(post.title)
                        .bold()
                        .lineLimit(1)
                    
                    Text(post.body)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .onAppear {
            if vm.postData.isEmpty {
                Task {
                    await vm.fetchData()
                }
            }
        }
    }
}*/
