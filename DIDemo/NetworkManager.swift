import Foundation

// MARK: - NetworkError
enum NetworkError: Error {
    case invalidURL
    case failedToEncodeBody
    case requestFailed(Error)
    case unexpectedStatusCode(Int)
    case noData
    case decodingError(Error)
}

// MARK: - TranslationResponse
struct TranslationResponse: Codable {
    let text: String
    let sourceLang: String
    let targetLang: String
    
    enum CodingKeys: String, CodingKey {
        case text
        case sourceLang = "source_lang"
        case targetLang = "target_lang"
    }
}

class NetworkManager {
    // MARK: - Cache for duplicate request prevention
    private static var lastRequestText: String?
    private static var lastRequestSourceLang: String?
    private static var lastRequestTargetLang: String?
    private static var lastResponse: TranslationResponse?
    
    static func sendPostRequest(text: String, sourceLang: String, targetLang: String, completion: @escaping (Result<TranslationResponse, Error>) -> Void) {
        // Check if request parameters haven't changed since last request
        if lastRequestText == text &&
           lastRequestSourceLang == sourceLang &&
           lastRequestTargetLang == targetLang,
           let cachedResponse = lastResponse {
            // Return cached response
            completion(.success(cachedResponse))
            return
        }
        
        // Используем URL, который вы указали
        guard let url = URL(string: "http://localhost:8080/api/v1/translate") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }

        let body: [String: String] = [
            "text": text,
            "source_lang": sourceLang,
            "target_lang": targetLang
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let jsonData = try? JSONEncoder().encode(body) else {
            completion(.failure(NetworkError.failedToEncodeBody))
            return
        }
        request.httpBody = jsonData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(NetworkError.requestFailed(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    completion(.failure(NetworkError.unexpectedStatusCode(statusCode)))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NetworkError.noData))
                    return
                }
                
                do {
                    let translationResponse = try JSONDecoder().decode(TranslationResponse.self, from: data)
                    
                    // Update cache on successful response
                    lastRequestText = text
                    lastRequestSourceLang = sourceLang
                    lastRequestTargetLang = targetLang
                    lastResponse = translationResponse
                    
                    completion(.success(translationResponse))
                } catch {
                    completion(.failure(NetworkError.decodingError(error)))
                }
            }
        }
        task.resume()
    }
} 