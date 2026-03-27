import Foundation
import UIKit
import CryptoKit

class ImageCacheService {
    static let shared = ImageCacheService()

    private let cacheDirectory: URL
    private let maxCacheSize: Int = 50 * 1024 * 1024 // 50MB

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        cacheDirectory = appSupport.appendingPathComponent("receipts", isDirectory: true)

        // 建立目錄
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Public API

    /// 儲存圖片到本地快取（上傳後呼叫）
    func save(_ data: Data, for url: String) {
        let filePath = filePath(for: url)
        try? data.write(to: filePath)
        enforceSizeLimit()
    }

    /// 從本地快取載入圖片，沒有則從 URL 下載並快取
    func loadImage(for urlString: String) async -> UIImage? {
        // 1. 先查本地
        if let data = loadFromDisk(for: urlString),
           let image = UIImage(data: data) {
            // 更新存取時間（LRU）
            touch(for: urlString)
            return image
        }

        // 2. 本地沒有，從 URL 下載
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                save(data, for: urlString)
                return image
            }
        } catch {
            print("Failed to download image: \(error.localizedDescription)")
        }
        return nil
    }

    /// 檢查本地是否有快取
    func hasCached(for url: String) -> Bool {
        FileManager.default.fileExists(atPath: filePath(for: url).path)
    }

    /// 清除所有快取
    func clearAll() {
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    /// 目前快取大小（bytes）
    func currentCacheSize() -> Int {
        guard let files = try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        return files.reduce(0) { total, file in
            let size = (try? file.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            return total + size
        }
    }

    // MARK: - Private

    private func filePath(for url: String) -> URL {
        let hash = SHA256.hash(data: Data(url.utf8))
        let fileName = hash.compactMap { String(format: "%02x", $0) }.joined()
        return cacheDirectory.appendingPathComponent(fileName + ".jpg")
    }

    private func loadFromDisk(for url: String) -> Data? {
        let path = filePath(for: url)
        return FileManager.default.contents(atPath: path.path)
    }

    private func touch(for url: String) {
        let path = filePath(for: url)
        try? FileManager.default.setAttributes(
            [.modificationDate: Date()],
            ofItemAtPath: path.path
        )
    }

    /// LRU 淘汰：超過上限時刪除最舊的檔案
    private func enforceSizeLimit() {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]
        ) else { return }

        var totalSize = 0
        var fileInfos: [(url: URL, size: Int, date: Date)] = []

        for file in files {
            guard let values = try? file.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]) else { continue }
            let size = values.fileSize ?? 0
            let date = values.contentModificationDate ?? Date.distantPast
            totalSize += size
            fileInfos.append((url: file, size: size, date: date))
        }

        guard totalSize > maxCacheSize else { return }

        // 按修改時間排序，最舊的先刪
        fileInfos.sort { $0.date < $1.date }

        for info in fileInfos {
            guard totalSize > maxCacheSize else { break }
            try? FileManager.default.removeItem(at: info.url)
            totalSize -= info.size
        }
    }
}
