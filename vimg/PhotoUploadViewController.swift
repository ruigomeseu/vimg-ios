//
//  PhotoUploadViewController.swift
//  vimg
//
//  Created by Rui Gomes on 30/01/15.
//  Copyright (c) 2015 Rui Gomes. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import AssetsLibrary
import Darwin
import Alamofire

class PhotoUploadViewController: UIViewController {
    
    var capturedPhoto: UIImage?
    var rotatedPhoto: UIImage?
    var uuidString: NSString?
    
    @IBOutlet weak var urlLabel: UILabel!
    
    @IBOutlet weak var photoView: UIView!
    
    @IBOutlet weak var uploadButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        println("captured photo loaded")
        
        urlLabel.hidden = true
        
        //rotatedPhoto = rotate(capturedPhoto!, orientation: UIImageOrientation.Left)
        rotatedPhoto = UIImage(CGImage: capturedPhoto?.CGImage, scale: 1.0, orientation: UIImageOrientation.UpMirrored)
     
        photoView.layer.contents = rotatedPhoto!.CGImage
        
    }
    
    @IBAction func uploadWasPressed(sender: AnyObject) {
        uploadButton.enabled = false
        
        var jpgImage: NSData = UIImageJPEGRepresentation(rotatedPhoto, CGFloat(0.7))
        
        let parameters = [
            "device_id": String(uuidString!)
        ]
        
        let urlRequest = urlRequestWithComponents("http://vimg.co/images", parameters: parameters, imageData: jpgImage)
        
        Alamofire.upload(urlRequest.0, urlRequest.1)
            .progress { (bytesWritten, totalBytesWritten, totalBytesExpectedToWrite) in
                println("\(totalBytesWritten) / \(totalBytesExpectedToWrite)")
            }
            .responseJSON { (request, response, json, error) in
                if(error === nil) {
                    println(json)
                    var id: String = String(json!.valueForKey("id") as NSString)
                    
                    self.urlLabel.hidden = false
                    self.urlLabel.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
                    self.urlLabel.text = "vimg.co/\(id)"
                }
        }
        
        
        
    }
    
    @IBAction func cancelWasPressed(sender: AnyObject) {
        self.performSegueWithIdentifier("cancelPhotoUploadSegue", sender: self)
    }
    
    func radians(degrees: Double) -> CGFloat {
        return CGFloat((degrees * M_PI))
    }
    
    func rotate(source: UIImage, orientation: UIImageOrientation) -> UIImage {
        UIGraphicsBeginImageContext(source.size)
        
        println(radians(90.0))
        
        var context: CGContextRef = UIGraphicsGetCurrentContext()
        
        if (orientation == UIImageOrientation.Right) {
            CGContextRotateCTM (context, radians(90.0));
        } else if (orientation == UIImageOrientation.Left) {
            CGContextRotateCTM (context, radians(-90.0));
        } else if (orientation == UIImageOrientation.Down) {
            //Nothing
        } else if (orientation == UIImageOrientation.Up) {
            CGContextRotateCTM (context, radians(180.0));
        }
        
        source.drawAtPoint(CGPointMake(0,0))
        
        var newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    // this function creates the required URLRequestConvertible and NSData we need to use Alamofire.upload
    func urlRequestWithComponents(urlString:String, parameters:Dictionary<String, String>, imageData:NSData) -> (URLRequestConvertible, NSData) {
        
        // create url request to send
        var mutableURLRequest = NSMutableURLRequest(URL: NSURL(string: urlString)!)
        mutableURLRequest.HTTPMethod = Alamofire.Method.POST.rawValue
        let boundaryConstant = "leWildBoundary3123";
        let contentType = "multipart/form-data;boundary="+boundaryConstant
        mutableURLRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        
        
        // create upload data to send
        let uploadData = NSMutableData()
        
        let date = NSDate()
        let timestamp = date.timeIntervalSince1970
        
        // add image
        uploadData.appendData("\r\n--\(boundaryConstant)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        uploadData.appendData("Content-Disposition: form-data; name=\"image\"; filename=\"\(timestamp).jpg\"\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        uploadData.appendData("Content-Type: image/jpg\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        uploadData.appendData(imageData)
        
        // add parameters
        for (key, value) in parameters {
            uploadData.appendData("\r\n--\(boundaryConstant)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            uploadData.appendData("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".dataUsingEncoding(NSUTF8StringEncoding)!)
        }
        uploadData.appendData("\r\n--\(boundaryConstant)--\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        
        
        // return URLRequestConvertible and NSData
        return (Alamofire.ParameterEncoding.URL.encode(mutableURLRequest, parameters: nil).0, uploadData)
    }
}
