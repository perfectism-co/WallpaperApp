import UIKit
import PhotosUI

class ViewController: UIViewController, PHPickerViewControllerDelegate {

    // 1. 呈現照片選取器
    func showPhotoPicker() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1 // 限制一次選一張
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    // 2. 當使用者選完照片後觸發
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let itemProvider = results.first?.itemProvider else { return }
        
        if itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                if let uiImage = image as? UIImage {
                    self.uploadImage(uiImage)
                }
            }
        }
    }

    // 3. 處理圖片壓縮並上傳
    func uploadImage(_ image: UIImage) {
        // 將圖片轉為 Data (壓縮至 0.5 品質)
        guard let imageData = image.jpegData(compressionQuality: 0.5) else { return }
        
        let url = URL(string: "https://your-api-endpoint.com/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // 設定 Multipart/Form-Data 標頭
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // 建立 Body
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        // 發送請求
        let task = URLSession.shared.uploadTask(with: request, from: body) { data, response, error in
            if let error = error {
                print("上傳失敗: \(error)")
                return
            }
            print("上傳成功")
        }
        task.resume()
    }
}
