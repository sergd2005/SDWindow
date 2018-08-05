//
//  SDWindow.m
//  SDWindow
//
//  Created by Sergii Dankevych on 8/4/18.
//  Copyright © 2018 sdsoft. All rights reserved.
//

#import "SDWindow.h"

typedef enum
{
    SDBorderTypeLeft = 0,
    SDBorderTypeRight,
    SDBorderTypeTop,
    SDBorderTypeBottom
} SDBorderType;

@interface SDWindow()
@property (nonatomic, strong) NSMutableDictionary <id <NSCopying>, UIView *> *selectionViews;
@property (nonatomic, strong) NSMutableArray <UIView *> *distancesViews;
@property (nonatomic, assign) NSUInteger eventsCounter;
@property (nonatomic, assign) BOOL enabled;
@end

@implementation SDWindow

- (NSUInteger)selectionViewTag
{
    return self.hash;
}

- (void)setEnabled:(BOOL)enabled
{
    if (_enabled != enabled) {
        _enabled = enabled;
        if (enabled == NO)
            [self removeAllViews];
    }
}

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake)
    {
        self.enabled = !self.enabled;
    }
}

- (CGRect)convertFrameOfView:(UIView *)view
{
    CGRect locationInView = view.frame;
    while (view.superview.superview)
    {
        locationInView = [view.superview.superview convertRect:locationInView
                                                      fromView:view.superview];
        view = view.superview;
    }
    return locationInView;
}

- (UIView *)hitTest:(CGPoint)location subviews:(NSArray <UIView *> *)subviews
{
    UIView *hittedView = nil;
    NSEnumerator *enumerator = [subviews reverseObjectEnumerator];
    UIView *view = nil;
    while ((view = [enumerator nextObject]) && !hittedView)
    {
        CGPoint locationInSubview = [self convertPoint:location toView:view];
        if (CGRectContainsPoint(view.bounds, locationInSubview) &&
            !view.hidden &&
            view.tag != self.selectionViewTag)
        {
            hittedView = [self hitTest:location subviews:view.subviews] ? : view;
        }
    };
    return hittedView;
}

- (UIView *)hitTest:(CGPoint)location
{
    return [self hitTest:location subviews:self.subviews];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    return self.enabled ? self : [super hitTest:point withEvent:event];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (!self.enabled) return;
    [touches enumerateObjectsUsingBlock:^(UITouch * _Nonnull touch, BOOL * _Nonnull stop)
     {
         CGPoint locationInWindow = [touch locationInView:self];
         [self addSelectionViewForView:[self hitTest:locationInWindow]];
         [self updateDistanceViews];
     }];
}

- (void)updateDistanceViews
{
    [self removeAllDistanceViews];
    NSArray <UIView *> *selectionViews = self.selectionViews.allValues;
    for (int i = 0; i < (int)selectionViews.count - 1; i++)
    {
        [self updateHorizontalDistanceViewsBetweenView1:selectionViews[i]
                                               andView2:selectionViews[i + 1]];
    }
}

- (void)updateHorizontalDistanceViewsBetweenView1:(UIView *)view1 andView2:(UIView *)view2
{
    CGRect frame1 = view1.frame;
    CGRect frame2 = view2.frame;
    CGRect leftFrame = frame1.origin.x <= frame2.origin.x ? frame1 : frame2;
    CGRect rightFrame = frame1.origin.x > frame2.origin.x ? frame1 : frame2;
    
    CGRect leftBorderOfLeftFrame = [self borderRect:SDBorderTypeLeft
                                           fromRect:leftFrame];
    CGRect rightBorderOfLeftFrame = [self borderRect:SDBorderTypeRight
                                            fromRect:leftFrame];
    CGRect leftBorderOfRightFrame = [self borderRect:SDBorderTypeLeft
                                            fromRect:rightFrame];
    CGRect rightBorderOfRightFrame = [self borderRect:SDBorderTypeRight
                                             fromRect:rightFrame];
    
    // case when frames do not intersect horizontally
    if (rightBorderOfLeftFrame.origin.x <= leftBorderOfRightFrame.origin.x)
    {
        // in that case we build single distance view between
        // rightBorderOfLeftFrame and leftBorderOfRightFrame
        [self addHorizontalDistanceViewsBetweenLeftBorder:rightBorderOfLeftFrame
                                           andRightBorder:leftBorderOfRightFrame];
    }
    else
    {   // case when frames intersecting horizontally
        // in this case we add distance views between
        // leftBorderOfLeftFrame and leftBorderOfRightFrame
        // rightBorderOfLeftFrame and rightBorderOfRightFrame
        [self addHorizontalDistanceViewsBetweenLeftBorder:leftBorderOfLeftFrame
                                           andRightBorder:leftBorderOfRightFrame];
        // determine layout of right borders
        CGRect leftBorder =
        rightBorderOfLeftFrame.origin.x <= rightBorderOfRightFrame.origin.x ?
        rightBorderOfLeftFrame : rightBorderOfRightFrame;
        CGRect rightBorder = rightBorderOfLeftFrame.origin.x > rightBorderOfRightFrame.origin.x ?
        rightBorderOfLeftFrame : rightBorderOfRightFrame;
        [self addHorizontalDistanceViewsBetweenLeftBorder:leftBorder
                                           andRightBorder:rightBorder];
    }
}

- (void)addHorizontalDistanceViewsBetweenLeftBorder:(CGRect)leftBorder
                                     andRightBorder:(CGRect)rightBorder
{
    CGRect horizontalDistanceFrame = [self horizontalDistanceFrameBetweenLeftBorder:leftBorder
                                                                     andRightBorder:rightBorder];
    [self addDistanceViewWithFrame:horizontalDistanceFrame];
    [self addBordersBetweenHorizontalDistanceViewFrame:horizontalDistanceFrame
                                             andBorder:leftBorder];
    [self addBordersBetweenHorizontalDistanceViewFrame:horizontalDistanceFrame
                                             andBorder:rightBorder];
}

- (void)addBordersBetweenHorizontalDistanceViewFrame:(CGRect)horizontalDistanceViewFrame
                                           andBorder:(CGRect)border
{
    CGRect topFrame = horizontalDistanceViewFrame.origin.y <= border.origin.y ? horizontalDistanceViewFrame : border;
    CGRect bottomFrame = horizontalDistanceViewFrame.origin.y > border.origin.y ? horizontalDistanceViewFrame : border;
    CGRect topFrameBottomBorder = [self borderRect:SDBorderTypeBottom fromRect:topFrame];
    CGRect bottomFrameTopBorder = [self borderRect:SDBorderTypeTop fromRect:bottomFrame];
    if (topFrameBottomBorder.origin.y < bottomFrameTopBorder.origin.y)
        [self addDistanceViewWithFrame:
         [self verticalDistanceFrameBetweenTopBorder:topFrameBottomBorder
                                     andBottomBorder:bottomFrameTopBorder]];
}

- (CGRect)verticalDistanceFrameBetweenTopBorder:(CGRect)topBorder
                                andBottomBorder:(CGRect)bottomBorder
{
    CGFloat xPosition = 0;
    CGRect leftFrame = topBorder.origin.x < bottomBorder.origin.x ? topBorder : bottomBorder;
    CGRect rightFrame = topBorder.origin.x > bottomBorder.origin.x ? topBorder : bottomBorder;
    CGRect leftFrameRightBorder = [self borderRect:SDBorderTypeRight fromRect:leftFrame];
    CGRect rightFrameLeftBorder = [self borderRect:SDBorderTypeLeft fromRect:rightFrame];
    xPosition = leftFrameRightBorder.origin.x < rightFrameLeftBorder.origin.x ?
    ((rightFrameLeftBorder.origin.x - leftFrameRightBorder.origin.x)/2 +
     rightFrameLeftBorder.origin.x) :
    rightFrameLeftBorder.origin.x;
    return CGRectMake(xPosition,
                      topBorder.origin.y,
                      1,
                      bottomBorder.origin.y - topBorder.origin.y);
}

- (CGRect)horizontalDistanceFrameBetweenLeftBorder:(CGRect)leftBorder
                                    andRightBorder:(CGRect)rightBorder
{
    CGFloat yPosition = 0;
    CGRect topFrame = leftBorder.origin.y < rightBorder.origin.y ? leftBorder : rightBorder;
    CGRect bottomFrame = leftBorder.origin.y > rightBorder.origin.y ? leftBorder : rightBorder;
    CGRect topFrameBottomBorder = [self borderRect:SDBorderTypeBottom fromRect:topFrame];
    CGRect bottomFrameTopBorder = [self borderRect:SDBorderTypeTop fromRect:bottomFrame];
    yPosition = topFrameBottomBorder.origin.y < bottomFrameTopBorder.origin.y ?
    ((bottomFrameTopBorder.origin.y - topFrameBottomBorder.origin.y)/2 +
     topFrameBottomBorder.origin.y) :
    bottomFrameTopBorder.origin.y;
    return CGRectMake(leftBorder.origin.x,
                      yPosition,
                      rightBorder.origin.x - leftBorder.origin.x,
                      1);
}

- (CGRect)borderRect:(SDBorderType)borderType fromRect:(CGRect)rect
{
    CGRect borderToReturn = CGRectZero;
    switch (borderType) {
        case SDBorderTypeLeft:
            borderToReturn = CGRectMake(rect.origin.x,
                                        rect.origin.y,
                                        1,
                                        rect.size.height);
            break;
        case SDBorderTypeRight:
            borderToReturn = CGRectMake(rect.origin.x + rect.size.width,
                                        rect.origin.y,
                                        1,
                                        rect.size.height);
            break;
        case SDBorderTypeTop:
            borderToReturn = CGRectMake(rect.origin.x,
                                        rect.origin.y,
                                        rect.size.width,
                                        1);
            break;
        case SDBorderTypeBottom:
            borderToReturn = CGRectMake(rect.origin.x,
                                        rect.origin.y + rect.size.height,
                                        rect.size.width,
                                        1);
            break;
        default:
            break;
    }
    return borderToReturn;
}

- (void)addSelectionViewForView:(UIView *)view
{
    if (!self.selectionViews)
        self.selectionViews = [NSMutableDictionary new];
    UIView *selectionView = self.selectionViews[@(view.hash)];
    if (selectionView)
    {
        [selectionView removeFromSuperview];
        [self.selectionViews removeObjectForKey:@(view.hash)];
    } else
    {
        CGRect frameOfViewInCurrentView = [self convertFrameOfView:view];
        selectionView = [[UIView alloc] initWithFrame:frameOfViewInCurrentView];
        selectionView.backgroundColor = UIColor.clearColor;
        selectionView.layer.borderWidth = 1;
        selectionView.layer.borderColor = UIColor.redColor.CGColor;
        selectionView.userInteractionEnabled = NO;
        selectionView.tag = self.selectionViewTag;
        [self addSubview:selectionView];
        self.selectionViews[@(view.hash)] = selectionView;
    }
}

- (void)addDistanceViewWithFrame:(CGRect)frame
{
    if (!self.distancesViews)
        self.distancesViews = [NSMutableArray new];
    UIView *distanceView = [[UIView alloc] initWithFrame:frame];
    distanceView.backgroundColor = UIColor.blueColor;
    [self addSubview:distanceView];
    [self.distancesViews addObject:distanceView];
}

- (void)removeAllDistanceViews
{
    [self.distancesViews enumerateObjectsUsingBlock:^(UIView * _Nonnull view,
                                                      NSUInteger idx,
                                                      BOOL * _Nonnull stop)
     {
         [view removeFromSuperview];
     }];
    [self.distancesViews removeAllObjects];
}

- (void)removeAllViews
{
    [self removeAllDistanceViews];
    [self.selectionViews enumerateKeysAndObjectsUsingBlock:^(id<NSCopying>  _Nonnull key, UIView * _Nonnull selectionView, BOOL * _Nonnull stop) {
        [selectionView removeFromSuperview];
    }];
    [self.selectionViews removeAllObjects];
}

@end
