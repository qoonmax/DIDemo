import Foundation

class NetworkManager {
    static func sendPostRequest(text: String, sourceLang: String, targetLang: String) {
        // Используем URL, который вы указали
        guard let url = URL(string: "https://webhook.site/43254787-e659-48e8-a43b-7f8aa1c883f9") else {
            print("Error: invalid URL")
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
            print("Error: failed to encode body")
            return
        }
        request.httpBody = jsonData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending request: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("Error with the response, unexpected status code: \(String(describing: response))")
                return
            }
            
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                print("Response data string:\n \(dataString)")
                // Здесь вы можете обработать ответ, например, обновить UI
            }
        }
        task.resume()
    }
} 