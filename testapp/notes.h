//    if (!self.enabled)
//    {
//        [self removeAllViews];
//        return [super hitTest:point withEvent:event];
//    }
//    self.eventsCounter++;
//    if (self.eventsCounter % 2 == 0)
//    {
//        self.eventsCounter = 0;
//        return self;
//    }
//
//
//
//    if (self.touchedViews.count == 2)
//    {
//        [self removeAllViews];
//        return self;
//    }
//    UIView *view = [super hitTest:point withEvent:event];
//
//    CGRect frameOfViewInCurrentView = [view convertRect:view.frame toView:self];
//
//    if (self.selectionViews.count == 2)
//    {
//        CGRect frame1 = self.selectionViews.firstObject.frame;
//        CGRect frame2 = self.selectionViews.lastObject.frame;
//        CGRect diffFrame = CGRectMake(fabs(frame1.origin.x - frame2.origin.x),
//                                      fabs(frame1.origin.y - frame2.origin.y),
//                                      fabs(frame1.size.width + frame1.origin.x -
//                                           (frame2.size.width + frame2.origin.x)),
//                                      fabs(frame1.size.height + frame1.origin.y -
//                                           (frame2.size.height + frame2.origin.y)));
//        // | <-> |
//        if (CGRectIntersectsRect(frame1, frame2))
//        {
//            CGRect leftHorizontalDistanceViewFrame =
//            CGRectMake(MIN(frame1.origin.x, frame2.origin.x),
//                       MIN(CGRectGetMidY(frame1), CGRectGetMidY(frame2)),
//                       diffFrame.origin.x,
//                       1);
//            [self addDistanceViewWithFrame:leftHorizontalDistanceViewFrame];
//            CGRect rightHorizontalDistanceViewFrame =
//            CGRectMake(MIN(CGRectGetMaxX(frame1), CGRectGetMaxX(frame2)),
//                       MIN(CGRectGetMidY(frame1), CGRectGetMidY(frame2)),
//                       diffFrame.size.width,
//                       1);
//            [self addDistanceViewWithFrame:rightHorizontalDistanceViewFrame];
//            CGRect topVerticalDistanceViewFrame =
//            CGRectMake(MAX(CGRectGetMidX(frame1), CGRectGetMidX(frame2)),
//                       MIN(frame1.origin.y, frame2.origin.y) + 1,
//                       1,
//                       diffFrame.origin.y);
//            [self addDistanceViewWithFrame:topVerticalDistanceViewFrame];
//        } else {
//            CGRect horizontalDistanceViewFrame =
//            CGRectMake(MIN(CGRectGetMaxX(frame1),CGRectGetMaxX(frame2)),
//                       MIN(CGRectGetMidY(frame1), CGRectGetMidY(frame2)),
//                       MAX(frame1.origin.x, frame2.origin.x) - MIN(CGRectGetMaxX(frame1),CGRectGetMaxX(frame2)),
//                       1);
//            [self addDistanceViewWithFrame:horizontalDistanceViewFrame];
//        }
//    }

//- (void)addTouchedView:(UIView *)view
//{
//    if (!self.touchedViews)
//        self.touchedViews = [NSMutableArray new];
//    if ([self.touchedViews containsObject:view])
//    {
//        [self.touchedViews removeObject:view];
//    }
//    else
//        [self.touchedViews addObject:view];
//}
