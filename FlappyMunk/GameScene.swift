//
//  GameScene.swift
//  FlappyMunk
//
//  Created by Guy Morita on 12/11/14.
//  Copyright (c) 2014 geemoo. All rights reserved.
//

import SpriteKit

var pillarCoefficient = 50
var curTime = 0
var barrier: UInt32 = 0x1 << 1
var protagonist: UInt32 = 0x1 << 2

var skyBlue:UIColor = UIColor(red: CGFloat(38.0/255.0), green: CGFloat(143.0/255.0), blue: CGFloat(222.0/255.0), alpha: CGFloat(1.0))


protocol FlappyMunkDelegate {
    func gamePointScored(gameScene: GameScene)
    
    func gameOver(gameScene: GameScene)
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var chippy: SKSpriteNode!
    var barriers: Array<SKSpriteNode>!
    var delegateFlappy: FlappyMunkDelegate?
    var cityBackground: SKSpriteNode!
    var gameActive: Bool!
    var startTime: Int!
    
    required init(coder aDecoder: NSCoder) {
        fatalError("NSCoder not supported")
    }
    
    override init(size: CGSize) {
        super.init(size: size)

        gameActive = true
        barriers = Array<SKSpriteNode>()
        startTime = Int(CACurrentMediaTime())
        let background = SKSpriteNode(color: skyBlue, size: self.frame.size)
        background.anchorPoint = CGPoint(x: 0, y: 0)
        addChild(background)
        
        cityBackground = SKSpriteNode(imageNamed: "landscape")
        cityBackground.xScale = 0.7
        cityBackground.yScale = 0.7
        let moveCityBackground = SKAction.moveByX(-5.0, y: 0, duration: 1.0)
        let moveBackgroundForever = SKAction.repeatActionForever(moveCityBackground)
        cityBackground.runAction(moveBackgroundForever)
        resetBackgroundPosition()
        
        self.addChild(cityBackground)
        
        let ground = SKSpriteNode(color: UIColor.clearColor(), size: CGSizeMake(500, 50))
        ground.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMinY(self.frame)+125)
        ground.physicsBody = SKPhysicsBody(rectangleOfSize: ground.size)
        ground.physicsBody?.affectedByGravity = false
        ground.physicsBody?.dynamic = true
        ground.physicsBody?.mass = 1000.0
        ground.physicsBody?.collisionBitMask = 0
        ground.physicsBody?.categoryBitMask = barrier
        ground.physicsBody?.contactTestBitMask = protagonist

        addChild(ground)
        
        self.physicsWorld.gravity = CGVectorMake(0.0, -6.0)
        self.physicsWorld.contactDelegate = self
        
        addChippy()
    }
    
    func addChippy() {
        chippy = SKSpriteNode(imageNamed:"flying_chippy")
        chippy.xScale = 0.16
        chippy.yScale = 0.16
        
        setChippyPosition()
        
        addChild(chippy)
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
        });
    }
    
    func resetBackgroundPosition() {
        cityBackground.position = CGPoint(x:CGRectGetMidX(self.frame) + 280, y:CGRectGetMinY(self.frame)+180)
    }
    
    func setPositionsForNewGame() {
        chippy.physicsBody?.dynamic = false
        chippy.physicsBody = nil
        
        for (idx, barrier) in enumerate(barriers) {
            barrier.physicsBody?.dynamic = false
            barrier.physicsBody = nil
            removeChildrenInArray([barrier])
        }
        resetBackgroundPosition()
        setChippyPosition()
    }

    
    func setChippyPosition() {
        startTime = Int(CACurrentMediaTime())
        chippy.physicsBody = SKPhysicsBody(rectangleOfSize: chippy.size)
        chippy.physicsBody?.dynamic = true
        chippy.physicsBody?.categoryBitMask = protagonist
        chippy.physicsBody?.contactTestBitMask = barrier
        chippy.position = CGPoint(x:CGRectGetMidX(self.frame) - 100, y:CGRectGetMidY(self.frame) + 100)
    }
    
    override func update(currentTime: CFTimeInterval) {
        let curTimeInt = Int(currentTime)
        
        if curTime < curTimeInt - 2 {
            if curTime != 0 && startTime < curTimeInt - 2 {
                delegateFlappy?.gamePointScored(self)
            }
            curTime = curTimeInt
            addClouds()

        }
        if arc4random_uniform(10) == 1 {
            addSmoke()
        }
    }
    
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
    
    func addClouds() {
        let randomHeight = arc4random_uniform(200)
        
        let cloud = SKSpriteNode(imageNamed: "column_big")
        cloud.xScale = 0.3
        cloud.yScale = 0.3
        let cloudPos = CGPoint(x:CGRectGetMaxX(self.frame) + CGFloat(pillarCoefficient), y:CGRectGetMaxY(self.frame) + 100 + CGFloat(randomHeight))
        cloud.position = cloudPos
        
        self.addChild(cloud)
        
        cloud.physicsBody = SKPhysicsBody(rectangleOfSize: cloud.size)
        cloud.physicsBody?.affectedByGravity = false
        cloud.physicsBody?.velocity = CGVectorMake(-110, 0)
        cloud.physicsBody?.dynamic = true
        cloud.physicsBody?.mass = 1000.0
        cloud.physicsBody?.categoryBitMask = barrier
        cloud.physicsBody?.contactTestBitMask = protagonist
        cloud.physicsBody?.collisionBitMask = 0
        cloud.physicsBody?.linearDamping = 0.0
        
        let building = SKSpriteNode(imageNamed: "column_big")
        building.xScale = 0.3
        building.yScale = 0.3
        let buildingPos = CGPoint(x: CGRectGetMaxX(self.frame) + CGFloat(pillarCoefficient), y: CGRectGetMinY(self.frame) - 200 + CGFloat(randomHeight))
        building.position = buildingPos

        self.addChild(building)
        
        building.physicsBody = SKPhysicsBody(rectangleOfSize: building.size)
        building.physicsBody?.affectedByGravity = false
        building.physicsBody?.dynamic = true
        building.physicsBody?.mass = 1000.0
        building.physicsBody?.velocity = CGVectorMake(-110, 0)
        building.physicsBody?.categoryBitMask = barrier
        building.physicsBody?.contactTestBitMask = protagonist
        building.physicsBody?.collisionBitMask = 0
        building.physicsBody?.linearDamping = 0.0
        
        self.barriers.append(cloud)
        self.barriers.append(building)
    }
   
}
