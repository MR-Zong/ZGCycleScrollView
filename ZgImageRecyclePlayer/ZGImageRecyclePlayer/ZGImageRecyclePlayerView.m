//
//  ZGImageRecyclePlayerView.m
//  ZgImageRecyclePlayer
//
//  Created by 徐宗根 on 16/1/2.
//  Copyright © 2016年 XuZonggen. All rights reserved.
//

#import "ZGImageRecyclePlayerView.h"


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

@interface ZGImageRecyclePlayerView () <UIScrollViewDelegate>


/** scrollView */
@property (nonatomic,strong) UIScrollView *sv;

@property (nonatomic,strong) NSMutableSet *imageViewsMemoryCache;

@property (nonatomic,strong) UIImageView *curImageView;

@property (nonatomic,strong) UIImageView *tmpImageView;

@property (nonatomic,assign) BOOL stopFlag;

@property (nonatomic,assign) BOOL onDrag;

@property (nonatomic,assign) BOOL shouldLeftSlip;

@property (nonatomic,assign) BOOL shouldRightSlip;

@property (nonatomic,assign) BOOL pageSuccess;

@property (nonatomic,copy) NSArray *images;

@property (nonatomic,assign) NSInteger imageIndex;


/** pageContoller */
@property (nonatomic,strong) UIPageControl *pageControl;

/** timer */
@property (nonatomic,strong) NSTimer *timer;

@end



@implementation ZGImageRecyclePlayerView
+ (instancetype)imageRecyclePlayerViewWithImages:(NSArray *)images Frame:(CGRect)frame
{
    ZGImageRecyclePlayerView *recycleView = [[ZGImageRecyclePlayerView alloc] initWithFrame:frame];
    
    recycleView.images = images;
    
    return recycleView;
}


- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        /** scrollView */
        UIScrollView *sv = [[UIScrollView alloc] init];
        self.sv = sv;
        sv.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        sv.contentInset = UIEdgeInsetsMake(0, 0, 0, -sv.frame.size.width);
        sv.pagingEnabled = YES;
        sv.bounces = NO;
        sv.contentOffset = CGPointMake(sv.frame.size.width, 0);
        sv.showsHorizontalScrollIndicator = NO;
        sv.delegate = self;
        [sv addObserver:self forKeyPath:OBJKEY(sv, contentOffset) options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        
        
        /** imageView */
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(sv.frame.size.width, 0, sv.frame.size.width, sv.frame.size.height)];
        self.curImageView = imgView;
        imgView.backgroundColor = [UIColor whiteColor];
        [sv addSubview:imgView];
        
        sv.contentSize = CGSizeMake(sv.frame.size.width * (sv.subviews.count + 2), 0);
        
        [self addSubview:sv];
        
        /** pageControl */
        UIPageControl *pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, sv.frame.size.height - 20, sv.frame.size.width, 20)];
        self.pageControl = pageControl;
        
        pageControl.pageIndicatorTintColor = [UIColor grayColor];
        pageControl.numberOfPages = 3;
        pageControl.hidesForSinglePage = YES;
        [self addSubview:pageControl];
        
        
        /**参数初始化 */
        self.stopFlag = YES;
        
        self.shouldLeftSlip = YES;
        
        self.shouldRightSlip = YES;
        
        self.pageSuccess = NO;
        
        self.imageIndex = 0;
        
#ifdef TIMERON
        [self timerStart];
#endif
    
        
    }
    
    return self;
}


- (void)dealloc
{
    [self.sv removeObserver:self forKeyPath:OBJKEY(self.sv, contentOffset)];
}


#pragma mark - sv.contentOffset KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([change[@"new"] CGPointValue].x  == [change[@"old"] CGPointValue].x) return;
    
    if ( self.onDrag )
    {
        //        NSLog(@"sv.contentOffset.x == %f",self.sv.contentOffset.x);
        
        if ( self.shouldRightSlip && self.sv.contentOffset.x < self.sv.frame.size.width ) {
            self.stopFlag = YES;
            self.shouldRightSlip = NO;
            self.shouldLeftSlip = YES;
            
            if (self.tmpImageView) {
                
                [self.imageViewsMemoryCache addObject:self.tmpImageView];
                [self.tmpImageView removeFromSuperview];
                self.tmpImageView = nil;
                //        NSLog(@"contentOffset %@",NSStringFromCGPoint(self.sv.contentOffset));
                // 一定要加 因为系统的scrollView pageEnable 会把contentOffset 修改错，要把它调回来
                //[self.sv setContentOffset:CGPointMake(self.sv.frame.size.width, 0)];
                
                
            }
            NSLog(@"************shouldRightSlip**********************");
            
        }
        
        
        if ( self.shouldLeftSlip && self.sv.contentOffset.x > self.sv.frame.size.width ) {
            self.stopFlag = YES;
            self.shouldLeftSlip = NO;
            self.shouldRightSlip = YES;
            
            
            if (self.tmpImageView) {
                
                [self.imageViewsMemoryCache addObject:self.tmpImageView];
                [self.tmpImageView removeFromSuperview];
                self.tmpImageView = nil;
                //        NSLog(@"contentOffset %@",NSStringFromCGPoint(self.sv.contentOffset));
                // 一定要加 因为系统的scrollView pageEnable 会把contentOffset 修改错，要把它调回来
                //[self.sv setContentOffset:CGPointMake(self.sv.frame.size.width, 0)];
                
                
            }
            NSLog(@"************shouldLeftSlip**********************");
        }
        
        
    } // end if ( self.onDrag )
    
    if (self.stopFlag) {
        
        UIImageView *imgView = [self dequeueImageView];
        if (imgView) {
            imgView.backgroundColor = ZGRandomColor;
            NSLog(@"从缓存池取出的");
        }
        
        if(!imgView)
        {
            imgView = [[UIImageView alloc] init];
            [self.imageViewsMemoryCache addObject:imgView];
            
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
            [self.imageViewsMemoryCache removeObject:self.tmpImageView];
            
            
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
            [self.imageViewsMemoryCache removeObject:self.tmpImageView];
            
        }
    }
    
    
}


- (UIImageView *)dequeueImageView
{
    return [self.imageViewsMemoryCache anyObject];
}

#pragma mark - <UIScrollViewDelegate>
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
#ifdef TIMERON
    [self timerStop];
#endif
    self.onDrag = YES;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    self.onDrag = NO;
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    // 判断scrollView是否换页
    if(scrollView.contentOffset.x >= self.sv.frame.size.width * 0.5 && scrollView.contentOffset.x <= self.sv.frame.size.width *1.5 )
    {
        self.pageSuccess = NO;
    }else{
        self.pageSuccess = YES;
    }
    
    if (self.pageSuccess == NO) {
        [self.imageViewsMemoryCache addObject:self.tmpImageView];
        [self.tmpImageView removeFromSuperview];
        self.tmpImageView = nil;
        
        //        NSLog(@"contentOffset %@",NSStringFromCGPoint(self.sv.contentOffset));
        // 一定要加 因为系统的scrollView pageEnable 会把contentOffset 修改错，要把它调回来
        [self.sv setContentOffset:CGPointMake(self.sv.frame.size.width, 0)];
        
        
    }else{
        
        [self.imageViewsMemoryCache addObject:self.curImageView];
        [self.curImageView removeFromSuperview];
        self.curImageView = self.tmpImageView;
        self.tmpImageView = nil;
        
        CGRect tmpRect = self.curImageView.frame;
        tmpRect.origin.x = self.sv.frame.size.width;
        self.curImageView.frame = tmpRect;
        // NSLog(@"self.curImageView.frame %@",NSStringFromCGRect(self.curImageView.frame));
        [self.sv setContentOffset:CGPointMake(self.sv.frame.size.width, 0)];
        
    }
    
    
    self.pageControl.currentPage = [self.images indexOfObject:self.curImageView.image];
    self.stopFlag = YES;
#ifdef TIMERON
    [self timerStart];
#endif
    
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    
    [self.imageViewsMemoryCache addObject:self.curImageView];
    [self.curImageView removeFromSuperview];
    self.curImageView = self.tmpImageView;
    self.tmpImageView = nil;
    
    CGRect tmpRect = self.curImageView.frame;
    tmpRect.origin.x = self.sv.frame.size.width;
    self.curImageView.frame = tmpRect;
    [self.sv setContentOffset:CGPointMake(self.sv.frame.size.width, 0)];
    
    self.pageControl.currentPage = [self.images indexOfObject:self.curImageView.image];
    self.stopFlag = YES;
    
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


#pragma mark - lazyLoad
- (NSMutableSet *)imageViewsMemoryCache
{
    if (!_imageViewsMemoryCache) {
        _imageViewsMemoryCache = [NSMutableSet set];
    }
    return _imageViewsMemoryCache;
}

- (void)setImageIndex:(NSInteger)imageIndex
{
    if (self.images.count && imageIndex >= self.images.count) {
        imageIndex = 0;
    }
    _imageIndex = imageIndex;
    
}

- (void)setImages:(NSArray *)images
{
    _images = images;
    
    if (_images.count) {
        
        self.curImageView.image = _images[0];
    }
    self.pageControl.numberOfPages = _images.count;
    if (_images.count <= 1) {
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

@end
