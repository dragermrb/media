import Foundation
import Photos
import Capacitor

public class JSDate {
    static func toString(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: date)
    }
}

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(MediaPlugin)
public class MediaPlugin: CAPPlugin {
    typealias JSObject = [String:Any]
    static let DEFAULT_QUANTITY = 25
    static let DEFAULT_TYPES = "photos"
    static let DEFAULT_THUMBNAIL_WIDTH = 256
    static let DEFAULT_THUMBNAIL_HEIGHT = 256
    
    // Must be lazy here because it will prompt for permissions on instantiation without it
    lazy var imageManager = PHCachingImageManager()
    
    @objc func getAlbums(_ call: CAPPluginCall) {
        checkAuthorization(allowed: {
            self.fetchAlbumsToJs(call)
        }, notAllowed: {
            call.reject("Access to photos not allowed by user")
        })
    }
    
    @objc func getMedias(_ call: CAPPluginCall) {
        checkAuthorization(allowed: {
            self.fetchResultAssetsToJs(call)
        }, notAllowed: {
            call.reject("Access to photos not allowed by user")
        })
    }
    
    @objc func createAlbum(_ call: CAPPluginCall) {
        guard let name = call.getString("name") else {
            call.reject("Must provide a name")
            return
        }
        
        checkAuthorization(allowed: {
            self.createAlbumByName(name) { phAsset in
                if phAsset == nil {
                    call.reject("Unable to create album")
                    return
                } else {
                    call.resolve([
                        "identifier": phAsset?.localIdentifier as Any,
                        "name": phAsset?.localizedTitle as Any,
                    ])
                    return
                }
            }
        }, notAllowed: {
            call.reject("Access to photos not allowed by user")
        })
    }
    
    @objc func savePhoto(_ call: CAPPluginCall) {
        guard let data = call.getString("path") else {
            call.reject("Must provide the data path")
            return
        }
        
        checkAuthorization(allowed: {}, notAllowed: {
            call.reject("Access to photos not allowed by user")
            return
        })
        
        let album = call.getObject("album")
        var targetCollection: PHAssetCollection?
        var albumNameToCreate: String?;
        var assetId: String = ""
        
        if (album != nil){
            if (album?["id"] != nil) {
                targetCollection = findAlbumById(album?["id"] as! String)
                
                if targetCollection == nil {
                    call.reject("Unable to find that album by id")
                    return
                }
            }
            else if (album?["name"] != nil) {
                let albumName = album?["name"] as! String
                
                targetCollection = findAlbumByName(albumName)
                
                if targetCollection == nil {
                    albumNameToCreate = albumName
                }
            }
        }
        
        if albumNameToCreate != nil {
            self.createAlbumByName(albumNameToCreate!) { phAsset in
                if phAsset == nil {
                    call.reject("Unable to create album")
                    return
                } else {
                    targetCollection = phAsset
                    
                    if !targetCollection!.canPerform(.addContent) {
                        call.reject("Album doesn't support adding content (is this a smart album?)")
                        return
                    }
                }
                
                // Add it to the photo library.
                PHPhotoLibrary.shared().performChanges({
                    
                    let url = URL(string: data)
                    let data = try? Data(contentsOf: url!)
                    if (data != nil) {
                        let image = UIImage(data: data!)
                        let creationRequest = PHAssetChangeRequest.creationRequestForAsset(from: image!)
                        let placeHolder = creationRequest.placeholderForCreatedAsset
                        
                        if let collection = targetCollection {
                            let addAssetRequest = PHAssetCollectionChangeRequest(for: collection)
                            addAssetRequest?.addAssets([placeHolder!] as NSArray)
                            assetId = placeHolder!.localIdentifier
                        }
                    } else {
                        call.reject("Could not convert fileURL into Data");
                    }
                    
                }, completionHandler: {success, error in
                    if !success {
                        call.reject("Unable to save image to album")
                    } else {
                        let asset = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil).firstObject
                        
                        if asset == nil{
                            call.reject("Cannot fetch asset")
                            return
                        }
                        
                        self.getAssetUrl(asset!, completion: { (fullPath) in
                            call.resolve([
                                "filePath": fullPath!,
                            ])
                        })
                    }
                })
            }
        } else if targetCollection != nil {
            if !targetCollection!.canPerform(.addContent) {
                call.reject("Album doesn't support adding content (is this a smart album?)")
                return
            }
            
            // Add it to the photo library.
            PHPhotoLibrary.shared().performChanges({
                
                let url = URL(string: data)
                let data = try? Data(contentsOf: url!)
                if (data != nil) {
                    let image = UIImage(data: data!)
                    let creationRequest = PHAssetChangeRequest.creationRequestForAsset(from: image!)
                    let placeHolder = creationRequest.placeholderForCreatedAsset
                    
                    if let collection = targetCollection {
                        let addAssetRequest = PHAssetCollectionChangeRequest(for: collection)
                        addAssetRequest?.addAssets([placeHolder!] as NSArray)
                        assetId = placeHolder!.localIdentifier
                    }
                } else {
                    call.reject("Could not convert fileURL into Data");
                }
                
            }, completionHandler: {success, error in
                if !success {
                    call.reject("Unable to save image to album")
                } else {
                    let asset = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil).firstObject
                    
                    if asset == nil{
                        call.reject("Cannot fetch asset")
                        return
                    }
                    
                    self.getAssetUrl(asset!, completion: { (fullPath) in
                        call.resolve([
                            "filePath": fullPath!,
                        ])
                    })
                }
            })
        } else {
            call.reject("Cannot find album")
        }
        
    }
    
    @objc func saveVideo(_ call: CAPPluginCall) {
        guard let data = call.getString("path") else {
            call.reject("Must provide the data path")
            return
        }
        
        checkAuthorization(allowed: {}, notAllowed: {
            call.reject("Access to photos not allowed by user")
            return
        })
        
        let album = call.getObject("album")
        var targetCollection: PHAssetCollection?
        var albumNameToCreate: String?;
        var assetId: String = ""
        
        if (album != nil){
            if (album?["id"] != nil) {
                targetCollection = findAlbumById(album?["id"] as! String)
                
                if targetCollection == nil {
                    call.reject("Unable to find that album by id")
                    return
                }
            }
            else if (album?["name"] != nil) {
                let albumName = album?["name"] as! String
                
                targetCollection = findAlbumByName(albumName)
                
                if targetCollection == nil {
                    albumNameToCreate = albumName
                }
            }
        }
        
        if albumNameToCreate != nil {
            self.createAlbumByName(albumNameToCreate!) { phAsset in
                if phAsset == nil {
                    call.reject("Unable to create album")
                    return
                } else {
                    targetCollection = phAsset
                    
                    if !targetCollection!.canPerform(.addContent) {
                        call.reject("Album doesn't support adding content (is this a smart album?)")
                        return
                    }
                }
                
                // Add it to the photo library.
                PHPhotoLibrary.shared().performChanges({
                    let creationRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(string: data)!)
                    let placeHolder = creationRequest?.placeholderForCreatedAsset
                    
                    if let collection = targetCollection {
                        let addAssetRequest = PHAssetCollectionChangeRequest(for: collection)
                        addAssetRequest?.addAssets([placeHolder!] as NSArray)
                        assetId = placeHolder!.localIdentifier
                    }
                    
                }, completionHandler: {success, error in
                    if !success {
                        call.reject("Unable to save video to album")
                    } else {
                        let asset = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil).firstObject
                        
                        if asset == nil{
                            call.reject("Cannot fetch asset")
                            return
                        }
                        
                        self.getAssetUrl(asset!, completion: { (fullPath) in
                            call.resolve([
                                "filePath": fullPath!,
                            ])
                        })
                    }
                })
            }
        } else if targetCollection != nil {
            if !targetCollection!.canPerform(.addContent) {
                call.reject("Album doesn't support adding content (is this a smart album?)")
                return
            }
            
            // Add it to the photo library.
            PHPhotoLibrary.shared().performChanges({
                let creationRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(string: data)!)
                let placeHolder = creationRequest?.placeholderForCreatedAsset
                
                if let collection = targetCollection {
                    let addAssetRequest = PHAssetCollectionChangeRequest(for: collection)
                    addAssetRequest?.addAssets([placeHolder!] as NSArray)
                    assetId = placeHolder!.localIdentifier
                }
            }, completionHandler: {success, error in
                if !success {
                    call.reject("Unable to save video to album")
                } else {
                    let asset = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil).firstObject
                    
                    if asset == nil{
                        call.reject("Cannot fetch asset")
                        return
                    }
                    
                    self.getAssetUrl(asset!, completion: { (fullPath) in
                        call.resolve([
                            "filePath": fullPath!,
                        ])
                    })
                }
            })
        } else {
            call.reject("Cannot find album")
        }
    }
    
    @objc func saveGif(_ call: CAPPluginCall) {
        guard let data = call.getString("path") else {
            call.reject("Must provide the data path")
            return
        }
        
        checkAuthorization(allowed: {}, notAllowed: {
            call.reject("Access to photos not allowed by user")
            return
        })
        
        let album = call.getObject("album")
        var targetCollection: PHAssetCollection?
        var albumNameToCreate: String?;
        var assetId: String = ""
        
        if (album != nil){
            if (album?["id"] != nil) {
                targetCollection = findAlbumById(album?["id"] as! String)
                
                if targetCollection == nil {
                    call.reject("Unable to find that album by id")
                    return
                }
            }
            else if (album?["name"] != nil) {
                let albumName = album?["name"] as! String
                
                targetCollection = findAlbumByName(albumName)
                
                if targetCollection == nil {
                    albumNameToCreate = albumName
                }
            }
        }
        
        if albumNameToCreate != nil {
            self.createAlbumByName(albumNameToCreate!) { phAsset in
                if phAsset == nil {
                    call.reject("Unable to create album")
                    return
                } else {
                    targetCollection = phAsset
                    
                    if !targetCollection!.canPerform(.addContent) {
                        call.reject("Album doesn't support adding content (is this a smart album?)")
                        return
                    }
                }
                
                // Add it to the photo library.
                PHPhotoLibrary.shared().performChanges({
                    let creationRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: URL(string: data)!)
                    let placeHolder = creationRequest?.placeholderForCreatedAsset
                    
                    if let collection = targetCollection {
                        let addAssetRequest = PHAssetCollectionChangeRequest(for: collection)
                        addAssetRequest?.addAssets([creationRequest?.placeholderForCreatedAsset! as Any] as NSArray)
                        assetId = placeHolder!.localIdentifier
                    }
                    
                }, completionHandler: {success, error in
                    if !success {
                        call.reject("Unable to save gif to album")
                    } else {
                        let asset = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil).firstObject
                        
                        if asset == nil{
                            call.reject("Cannot fetch asset")
                            return
                        }
                        
                        self.getAssetUrl(asset!, completion: { (fullPath) in
                            call.resolve([
                                "filePath": fullPath!,
                            ])
                        })
                    }
                })
            }
        } else if targetCollection != nil {
            if !targetCollection!.canPerform(.addContent) {
                call.reject("Album doesn't support adding content (is this a smart album?)")
                return
            }
            
            // Add it to the photo library.
            PHPhotoLibrary.shared().performChanges({
                let creationRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: URL(string: data)!)
                let placeHolder = creationRequest?.placeholderForCreatedAsset
                
                if let collection = targetCollection {
                    let addAssetRequest = PHAssetCollectionChangeRequest(for: collection)
                    addAssetRequest?.addAssets([creationRequest?.placeholderForCreatedAsset! as Any] as NSArray)
                    assetId = placeHolder!.localIdentifier
                }
            }, completionHandler: {success, error in
                if !success {
                    call.reject("Unable to save gif to album")
                } else {
                    let asset = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil).firstObject
                    
                    if asset == nil{
                        call.reject("Cannot fetch asset")
                        return
                    }
                    
                    self.getAssetUrl(asset!, completion: { (fullPath) in
                        call.resolve([
                            "filePath": fullPath!,
                        ])
                    })
                }
            })
        } else {
            call.reject("Cannot find album")
        }
    }
    
    
    func checkAuthorization(allowed: @escaping () -> Void, notAllowed: @escaping () -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == PHAuthorizationStatus.authorized {
            allowed()
        } else {
            PHPhotoLibrary.requestAuthorization({ (newStatus) in
                if newStatus == PHAuthorizationStatus.authorized {
                    allowed()
                } else {
                    notAllowed()
                }
            })
        }
    }
    
    func fetchAlbumsToJs(_ call: CAPPluginCall) {
        var albums = [JSObject]()
        
        let loadSharedAlbums = call.getBool("loadShared", false)
        
        // Load our smart albums
        var fetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)
        fetchResult.enumerateObjects({ (collection, count, stop: UnsafeMutablePointer<ObjCBool>) in
            var o = JSObject()
            o["name"] = collection.localizedTitle
            o["identifier"] = collection.localIdentifier
            o["type"] = "smart"
            albums.append(o)
        })
        
        if loadSharedAlbums {
            fetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumCloudShared, options: nil)
            fetchResult.enumerateObjects({ (collection, count, stop: UnsafeMutablePointer<ObjCBool>) in
                var o = JSObject()
                o["name"] = collection.localizedTitle
                o["identifier"] = collection.localIdentifier
                o["type"] = "shared"
                albums.append(o)
            })
        }
        
        // Load our user albums
        PHCollectionList.fetchTopLevelUserCollections(with: nil).enumerateObjects({ (collection, count, stop: UnsafeMutablePointer<ObjCBool>) in
            var o = JSObject()
            o["name"] = collection.localizedTitle
            o["identifier"] = collection.localIdentifier
            o["type"] = "user"
            albums.append(o)
        })
        
        call.resolve([
            "albums": albums
        ])
    }
    
    func fetchResultAssetsToJs(_ call: CAPPluginCall) {
        var assets: [JSObject] = []
        
        let albumId = call.getString("albumIdentifier")
        
        let quantity = call.getInt("quantity", MediaPlugin.DEFAULT_QUANTITY)
        
        var targetCollection: PHAssetCollection?
        
        let options = PHFetchOptions()
        options.fetchLimit = quantity
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        if albumId != nil {
            let albumFetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [albumId!], options: nil)
            albumFetchResult.enumerateObjects({ (collection, count, _) in
                targetCollection = collection
            })
        }
        
        var fetchResult: PHFetchResult<PHAsset>;
        if targetCollection != nil {
            fetchResult = PHAsset.fetchAssets(in: targetCollection!, options: options)
        } else {
            fetchResult = PHAsset.fetchAssets(with: options)
        }
        
        let types = call.getString("types") ?? MediaPlugin.DEFAULT_TYPES
        let thumbnailWidth = call.getInt("thumbnailWidth", MediaPlugin.DEFAULT_THUMBNAIL_WIDTH)
        let thumbnailHeight = call.getInt("thumbnailHeight", MediaPlugin.DEFAULT_THUMBNAIL_HEIGHT)
        let thumbnailSize = CGSize(width: thumbnailWidth, height: thumbnailHeight)
        let thumbnailQuality = call.getInt("thumbnailQuality", 95)
        
        let requestOptions = PHImageRequestOptions()
        requestOptions.isNetworkAccessAllowed = true
        requestOptions.version = .current
        requestOptions.deliveryMode = .opportunistic
        requestOptions.isSynchronous = true
        
        fetchResult.enumerateObjects({ (asset, count: Int, stop: UnsafeMutablePointer<ObjCBool>) in
            
            if asset.mediaType == .image && types == "videos" {
                return
            }
            if asset.mediaType == .video && types == "photos" {
                return
            }
            
            var a = JSObject()
            
            self.imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: requestOptions, resultHandler: { (fetchedImage, _) in
                guard let image = fetchedImage else {
                    return
                }
                
                a["identifier"] = asset.localIdentifier
                
                // TODO: We need to know original type
                a["data"] = image.jpegData(compressionQuality: CGFloat(thumbnailQuality) / 100.0)?.base64EncodedString()
                
                if asset.creationDate != nil {
                    a["creationDate"] = JSDate.toString(asset.creationDate!)
                }
                a["fullWidth"] = asset.pixelWidth
                a["fullHeight"] = asset.pixelHeight
                a["thumbnailWidth"] = image.size.width
                a["thumbnailHeight"] = image.size.height
                a["location"] = self.makeLocation(asset)
                
                assets.append(a)
            })
        })
        
        call.resolve([
            "medias": assets
        ])
    }
    
    
    func makeLocation(_ asset: PHAsset) -> JSObject {
        var loc = JSObject()
        guard let location = asset.location else {
            return loc
        }
        
        loc["latitude"] = location.coordinate.latitude
        loc["longitude"] = location.coordinate.longitude
        loc["altitude"] = location.altitude
        loc["heading"] = location.course
        loc["speed"] = location.speed
        return loc
    }
    
    func findAlbumByName(_ name:String) -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", name)
        let fetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: fetchOptions)
        guard let photoAlbum = fetchResult.firstObject else {
            return nil
        }
        
        return photoAlbum
    }
    
    func findAlbumById(_ id:String) -> PHAssetCollection? {
        var targetCollection: PHAssetCollection?
        
        let albumFetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [id], options: nil)
        albumFetchResult.enumerateObjects({ (collection, count, _) in
            targetCollection = collection
        })
        
        
        return targetCollection
    }
    
    func createAlbumByName(_ albumName:String, completion: @escaping (_ phAsset: PHAssetCollection?) -> Void) -> Void{
        
        var albumPlaceholder: PHObjectPlaceholder?
        var targetCollection: PHAssetCollection?
        
        PHPhotoLibrary.shared().performChanges({
            let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
            albumPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
        }, completionHandler: { success, error in
            if (!success || albumPlaceholder == nil) {
                completion(nil)
            } else {
                targetCollection = self.findAlbumById(albumPlaceholder!.localIdentifier)
                
                if targetCollection == nil {
                    completion(nil)
                } else {
                    completion(targetCollection)
                }
            }
        })
    }
    
    func getAssetUrl(_ asset: PHAsset, completion: @escaping (_ fullPath: String?) -> Void) {
        
        let imageRequestOptions = PHImageRequestOptions()
        imageRequestOptions.isSynchronous = false
        imageRequestOptions.resizeMode = .exact
        imageRequestOptions.deliveryMode = .highQualityFormat
        imageRequestOptions.version = .current
        imageRequestOptions.isNetworkAccessAllowed = true
        
        if asset.mediaType == .image {
            let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
            asset.requestContentEditingInput(with: options, completionHandler: {(contentEditingInput: PHContentEditingInput?, info: [AnyHashable : Any]) -> Void in
                if let contentEditingInput = contentEditingInput {
                    completion(contentEditingInput.fullSizeImageURL?.absoluteString)
                } else {
                    completion(nil)
                }
            })
        } else if asset.mediaType == .video {
            PHImageManager.default().requestAVAsset(forVideo: asset, options: nil, resultHandler: { (avAsset: AVAsset?, avAudioMix: AVAudioMix?, info: [AnyHashable : Any]?) in
                
                if( avAsset is AVURLAsset ) {
                    let video_asset = avAsset as! AVURLAsset
                    let url = URL(fileURLWithPath: video_asset.url.relativePath)
                    completion(url.relativePath)
                }
                else if(avAsset is AVComposition) {
                    let token = info?["PHImageFileSandboxExtensionTokenKey"] as! String
                    let path = token.components(separatedBy: ";").last
                    completion(path)
                }
            })
        }
    }
}
