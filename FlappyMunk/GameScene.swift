//
//  GameScene.swift
//  FlappyMunk
//
//  Created by Guy Morita on 12/11/14.
//  Copyright (c) 2014 geemoo. All rights reserved.
//

import SpriteKit

var screenSize = UIScreen.mainScreen().bounds.height
var displaySizeDifferenceCoefficient:CGFloat = 0.2998
var screenOffset = screenSize * displaySizeDifferenceCoefficient
var pillarCoefficient = 50
var barrier: UInt32 = 0x1 << 1
var protagonist: UInt32 = 0x1 << 2
var skyBlue:UIColor = UIColor(red: CGFloat(118.0/255.0), green: CGFloat(200.0/255.0), blue: CGFloat(231.0/255.0), alpha: CGFloat(1.0))


protocol FlappyMunkDelegate {
    func gamePointScored(gameScene: GameScene)
    
    func gameOver(gameScene: GameScene)
    
    func gameDidStart(gameScene: GameScene)
}


class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var chippy: SKSpriteNode!
    var barriers: Array<SKSpriteNode>!
    var delegateFlappy: FlappyMunkDelegate?
    var cityMiddleground: SKSpriteNode!
    var gameActive: Bool!
    var startTime: Int!
    var scoreTime: Int!
    var curDifficulty: CGFloat!
    
    required init(coder aDecoder: NSCoder) {
        fatalError("NSCoder not supported")
    }
    
    override init(size: CGSize) {
        super.init(size: size)

        gameActive = true
        barriers = Array<SKSpriteNode>()
        startTime = Int(CACurrentMediaTime())
        scoreTime = 0
        curDifficulty = 0.0
        
        setupEnvironment()
    }
    
    // MARK: Environment
    
    func setupEnvironment() {
        addBackgrond()
        
        addMiddleground()
        
        addGround()
        
        addPhysics()
        
        addChippy()
    }
    
    func addBackgrond() {
        let background = SKSpriteNode(color: skyBlue, size: self.frame.size)
        background.anchorPoint = CGPoint(x: 0, y: 0)
        addChild(background)
    }
    
    func addMiddleground() {
        cityMiddleground = SKSpriteNode(imageNamed: "landscape")
        cityMiddleground.xScale = screenOffset / 290
        cityMiddleground.yScale = screenOffset / 290
        let movecityMiddleground = SKAction.moveByX(-5.0, y: 0, duration: 1.0)
        let moveBackgroundForever = SKAction.repeatActionForever(movecityMiddleground)
        cityMiddleground.runAction(moveBackgroundForever)
        resetCityMiddlegroundPosition()
        
        self.addChild(cityMiddleground)

    }
    
    func resetCityMiddlegroundPosition() {
        cityMiddleground.position = CGPoint(x:CGRectGetMidX(self.frame) + 280, y:screenOffset*0.9)
    }
    
    func addGround() {
        let ground = SKSpriteNode(color: UIColor.clearColor(), size: CGSizeMake(500, 50))
        ground.position = CGPoint(x:CGRectGetMidX(self.frame), y:screenOffset*0.9-57)
        ground.physicsBody = SKPhysicsBody(rectangleOfSize: ground.size)
        ground.physicsBody?.affectedByGravity = false
        ground.physicsBody?.dynamic = true
        ground.physicsBody?.mass = 1000.0
        ground.physicsBody?.collisionBitMask = 0
        ground.physicsBody?.categoryBitMask = barrier
        ground.physicsBody?.contactTestBitMask = protagonist
        
        addChild(ground)
    }
    
    func addPhysics() {
        self.physicsWorld.gravity = CGVectorMake(0.0, -6.0)
        self.physicsWorld.contactDelegate = self
    }
    
    func addChippy() {
        chippy = SKSpriteNode(imageNamed:"flying_chippy")
        chippy.xScale = screenOffset / 1300
        chippy.yScale = screenOffset / 1300
        
        setChippyPosition()
        
        addChild(chippy)
    }
    
    func setChippyPosition() {
        startTime = Int(CACurrentMediaTime())
        chippy.physicsBody = SKPhysicsBody(rectangleOfSize: chippy.size)
        chippy.physicsBody?.dynamic = true
        chippy.physicsBody?.categoryBitMask = protagonist
        chippy.physicsBody?.contactTestBitMask = barrier
        chippy.position = CGPoint(x:CGRectGetMidX(self.frame) - 100, y:CGRectGetMidY(self.frame) + 100)
    }
    
    // MARK: Game Loop
    
    override func update(currentTime: CFTimeInterval) {
        let curTimeInt = Int(currentTime)
        let atLeastTwoSecondsHavePassed = scoreTime < curTimeInt - 2
        
        if atLeastTwoSecondsHavePassed {
            
            // score is based on how much time has passed, this is in line with the rate the pillars move
            if scoreTime != 0 && atLeastTwoSecondsHavePassed {
                delegateFlappy?.gamePointScored(self)
            }
            scoreTime = curTimeInt
            curDifficulty = curDifficulty + 0.3
            addPillars(curDifficulty)
        }
        
        // randomly produces plane smoke
        if arc4random_uniform(10) == 1 {
            addSmoke()
        }
    }
    
    func addPillars(difficulty: CGFloat) {
        let baseHeight = -CGFloat(screenOffset)
        // primary adjustment that positions the bottom pillar at a normal position
        let primaryAdjustment = baseHeight + CGFloat(arc4random_uniform(UInt32(screenOffset))) * 1.5
        // makes the cap wider for smaller screens
//        let smallScreenBoost = (667-screenSize) / 3.5
        // slowly adds difficulty over time, making the gap more narrow
        let difficultyOffset = (screenOffset/200) * difficulty
        
        let topPillar = addPillar()
        let topPillarPos = CGPoint(x: CGRectGetMaxX(self.frame) + CGFloat(pillarCoefficient), y: primaryAdjustment + topPillar.size.height + screenOffset - difficultyOffset)
        topPillar.position = topPillarPos
        self.barriers.append(topPillar)

        let bottomPillar = addPillar()
        let bottomPillarPos = CGPoint(x: CGRectGetMaxX(self.frame) + CGFloat(pillarCoefficient), y: primaryAdjustment + difficultyOffset)
        bottomPillar.position = bottomPillarPos
        self.barriers.append(bottomPillar)
    }
    
    
    func addPillar() -> SKSpriteNode {
        let pillar = SKSpriteNode(imageNamed: "column_big")
        pillar.xScale = screenOffset / 680
        pillar.yScale = screenOffset / 680
        
        self.addChild(pillar)
        
        pillar.physicsBody = SKPhysicsBody(rectangleOfSize: pillar.size)
        pillar.physicsBody?.affectedByGravity = false
        pillar.physicsBody?.dynamic = true
        pillar.physicsBody?.mass = 1000.0
        pillar.physicsBody?.velocity = CGVectorMake(-110, 0)
        pillar.physicsBody?.categoryBitMask = barrier
        pillar.physicsBody?.contactTestBitMask = protagonist
        pillar.physicsBody?.collisionBitMask = 0
        pillar.physicsBody?.linearDamping = 0.0
        
        return pillar
    }
    
    func addSmoke() {
        let smokeO = SKSpriteNode()
        let circleNode = SKShapeNode(circleOfRadius: 5.0)
        
        circleNode.strokeColor = UIColor.whiteColor()
        circleNode.fillColor = UIColor.whiteColor()
        circleNode.lineWidth = 5
        smokeO.addChild(circleNode)
        smokeO.position = CGPointMake(chippy.position.x - 15, chippy.position.y)
        addChild(smokeO)
        moveSmoke(smokeO)
    }
    
    func moveSmoke(smoke: SKSpriteNode) {
        let currentPosition = smoke.position
        let randX = CGFloat(arc4random_uniform(80))
        let randY = CGFloat(arc4random_uniform(100)) + currentPosition.y
        smoke.runAction(SKAction.scaleTo(3.0, duration: 1.0))
        smoke.runAction(SKAction.fadeAlphaTo(0.0, duration: 1.0))
        smoke.runAction(SKAction.moveTo(CGPointMake(-randX, randY), duration: 2.0))

        var delta: Int64 = 4 * Int64(NSEC_PER_SEC)
        var time = dispatch_time(DISPATCH_TIME_NOW, delta)
        dispatch_after(time, dispatch_get_main_queue(), {
            self.removeChildrenInArray([smoke])
        })
    }
    
    // MARK: New Game
    
    func setPositionsForNewGame() {
        scoreTime = 0
        curDifficulty = 0.0
        delegateFlappy?.gameDidStart(self)
        chippy.physicsBody?.dynamic = false
        chippy.physicsBody = nil
        
        for (idx, barrier) in enumerate(barriers) {
            barrier.physicsBody?.dynamic = false
            barrier.physicsBody = nil
            removeChildrenInArray([barrier])
        }
        resetCityMiddlegroundPosition()
        setChippyPosition()
    }
    
    // MARK: Actions

    func playSound(sound: String) {
        runAction(SKAction.playSoundFileNamed(sound, waitForCompletion: false))
    }
    
    func didEndContact(contact: SKPhysicsContact) {
        delegateFlappy?.gameOver(self)
    }
    
    func popChippy() {
        chippy.physicsBody?.velocity = CGVectorMake(0.0, 400.0)
        
        let rotateUpwards = SKAction.rotateToAngle(CGFloat(M_PI*0.25), duration:0.3, shortestUnitArc: true)
        chippy.runAction(rotateUpwards)
        runAction(SKAction.waitForDuration(0.3), completion: chippyRotatingForward)
    }
    
    func chippyRotatingForward() {
        let action = SKAction.rotateToAngle(CGFloat(M_PI*1.75), duration: 1.0, shortestUnitArc: true)
        chippy.runAction(action)
    }
    func flipChippy() {
        chippy.removeAllActions()
        let backFlip = SKAction.rotateByAngle(CGFloat(M_PI*2), duration:0.5)
        chippy.runAction(backFlip)
    }
   
}
