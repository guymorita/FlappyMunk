//
//  GameViewController.swift
//  FlappyMunk
//
//  Created by Guy Morita on 12/11/14.
//  Copyright (c) 2014 geemoo. All rights reserved.
//

import UIKit
import SpriteKit

extension SKNode {
    class func unarchiveFromFile(file : NSString) -> SKNode? {
        if let path = NSBundle.mainBundle().pathForResource(file, ofType: "sks") {
            var sceneData = NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe, error: nil)!
            var archiver = NSKeyedUnarchiver(forReadingWithData: sceneData)
            
            archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
            let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as GameScene
            archiver.finishDecoding()
            return scene
        } else {
            return nil
        }
    }
}

class GameViewController: UIViewController, FlappyMunkDelegate, UIGestureRecognizerDelegate {
    
    var scene:GameScene!
    var score:Int!
    
    @IBOutlet weak var scoreLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure the view.

        let skView = self.view as SKView
        skView.showsFPS = true
        skView.showsNodeCount = true
        
        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView.ignoresSiblingOrder = true
        
        /* Set the scale mode to scale to fit the window */
        
        scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .AspectFill
        scene.delegateFlappy = self
        
        score = 0
        
        skView.presentScene(scene)
    }
    
    func gamePointScored(gameScene: GameScene) {
        score = score + 1
        updateScoreLabel()
        animationScoreLabel()
    }
    
    func gameOver(gameScene: GameScene) {
        score = 0
        updateScoreLabel()
        scene.setPositionsForNewGame()
    }
    
    func updateScoreLabel() {
        scoreLabel.text = "\(score)"
    }

    func animationScoreLabel() {
        var animation = CABasicAnimation(keyPath: "transform.scale")
        animation.toValue = NSNumber(float: 0.9)
        animation.duration = 0.3
        animation.autoreverses = true
        scoreLabel.layer.addAnimation(animation, forKey: nil)
    }
    
    @IBAction func didTap(sender: UITapGestureRecognizer) {
        scene.popChippy()
        scene.playSound("jump.wav")
    }

    override func shouldAutorotate() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> Int {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return Int(UIInterfaceOrientationMask.AllButUpsideDown.rawValue)
        } else {
            return Int(UIInterfaceOrientationMask.All.rawValue)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
