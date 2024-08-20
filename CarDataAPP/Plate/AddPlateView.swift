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
    @State private var alertMessage: AlertMessage?
    
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
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.orange)
                                                .shadow(radius: 5)
                                        )
                                        .foregroundColor(.white)
                                    }
                .sheet(isPresented: $showingScanner) {
                    PlateScannerView { scannedText in
                        let formattedScannedText = formatPlateNumber(scannedText)
                        if plateNumber == formattedScannedText {
                            alertMessage = AlertMessage(message: "此車牌已掃描過")
                        } else {
                            plateNumber = formattedScannedText
                        }
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
        .alert(item: $alertMessage) { alertMessage in
            Alert(title: Text(alertMessage.message))
        }
    }

    private func formatPlateNumber(_ input: String) -> String {
        let digitsAndLetters = input.uppercased().filter { $0.isLetter || $0.isNumber }
        
        switch digitsAndLetters.count {
        case 5:
            if digitsAndLetters.prefix(2).allSatisfy({ $0.isLetter }) {
                // 2英文 3數字
                return "\(digitsAndLetters.prefix(2))-\(digitsAndLetters.dropFirst(2))"
            } else if digitsAndLetters.suffix(2).allSatisfy({ $0.isLetter }) {
                // 3數字 2英文
                return "\(digitsAndLetters.prefix(3))-\(digitsAndLetters.suffix(2))"
            } else {
                return digitsAndLetters
            }
            
        case 6:
            if digitsAndLetters.prefix(3).allSatisfy({ $0.isLetter }) {
                // 3英文 3數字
                return "\(digitsAndLetters.prefix(3))-\(digitsAndLetters.dropFirst(3))"
            } else if digitsAndLetters.suffix(3).allSatisfy({ $0.isLetter }) {
                // 3數字 3英文
                return "\(digitsAndLetters.prefix(3))-\(digitsAndLetters.suffix(3))"
            } else {
                return digitsAndLetters
            }
            
        case 7:
            if digitsAndLetters.prefix(3).allSatisfy({ $0.isLetter }) {
                // 3英文 4數字
                return "\(digitsAndLetters.prefix(3))-\(digitsAndLetters.dropFirst(3))"
            } else if digitsAndLetters.suffix(2).allSatisfy({ $0.isLetter }) {
                // 4數字 2英文
                return "\(digitsAndLetters.prefix(4))-\(digitsAndLetters.suffix(2))"
            } else {
                return digitsAndLetters
            }
            
        default:
            return digitsAndLetters
        }
    }

    private func isValidPlateNumber(_ input: String) -> Bool {
        let formattedInput = formatPlateNumber(input)
        let patterns = [
            "^[A-Z]{3}-[0-9]{4}$",  // 3英文 4數字
            "^[A-Z]{3}-[0-9]{3}$",  // 3英文 3數字
            "^[A-Z]{2}-[0-9]{3}$",  // 2英文 3數字
            "^[A-Z]{3}-[0-9]{2}$",  // 3英文 2數字
            "^[0-9]{4}-[A-Z]{2}$",  // 4數字 2英文
            "^[0-9]{3}-[A-Z]{2}$",  // 3數字 2英文
            "^[0-9]{3}-[A-Z]{3}$"   // 3數字 3英文
        ]
        
        for pattern in patterns {
            let regex = try! NSRegularExpression(pattern: pattern)
            let range = NSRange(location: 0, length: formattedInput.utf16.count)
            if regex.firstMatch(in: formattedInput, options: [], range: range) != nil {
                return true
            }
        }
        
        return false
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// 自定義 AlertMessage 結構
struct AlertMessage: Identifiable {
    let id = UUID() // 確保每個消息都有唯一的 ID
    let message: String
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
        let formattedInput = formatPlateNumber(input)
        let patterns = [
            "^[A-Z]{3}-[0-9]{4}$",  // 3英文 4數字
            "^[A-Z]{3}-[0-9]{3}$",  // 3英文 3數字
            "^[A-Z]{2}-[0-9]{3}$",  // 2英文 3數字
            "^[A-Z]{3}-[0-9]{2}$",  // 3英文 2數字
            "^[0-9]{4}-[A-Z]{2}$",  // 4數字 2英文
            "^[0-9]{3}-[A-Z]{2}$",  // 3數字 2英文
            "^[0-9]{3}-[A-Z]{3}$"   // 3數字 3英文
        ]
        
        for pattern in patterns {
            let regex = try! NSRegularExpression(pattern: pattern)
            let range = NSRange(location: 0, length: formattedInput.utf16.count)
            if regex.firstMatch(in: formattedInput, options: [], range: range) != nil {
                return true
            }
        }
        
        return false
    }
    
    private func formatPlateNumber(_ input: String) -> String {
        let digitsAndLetters = input.uppercased().filter { $0.isLetter || $0.isNumber }
        
        switch digitsAndLetters.count {
        case 5:
            if digitsAndLetters.prefix(2).allSatisfy({ $0.isLetter }) {
                return "\(digitsAndLetters.prefix(2))-\(digitsAndLetters.dropFirst(2))"
            } else if digitsAndLetters.suffix(2).allSatisfy({ $0.isLetter }) {
                return "\(digitsAndLetters.prefix(3))-\(digitsAndLetters.suffix(2))"
            } else {
                return digitsAndLetters
            }
            
        case 6:
            if digitsAndLetters.prefix(3).allSatisfy({ $0.isLetter }) {
                return "\(digitsAndLetters.prefix(3))-\(digitsAndLetters.dropFirst(3))"
            } else if digitsAndLetters.suffix(3).allSatisfy({ $0.isLetter }) {
                return "\(digitsAndLetters.prefix(3))-\(digitsAndLetters.suffix(3))"
            } else {
                return digitsAndLetters
            }
            
        case 7:
            if digitsAndLetters.prefix(3).allSatisfy({ $0.isLetter }) {
                return "\(digitsAndLetters.prefix(3))-\(digitsAndLetters.dropFirst(3))"
            } else if digitsAndLetters.suffix(2).allSatisfy({ $0.isLetter }) {
                return "\(digitsAndLetters.prefix(4))-\(digitsAndLetters.suffix(2))"
            } else {
                return digitsAndLetters
            }
            
        default:
            return digitsAndLetters
        }
    }
}
