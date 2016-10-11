//
//  GameScene.swift
//  SpaceBlaster
//
//  Created by iMac on 10/11/16.
//  Copyright (c) 2016 Marshall. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion


class GameScene: SKScene , SKPhysicsContactDelegate{
    var starfield:SKEmitterNode!
    var player:SKSpriteNode!
    var scoreLabel:SKLabelNode!
    var score:Int = 0 {
        didSet {
            
            scoreLabel.text = "Score: \(score)"
            
        }
    }
    
    var gameTimer: NSTimer!
    
    var possibleAliens = ["alien", "alien2", "alien3"]
    
    let alienCategory:UInt32 = 0x1 << 1
    let photonTorpedoCategory:UInt32 = 0x1 << 0
    
    let motionManager = CMMotionManager()
    var xAcceleration:CGFloat = 0
    
    
    override func didMoveToView(view: SKView) {
        
        let frameWidth = self.view?.frame.width
        let frameHeight = self.view?.frame.height
        
        
        starfield = SKEmitterNode(fileNamed: "Starfield")
        starfield.position = CGPoint(x: frameWidth!, y: frameHeight! + 100)
        starfield.advanceSimulationTime(10)
        self.addChild(starfield)
        
        starfield.zPosition = -1
        
        player = SKSpriteNode(imageNamed: "shuttle")
        
        player.position = CGPoint(x: self.frame.size.width / 2, y: player.frame.size.height / 2 + 20)
        
        self.addChild(player)
        
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.contactDelegate = self
        
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.position = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height - 50)
        print(self.frame.size.height)
        scoreLabel.fontName = "Avenir-Light"
        scoreLabel.fontSize = 30
        scoreLabel.fontColor = UIColor.whiteColor()
        score = 0
        self.addChild(scoreLabel)
        
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue()!) { (data: CMAccelerometerData?, error: NSError?) in
            if let accelerometerData = data {
                let acceleration = accelerometerData.acceleration
                self.xAcceleration = CGFloat(acceleration.x) * 0.75 + self.xAcceleration * 0.25
                
                
            }
        }
        
        gameTimer = NSTimer.scheduledTimerWithTimeInterval(0.75, target: self, selector: #selector(addAlien), userInfo: nil, repeats: true)
        
    }
    
    func addAlien () {
        
        possibleAliens = GKRandomSource.sharedRandom().arrayByShufflingObjectsInArray(possibleAliens) as! [String]
        let frameWidth: Int = Int((self.view?.frame.width)!)
        let alien = SKSpriteNode(imageNamed: possibleAliens[0])
        let randomAlienPosition = GKRandomDistribution(lowestValue: 0, highestValue: frameWidth * 2)
        let position = CGFloat(randomAlienPosition.nextInt())
        
        alien.position = CGPoint(x: position, y: self.frame.size.height + alien.size.height)
        
        alien.physicsBody = SKPhysicsBody(rectangleOfSize: alien.size)
        
        alien.physicsBody?.dynamic = true
        
        alien.physicsBody?.categoryBitMask = alienCategory
        alien.physicsBody?.contactTestBitMask = photonTorpedoCategory
        alien.physicsBody?.collisionBitMask = 0
        
        self.addChild(alien)
        
        let animationDuration:NSTimeInterval = 6.0
        
        var actionArray = [SKAction]()
        
        actionArray.append(SKAction.moveTo(CGPoint(x: position, y: -alien.size.height), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        alien.runAction(SKAction.sequence(actionArray))
        
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        fireTorpedo()
    }
    
    func fireTorpedo() {
        
        self.runAction(SKAction.playSoundFileNamed("torpedo.mp3", waitForCompletion: false))
        
        let torpedoNode = SKSpriteNode(imageNamed: "torpedo")
        torpedoNode.position = player.position
        torpedoNode.position.y += 5
        torpedoNode.physicsBody = SKPhysicsBody(circleOfRadius: torpedoNode.size.width / 2)
        torpedoNode.physicsBody?.dynamic = true
        
        torpedoNode.physicsBody?.categoryBitMask = photonTorpedoCategory
        torpedoNode.physicsBody?.contactTestBitMask = alienCategory
        torpedoNode.physicsBody?.collisionBitMask = 0
        torpedoNode.physicsBody?.usesPreciseCollisionDetection = true
        
        self.addChild(torpedoNode)

        let animationDuration: NSTimeInterval = 0.3
        
        var actionArray = [SKAction]()
        
        actionArray.append(SKAction.moveTo(CGPoint(x: player.position.x, y: self.frame.size.height + 10), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        torpedoNode.runAction(SKAction.sequence(actionArray))
        
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        var firstBody:SKPhysicsBody
        var secondBody:SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            
            firstBody = contact.bodyA
            secondBody = contact.bodyB
            
        } else {
         
            firstBody = contact.bodyB
            secondBody = contact.bodyA
            
        }
        
        if (firstBody.categoryBitMask & photonTorpedoCategory) != 0 && (secondBody.categoryBitMask & alienCategory) != 0 {
            
            torpedoDidCollideWithAlien(firstBody.node as! SKSpriteNode, alienNode: secondBody.node as! SKSpriteNode)
            
        }
    }
    
    func torpedoDidCollideWithAlien (torpedoNode:SKSpriteNode, alienNode: SKSpriteNode) {
        
        let explosion = SKEmitterNode(fileNamed: "Explosion")
        explosion?.position = alienNode.position
        self.addChild(explosion!)
        
        self.runAction(SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false))
        
        torpedoNode.removeFromParent()
        alienNode.removeFromParent()
        
        self.runAction(SKAction.waitForDuration(2.0), completion: {
            
            explosion?.removeFromParent()
        })
        
        score += 5
        
    }
    
    override func didSimulatePhysics() {
        
        player.position.x += xAcceleration * 50
        
        if player.position.x < -20 {
            
            player.position = CGPoint(x: self.frame.size.width + 20, y: player.position.y)
        } else if player.position.x > self.frame.size.width + 20 {
            player.position = CGPoint(x: -20, y: player.position.y)
            
        }
        
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
}
