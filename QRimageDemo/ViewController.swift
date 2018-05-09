//
//  ViewController.swift
//  QRimageDemo
//
//  Created by jia on 2018/5/9.
//  Copyright © 2018年 L.Crown. All rights reserved.
//
//  参考:https://blog.csdn.net/qq_30970529/article/details/52233292

import Cocoa

class ViewController: NSViewController {
    @IBOutlet weak var imageView: NSImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let iconImage = NSImage(named: NSImage.Name(rawValue: "light"))
        imageView.image = createQRImage(message: "Hello QRCode", backgroundColor: .white, foregroundColor: .blue, fillImage: iconImage)
    }
    
    @IBAction func showMessage(_ sender: NSButton) {
        sender.title = recognizeQRCode(targetImage: imageView.image!) ?? "can not recoginize"
    }
    
    
    /// 识别二维码
    ///
    /// - Parameter targetImage: 目标图片
    /// - Returns: 二维码信息字符串
    func recognizeQRCode(targetImage: NSImage) -> String? {
        
        let imageData = targetImage.tiffRepresentation(using: .none, factor: 0)
        let ciImage = CIImage(data: imageData!)
        /*创建探测器 options 是字典key:
         CIDetectorAccuracy 精度
         CIDetectorTracking 轨迹
         CIDetectorMinFeatureSize 最小特征尺寸
         CIDetectorNumberOfAngles 角度**/
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: CIContext(), options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])
        
        let featers = detector?.features(in: ciImage!) as? [CIQRCodeFeature]
        return featers?.last?.messageString
    }
    
    
    /// 创建二维码图片
    ///
    /// - Parameters:
    ///   - message: 二维码信息 String
    ///   - size: 生成图片的大小
    ///   - backgroundColor: 图片背景色
    ///   - foregroundColor: 二维码颜色
    ///   - fillImage: 修饰图片（logo图之类的）
    /// - Returns: 二维码图片 NSImage
    func createQRImage(message: String, size: NSSize = NSSize(width: 200, height: 200), backgroundColor: CIColor = .white, foregroundColor: CIColor = .black, fillImage: NSImage? = nil) -> NSImage? {
        guard let originImage = generateOriginQRImage(message: message) else {
            fatalError("failed to generate a QRImage")
        }
        
        let colorFilter = CIFilter(name: "CIFalseColor")
        //输入图片
        colorFilter!.setValue(originImage, forKey: "inputImage")
        //输入颜色
        colorFilter!.setValue(foregroundColor, forKey: "inputColor0")
        colorFilter!.setValue(backgroundColor, forKey: "inputColor1")
        
        guard let colorImage = colorFilter?.outputImage?.transformed(by: CGAffineTransform(scaleX: size.width/originImage.extent.width, y: size.height/originImage.extent.height)) else {
            fatalError("failed to generate the colorImage")
        }
        
        let image = NSImage(cgImage: convertCIImageToCGImage(inputImage: colorImage)!, size: size)
        
        if let fillImage = fillImage {
            let fillRect = CGRect(x: (size.width - size.width/4)/2, y: (size.height - size.height/4)/2, width: size.width/4, height: size.height/4)
            image.lockFocus()
            fillImage.draw(in: fillRect)
            image.unlockFocus()
        }
        
        return image
    }
    
    
    /// 生成原始二维码
    ///
    /// - Parameter message: 二维码信息
    /// - Returns: 二维码图片 CIImage
    private func generateOriginQRImage(message: String) -> CIImage? {
        let messageData = message.data(using: .utf8)
        // 创建二维码滤镜
        let qrCIFilter = CIFilter(name: "CIQRCodeGenerator")
        guard qrCIFilter != nil else {
            fatalError("QRCIFilter is nil")
        }
        qrCIFilter!.setValue(messageData, forKey: "inputMessage")
        //L7% M15% Q25% H%30% 纠错级别. 默认值是M
        qrCIFilter!.setValue("H", forKey: "inputCorrectionLevel")
        
        return qrCIFilter!.outputImage
    }
    
    /// CIImage转成CGImage
    ///
    /// - Parameter inputImage: CIImage
    /// - Returns: CGImage
    private func convertCIImageToCGImage(inputImage: CIImage) -> CGImage? {
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(inputImage, from: inputImage.extent) {
            return cgImage
        }
        return nil
    }

}

