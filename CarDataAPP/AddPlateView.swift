//
//  AddPlateView.swift
//  CarDataAPP
//
//  Created by BBOB on 2024/8/18.
//

import SwiftUI
import AVFoundation
import Vision

struct AddPlateView: View {
    var onSave: (CarPlate) -> Void
    @State private var plateNumber: String = ""
    @State private var showingScanner = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("新增車牌")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
                .foregroundColor(.primary)

            TextField("ABC-1234", text: $plateNumber)
                .font(.title2)
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
                .shadow(radius: 5)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                .onChange(of: plateNumber) { newValue in
                    plateNumber = formatPlateNumber(newValue)
                }

            HStack {
                Button(action: {
                    showingScanner = true
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("掃描車牌")
                            .fontWeight(.bold)
                    }
                    .font(.title2)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                }
                .padding(.horizontal, 16)
                .sheet(isPresented: $showingScanner) {
                    PlateScannerView { scannedText in
                        plateNumber = scannedText
                        showingScanner = false
                    }
                }
                
                Button(action: {
                    let newPlate = CarPlate(id: UUID().uuidString, number: plateNumber)
                    onSave(newPlate)
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("儲存車牌")
                            .fontWeight(.bold)
                    }
                    .font(.title2)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                }
                .padding(.horizontal, 16)
                .disabled(!isValidPlateNumber(plateNumber))
            }
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
        .onTapGesture {
            hideKeyboard()
        }
    }

    private func formatPlateNumber(_ input: String) -> String {
        let digitsAndLetters = input.uppercased().filter { $0.isLetter || $0.isNumber }
        let formatted = digitsAndLetters.prefix(3) + "-" + digitsAndLetters.dropFirst(3).prefix(4)
        return String(formatted)
    }

    private func isValidPlateNumber(_ input: String) -> Bool {
        let pattern = "^[A-Z]{3}-[0-9]{4}$"
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: input.utf16.count)
        return regex.firstMatch(in: input, options: [], range: range) != nil
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// 這個是掃描器的視圖
struct PlateScannerView: UIViewControllerRepresentable {
    var onScanned: (String) -> Void
    
    func makeUIViewController(context: Context) -> PlateScannerViewController {
        return PlateScannerViewController(onScanned: onScanned)
    }
    
    func updateUIViewController(_ uiViewController: PlateScannerViewController, context: Context) {}
}

// 這是實際的掃描控制器
class PlateScannerViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var onScanned: (String) -> Void
    private var captureSession: AVCaptureSession!
    
    init(onScanned: @escaping (String) -> Void) {
        self.onScanned = onScanned
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureSession()
    }
    
    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            return
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(videoOutput)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNRecognizeTextRequest { (request, error) in
            if let observations = request.results as? [VNRecognizedTextObservation] {
                for observation in observations {
                    if let topCandidate = observation.topCandidates(1).first {
                        let recognizedText = topCandidate.string
                        if self.isValidPlateNumber(recognizedText) {
                            DispatchQueue.main.async {
                                self.captureSession.stopRunning()
                                self.onScanned(recognizedText)
                            }
                            return
                        }
                    }
                }
            }
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
    
    private func isValidPlateNumber(_ input: String) -> Bool {
        let pattern = "^[A-Z]{3}-[0-9]{4}$"
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: input.utf16.count)
        return regex.firstMatch(in: input, options: [], range: range) != nil
    }
}
