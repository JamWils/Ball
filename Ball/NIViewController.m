//
//  NIViewController.m
//  Ball
//
//  Created by James Wilson on 9/21/13.
//  Copyright (c) 2013 James Wilson. All rights reserved.
//

#import <CoreImage/CoreImage.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Accelerate/Accelerate.h>
#import "NIViewController.h"
#import "NIMyScene.h"
#import "UIImage+StackBlur.h"
#import "NIBlurView.h"

@interface NIViewController(){
    SKScene * _scene;
    UIImage * blurredImage;
    BOOL _createdBlurred;
}

@end

@implementation NIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _createdBlurred = FALSE;
}

- (void)viewWillLayoutSubviews
{
    SKView * skView = (SKView *)self.view;

    SKScene * scene = [NIMyScene sceneWithSize:skView.bounds.size];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    
    // Present the scene.
    [skView presentScene:scene];
    
    
    self.view.opaque = NO;
    self.view.backgroundColor = [UIColor clearColor];
    
    _scene = skView.scene;
}

- (void)captureBlur {
    _createdBlurred = TRUE;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

@end
