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
        [self updateDistanceViewsBetweenView1:selectionViews[i]
                                     andView2:selectionViews[i + 1]
                           horizontalDistance:YES];
        [self updateDistanceViewsBetweenView1:selectionViews[i]
                                     andView2:selectionViews[i + 1]
                           horizontalDistance:NO];
    }
}

- (void)updateDistanceViewsBetweenView1:(UIView *)view1
                               andView2:(UIView *)view2
                     horizontalDistance:(BOOL)horizontalDistance
{
    CGRect leftFrame, rightFrame, topFrame, bottomFrame;
    [self compareFrame1:view1.frame
              andFrame2:view2.frame
              leftFrame:&leftFrame
             rightFrame:&rightFrame
               topFrame:&topFrame
            bottomFrame:&bottomFrame];
    
    CGRect topBorderOfTopFrame = [self borderRect:SDBorderTypeTop
                                         fromRect:topFrame];
    CGRect bottomBorderOfTopFrame = [self borderRect:SDBorderTypeBottom
                                            fromRect:topFrame];
    CGRect topBorderOfBottomFrame = [self borderRect:SDBorderTypeTop
                                            fromRect:bottomFrame];
    CGRect bottomBorderOfBottomFrame = [self borderRect:SDBorderTypeBottom
                                               fromRect:bottomFrame];
    
    CGRect leftBorderOfLeftFrame = [self borderRect:SDBorderTypeLeft
                                           fromRect:leftFrame];
    CGRect rightBorderOfLeftFrame = [self borderRect:SDBorderTypeRight
                                            fromRect:leftFrame];
    CGRect leftBorderOfRightFrame = [self borderRect:SDBorderTypeLeft
                                            fromRect:rightFrame];
    CGRect rightBorderOfRightFrame = [self borderRect:SDBorderTypeRight
                                             fromRect:rightFrame];
    
    // case when frames do not intersect vertically
    if (horizontalDistance ?
        rightBorderOfLeftFrame.origin.x <= leftBorderOfRightFrame.origin.x :
        bottomBorderOfTopFrame.origin.y <= topBorderOfBottomFrame.origin.y)
    {
        // in that case we build single distance view between
        // rightBorderOfLeftFrame and leftBorderOfRightFrame
        [self addDistanceViewsBetweenBorder1:horizontalDistance ? rightBorderOfLeftFrame : bottomBorderOfTopFrame
                                  andBorder2:horizontalDistance ? leftBorderOfRightFrame : topBorderOfBottomFrame
                          horizontalDistance:horizontalDistance];
    }
    else
    {   // case when frames intersecting horizontally
        // in this case we add distance views between
        // leftBorderOfLeftFrame and leftBorderOfRightFrame
        // rightBorderOfLeftFrame and rightBorderOfRightFrame
        [self addDistanceViewsBetweenBorder1:horizontalDistance ? leftBorderOfLeftFrame : topBorderOfTopFrame
                                  andBorder2:horizontalDistance ? leftBorderOfRightFrame : topBorderOfBottomFrame
                          horizontalDistance:horizontalDistance];
        // determine layout of right borders
        CGRect topBorder =
        bottomBorderOfTopFrame.origin.y <= bottomBorderOfBottomFrame.origin.y ?
        bottomBorderOfTopFrame : bottomBorderOfBottomFrame;
        CGRect bottomBorder = bottomBorderOfTopFrame.origin.y > bottomBorderOfBottomFrame.origin.y ?
        bottomBorderOfTopFrame : bottomBorderOfBottomFrame;
        
        CGRect leftBorder =
        rightBorderOfLeftFrame.origin.x <= rightBorderOfRightFrame.origin.x ?
        rightBorderOfLeftFrame : rightBorderOfRightFrame;
        CGRect rightBorder = rightBorderOfLeftFrame.origin.x > rightBorderOfRightFrame.origin.x ?
        rightBorderOfLeftFrame : rightBorderOfRightFrame;
        
        [self addDistanceViewsBetweenBorder1:horizontalDistance ? leftBorder : topBorder
                                  andBorder2:horizontalDistance ? rightBorder : bottomBorder
                          horizontalDistance:horizontalDistance];
    }
}

- (void)addDistanceViewsBetweenBorder1:(CGRect)border1
                            andBorder2:(CGRect)border2
                    horizontalDistance:(BOOL)horizontalDistance
{
    if (horizontalDistance ?
        border1.origin.x == border2.origin.x
        : border1.origin.y == border2.origin.y) return;
    CGRect horizontalDistanceFrame = [self distanceFrameBetweenBorder1:border1
                                                            andBorder2:border2
                                                    horizontalDistance:horizontalDistance];
    [self addDistanceViewWithFrame:horizontalDistanceFrame];
    [self addBorderBetweenDistanceViewFrame:horizontalDistanceFrame
                                  andBorder:border1
                         horizontalDistance:horizontalDistance];
    [self addBorderBetweenDistanceViewFrame:horizontalDistanceFrame
                                  andBorder:border2
                         horizontalDistance:horizontalDistance];
}

- (void)compareFrame1:(CGRect)frame1
            andFrame2:(CGRect)frame2
            leftFrame:(CGRect *)leftFrame
           rightFrame:(CGRect *)rightFrame
             topFrame:(CGRect *)topFrame
          bottomFrame:(CGRect *)bottomFrame

{
    *leftFrame = frame1.origin.x < frame2.origin.x ? frame1 : frame2;
    *rightFrame = frame1.origin.x > frame2.origin.x ? frame1 : frame2;
    *topFrame = frame1.origin.y < frame2.origin.y ? frame1 : frame2;
    *bottomFrame = frame1.origin.y > frame2.origin.y ? frame1 : frame2;
}

- (void)addBorderBetweenDistanceViewFrame:(CGRect)distanceViewFrame
                                andBorder:(CGRect)border
                       horizontalDistance:(BOOL)horizontalDistance
{
    CGRect leftFrame, rightFrame, topFrame, bottomFrame;
    [self compareFrame1:distanceViewFrame
              andFrame2:border
              leftFrame:&leftFrame
             rightFrame:&rightFrame
               topFrame:&topFrame
            bottomFrame:&bottomFrame];
    
    CGRect leftFrameRightBorder = [self borderRect:SDBorderTypeRight fromRect:leftFrame];
    CGRect rightFrameLeftBorder = [self borderRect:SDBorderTypeLeft fromRect:rightFrame];
    CGRect topFrameBottomBorder = [self borderRect:SDBorderTypeBottom fromRect:topFrame];
    CGRect bottomFrameTopBorder = [self borderRect:SDBorderTypeTop fromRect:bottomFrame];
    
    if (horizontalDistance ?
        topFrameBottomBorder.origin.y < bottomFrameTopBorder.origin.y :
        leftFrameRightBorder.origin.x < rightFrameLeftBorder.origin.x )
        [self addDistanceViewWithFrame:
         [self distanceFrameBetweenBorder1:!horizontalDistance ? leftFrameRightBorder : topFrameBottomBorder
                                andBorder2:!horizontalDistance ? rightFrameLeftBorder : bottomFrameTopBorder
                        horizontalDistance:!horizontalDistance]];
}



- (CGRect)distanceFrameBetweenBorder1:(CGRect)border1
                           andBorder2:(CGRect)border2
                   horizontalDistance:(BOOL)horizontalDistance
{
    CGRect leftFrame, rightFrame, topFrame, bottomFrame;
    [self compareFrame1:border1
              andFrame2:border2
              leftFrame:&leftFrame
             rightFrame:&rightFrame
               topFrame:&topFrame
            bottomFrame:&bottomFrame];
    
    CGRect leftFrameRightBorder = [self borderRect:SDBorderTypeRight fromRect:leftFrame];
    CGRect rightFrameLeftBorder = [self borderRect:SDBorderTypeLeft fromRect:rightFrame];
    CGRect topFrameBottomBorder = [self borderRect:SDBorderTypeBottom fromRect:topFrame];
    CGRect bottomFrameTopBorder = [self borderRect:SDBorderTypeTop fromRect:bottomFrame];
    
    CGFloat xPosition = horizontalDistance ? leftFrame.origin.x :
    (leftFrameRightBorder.origin.x < rightFrameLeftBorder.origin.x ?
     ((rightFrameLeftBorder.origin.x - leftFrameRightBorder.origin.x)/2 +
      leftFrameRightBorder.origin.x) :
     rightFrameLeftBorder.origin.x);
    CGFloat yPosition = horizontalDistance ?
    (topFrameBottomBorder.origin.y < bottomFrameTopBorder.origin.y ?
     (bottomFrameTopBorder.origin.y - topFrameBottomBorder.origin.y)/2 +
     topFrameBottomBorder.origin.y :
     bottomFrameTopBorder.origin.y) :
    topFrame.origin.y;
    return CGRectMake(xPosition,
                      yPosition,
                      !horizontalDistance ? 1 : border2.origin.x - border1.origin.x,
                      horizontalDistance ? 1 : border2.origin.y - border1.origin.y);
    
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
