//
//  SphereMenu.swift
//  Sphere Menu
//
//  Created by Camilo Morales on 10/21/14.
//  Copyright (c) 2014 Camilo Morales. All rights reserved.
//

import Foundation
import UIKit

protocol SphereMenuDelegate{
    func sphereDidSelected(index:Int)
}

class SphereMenu:UIView, UICollisionBehaviorDelegate{
    

    let kItemInitTag:Int = 1001
    let kAngleOffset:CGFloat = CGFloat(M_PI_2) / 2.0
    let kSphereLength:CGFloat = 80
    let kSphereDamping:Float = 0.3
    
    var delegate:SphereMenuDelegate?
    var count:Int?
    var start:UIImageView?
    var images:Array<UIImage>?
    var items:Array<UIImageView>?
    var positions:Array<NSValue>?
    
    // animator and behaviors
    var animator:UIDynamicAnimator?
    var collision:UICollisionBehavior?
    var itemBehavior:UIDynamicItemBehavior?
    var snaps:Array<UISnapBehavior>?
    
    var tapOnStart:UITapGestureRecognizer?
    
    var bumper:UIDynamicItem?
    var expanded:Bool?
    var tapToDismiss = true
    
    var dismissTap:UITapGestureRecognizer?
    
    required init(startPoint:CGPoint, startImage:UIImage, submenuImages:Array<UIImage>, tapToDismiss:Bool){
        
        super.init(frame: CGRectZero)
        
        self.images = submenuImages;
        self.count = self.images!.count;
        self.start = UIImageView(image: startImage, highlightedImage: nil)
        self.start!.userInteractionEnabled = true;
        self.tapOnStart = UITapGestureRecognizer(target: self, action:"startTapped:")
        self.start!.addGestureRecognizer(self.tapOnStart!)
        self.addSubview(self.start!);
        self.bounds = CGRectMake(0, 0, startImage.size.width, startImage.size.height);
        self.center = startPoint;
        self.expanded = false
        self.tapToDismiss = tapToDismiss
        self.dismissTap = UITapGestureRecognizer(target: self, action: "hide")

    }
    
    required init(coder aDecoder: NSCoder) {
        self.count = 0;
        self.start = UIImageView()
        self.images = Array()
        super.init(frame: CGRectZero)
    }
    
    required override init(frame: CGRect) {
        self.count = 0;
        self.start = UIImageView()
        self.images = Array()
        super.init(frame: frame)
    }
    
    override func didMoveToSuperview() {
        self.commonSetup()
    }
    
    func hide(){
        if (self.expanded!) {
            self.shrinkSubmenu()
        }
    }
    
    func commonSetup()
    {
        self.items = Array()
        self.positions = Array()
        self.snaps = Array()

        // setup the items
        for (var i = 0; i < self.count; i++) {
            var item = UIImageView(image: self.images![i])
            item.tag = kItemInitTag + i;
            item.userInteractionEnabled = true;
            self.superview?.addSubview(item)
    
            let position = self.centerForSphereAtIndex(i)
            item.center = self.center;
            self.positions?.append(NSValue(CGPoint: position))
    
            let tap = UITapGestureRecognizer(target: self, action:"tapped:")
            item.addGestureRecognizer(tap)
    
            let pan = UIPanGestureRecognizer(target: self, action: "panned:")
            item.addGestureRecognizer(pan)
            self.items?.append(item)
        }
    
        self.superview?.bringSubviewToFront(self)
    
        // setup animator and behavior
        self.animator = UIDynamicAnimator(referenceView: self.superview!)
        self.collision = UICollisionBehavior(items: self.items!)
        self.collision?.translatesReferenceBoundsIntoBoundary = true;
        self.collision?.collisionDelegate = self;
        
        for (var i = 0; i < self.count; i++) {
            var snap = UISnapBehavior(item: self.items![i], snapToPoint: self.center)
            snap.damping = CGFloat(kSphereDamping)
            self.snaps?.append(snap)
        }
    
        self.itemBehavior = UIDynamicItemBehavior(items: self.items!)
        self.itemBehavior?.allowsRotation = false;
        self.itemBehavior?.elasticity = 0.25;
        self.itemBehavior?.density = 0.5;
        self.itemBehavior?.angularResistance = 4;
        self.itemBehavior?.resistance = 10;
        self.itemBehavior?.elasticity = 0.8;
        self.itemBehavior?.friction = 0.5;
    }

    func centerForSphereAtIndex(index:Int) -> CGPoint{
        let firstAngle:CGFloat = CGFloat(M_PI) + (CGFloat(M_PI_2) - kAngleOffset) + CGFloat(index) * kAngleOffset
        let startPoint = self.center
        let x = startPoint.x + cos(firstAngle) * kSphereLength;
        let y = startPoint.y + sin(firstAngle) * kSphereLength;
        let position = CGPointMake(x, y);
        return position;
    }
    
    func startTapped(gesture:UITapGestureRecognizer){
        self.animator?.removeBehavior(self.collision)
        self.animator?.removeBehavior(self.itemBehavior)
        self.removeSnapBehaviors()
        
        if (self.expanded == true) {
            self.shrinkSubmenu()
        } else {
            self.expandSubmenu()
        }
    }

    func tapped(gesture:UITapGestureRecognizer)
    {
        var tag = gesture.view?.tag
        tag? -= Int(kItemInitTag)
        self.delegate?.sphereDidSelected(tag!)
        self.shrinkSubmenu()
    }

    func panned(gesture:UIPanGestureRecognizer)
    {
        var touchedView = gesture.view;
        if (gesture.state == UIGestureRecognizerState.Began) {
            self.animator?.removeBehavior(self.itemBehavior)
            self.animator?.removeBehavior(self.collision)
            self.removeSnapBehaviors()
        } else if (gesture.state == UIGestureRecognizerState.Changed) {
            touchedView?.center = gesture.locationInView(self.superview)
        } else if (gesture.state == UIGestureRecognizerState.Ended) {
            self.bumper = touchedView;
            self.animator?.addBehavior(self.collision)
            let index = self.indexOfItemInArray(self.items!, item: touchedView!)

            if (index >= 0) {
                self.snapToPostionsWithIndex(index)
            }

        }
    }
    
    func indexOfItemInArray(dataArray:Array<UIImageView>, item:AnyObject) -> Int{
        var index = -1
        for (var i = 0; i < dataArray.count; i++){
            if (dataArray[i] === item){
                index = i
                break
            }
        }
        return index
    }
    
    func shrinkSubmenu(){
        self.animator?.removeBehavior(self.collision)
        
        for (var i = 0; i < self.count; i++) {
           self.snapToStartWithIndex(i)
        }
        self.expanded = false;
        self.superview?.removeGestureRecognizer(self.dismissTap!)
    }
    
    func expandSubmenu(){
        for (var i = 0; i < self.count; i++) {
           self.snapToPostionsWithIndex(i)
        }
        self.expanded = true;
        self.superview?.addGestureRecognizer(self.dismissTap!)
    }
    
    func snapToStartWithIndex(index:Int)
    {
        var snap = UISnapBehavior(item: self.items![index], snapToPoint: self.center)
        snap.damping = CGFloat(kSphereDamping)
        var snapToRemove = self.snaps![index];
        self.snaps![index] = snap;
        self.animator?.removeBehavior(snapToRemove)
        self.animator?.addBehavior(snap)
    }
    
    func snapToPostionsWithIndex(index:Int)
    {
        let positionValue:AnyObject = self.positions![index];
        let position = positionValue.CGPointValue()
        let snap = UISnapBehavior(item: self.items![index], snapToPoint: position)
        snap.damping = CGFloat(kSphereDamping)
        let snapToRemove = self.snaps![index];
        self.snaps![index] = snap;
        self.animator?.removeBehavior(snapToRemove)
        self.animator?.addBehavior(snap)
    }

    func removeSnapBehaviors()
    {
        for (var i = 0; i < self.snaps?.count; i++){
            self.animator?.removeBehavior(self.snaps?[i])
        }
    }
    
    func collisionBehavior(behavior: UICollisionBehavior, endedContactForItem item1: UIDynamicItem, withItem item2: UIDynamicItem) {
      //  return;
       self.animator?.addBehavior(self.itemBehavior)

        if (item1 !== self.bumper){
            let index = self.indexOfItemInArray(self.items!, item: item1)
            if (index >= 0) {
                self.snapToPostionsWithIndex(index)
            }
        }
        
        if (item2 !== self.bumper){
            let index = self.indexOfItemInArray(self.items!, item: item2)
            if (index >= 0) {
                self.snapToPostionsWithIndex(index)
            }
        }
    }

}

