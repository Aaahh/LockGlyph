#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioServices.h>
#import "PKGlyphView.h"
#import "LockGlyph.h"
#import "SpacemanBlocks.h"

#define kBundlePath @"/Library/Application Support/LockGlyph/Themes/"

#define TouchIDFingerUp	0
#define TouchIDFingerDown  1
#define TouchIDFingerHeld  2
#define TouchIDMatched	 3
#define TouchIDNotMatched  9

#define kDefaultPrimaryColor [[UIColor alloc] initWithRed:188/255.0f green:188/255.0f blue:188/255.0f alpha:1.0f]
#define kDefaultSecondaryColor [[UIColor alloc] initWithRed:119/255.0f green:119/255.0f blue:119/255.0f alpha:1.0f]

UIView *lockView = nil;
PKGlyphView *fingerglyph = nil;
SystemSoundID unlockSound;

BOOL authenticated;
BOOL usingGlyph;
BOOL doingScanAnimation;
BOOL doingTickAnimation;
NSBundle *themeAssets;
SMDelayedBlockHandle unlockBlock;

BOOL enabled;
BOOL useUnlockSound;
BOOL useTickAnimation;
BOOL useFasterAnimations;
BOOL vibrateOnIncorrectFinger;
BOOL shakeOnIncorrectFinger;
BOOL useShine;
UIColor *primaryColor;
UIColor *secondaryColor;
BOOL enablePortraitY;
CGFloat portraitY;
BOOL enableLandscapeY;
CGFloat landscapeY;
NSString *themeBundleName;
BOOL shouldNotDelay;

UIColor *primaryColorOverride;
UIColor *secondaryColorOverride;
BOOL overrideIsForCustomCover;

static void setPrimaryColorOverride(UIColor *color) {
  if ([primaryColorOverride isEqual:color]) {
    return;
  }
  primaryColorOverride = color;
}

static void setSecondaryColorOverride(UIColor *color) {
  if ([secondaryColorOverride isEqual:color]) {
    return;
  }
  secondaryColorOverride = color;
}

static UIColor * activePrimaryColor() {
  return primaryColorOverride ?: primaryColor;
}

static UIColor * activeSecondaryColor() {
  return secondaryColorOverride ?: secondaryColor;
}

static UIColor* parseColorFromPreferences(NSString* string) {
	NSArray *prefsarray = [string componentsSeparatedByString: @":"];
	NSString *hexString = [prefsarray objectAtIndex:0];
	double alpha = [[prefsarray objectAtIndex:1] doubleValue];

	unsigned rgbValue = 0;
	NSScanner *scanner = [NSScanner scannerWithString:hexString];
	[scanner setScanLocation:1]; // bypass '#' character
	[scanner scanHexInt:&rgbValue];
	return [[UIColor alloc] initWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:alpha];
}

static void loadPreferences() {
	CFPreferencesAppSynchronize(CFSTR("com.evilgoldfish.lockglyph"));
	enabled = !CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR("com.evilgoldfish.lockglyph")) ? YES : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR("com.evilgoldfish.lockglyph")) boolValue];
	useUnlockSound = !CFPreferencesCopyAppValue(CFSTR("useUnlockSound"), CFSTR("com.evilgoldfish.lockglyph")) ? YES : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("useUnlockSound"), CFSTR("com.evilgoldfish.lockglyph")) boolValue];
	useTickAnimation = !CFPreferencesCopyAppValue(CFSTR("useTickAnimation"), CFSTR("com.evilgoldfish.lockglyph")) ? YES : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("useTickAnimation"), CFSTR("com.evilgoldfish.lockglyph")) boolValue];
	useFasterAnimations = !CFPreferencesCopyAppValue(CFSTR("useFasterAnimations"), CFSTR("com.evilgoldfish.lockglyph")) ? NO : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("useFasterAnimations"), CFSTR("com.evilgoldfish.lockglyph")) boolValue];
	vibrateOnIncorrectFinger = !CFPreferencesCopyAppValue(CFSTR("vibrateOnIncorrectFinger"), CFSTR("com.evilgoldfish.lockglyph")) ? YES : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("vibrateOnIncorrectFinger"), CFSTR("com.evilgoldfish.lockglyph")) boolValue];
	shakeOnIncorrectFinger = !CFPreferencesCopyAppValue(CFSTR("shakeOnIncorrectFinger"), CFSTR("com.evilgoldfish.lockglyph")) ? YES : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("shakeOnIncorrectFinger"), CFSTR("com.evilgoldfish.lockglyph")) boolValue];
	useShine = !CFPreferencesCopyAppValue(CFSTR("useShine"), CFSTR("com.evilgoldfish.lockglyph")) ? YES : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("useShine"), CFSTR("com.evilgoldfish.lockglyph")) boolValue];
	primaryColor = !CFPreferencesCopyAppValue(CFSTR("primaryColor"), CFSTR("com.evilgoldfish.lockglyph")) ? kDefaultPrimaryColor : parseColorFromPreferences((__bridge id)CFPreferencesCopyAppValue(CFSTR("primaryColor"), CFSTR("com.evilgoldfish.lockglyph")));
	secondaryColor = !CFPreferencesCopyAppValue(CFSTR("secondaryColor"), CFSTR("com.evilgoldfish.lockglyph")) ? kDefaultSecondaryColor : parseColorFromPreferences((__bridge id)CFPreferencesCopyAppValue(CFSTR("secondaryColor"), CFSTR("com.evilgoldfish.lockglyph")));
	enablePortraitY = !CFPreferencesCopyAppValue(CFSTR("enablePortraitY"), CFSTR("com.evilgoldfish.lockglyph")) ? NO : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("enablePortraitY"), CFSTR("com.evilgoldfish.lockglyph")) boolValue];
	portraitY = !CFPreferencesCopyAppValue(CFSTR("portraitY"), CFSTR("com.evilgoldfish.lockglyph")) ? 0 : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("portraitY"), CFSTR("com.evilgoldfish.lockglyph")) floatValue];
	enableLandscapeY = !CFPreferencesCopyAppValue(CFSTR("enableLandscapeY"), CFSTR("com.evilgoldfish.lockglyph")) ? NO : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("enableLandscapeY"), CFSTR("com.evilgoldfish.lockglyph")) boolValue];
	landscapeY = !CFPreferencesCopyAppValue(CFSTR("landscapeY"), CFSTR("com.evilgoldfish.lockglyph")) ? 0 : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("landscapeY"), CFSTR("com.evilgoldfish.lockglyph")) floatValue];
	themeBundleName = !CFPreferencesCopyAppValue(CFSTR("currentTheme"), CFSTR("com.evilgoldfish.lockglyph")) ? @"LockGlyph-Default.bundle" : (__bridge id)CFPreferencesCopyAppValue(CFSTR("currentTheme"), CFSTR("com.evilgoldfish.lockglyph"));
	shouldNotDelay = !CFPreferencesCopyAppValue(CFSTR("shouldNotDelay"), CFSTR("com.evilgoldfish.lockglyph")) ? NO : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("shouldNotDelay"), CFSTR("com.evilgoldfish.lockglyph")) boolValue];

	NSURL *bundleURL = [[NSURL alloc] initFileURLWithPath:kBundlePath];
	themeAssets = nil;
	themeAssets = [[NSBundle alloc] initWithURL:[bundleURL URLByAppendingPathComponent:themeBundleName]];

	if (unlockSound)
		AudioServicesDisposeSystemSoundID(unlockSound);

	if ([[NSFileManager defaultManager] fileExistsAtPath:[themeAssets pathForResource:@"SuccessSound" ofType:@"wav"]]) {
		NSURL *pathURL = [NSURL fileURLWithPath:[themeAssets pathForResource:@"SuccessSound" ofType:@"wav"]];
		AudioServicesCreateSystemSoundID((__bridge CFURLRef) pathURL, &unlockSound);
	} else {
		NSURL *pathURL = [NSURL fileURLWithPath:@"/Library/Application Support/LockGlyph/Themes/LockGlyph-Default.bundle/SuccessSound.wav"];
		AudioServicesCreateSystemSoundID((__bridge CFURLRef) pathURL, &unlockSound);
	}
}

static void performFingerScanAnimation(void) {
	if (fingerglyph && [fingerglyph respondsToSelector:@selector(setState:animated:completionHandler:)]) {
		doingScanAnimation = YES;
		[fingerglyph setState:1 animated:YES completionHandler:^{
			doingScanAnimation = NO;
		}];
	}
}

static void resetFingerScanAnimation(void) {
	if (fingerglyph && [fingerglyph respondsToSelector:@selector(setState:animated:completionHandler:)]){
		if (fingerglyph.customImage)
			[fingerglyph setState:5 animated:YES completionHandler:nil];
		else
			[fingerglyph setState:0 animated:YES completionHandler:nil];
	}
}

static void performTickAnimation(void) {
	if (fingerglyph && [fingerglyph respondsToSelector:@selector(setState:animated:completionHandler:)]) {
		doingTickAnimation = YES;
		[fingerglyph setState:6 animated:YES completionHandler:^{
			doingTickAnimation = NO;
			fingerglyph = nil;
		}];
	}
}

static void performShakeFingerFailAnimation(void) {
	if (fingerglyph) {
		CABasicAnimation *shakeanimation = [CABasicAnimation animationWithKeyPath:@"position"];
		[shakeanimation setDuration:0.05];
		[shakeanimation setRepeatCount:4];
		[shakeanimation setAutoreverses:YES];
		[shakeanimation setFromValue:[NSValue valueWithCGPoint:CGPointMake(fingerglyph.center.x - 10, fingerglyph.center.y)]];
		[shakeanimation setToValue:[NSValue valueWithCGPoint:CGPointMake(fingerglyph.center.x + 10, fingerglyph.center.y)]];
		[[fingerglyph layer] addAnimation:shakeanimation forKey:@"position"];
	}
}

@interface SBLockScreenScrollView : UIScrollView
-(void)addShineAnimationToView:(UIView*)aView;
@end

%hook SBLockScreenScrollView

%new
- (void)lockGlyphTapHandler:(UITapGestureRecognizer *)recognizer {
	performFingerScanAnimation();
	fingerglyph.userInteractionEnabled = NO;
	if (!shouldNotDelay) {
		double delayInSeconds = 0.5;
		if (useFasterAnimations) {
			delayInSeconds = 0.4;
		}
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
			if (useTickAnimation) {
				authenticated = YES;
				performTickAnimation();

				double delayInSeconds = 1.0;
				if (useFasterAnimations) {
					delayInSeconds = 0.4;
				}
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
					if (!useTickAnimation && useUnlockSound && unlockSound) {
						AudioServicesPlaySystemSound(unlockSound);
					}
					authenticated = NO;
					[[%c(SBLockScreenManager) sharedInstance] unlockUIFromSource:0 withOptions:nil];
					resetFingerScanAnimation();
					fingerglyph.userInteractionEnabled = YES;
				});
			} else {
				[[%c(SBLockScreenManager) sharedInstance] unlockUIFromSource:0 withOptions:nil];
				resetFingerScanAnimation();
				fingerglyph.userInteractionEnabled = YES;
			}
		});
	} else {
		[[%c(SBLockScreenManager) sharedInstance] unlockUIFromSource:0 withOptions:nil];
		resetFingerScanAnimation();
		fingerglyph.userInteractionEnabled = YES;
	}
}

%new
- (void)LG_RevertUI:(NSNotification *)notification {
	setPrimaryColorOverride(nil);
	setSecondaryColorOverride(nil);
	if (enabled && usingGlyph && fingerglyph) {
		fingerglyph.primaryColor = activePrimaryColor();
		fingerglyph.secondaryColor = activeSecondaryColor();
	}
}

 %new
- (void)LG_ColorizeUI:(NSNotification *)notification {
	NSDictionary *userInfo = [notification userInfo];
	UIColor *primaryColor;
	UIColor *secondaryColor;
	if([notification.name isEqualToString:@"ColorFlowLockScreenColorizationNotification"]) {
		primaryColor = userInfo[@"PrimaryColor"];
		secondaryColor = userInfo[@"SecondaryColor"];
		overrideIsForCustomCover = NO;
	}
	else if([notification.name isEqualToString:@"CustomCoverLockScreenColourUpdateNotification"]) {
		primaryColor = userInfo[@"PrimaryColour"];
		secondaryColor = userInfo[@"SecondaryColour"];
		overrideIsForCustomCover = YES;
	}
	setPrimaryColorOverride(primaryColor);
	setSecondaryColorOverride(secondaryColor);
	if (enabled && usingGlyph && fingerglyph) {
		fingerglyph.primaryColor = activePrimaryColor();
		fingerglyph.secondaryColor = activeSecondaryColor();
	}
}

-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	%orig;
}

-(void)didMoveToWindow {
	if (!self.window) {
		fingerglyph = nil;

		// Fix to revert CustomCover override once we've been removed from the window.
		if (overrideIsForCustomCover) {
			setPrimaryColorOverride(nil);
			setSecondaryColorOverride(nil);
		}
		return;
	}

	if (enabled) {
		// So we don't receive multiple notifications from over registering.
		NSString *CFRevert = @"ColorFlowLockScreenColorReversionNotification";
		NSString *CFColor = @"ColorFlowLockScreenColorizationNotification";
		NSString *CCRevert = @"CustomCoverLockScreenColourResetNotification";
		NSString *CCColor = @"CustomCoverLockScreenColourUpdateNotification";
		[[NSNotificationCenter defaultCenter] removeObserver:self name:CFRevert object:nil];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:CFColor object:nil];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:CCRevert object:nil];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:CCColor object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(LG_RevertUI:)
												 name:CFRevert
											   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(LG_ColorizeUI:)
													 name:CFColor
												   object:nil];
	   [[NSNotificationCenter defaultCenter] addObserver:self
											selector:@selector(LG_RevertUI:)
												name:CCRevert
											  object:nil];
	   [[NSNotificationCenter defaultCenter] addObserver:self
												selector:@selector(LG_ColorizeUI:)
													name:CCColor
												  object:nil];
		lockView = (UIView *)self;
		authenticated = NO;
		usingGlyph = YES;
		fingerglyph = [[%c(PKGlyphView) alloc] initWithStyle:0];
		fingerglyph.delegate = (id<PKGlyphViewDelegate>)self;
		fingerglyph.primaryColor = activePrimaryColor();
		fingerglyph.secondaryColor = activeSecondaryColor();
		if (themeAssets && ([[NSFileManager defaultManager] fileExistsAtPath:[themeAssets pathForResource:@"IdleImage" ofType:@"png"]] || [[NSFileManager defaultManager] fileExistsAtPath:[themeAssets pathForResource:@"IdleImage@2x" ofType:@"png"]])) {
			UIImage *customImage = [UIImage imageWithContentsOfFile:[themeAssets pathForResource:@"IdleImage" ofType:@"png"]];
			fingerglyph.customImage = [UIImage imageWithCGImage:customImage.CGImage scale:[UIScreen mainScreen].scale orientation:customImage.imageOrientation];
			[fingerglyph setState:5 animated:YES completionHandler:nil];
		} else {
			fingerglyph.customImage = nil;
		}
		UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(lockGlyphTapHandler:)];
		[fingerglyph addGestureRecognizer:tap];

		CGRect screen = [[UIScreen mainScreen] bounds];
		if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
			if (landscapeY == 0 || !enableLandscapeY)
				fingerglyph.center = CGPointMake(screen.size.width+CGRectGetMidX(screen),screen.size.height-60);
			else
				fingerglyph.center = CGPointMake(screen.size.height+CGRectGetMidY(screen),landscapeY);
		} else {
			if (portraitY == 0 || !enablePortraitY)
				fingerglyph.center = CGPointMake(screen.size.width+CGRectGetMidX(screen),screen.size.height-60);
			else
				fingerglyph.center = CGPointMake(screen.size.width+CGRectGetMidX(screen),portraitY);
		}
		if (useShine) {
			[self addShineAnimationToView:fingerglyph];
		}
		[[[[%c(SBLockScreenManager) sharedInstance] lockScreenViewController] lockScreenView] setSlideToUnlockHidden:YES forRequester:@"com.evilgoldfish.lockglyph"];
		[self addSubview:fingerglyph];
	}
}

/* Not my method, taken from this Stack Overflow
answer:
http://stackoverflow.com/a/26081621
*/
%new
-(void)addShineAnimationToView:(UIView*)aView
{
	CAGradientLayer *gradient = [CAGradientLayer layer];
	[gradient setStartPoint:CGPointMake(0, 0)];
	[gradient setEndPoint:CGPointMake(1, 0)];
	gradient.frame = CGRectMake(0, 0, aView.bounds.size.width*3, aView.bounds.size.height);
	float lowerAlpha = 0.78;
	gradient.colors = [NSArray arrayWithObjects:
					   (id)[[UIColor colorWithWhite:1 alpha:lowerAlpha] CGColor],
					   (id)[[UIColor colorWithWhite:1 alpha:lowerAlpha] CGColor],
					   (id)[[UIColor colorWithWhite:1 alpha:1.0] CGColor],
					   (id)[[UIColor colorWithWhite:1 alpha:1.0] CGColor],
					   (id)[[UIColor colorWithWhite:1 alpha:1.0] CGColor],
					   (id)[[UIColor colorWithWhite:1 alpha:lowerAlpha] CGColor],
					   (id)[[UIColor colorWithWhite:1 alpha:lowerAlpha] CGColor],
					   nil];
	gradient.locations = [NSArray arrayWithObjects:
						  [NSNumber numberWithFloat:0.0],
						  [NSNumber numberWithFloat:0.4],
						  [NSNumber numberWithFloat:0.45],
						  [NSNumber numberWithFloat:0.5],
						  [NSNumber numberWithFloat:0.55],
						  [NSNumber numberWithFloat:0.6],
						  [NSNumber numberWithFloat:1.0],
						  nil];

	CABasicAnimation *theAnimation;
	theAnimation=[CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
	theAnimation.duration = 2;
	theAnimation.repeatCount = INFINITY;
	theAnimation.autoreverses = NO;
	theAnimation.removedOnCompletion = NO;
	theAnimation.fillMode = kCAFillModeForwards;
	theAnimation.fromValue=[NSNumber numberWithFloat:-aView.frame.size.width*2];
	theAnimation.toValue=[NSNumber numberWithFloat:0];
	[gradient addAnimation:theAnimation forKey:@"animateLayer"];

	aView.layer.mask = gradient;
}

%new(v@:@c)
- (void)glyphView:(PKGlyphView *)arg1 revealingCheckmark:(BOOL)arg2 {
	if (useUnlockSound && useTickAnimation && unlockSound) {
		AudioServicesPlaySystemSound(unlockSound);
	}
}

%end

%hook PKFingerprintGlyphView

-(void)_setProgress:(double)arg1 withDuration:(double)arg2 forShapeLayerAtIndex:(unsigned long long)arg {
	if (lockView && enabled && useFasterAnimations && usingGlyph && (doingTickAnimation || doingScanAnimation)) {
		if (authenticated) {
			arg2 = MIN(arg2, 0.1);
		} else {
			arg1 = MIN(arg1, 0.8);
			arg2 *= 0.5;
		}
	}
	%orig;
}

- (double)_minimumAnimationDurationForStateTransition {
	return authenticated && useFasterAnimations && usingGlyph && (doingTickAnimation || doingScanAnimation) ? 0.1 : %orig;
}

%end

@interface SBAssistantController : NSObject
+(BOOL)isAssistantVisible;
@end

%hook SBLockScreenManager

- (void)_bioAuthenticated:(id)arg1 {
	if ([%c(SBAssistantController) isAssistantVisible] || self.bioAuthenticatedWhileMenuButtonDown) {
		if (unlockBlock)
			cancel_delayed_block(unlockBlock);
		return;
	}
	if (lockView && self.isUILocked && enabled && !authenticated && !shouldNotDelay && ![[self lockScreenViewController] isPasscodeLockVisible]) {
		fingerglyph.userInteractionEnabled = NO;
		authenticated = YES;
		performTickAnimation();

		double delayInSeconds = 1.3;
		if (!useTickAnimation) {
			delayInSeconds = 0.3;
		}
		if (useFasterAnimations) {
			delayInSeconds = 0.5;
			if (!useTickAnimation) {
				delayInSeconds = 0.1;
			}
		}
		unlockBlock = perform_block_after_delay(delayInSeconds, ^(void){
			if (!useTickAnimation && useUnlockSound && unlockSound) {
				AudioServicesPlaySystemSound(unlockSound);
			}
			if (fingerglyph) {
				fingerglyph.userInteractionEnabled = YES;
				fingerglyph.delegate = nil;
				lockView = nil;
			}
			%orig;
		});
	} else {
		if (self.bioAuthenticatedWhileMenuButtonDown)
			return;

		%orig;
		if (!self.isUILocked) {
			if (!useTickAnimation && useUnlockSound && unlockSound && shouldNotDelay) {
				AudioServicesPlaySystemSound(unlockSound);
			}
			fingerglyph = nil;
		}
	}
}

-(void)_finishUIUnlockFromSource:(int)source withOptions:(id)options {
	if (fingerglyph) {
		fingerglyph.delegate = nil;
		usingGlyph = NO;
		lockView = nil;
	}
	%orig;
}

- (void)biometricEventMonitor:(id)arg1 handleBiometricEvent:(unsigned long long)arg2 {
	%orig;
	//start animation
	if (lockView && self.isUILocked && enabled && !authenticated) {
		switch (arg2) {
			case TouchIDFingerDown:
				performFingerScanAnimation();
				break;
			case TouchIDFingerUp:
				resetFingerScanAnimation();
				break;
		}
	}
}

%end

%hook SBBiometricEventLogger

- (void)_tryAgain:(id)arg1 {
	%orig;
	SBLockScreenManager *manager = [%c(SBLockScreenManager) sharedInstance];
	if (lockView && manager.isUILocked && enabled && !authenticated) {
		if (shakeOnIncorrectFinger) {
			performShakeFingerFailAnimation();
		}
		if (vibrateOnIncorrectFinger) {
			AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
		}
	}
}

%end

%hook SBLockScreenViewController

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	%orig;
	CGRect screen = [[UIScreen mainScreen] bounds];
	if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
		if (landscapeY == 0 || !enableLandscapeY)
			fingerglyph.center = CGPointMake(screen.size.width+CGRectGetMidX(screen),screen.size.height-60);
		else
			fingerglyph.center = CGPointMake(screen.size.height+CGRectGetMidY(screen),landscapeY);
	} else {
		if (portraitY == 0 || !enablePortraitY)
			fingerglyph.center = CGPointMake(screen.size.width+CGRectGetMidX(screen),screen.size.height-60);
		else
			fingerglyph.center = CGPointMake(screen.size.width+CGRectGetMidX(screen),portraitY);
	}
}

%new
+(PKGlyphView *)getLockGlyphView {
	return fingerglyph;
}

%end

%hook SBLockScreenPasscodeOverlayViewController

- (void)viewWillAppear:(_Bool)arg1 {
	%orig;
	fingerglyph.hidden = YES;
}

- (void)passcodeLockViewPasscodeEnteredViaMesa:(id)arg1 {
	%orig;
	fingerglyph.hidden = NO;
}

- (void)passcodeLockViewPasscodeEntered:(id)arg1 {
	%orig;
	fingerglyph.hidden = NO;
}

%end

%hook SBAssistantController

-(void)_viewWillDisappearOnMainScreen:(BOOL)_view {
	if (fingerglyph) {
		resetFingerScanAnimation();
	}
	%orig;
}

%end

%ctor {
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
									NULL,
									(CFNotificationCallback)loadPreferences,
									CFSTR("com.evilgoldfish.lockglyph.settingschanged"),
									NULL,
									CFNotificationSuspensionBehaviorCoalesce);
	loadPreferences();
}
