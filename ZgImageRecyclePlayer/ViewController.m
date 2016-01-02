//
//  ViewController.m
//  ZgImageRecyclePlayer
//
//  Created by 徐宗根 on 15/12/1.
//  Copyright (c) 2015年 XuZonggen. All rights reserved.
//

#import "ViewController.h"
#import "ZGImageRecyclePlayerView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
      
    NSMutableArray *mImages = [NSMutableArray array];
    UIImage *img0 = [UIImage imageNamed:@"Clara-1"];
    UIImage *img1 = [UIImage imageNamed:@"Clara-2"];
    //    UIImage *img2 = [UIImage imageNamed:@"Clara-3"];
    UIImage *img3 = [UIImage imageNamed:@"Clara-4"];
    
    [mImages addObject:img0];
    [mImages addObject:img1];
    //    [mImages addObject:img2];
    [mImages addObject:img3];
    
    
    ZGImageRecyclePlayerView *imageRecyclePlayerView = [ZGImageRecyclePlayerView imageRecyclePlayerViewWithImages:mImages.copy Frame:CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.width, 500)];
    
    [self.view addSubview:imageRecyclePlayerView];
}


@end
