//
//  UIBezierPath+Ext.swift
//  UXMPDFKit
//
//  Created by FSKJ on 2022/6/28.
//

import Foundation

extension UIBezierPath {
    // 移动位置
    func move(fromPoint: CGPoint, toPoint: CGPoint) {
        let moveX = toPoint.x - fromPoint.x
        let moveY = toPoint.y - fromPoint.y
        apply(CGAffineTransform(translationX: moveX, y: moveY))
    }

    // 缩放
    func scale(fromSize: CGSize, toSize: CGSize) {
        if fromSize.width == 0 || fromSize.height == 0 {
            return
        }
        let scaleWidth = toSize.width / fromSize.width
        let scaleHeight = toSize.height / fromSize.height
        self.apply(CGAffineTransform(scaleX: scaleWidth, y: scaleHeight))
    }
}
