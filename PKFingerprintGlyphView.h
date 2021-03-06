//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import <UIKit/UIKit.h>

#import "PKMicaResizableView-Protocol.h"

@class CALayer, NSArray, NSMutableArray, NSString, UIColor;

@interface PKFingerprintGlyphView : UIView <PKMicaResizableView>
{
    CALayer *_backgroundLayer;
    CALayer *_foregroundLayer;
    CALayer *_foregroundRingContainerLayer;
    NSArray *_backgroundShapeLayers;
    NSArray *_foregroundShapeLayers;
    NSArray *_foregroundRingShapeLayers;
    CALayer *_maskLayer;
    CALayer *_maskForegroundLayer;
    unsigned int _transitionIndex;
    BOOL _transitioning;
    int _priorState;
    NSMutableArray *_transitionCompletionHandlers;
    double _lastAnimationWillFinish;
    BOOL _rotatingRing;
    NSString *_rotationAnimationKey;
    UIColor *_primaryColor;
    UIColor *_secondaryColor;
    int _state;
    UIView *_contentView;
}

@property(readonly, nonatomic) UIView *contentView; // @synthesize contentView=_contentView;
@property(readonly, nonatomic) int state; // @synthesize state=_state;
@property(copy, nonatomic) UIColor *secondaryColor; // @synthesize secondaryColor=_secondaryColor;
@property(copy, nonatomic) UIColor *primaryColor; // @synthesize primaryColor=_primaryColor;
- (id)pathStateForLayer:(id)arg1;
- (void)setPathState:(id)arg1 forLayer:(id)arg2;
- (void)setSecondaryColor:(id)arg1 animated:(BOOL)arg2;
- (void)setPrimaryColor:(id)arg1 animated:(BOOL)arg2;
- (void)_setProgress:(float)arg1 withDuration:(double)arg2 forShapeLayerAtIndex:(unsigned int)arg3;
- (void)setProgress:(float)arg1 withDuration:(double)arg2;
- (void)setContentViewAlpha:(float)arg1 withDuration:(double)arg2;
- (void)_endRotationAnimation;
- (void)_startRotationAnimation;
- (void)_updateRotationAnimationsIfNecessary;
- (void)_hideNonRingShapeLayersWithTransitionIndex:(unsigned int)arg1 withGap:(BOOL)arg2 animated:(BOOL)arg3;
- (void)_continueHoldingStateForPathAtIndex:(unsigned int)arg1 withTransitionIndex:(unsigned int)arg2;
- (void)_startRecognitionHoldingStateWithTransitionIndex:(unsigned int)arg1;
- (void)_showFingerprintWithTransitionIndex:(unsigned int)arg1 animated:(BOOL)arg2;
- (void)_performTransitionWithTransitionIndex:(unsigned int)arg1 animated:(BOOL)arg2;
- (void)_executeAfterMinimumAnimationDurationForStateTransition:(CDUnknownBlockType)arg1;
- (double)_minimumAnimationDurationForStateTransition;
- (void)_updateLastAnimationTimeWithAnimationOfDuration:(double)arg1;
- (void)_finishTransitionForIndex:(unsigned int)arg1;
- (void)_executeTransitionCompletionHandlers:(BOOL)arg1;
- (void)setState:(int)arg1 animated:(BOOL)arg2 completionHandler:(CDUnknownBlockType)arg3;
- (struct CGSize)boundsSizeToMatchPointScale:(float)arg1;
- (float)pointScaleToMatchBoundsSize:(struct CGSize)arg1;
- (void)layoutSubviews;
- (void)dealloc;
- (id)init;
- (id)initWithFrame:(struct CGRect)arg1;

// Remaining properties
@property(readonly, copy) NSString *debugDescription;
@property(readonly, copy) NSString *description;
@property(readonly) unsigned int hash;
@property(readonly) Class superclass;

@end

