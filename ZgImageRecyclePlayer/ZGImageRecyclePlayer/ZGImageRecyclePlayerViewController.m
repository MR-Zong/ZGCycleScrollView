//
//  ZGImageRecyclePlayerViewController.m
//  ZGWuXianLunBoQi
//
//  Created by 徐宗根 on 15/12/1.
//  Copyright (c) 2015年 XuZonggen. All rights reserved.
//

#import "ZGImageRecyclePlayerViewController.h"

#define OBJKEY(obj,key) ((void)obj.key,@(#key))
#define ZGPAGECONTROLHEIGHT 20
// 颜色
#define ZGCOLOR_32(a,r,g,b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:(a)]
#define ZGCOLOR_24(r,g,b) ZGCOLOR_32(1.0,(r),(g),(b))
#define ZGGRAYCOLOR(v) ZGCOLOR_24((v),(v),(v))
#define ZGBACKGROUNDCOLOR ZGGRAYCOLOR(215)
#define ZGRandomColor ZGCOLOR_32(1.0,arc4random_uniform(255),arc4random_uniform(255),arc4random_uniform(255))

// timer up/down
// 解开注释，启动timer
#define TIMERON

@interface ZGImageRecyclePlayerViewController ()<UIScrollViewDelegate>



/** scrollView */
@property (nonatomic,strong) UIScrollView *sv;

@property (nonatomic,strong) NSMutableSet *imageViewSet;

@property (nonatomic,strong) UIImageView *curImageView;

@property (nonatomic,strong) UIImageView *tmpImageView;

@property (nonatomic,assign) BOOL stopFlag;

@property (nonatomic,assign) BOOL dragFlag;

@property (nonatomic,assign) BOOL leftFlag;

@property (nonatomic,assign) BOOL rightFlag;

@property (nonatomic,assign) BOOL pageFlag;

@property (nonatomic,copy) NSArray *images;

@property (nonatomic,assign) CGRect viewFrame;

@property (nonatomic,assign) NSInteger imageIndex;


/** pageContoller */
@property (nonatomic,strong) UIPageControl *pageControl;

/** timer */
@property (nonatomic,strong) NSTimer *timer;


@end



@implementation ZGImageRecyclePlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    // 至关重要
    self.view.frame = self.viewFrame;
    
    UIScrollView *sv = [[UIScrollView alloc] init];
    self.sv = sv;
 
    sv.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    //    sv.backgroundColor = [UIColor redColor];
    sv.pagingEnabled = YES;
    sv.bounces = NO;
    sv.contentOffset = CGPointMake(sv.frame.size.width, 0);
    sv.showsHorizontalScrollIndicator = NO;
    sv.delegate = self;
    [sv addObserver:self forKeyPath:OBJKEY(sv, contentOffset) options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(sv.frame.size.width, 0, sv.frame.size.width, sv.frame.size.height)];
    self.curImageView = imgView;
    
    imgView.backgroundColor = [UIColor whiteColor];
    
    [sv addSubview:imgView];
    
    sv.contentSize = CGSizeMake(sv.frame.size.width * (sv.subviews.count + 2), 0);
    
    [self.view addSubview:sv];
    
    /** pageControl */
    UIPageControl *pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, sv.frame.size.height - 20, sv.frame.size.width, 20)];
    self.pageControl = pageControl;
    
    pageControl.pageIndicatorTintColor = [UIColor grayColor];
    pageControl.numberOfPages = 3;
    
    /** pageControl 居中*/
    pageControl.hidesForSinglePage = YES;
    //        pageControl.contentMode = UIViewContentModeCenter;
    //        pageControl.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [self.view addSubview:pageControl];
    
    
    
    self.stopFlag = YES;
    
    self.leftFlag = YES;
    
    self.rightFlag = YES;
    
    self.pageFlag = NO;
    
    self.imageIndex = 0;
    
#ifdef TIMERON
    [self timerStart];
#endif
    
}


+ (instancetype)imageRecyclePlayerViewControllerWithImages:(NSArray *)images Frame:(CGRect)frame
{
    ZGImageRecyclePlayerViewController *recycleViewControler = [[ZGImageRecyclePlayerViewController alloc] init];
    
    recycleViewControler.images = images;
    recycleViewControler.viewFrame = frame;
    
    return recycleViewControler;
}

- (void)dealloc
{
    [self.sv removeObserver:self forKeyPath:OBJKEY(self.sv, contentOffset)];
}

- (void)viewWillAppear:(BOOL)animated
{
    
    if (self.images.count) {
        
        self.curImageView.image = self.images[0];
    }
    self.pageControl.numberOfPages = self.images.count;
    if (self.images.count <= 1) {
#ifdef TIMERON
        [self timerStop];
#endif
        self.sv.delegate = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [self.sv removeObserver:self forKeyPath:OBJKEY(self.sv, contentOffset)];
        });
        
        self.curImageView.frame = CGRectMake(0, 0, self.sv.frame.size.width, self.sv.frame.size.height);
        self.sv.contentSize = CGSizeMake(self.sv.frame.size.width, 0);
    }
    
}


#pragma mark - lazyLoad
- (NSMutableSet *)imageViewSet
{
    if (!_imageViewSet) {
        _imageViewSet = [NSMutableSet set];
    }
    return _imageViewSet;
}

- (void)setImageIndex:(NSInteger)imageIndex
{
    NSLog(@"imageIndex %zd,images.count %zd",imageIndex,self.images.count);
    
    if (self.images.count && imageIndex >= self.images.count) {
        imageIndex = 0;
    }
    _imageIndex = imageIndex;
    
}


#pragma mark - sv.contentOffset KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([change[@"new"] CGPointValue].x  == [change[@"old"] CGPointValue].x) return;
   
     //if ( self.dragFlag && (self.sv.frame.size.width + 5) > self.sv.contentOffset.x  && (self.sv.frame.size.width -5) < self.sv.contentOffset.x  )
    if ( self.dragFlag )
    {
        //NSLog(@"sv.contentOffset.x == %f",self.sv.contentOffset.x);

        if ( self.leftFlag && self.sv.contentOffset.x < self.sv.frame.size.width ) {
            self.stopFlag = YES;
            self.leftFlag = NO;
            self.rightFlag = YES;
            
            
            if (self.tmpImageView) {
                self.stopFlag = YES;
                
                [self.imageViewSet addObject:self.tmpImageView];
                [self.tmpImageView removeFromSuperview];
                self.tmpImageView = nil;
                //        NSLog(@"contentOffset %@",NSStringFromCGPoint(self.sv.contentOffset));
                // 一定要加 因为系统的scrollView pageEnable 会把contentOffset 修改错，要把它调回来
                //[self.sv setContentOffset:CGPointMake(self.sv.frame.size.width, 0)];
                
                
            }
            NSLog(@"**********************************");

        }
        
        
        if ( self.rightFlag && self.sv.contentOffset.x > self.sv.frame.size.width ) {
            self.stopFlag = YES;
            self.rightFlag = NO;
            self.leftFlag = YES;
            
            
            if (self.tmpImageView) {
                self.stopFlag = YES;
                
                [self.imageViewSet addObject:self.tmpImageView];
                [self.tmpImageView removeFromSuperview];
                self.tmpImageView = nil;
                //        NSLog(@"contentOffset %@",NSStringFromCGPoint(self.sv.contentOffset));
                // 一定要加 因为系统的scrollView pageEnable 会把contentOffset 修改错，要把它调回来
                //[self.sv setContentOffset:CGPointMake(self.sv.frame.size.width, 0)];
                
                
            }
            NSLog(@"**********************************");
        }
        


        
        
    }
    
    if (self.stopFlag) {
        
        UIImageView *imgView = [self dequeueImageView];
        if (imgView) {
            imgView.backgroundColor = ZGRandomColor;
            NSLog(@"从缓存池取出的");
        }
        
        if(!imgView)
        {
            imgView = [[UIImageView alloc] init];
            [self.imageViewSet addObject:imgView];
            
            imgView.backgroundColor = [UIColor blackColor];
            NSLog(@"缓存池没有，要创建一个");
        }
        
        
        if ( [change[@"new"] CGPointValue].x  > [change[@"old"] CGPointValue].x) {
            NSLog(@"往左滑    <<");
            
            
            imgView.frame = CGRectMake(self.curImageView.frame.origin.x + self.sv.frame.size.width, 0, self.sv.frame.size.width, self.sv.frame.size.height);
            
            self.stopFlag = NO;
            
            // 图片顺序
            NSInteger tmpImageIndex = [self.images indexOfObject:self.curImageView.image];
            NSLog(@"curImageIndex %zd",tmpImageIndex);
            if ( ++tmpImageIndex > self.images.count -1) {
                self.imageIndex = 0;
            }else {
                self.imageIndex = tmpImageIndex;
            }
            imgView.image = self.images[self.imageIndex];
            
            self.tmpImageView = imgView;
            [self.sv addSubview:imgView];
            // 从缓存池移除
            [self.imageViewSet removeObject:self.tmpImageView];
            
            
        }else if( [change[@"new"] CGPointValue].x  < [change[@"old"] CGPointValue].x){
            NSLog(@"往右滑     >>");
            
            
            
            imgView.frame = CGRectMake(self.curImageView.frame.origin.x - self.sv.frame.size.width, 0, self.sv.frame.size.width, self.sv.frame.size.height);
            
            self.stopFlag = NO;
            
            // 图片顺序
            NSInteger tmpImageIndex = [self.images indexOfObject:self.curImageView.image];
            NSLog(@"curImageIndex %zd",tmpImageIndex);
            if ( --tmpImageIndex < 0) {
                self.imageIndex = self.images.count - 1;
            }else {
                self.imageIndex = tmpImageIndex;
            }
            imgView.image = self.images[self.imageIndex];
            self.tmpImageView = imgView;
            [self.sv addSubview:imgView];
            [self.imageViewSet removeObject:self.tmpImageView];
            
        }
    }
    
    
}


- (UIImageView *)dequeueImageView
{
    return [self.imageViewSet anyObject];
}

#pragma mark - <UIScrollViewDelegate>
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
#ifdef TIMERON
    [self timerStop];
#endif
    self.dragFlag = YES;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if(scrollView.contentOffset.x >= self.sv.frame.size.width * 0.5 && scrollView.contentOffset.x <= self.sv.frame.size.width *1.5 )
    {
        self.pageFlag = NO;
    }else{
        self.pageFlag = YES;
    }
    self.dragFlag = NO;
    NSLog(@"scrollViewDidEndDragging");
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSLog(@"self.pageFlag %zd",self.pageFlag);
    if (self.pageFlag == NO) {
        [self.imageViewSet addObject:self.tmpImageView];
        [self.tmpImageView removeFromSuperview];
        self.tmpImageView = nil;
        
        //        NSLog(@"contentOffset %@",NSStringFromCGPoint(self.sv.contentOffset));
        // 一定要加 因为系统的scrollView pageEnable 会把contentOffset 修改错，要把它调回来
        [self.sv setContentOffset:CGPointMake(self.sv.frame.size.width, 0)];
        
        
    }else{
        
        [self.imageViewSet addObject:self.curImageView];
        [self.curImageView removeFromSuperview];
        self.curImageView = self.tmpImageView;
        self.tmpImageView = nil;
        
        CGRect tmpRect = self.curImageView.frame;
        tmpRect.origin.x = self.sv.frame.size.width;
        self.curImageView.frame = tmpRect;
       // NSLog(@"self.curImageView.frame %@",NSStringFromCGRect(self.curImageView.frame));
        [self.sv setContentOffset:CGPointMake(self.sv.frame.size.width, 0)];
        
        // 已经换在左滑，右滑处理了
        // pageFlage == YES 才能加
        // self.imageIndex += 1;
    }
    
    
    
    self.pageControl.currentPage = [self.images indexOfObject:self.curImageView.image];
    self.stopFlag = YES;
#ifdef TIMERON
    [self timerStart];
#endif
    
    NSLog(@"scrollViewDidEndDecelerating");
    
    
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    
    [self.imageViewSet addObject:self.curImageView];
    [self.curImageView removeFromSuperview];
    self.curImageView = self.tmpImageView;
    self.tmpImageView = nil;
    
    CGRect tmpRect = self.curImageView.frame;
    tmpRect.origin.x = self.sv.frame.size.width;
    self.curImageView.frame = tmpRect;
    [self.sv setContentOffset:CGPointMake(self.sv.frame.size.width, 0)];
    
    // 已经换在左滑，右滑处理了
    //self.imageIndex += 1;
    
    self.pageControl.currentPage = [self.images indexOfObject:self.curImageView.image];
    self.stopFlag = YES;
    
    NSLog(@"scrollViewDidEndScrollingAnimation");
}

#pragma mark - Timer
- (void)timerStart
{
    self.timer = [NSTimer timerWithTimeInterval:2 target:self selector:@selector(doTimer) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)timerStop
{
    [self.timer invalidate];
}

- (void)doTimer
{
    [self.sv setContentOffset:CGPointMake(self.sv.contentOffset.x + self.sv.frame.size.width, 0) animated:YES];
}





@end
