//
//  UXMSignAnnotation.swift
//  Pods
//
//  Created by Chris Anderson on 6/23/16.
//
//

import UIKit

open class UXMSignAnnotation: NSObject, NSCoding {
    public var page: Int?
    public var uuid: String = UUID().uuidString
    public var saved: Bool = false
    public weak var delegate: UXMPDFAnnotationEvent?

    var image: UIImage? {
        didSet {
            view.signImage.image = image
        }
    }

    var rect: CGRect = CGRect.zero {
        didSet {
            view.frame = self.rect
        }
    }

    lazy var view: PDFSignAnnotationView = PDFSignAnnotationView(parent: self)

    fileprivate var isEditing: Bool = false

    override public required init() { super.init() }

    public func didEnd() {
    }

    public required init(coder aDecoder: NSCoder) {
        page = aDecoder.decodeObject(forKey: "page") as? Int
        image = aDecoder.decodeObject(forKey: "image") as? UIImage
        rect = aDecoder.decodeCGRect(forKey: "rect")
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(page, forKey: "page")
        aCoder.encode(image, forKey: "image")
        aCoder.encode(rect, forKey: "rect")
    }
}

extension UXMSignAnnotation: UXMAnnotation {
    public func resize() {
        
    }

    public func mutableView() -> UIView {
        view = PDFSignAnnotationView(parent: self)
        return view
    }

    public func touchStarted(_ touch: UITouch, point: CGPoint) {
        if rect == CGRect.zero {
            rect = CGRect(origin: point, size: CGSize(width: 250, height: 100))
        }
        view.touchesBegan([touch], with: nil)
    }

    public func touchMoved(_ touch: UITouch, point: CGPoint) {
        view.touchesMoved([touch], with: nil)
    }

    public func touchEnded(_ touch: UITouch, point: CGPoint) {
        view.touchesEnded([touch], with: nil)
    }

    public func save() {
        saved = true
    }

    public func drawInContext(_ context: CGContext) {
        UIGraphicsPushContext(context)

        guard let image = self.image else { return }
        // Draw our CGImage in the context of our PDFAnnotation bounds
        image.draw(in: rect)

        UIGraphicsPopContext()
    }
}

extension UXMSignAnnotation: ResizableViewDelegate {
    func resizableViewDidBeginEditing(view: ResizableView) { }

    func resizableViewDidEndEditing(view: ResizableView) {
        rect = self.view.frame
    }

    func resizableViewDidSelectAction(view: ResizableView, action: String) {
        delegate?.annotation(annotation: self, selected: action)
    }
}

extension UXMSignAnnotation: UXMPDFAnnotationButtonable {
    public static var name: String? { return "Sign" }
    public static var buttonImage: UIImage? { return UIImage.bundledImage("sign") }
}

class PDFSignAnnotationView: ResizableView, UXMPDFAnnotationView {
    let signExtraPadding: CGFloat = 22.0

    var parent: UXMAnnotation?
    let signController = UXMFormSignatureViewController()
    override var canBecomeFirstResponder: Bool { return true }
    override var menuItems: [UIMenuItem] {
        return [
            UIMenuItem(
                title: "Delete",
                action: #selector(PDFSignAnnotationView.menuActionDelete(_:))
            ),
            UIMenuItem(
                title: "Sign",
                action: #selector(PDFSignAnnotationView.menuActionSign(_:))
            ),
        ]
    }

    var signImage: UIImageView = {
        var image = UIImageView()
//        image.contentMode = .scaleAsp ectFit
        image.backgroundColor = UIColor.clear
        return image
    }()

    override var frame: CGRect {
        didSet {
            signImage.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        }
    }

    convenience init(parent: UXMSignAnnotation) {
        self.init()

        self.parent = parent
        delegate = parent
        frame = parent.rect
        signImage.image = parent.image

        signController.delegate = parent

        signImage.backgroundColor = UIColor.clear
        signImage.isUserInteractionEnabled = false
        backgroundColor = UIColor.clear

        addSubview(signImage)
    }

    @objc func menuActionSign(_ sender: Any!) {
        delegate?.resizableViewDidSelectAction(view: self, action: "sign")

        isLocked = true
        signImage.isUserInteractionEnabled = true
        signImage.becomeFirstResponder()
        addSignature()
    }

    @objc func addSignature() {
        let nvc = UINavigationController(rootViewController: signController)
        nvc.modalPresentationStyle = .formSheet
        nvc.preferredContentSize = CGSize(width: 640, height: 300)
        nvc.modalPresentationStyle = .overFullScreen
        UIViewController.topController()?.present(nvc, animated: true)
    }

    override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(menuActionSign(_:)) {
            return true
        }
        return super.canPerformAction(action, withSender: sender)
    }
}

extension UXMSignAnnotation: UXMFormSignatureDelegate {
    func completedSignatureDrawing(field: UXMFormFieldSignatureCaptureView) {
        if let image = field.getSignature() {
            self.image = image
            let size = image.size.applying(.init(scaleX: 0.5, y: 0.5))
            self.rect = CGRect(origin: rect.origin, size: size)
        }

        view.isLocked = false
    }
}
