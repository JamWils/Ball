//
//  NIMyScene.m
//  Ball
//
//  Created by James Wilson on 9/21/13.
//  Copyright (c) 2013 James Wilson. All rights reserved.
//

#import "NIMyScene.h"

#define IS_IPHONE_5 ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )

@interface NIMyScene () <SKPhysicsContactDelegate> {
    
    
}

@end

@implementation NIMyScene {
    
    BOOL _dragging;
    
    CGPoint _touchOffset;
    CGVector _latestGravity;
    CGPoint _firstTouchPoint;
    CGPoint _lastTouchPoint;
    CGRect _perimeter;
    
    SKSpriteNode *_ballSprite;
    CMMotionManager *_motionManager;
    AVAudioPlayer *_audioPlayer;
    AVAudioPlayer *_backupPlayer;
    SKAction *_ballCollision;
}

static const uint32_t borderCategory = 0x1 << 0;
static const uint32_t ballCategory = 0x1 << 1;
dispatch_queue_t bounceQueue;

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        
        self.physicsWorld.gravity = CGVectorMake(0, -10);
        self.physicsWorld.contactDelegate = self;

        BOOL initSuccess = [self initMotion];
        
        [self configureAudioPlayers];
        bounceQueue = dispatch_queue_create("com.noesisingenuity.ball", NULL);
        
        if (initSuccess) {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                _perimeter = [self setupBackground:@"ballBackground-iPad" withBorder:20];
                [self addBallWithScale:.25];
            }
            else if (IS_IPHONE_5) {
                _perimeter = [self setupBackground:@"ballBackground-iPhone5" withBorder:10];
                [self addBallWithScale:.15];
            }
            else {
                _perimeter = [self setupBackground:@"ballBackground-iPhone4" withBorder:10];
                [self addBallWithScale:.15];
            }
        }
  
    }
    return self;
}

-(void)addCollisionWallsAroundScreen: (CGRect) perimeter {
    SKNode *edgeNode = [SKNode node];
    edgeNode.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:perimeter];
    edgeNode.physicsBody.dynamic = NO;
    edgeNode.physicsBody.collisionBitMask = borderCategory | ballCategory;
    edgeNode.physicsBody.categoryBitMask = borderCategory;
    edgeNode.physicsBody.contactTestBitMask = borderCategory | ballCategory;
    
    [self addChild:edgeNode];
}

-(CGRect) setupBackground: (NSString *) backgroundPath withBorder: (int)borderLength {
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    
    CGRect perimeter = CGRectMake(borderLength, borderLength, screenWidth - (borderLength * 2), screenHeight - (borderLength * 2));
    [self addCollisionWallsAroundScreen:perimeter];
    [self addBackground:backgroundPath];
    
    return perimeter;
}

-(void)addBackground:(NSString *) imagePath {
    SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:imagePath];
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    sprite.position = CGPointMake(screenWidth / 2, screenHeight / 2);
    
    [self addChild:sprite];
}

-(void)addBallWithScale:(float)scale {
    SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:@"ball"];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;

    sprite.xScale = .5;
    sprite.yScale = .5;
    
    /* The positions are based on the splash screen for ball.
     This way the sprite ball will appear where the ball was on the spashscreen making a smooth transition */
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (UIInterfaceOrientationIsLandscape([[UIDevice currentDevice] orientation])) {
            sprite.position = CGPointMake(460, screenHeight / 2);
        } else {
            sprite.position = CGPointMake(screenWidth / 2, 380);
        }
    }
    else if (IS_IPHONE_5) {
        sprite.position = CGPointMake(screenWidth / 2, 240);
    }
    else {
        sprite.position = CGPointMake(screenWidth / 2, 200);
    }
    
    _ballSprite = sprite;
    
    [self addChild:sprite];
    
    SKAction * shrinkBall = [SKAction scaleXTo:scale y:scale duration:1.0];
    
    [_ballSprite runAction:shrinkBall completion:^{
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            sprite.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:sprite.size.height/2];
            sprite.physicsBody.mass = 15;
            sprite.physicsBody.restitution = .8;
            sprite.physicsBody.affectedByGravity = TRUE;
            sprite.physicsBody.linearDamping = 0;
            sprite.physicsBody.collisionBitMask = borderCategory | ballCategory;
            sprite.physicsBody.categoryBitMask = ballCategory;
            sprite.physicsBody.contactTestBitMask = borderCategory | ballCategory;
        } else {
            sprite.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:sprite.size.height/2];
            sprite.physicsBody.mass = 10;
            sprite.physicsBody.restitution = .7;
            sprite.physicsBody.affectedByGravity = TRUE;
            sprite.physicsBody.linearDamping = 0;
            sprite.physicsBody.collisionBitMask = borderCategory | ballCategory;
            sprite.physicsBody.categoryBitMask = ballCategory;
            sprite.physicsBody.contactTestBitMask = borderCategory | ballCategory;
        }
        
    }];

}

-(void) configureAudioPlayers {
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"BallBounce" withExtension:@"caf"];
    NSError *error = nil;
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    _backupPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    
    if (!_audioPlayer || !_backupPlayer) {
        NSLog(@"Error creating player: %@", error);
    }
    
    _audioPlayer.rate = 0.5;
    _backupPlayer.rate = 0.5;
}

#pragma mark - CoreMotion support
-(BOOL) initMotion {
    if (!_motionManager) {
        _motionManager =[[CMMotionManager alloc] init];
    }
    
    [self stopMotion];
    
    if (_motionManager.deviceMotionAvailable) {
        [_motionManager startDeviceMotionUpdates];
    }
    
    if (_motionManager.accelerometerAvailable) {
        [_motionManager startAccelerometerUpdates];
    }
    
    return _motionManager != nil;
}

-(void) stopMotion {
    if (_motionManager.deviceMotionActive) {
        [_motionManager stopDeviceMotionUpdates];
    }
}

-(void)didBeginContact:(SKPhysicsContact *)contact {
    
    float normalizedVolume = ((contact.collisionImpulse - 0) / (100000 - 0)) / 20;
    [_audioPlayer setVolume:(normalizedVolume)];
    
    dispatch_async(bounceQueue, ^{
        
        if (!_audioPlayer.isPlaying) {
            [_audioPlayer play];
        } else {
            _backupPlayer.volume = normalizedVolume;
            [_backupPlayer play];
        }
        
    });
}

-(void)didEndContact:(SKPhysicsContact *)contact {

}

#pragma mark Touch Events

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        _firstTouchPoint = location;
        
        if (_ballSprite != nil) {
            if (location.x > _ballSprite.frame.origin.x && location.x < (_ballSprite.frame.origin.x + _ballSprite.frame.size.width) &&
                location.y > _ballSprite.frame.origin.y && location.y < (_ballSprite.frame.origin.y + _ballSprite.frame.size.height))
            {
                _touchOffset = CGPointMake(location.x - _ballSprite.frame.origin.x, location.y - _ballSprite.frame.origin.y);
                _dragging = TRUE;
            }
        }
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchLocation = [touch locationInNode:self];
        
    if (_dragging) {
        //This ensures the ball cannot be dragged passed the collision border of the screen...which would make the ball disappear
        if (touchLocation.x > _perimeter.origin.x && touchLocation.x < _perimeter.size.width && touchLocation.y > _perimeter.origin.y && touchLocation.y < _perimeter.size.height) {
            SKAction * moveAction = [SKAction moveTo:(CGPointMake(touchLocation.x, touchLocation.y)) duration:.01];
            [_ballSprite runAction:moveAction];
        }
        
        self.physicsWorld.gravity= CGVectorMake(0, 0);
        _ballSprite.physicsBody.velocity = CGVectorMake(0, 0);

    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        _lastTouchPoint = location;
    }
    
    if (_dragging) {
        self.physicsWorld.gravity = _latestGravity;
        _ballSprite.physicsBody.velocity = CGVectorMake((_lastTouchPoint.x - _firstTouchPoint.x) * 5, (_lastTouchPoint.y -_firstTouchPoint.y) * 7);
        _dragging = FALSE;
    }
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    if (_motionManager.deviceMotionActive && !_dragging) {
        CMDeviceMotion * motion = _motionManager.deviceMotion;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            _latestGravity = CGVectorMake(motion.gravity.x * 25, motion.gravity.y * 25);
            [_ballSprite.physicsBody applyImpulse:CGVectorMake(-motion.userAcceleration.x * 3000, -motion.userAcceleration.y * 3000)];
        } else {
            _latestGravity = CGVectorMake(motion.gravity.x * 12, motion.gravity.y * 12);
            [_ballSprite.physicsBody applyImpulse:CGVectorMake(-motion.userAcceleration.x * 2000, -motion.userAcceleration.y * 2000)];
        }
        
        self.physicsWorld.gravity = _latestGravity;
        
    }
}

@end
