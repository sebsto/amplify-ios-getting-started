//
//  UIImage+resize.swift
//  getting started
//
//  Created by Stormacq, Sebastien on 29/09/2021.
//  Copyright © 2021 Stormacq, Sebastien. All rights reserved.
//

import Foundation
import UIKit 

extension UIImage {
    
    func resize(to percentage: Float) -> UIImage {
        let newSize = CGSize(width: size.width * CGFloat(percentage),
                             height: size.height * CGFloat(percentage))
        return resize(to: newSize)
    }

    func resize(to newSize: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            let hScale = newSize.height / size.height
            let vScale = newSize.width / size.width
            let scale = max(hScale, vScale) // scaleToFill
            let resizeSize = CGSize(width: size.width*scale, height: size.height*scale)
            var middle = CGPoint.zero
            if resizeSize.width > newSize.width {
                middle.x -= (resizeSize.width-newSize.width)/2.0
            }
            if resizeSize.height > newSize.height {
                middle.y -= (resizeSize.height-newSize.height)/2.0
            }
            
            draw(in: CGRect(origin: middle, size: resizeSize))
        }
    }
}
