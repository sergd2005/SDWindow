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
        [self updateVericalDistanceViewsBetweenView1:selectionViews[i]
                                            andView2:selectionViews[i + 1]];
    }
}

- (void)updateVericalDistanceViewsBetweenView1:(UIView *)view1 andView2:(UIView *)view2
{
    CGRect frame1 = view1.frame;
    CGRect frame2 = view2.frame;
    CGRect topFrame = frame1.origin.y <= frame2.origin.y ? frame1 : frame2;
    CGRect bottomFrame = frame1.origin.y > frame2.origin.y ? frame1 : frame2;
    
    CGRect topBorderOfTopFrame = [self borderRect:SDBorderTypeTop
                                         fromRect:topFrame];
    CGRect bottomBorderOfTopFrame = [self borderRect:SDBorderTypeBottom
                                            fromRect:topFrame];
    CGRect topBorderOfBottomFrame = [self borderRect:SDBorderTypeTop
                                            fromRect:bottomFrame];
    CGRect bottomBorderOfBottomFrame = [self borderRect:SDBorderTypeBottom
                                               fromRect:bottomFrame];
    
    // case when frames do not intersect vertically
    if (bottomBorderOfTopFrame.origin.y <= topBorderOfBottomFrame.origin.y)
    {
        // in that case we build single distance view between
        // rightBorderOfLeftFrame and leftBorderOfRightFrame
        [self addVerticalDistanceViewsBetweenTopBorder:bottomBorderOfTopFrame
                                       andBottomBorder:topBorderOfBottomFrame];
    }
    else
    {   // case when frames intersecting horizontally
        // in this case we add distance views between
        // leftBorderOfLeftFrame and leftBorderOfRightFrame
        // rightBorderOfLeftFrame and rightBorderOfRightFrame
        [self addVerticalDistanceViewsBetweenTopBorder:topBorderOfTopFrame
                                       andBottomBorder:topBorderOfBottomFrame];
        // determine layout of right borders
        CGRect topBorder =
        bottomBorderOfTopFrame.origin.y <= bottomBorderOfBottomFrame.origin.y ?
        bottomBorderOfTopFrame : bottomBorderOfBottomFrame;
        CGRect bottomBorder = bottomBorderOfTopFrame.origin.y > bottomBorderOfBottomFrame.origin.y ?
        bottomBorderOfTopFrame : bottomBorderOfBottomFrame;
        [self addVerticalDistanceViewsBetweenTopBorder:topBorder
                                       andBottomBorder:bottomBorder];
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
    if (leftBorder.origin.x == rightBorder.origin.x) return;
    CGRect horizontalDistanceFrame = [self distanceFrameBetweenBorder1:leftBorder
                                                                     andBorder2:rightBorder
                                                    horizontalDistance:YES];
    [self addDistanceViewWithFrame:horizontalDistanceFrame];
    [self addBordersBetweenHorizontalDistanceViewFrame:horizontalDistanceFrame
                                             andBorder:leftBorder];
    [self addBordersBetweenHorizontalDistanceViewFrame:horizontalDistanceFrame
                                             andBorder:rightBorder];
}

- (void)addVerticalDistanceViewsBetweenTopBorder:(CGRect)topBorder
                                 andBottomBorder:(CGRect)bottomBorder
{
    if (topBorder.origin.y == bottomBorder.origin.y) return;
    CGRect verticalDistanceFrame = [self distanceFrameBetweenBorder1:topBorder
                                                               andBorder2:bottomBorder
                                                  horizontalDistance:NO];
    [self addDistanceViewWithFrame:verticalDistanceFrame];
    [self addBordersBetweenVerticalDistanceViewFrame:verticalDistanceFrame
                                           andBorder:topBorder];
    [self addBordersBetweenVerticalDistanceViewFrame:verticalDistanceFrame
                                           andBorder:bottomBorder];
}

- (void)addBordersBetweenVerticalDistanceViewFrame:(CGRect)verticalDistanceViewFrame
                                         andBorder:(CGRect)border
{
    CGRect leftFrame = verticalDistanceViewFrame.origin.x <= border.origin.x ? verticalDistanceViewFrame : border;
    CGRect rightFrame = verticalDistanceViewFrame.origin.x > border.origin.x ? verticalDistanceViewFrame : border;
    CGRect leftFrameRightBorder = [self borderRect:SDBorderTypeRight fromRect:leftFrame];
    CGRect rightFrameLeftBorder = [self borderRect:SDBorderTypeLeft fromRect:rightFrame];
    if (leftFrameRightBorder.origin.x < rightFrameLeftBorder.origin.x)
        [self addDistanceViewWithFrame:
         [self distanceFrameBetweenBorder1:leftFrameRightBorder
                                andBorder2:rightFrameLeftBorder
                        horizontalDistance:YES]];
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
         [self distanceFrameBetweenBorder1:topFrameBottomBorder
                                andBorder2:bottomFrameTopBorder
                        horizontalDistance:NO]];
}

- (CGRect)distanceFrameBetweenBorder1:(CGRect)border1
                           andBorder2:(CGRect)border2
                   horizontalDistance:(BOOL)horizontalDistance
{
    CGRect leftFrame = border1.origin.x < border2.origin.x ? border1 : border2;
    CGRect rightFrame = border1.origin.x > border2.origin.x ? border1 : border2;
    CGRect topFrame = border1.origin.y < border2.origin.y ? border1 : border2;
    CGRect bottomFrame = border1.origin.y > border2.origin.y ? border1 : border2;
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
    border1.origin.y;
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
