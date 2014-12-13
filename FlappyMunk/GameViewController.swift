//
//  GameViewController.swift
//  FlappyMunk
//
//  Created by Guy Morita on 12/11/14.
//  Copyright (c) 2014 geemoo. All rights reserved.
//

import UIKit
import SpriteKit

var chippyCostumeImages: Array<String>!

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
    var bestScore:Int!
    
    @IBOutlet weak var bestScoreLabel: UILabel!
    @IBOutlet weak var endGameScoreLabel: UILabel!
    @IBOutlet weak var inGameScoreLabel: UILabel!
    @IBOutlet weak var finalScoreView: UIView!
    @IBOutlet weak var playAgainButton: UIButton!
    @IBOutlet weak var cloud1: UIView!
    @IBOutlet weak var cloud2: UIView!
    @IBOutlet weak var cloud3: UIView!
    @IBOutlet weak var cloud4: UIView!
    @IBOutlet weak var cloud5: UIView!
    
    @IBOutlet weak var chippyImage: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure the view.

        let skView = self.view as SKView
        let model = UIDevice.currentDevice().model
        if (model == "iPhone Simulator") {
            skView.showsFPS = true
            skView.showsNodeCount = true
        }

        
        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView.ignoresSiblingOrder = true
        
        chippyCostumeImages = ["munk-dizzy", "munk-reg", "munk-halloween", "munk-holiday", "munk-fear", "munk-yahoo", "munk-suit", "munk-kim", "munk-hotel", "munk-sick", "munk-map", "munk-yc"]
        
        scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .AspectFill
        scene.delegateFlappy = self
        
        score = 0
        
        findBestScore()
        
        cloud1.layer.cornerRadius = 40.0
        cloud2.layer.cornerRadius = 35.0
        cloud3.layer.cornerRadius = 50.0
        cloud4.layer.cornerRadius = 25.0
        cloud5.layer.cornerRadius = 25.0

        finalScoreView.clipsToBounds = true
        
        finalScoreView.layer.cornerRadius = 10.0
        finalScoreView.layer.borderColor = UIColor.whiteColor().CGColor
        finalScoreView.layer.borderWidth = 3.0
        finalScoreView.alpha = 0
        
        playAgainButton.layer.cornerRadius = 10.0
        playAgainButton.layer.borderColor = UIColor.whiteColor().CGColor
        playAgainButton.layer.borderWidth = 3.0
        playAgainButton.alpha = 0
        
        skView.presentScene(scene)
        
    }
    
    func findBestScore() {
        var bestScoreOutput: AnyObject? = NSUserDefaults.standardUserDefaults().objectForKey("bestScore")
        if bestScoreOutput != nil {
            bestScore = bestScoreOutput as Int
        } else {
            bestScore = 0
        }
    }
    
    func gamePointScored(gameScene: GameScene) {
        score = score + 1
        updateScoreLabel()
        popScoreLabel(inGameScoreLabel, amount: 0.8)
    }
    
    func gameOver(gameScene: GameScene) {
        if score > bestScore {
            bestScore = score
            NSUserDefaults.standardUserDefaults().setObject(bestScore, forKey: "bestScore")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        endGameScoreDisplay()
        scene.view?.paused = true
        scene.gameActive = false
    }
    
    func gameDidStart(gameScene: GameScene) {
        score = 0
        updateScoreLabel()
        scene.gameActive = true
        scene.view?.paused = false
        hideScoreButtons()
    }
    
    func endGameScoreDisplay(){
        self.finalScoreView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.9, 0.9)
        self.endGameScoreLabel.text = "\(score)"
        self.bestScoreLabel.text = "\(bestScore)"
        setChippyImage()
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.inGameScoreLabel.alpha = 0
        })
        
        UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.finalScoreView.alpha = 1
            self.finalScoreView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1)
        }) { (Bool) -> Void in
            self.showPlayAgainButton()
            self.popScoreLabel(self.endGameScoreLabel, amount: 0.95)
            self.popScoreLabel(self.bestScoreLabel, amount: 0.95)
        }
    }
    
    func setChippyImage() {
        var randImg:Int
        if score < 1 {
            randImg = 0
        } else {
            randImg = Int(arc4random_uniform(UInt32(chippyCostumeImages.count)))
        }
        chippyImage.image = UIImage(named: chippyCostumeImages[randImg])
    }
    
    func showPlayAgainButton() {
        self.playAgainButton.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.9, 0.9)
        UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.playAgainButton.alpha = 1.0
            self.playAgainButton.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1)
        }) { (Bool) -> Void in
        }
    }
    
    func startNewGame() {
        scene.setPositionsForNewGame()
    }
    
    func hideScoreButtons() {
        UIView.animateWithDuration(0.1, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.playAgainButton.alpha = 0
            self.inGameScoreLabel.alpha = 1
            self.finalScoreView.alpha = 0
            }) { (Bool) -> Void in
        }
    }
    
    func updateScoreLabel() {
        inGameScoreLabel.text = "\(score)"
    }

    func popScoreLabel(label: UILabel, amount: Float) {
        var animation = CABasicAnimation(keyPath: "transform.scale")
        animation.toValue = NSNumber(float: amount)
        animation.duration = 0.3
        animation.autoreverses = true
        label.layer.addAnimation(animation, forKey: nil)
    }
    
    @IBAction func didTapPlayAgain(sender: UIButton) {
        scene.setPositionsForNewGame()
    }
    @IBAction func didTap(sender: UITapGestureRecognizer) {
        if scene.gameActive == true {
            scene.popChippy()
            scene.playSound("jump.wav")
        }
    }
    
    @IBAction func didTwoFingerTouch(sender: UITapGestureRecognizer) {
        if scene.gameActive == true {
            scene.flipChippy()
        }
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
