//
//  ViewController.swift
//  PoseEstimation-CoreML
//
//  Created by GwakDoyoung on 05/07/2018.
//  Copyright © 2018 tucan9389. All rights reserved.
//

import UIKit
import Vision
import CoreMedia

class JointViewController: UIViewController {
    public typealias DetectObjectsCompletion = ([BodyPoint?]?, Error?) -> Void
    
    // MARK: - UI Properties
    @IBOutlet weak var videoPreview: UIView!
    @IBOutlet weak var jointView: DrawingJointView!
    @IBOutlet weak var labelsTableView: UITableView!
    
    @IBOutlet weak var inferenceLabel: UILabel!
    @IBOutlet weak var etimeLabel: UILabel!
    @IBOutlet weak var fpsLabel: UILabel!
    
    // MARK - Inference Result Data
    private var tableData: [BodyPoint?] = []
    
    // MARK - Performance Measurement Property
    private let 👨‍🔧 = 📏()
    
    // MARK - Core ML model
    typealias EstimationModel = hourglass
    
    // MARK: - Vision Properties
    var request: VNCoreMLRequest?
    var visionModel: VNCoreMLModel?
    
    // MARK: - AV Property
    var videoCapture: VideoCapture!
    
    // MARK: - View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SuperSocketManager.shared.connect {
            // setup the model
            
            
        }
        
        self.setUpModel()
        
        // setup camera
        self.setUpCamera()
        
        // setup tableview datasource on bottom
        self.labelsTableView.dataSource = self
        
        // setup delegate for performance measurement
        self.👨‍🔧.delegate = self
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.videoCapture.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.videoCapture.stop()
    }
    
    // MARK: - Setup Core ML
    func setUpModel() {
        if let visionModel = try? VNCoreMLModel(for: EstimationModel().model) {
            self.visionModel = visionModel
            request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
            request?.imageCropAndScaleOption = .scaleFill
        } else {
            fatalError()
        }
    }
    
    // MARK: - SetUp Video
    func setUpCamera() {
        videoCapture = VideoCapture()
        videoCapture.delegate = self
        videoCapture.fps = 30
        videoCapture.setUp(sessionPreset: .vga640x480) { success in
            
            if success {
                // add preview view on the layer
                if let previewLayer = self.videoCapture.previewLayer {
                    self.videoPreview.layer.addSublayer(previewLayer)
                    self.resizePreviewLayer()
                }
                
                // start video preview when setup is done
                self.videoCapture.start()
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resizePreviewLayer()
    }
    
    func resizePreviewLayer() {
        videoCapture.previewLayer?.frame = videoPreview.bounds
    }
}

// MARK: - VideoCaptureDelegate
extension JointViewController: VideoCaptureDelegate {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?, timestamp: CMTime) {
        // the captured image from camera is contained on pixelBuffer
        if let pixelBuffer = pixelBuffer {
            // start of measure
            self.👨‍🔧.🎬👏()
            
            // predict!
            self.predictUsingVision(pixelBuffer: pixelBuffer)
        }
    }
}

extension JointViewController {
    // MARK: - Inferencing
    func predictUsingVision(pixelBuffer: CVPixelBuffer) {
        guard let request = request else { fatalError() }
        // vision framework configures the input size of image following our model's input configuration automatically
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        try? handler.perform([request])
    }
    
    // MARK: - Poseprocessing
    func visionRequestDidComplete(request: VNRequest, error: Error?) {
        self.👨‍🔧.🏷(with: "endInference")
        if let observations = request.results as? [VNCoreMLFeatureValueObservation],
            let heatmap = observations.first?.featureValue.multiArrayValue {
            
            // convert heatmap to [keypoint]
            let n_kpoints = heatmap.convertHeatmapToBodyPoint()
            
            DispatchQueue.main.sync {
                // draw line
                self.jointView.bodyPoints = n_kpoints
                
                if let rightWrist = n_kpoints[4],
                    let leftWrist = n_kpoints[7] {
                    if rightWrist.maxConfidence > 0.2 {
                        SuperSocketManager.shared.emit(eventName: "HAND:MOVE", data: ["x" : 1-rightWrist.maxPoint.x,"y":rightWrist.maxPoint.y])
                    }
                    
                }
                
                
                
                // show key points description
                //self.showKeypointsDescription(with: n_kpoints)
                
                // end of measure
                self.👨‍🔧.🎬🤚()
            }
        } else {
            // end of measure
            self.👨‍🔧.🎬🤚()
        }
    }
    
    func showKeypointsDescription(with n_kpoints: [BodyPoint?]) {
        self.tableData = n_kpoints
        self.labelsTableView.reloadData()
    }
}

// MARK: - UITableView Data Source
extension JointViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count// > 0 ? 1 : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "LabelCell", for: indexPath)
        cell.textLabel?.text = Constant.pointLabels[indexPath.row]
        if let body_point = tableData[indexPath.row] {
            let pointText: String = "\(String(format: "%.3f", body_point.maxPoint.x)), \(String(format: "%.3f", body_point.maxPoint.y))"
            cell.detailTextLabel?.text = "(\(pointText)), [\(String(format: "%.3f", body_point.maxConfidence))]"
        } else {
            cell.detailTextLabel?.text = "N/A"
        }
        return cell
    }
}


// MARK: - 📏(Performance Measurement) Delegate
extension JointViewController: 📏Delegate {
    func updateMeasure(inferenceTime: Double, executionTime: Double, fps: Int) {
        //print(executionTime, fps)
        self.inferenceLabel.text = "inference: \(Int(inferenceTime*1000.0)) mm"
        self.etimeLabel.text = "execution: \(Int(executionTime*1000.0)) mm"
        self.fpsLabel.text = "fps: \(fps)"
    }
}
