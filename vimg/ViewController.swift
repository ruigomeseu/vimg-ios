//
//  ViewController.swift
//  vimg
//
//  Created by Rui Gomes on 29/01/15.
//  Copyright (c) 2015 Rui Gomes. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary

class ViewController: UIViewController {
    
    let captureSession = AVCaptureSession()
    var previewLayer : AVCaptureVideoPreviewLayer?
    var stillImageOutput: AVCaptureStillImageOutput = AVCaptureStillImageOutput()
    var uuidString: NSString?
    
    var camerasError : NSError? = nil
    
    var cameras = [AVCaptureDeviceInput]()
    var cameraInUse: Int = 0
    
    var capturedPhoto: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.generateCFUUID()
        
        // Do any additional setup after loading the view, typically from a nib.
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        
        let devices = AVCaptureDevice.devices()
        
        // Loop through all the capture devices on this phone
        for device in devices {
            // Make sure this particular device supports video
            if (device.hasMediaType(AVMediaTypeVideo)) {
                cameras.append(AVCaptureDeviceInput(device: device as AVCaptureDevice, error: &camerasError))
            }
        }
        
        if(cameras.count > 0) {
            beginSession()
        }
    }
    
    func generateCFUUID() {
        
        let defaults = NSUserDefaults.standardUserDefaults()
        if let uuidStringFromDefaults: AnyObject = defaults.objectForKey("vimgCFUUID")
        {
            self.uuidString = uuidStringFromDefaults as? NSString
            println("got uuid from userdefaults")
        } else {
            println("creating uuid")
            var uuid: CFUUID = CFUUIDCreate(nil)
            uuidString = CFUUIDCreateString(nil, uuid)
            defaults.setObject(uuidString, forKey: "vimgCFUUID")
        }
        
        println(uuidString);
        
    }
    
    @IBAction func cameraButtonWasPressed(sender: AnyObject) {
    
        if let videoConnection = stillImageOutput.connectionWithMediaType(AVMediaTypeVideo){
            
            if(videoConnection.supportsVideoOrientation)
            {
                videoConnection.videoOrientation = AVCaptureVideoOrientation.Portrait
            }
            
            stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection){
                (imageSampleBuffer : CMSampleBuffer!, _) in
                
                let imageDataJpeg = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageSampleBuffer)

                var pickedImage: UIImage = UIImage(data: imageDataJpeg)!
                
                self.capturedPhoto = pickedImage
                
                
                self.performSegueWithIdentifier("photoUploadSegue", sender: self)
                
                
            }
            
            
        }
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "photoUploadSegue") {
            let viewController = segue.destinationViewController as PhotoUploadViewController
            viewController.capturedPhoto = self.capturedPhoto
            viewController.uuidString = self.uuidString
            viewController.cameraUsed = self.cameraInUse
        }
    }
    
    @IBAction func switchCameraButtonWasPressed(sender: AnyObject) {
        captureSession.removeInput(cameras[cameraInUse])
        
        //toggle between 0 and 1
        cameraInUse = (cameraInUse + 1) % 2
        
        captureSession.addInput(cameras[cameraInUse])
    }
    
    func beginSession() {
        captureSession.addInput(cameras[cameraInUse])
        captureSession.addOutput(stillImageOutput)
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        var bounds: CGRect = view.layer.bounds
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer?.bounds = bounds
        previewLayer?.position=CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
        
        self.view.layer.insertSublayer(previewLayer, atIndex:0)
        previewLayer?.frame = self.view.layer.frame
        captureSession.startRunning()
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func supportedInterfaceOrientations() -> Int {
        return UIInterfaceOrientation.Portrait.rawValue
    }
    
}