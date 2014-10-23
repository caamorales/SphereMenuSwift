//
//  ViewController.swift
//  Sphere Menu
//
//  Created by Camilo Morales on 10/21/14.
//  Copyright (c) 2014 Camilo Morales. All rights reserved.
//

import UIKit

class ViewController: UIViewController, SphereMenuDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.view.backgroundColor = UIColor(red:0.2, green:0.38, blue:0.8, alpha:1)
        let start = UIImage(named: "start")
        let image1 = UIImage(named: "icon-twitter")
        let image2 = UIImage(named: "icon-email")
        let image3 = UIImage(named: "icon-facebook")
        var images:[UIImage] = [image1!,image2!,image3!]
        var menu = SphereMenu(startPoint: CGPointMake(160, 320), startImage: start!, submenuImages:images)
        menu.delegate = self
        self.view.addSubview(menu)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func sphereDidSelected(index: Int) {
        println("\(index)")
    }

}

