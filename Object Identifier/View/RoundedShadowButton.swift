//
//  RoundedShadowButton.swift
//  Object Identifier
//
//  Created by Swapnil Chauhan on 26/08/17.
//  Copyright © 2017 Swapnil Chauhan. All rights reserved.
//

import UIKit

class RoundedShadowButton: UIButton {

    override func awakeFromNib() {
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowRadius = 15
        self.layer.shadowOpacity = 0.75
        self.layer.cornerRadius = self.frame.height / 2
    }
}
