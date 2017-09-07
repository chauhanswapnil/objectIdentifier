//
//  ViewController.swift
//  Object Identifier
//
//  Created by Swapnil Chauhan on 26/08/17.
//  Copyright © 2017 Swapnil Chauhan. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision

var speech = true
var toSpeak = false

enum FlashState {
    case off
    case on
}
class CameraVC: UIViewController {
    
    //Variables
    var captureSession: AVCaptureSession!
    var cameraOutput: AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var photoData: Data?
    var flashControlState: FlashState = .off
    var speechSynthesizer = AVSpeechSynthesizer()
    
    //Outlets
    @IBOutlet weak var speechLabel: UIButton!
    @IBOutlet weak var captureImageView: UIImageView!
    @IBOutlet weak var flashBtn: RoundedShadowButton!
    @IBOutlet weak var identificationLabel: UILabel!
    @IBOutlet weak var confidenceLabel: UILabel!
    @IBOutlet weak var cameraView: RoundedShadowImageView!
    @IBOutlet weak var roundedLabelView: RoundedShadowView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        previewLayer.frame = cameraView.bounds
        speechSynthesizer.delegate = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapCameraView))
        tap.numberOfTapsRequired = 1

        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
        
        let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
        
        do{
            
            let input = try AVCaptureDeviceInput(device: backCamera!)
            if captureSession.canAddInput(input) == true
            {
                captureSession.addInput(input)
            }
        cameraOutput = AVCapturePhotoOutput()
       
            if captureSession.canAddOutput(cameraOutput) == true
            {
                captureSession.addOutput(cameraOutput!)
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
                previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
                previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                cameraView.layer.addSublayer(previewLayer!)
                cameraView.addGestureRecognizer(tap)
                captureSession.startRunning()
            }
        }
        catch {
            debugPrint(error)
        }
    }
    
    @objc func didTapCameraView()
    {
        let settings = AVCapturePhotoSettings()
        settings.previewPhotoFormat = settings.embeddedThumbnailPhotoFormat
        if flashControlState == .off {
            settings.flashMode = .off
        }
        else
        {
            settings.flashMode = .on
        }
        cameraOutput.capturePhoto(with: settings, delegate: self)
    }
    func resultsMethod(request: VNRequest , error: Error?)
    {
        guard let results = request.results as? [VNClassificationObservation] else { return }
        for classifications in results {
            if classifications.confidence < 0.2 {
                
                let unkownObjectMessage = "I'm not sure what this is. Please try again!"

                self.identificationLabel.text = unkownObjectMessage
                if speech == true {
                synthesizeSpeech(fromString: unkownObjectMessage)
                }
                self.confidenceLabel.text = ""
                break
            }
            else {
                let identification = classifications.identifier
                let confidence = Int(classifications.confidence*100)
                self.identificationLabel.text = identification
                self.confidenceLabel.text = "CONFIDENCE: \(confidence)%"
                
                if speech == true {
                let completeSentence = "I think it is \(identification).      I am \(confidence) percent sure."
                synthesizeSpeech(fromString: completeSentence)
                }
                break
            }
        }
    }
    func synthesizeSpeech(fromString string: String) {
        let speechUtterance = AVSpeechUtterance(string: string)
        speechSynthesizer.speak(speechUtterance)
    }
    @IBAction func flashBtnPressed(_ sender: Any) {
        switch(flashControlState)
        {
        case .off:
            flashBtn.setTitle("FLASH ON", for: .normal)
            flashControlState = .on
        case .on:
            flashBtn.setTitle("FLASH OFF", for: .normal)
            flashControlState = .off
            
        }
    }
    
    @IBAction func speechBtnPressed(_ sender: Any) {
        if speech == true {
            toSpeak = false
            speechLabel.setTitle("SPEECH OFF", for: .normal)
            speech = false
        }
        else
        {
            toSpeak = true
            speechLabel.setTitle("SPEECH ON", for: .normal)
            speech = true
        }
    }
}


extension CameraVC: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    
        if let error = error {
            debugPrint(error)
        } else{
            photoData = photo.fileDataRepresentation()
            do{
                let model = try VNCoreMLModel(for: MobileNet().model)
                //let model = try VNCoreMLModel(for:MobileNet().mlmodel)
                let request = VNCoreMLRequest(model: model, completionHandler: resultsMethod)
                let handler = VNImageRequestHandler(data: photoData!)
                try handler.perform([request])
            }
            catch {
                debugPrint(error)
            }
            let image = UIImage(data: photoData!)
            self.captureImageView.image = image
        }
    }
}
extension CameraVC: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    }
}
