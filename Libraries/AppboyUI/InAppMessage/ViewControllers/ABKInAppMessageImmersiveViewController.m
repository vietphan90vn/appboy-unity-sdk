#import "ABKInAppMessageImmersiveViewController.h"
#import "ABKInAppMessageWindowController.h"
#import "ABKUIUtils.h"

static NSInteger const CloseButtonTag = 50;

@implementation ABKInAppMessageImmersiveViewController

#pragma mark - Immersive In-App Message View UI Initialization

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.view.translatesAutoresizingMaskIntoConstraints = NO;
  self.inAppMessageHeaderLabel.text = [self getInAppMessage].header;
  self.inAppMessageHeaderLabel.textAlignment = [self getInAppMessage].headerTextAlignment;
  self.graphicImageView.contentMode = self.inAppMessage.imageContentMode;
  
  if ([self getInAppMessage].headerTextColor != nil) {
    [self.inAppMessageHeaderLabel setTextColor:[self getInAppMessage].headerTextColor];
  }
  [self changeCloseButtonColor];
  
  if ([self getInAppMessage].imageStyle == ABKInAppMessageGraphic) {
    [self setupLayoutForGraphic];
  } else {
    [self setupLayoutForTopImage];
  }
  [self setupButtons];
  if ([self getInAppMessage].frameColor != nil) {
    self.view.superview.backgroundColor = [self getInAppMessage].frameColor;
  } else {
    self.view.superview.backgroundColor = [UIColor colorWithRed:0.19
                                                          green:0.19
                                                           blue:0.19
                                                          alpha:0.75];
  }
  
  self.view.superview.accessibilityViewIsModal = YES;
  
  NSLayoutConstraint *centerYConstraint = [NSLayoutConstraint constraintWithItem:self.view
                                                                       attribute:NSLayoutAttributeCenterY
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.view.superview
                                                                       attribute:NSLayoutAttributeCenterY
                                                                      multiplier:1
                                                                        constant:0];
  centerYConstraint.priority = 999;
  [self.view.superview addConstraint:centerYConstraint];
  
  [self.view.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.view
                                                                  attribute:NSLayoutAttributeCenterX
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.view.superview
                                                                  attribute:NSLayoutAttributeCenterX
                                                                 multiplier:1
                                                                   constant:0]];
  
  self.view.alpha = 0.0f;
}

- (void)changeCloseButtonColor {
  UIView *buttonView = [self.view viewWithTag:CloseButtonTag];
  if ([buttonView isKindOfClass:[UIButton class]]) {
    UIColor *closeButtonColor = [self getInAppMessage].closeButtonColor ?
      [self getInAppMessage].closeButtonColor : [UIColor blackColor];
    UIButton *closeButton = (UIButton *)buttonView;
    UIImage *closeButtonImage = closeButton.currentImage;
    UIImage *newImage = [ABKUIUtils maskImage:closeButtonImage toColor:closeButtonColor];
    [closeButton setImage:newImage forState:UIControlStateNormal];
  }
}

- (void)setupLayoutForGraphic {
  NSLog(@"Please override method setupLayoutForGraphic: to create proper layout for graphic image style.");
}

- (void)setupLayoutForTopImage {
  NSLog(@"Please override method setupLayoutForTopImage: to create proper layout for top image style.");
}

- (void)setupButtons {
  NSArray *buttons = [self getInAppMessage].buttons;
  if (![ABKUIUtils objectIsValidAndNotEmpty:buttons]) {
    [self.leftInAppMessageButton removeFromSuperview];
    [self.rightInAppMessageButton removeFromSuperview];
    self.leftInAppMessageButton = nil;
    self.rightInAppMessageButton = nil;
    if ([self getInAppMessage].imageStyle != ABKInAppMessageGraphic) {
      UIView *bottomView = [self bottomViewWithNoButton];
      if ([ABKUIUtils objectIsValidAndNotEmpty:bottomView]) {
        NSArray *bottomConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[view]-20-|"
                                                                             options:0
                                                                             metrics:nil
                                                                               views:@{@"view" : bottomView}];
        [self.view addConstraints:bottomConstraints];
      }
    }
  } else if (buttons.count == 1) {
    [self.rightInAppMessageButton removeFromSuperview];
    self.rightInAppMessageButton = nil;
    self.leftInAppMessageButton.inAppButtonModel = buttons[0];
    NSArray *tailConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[button]-20-|"
                                                                       options:0
                                                                       metrics:nil
                                                                         views:@{@"button" : self.leftInAppMessageButton}];
    [self.view addConstraints:tailConstraints];
  } else {
    self.leftInAppMessageButton.inAppButtonModel = buttons[0];
    self.rightInAppMessageButton.inAppButtonModel = buttons[1];
  }
}

- (void)setInAppMessage:(ABKInAppMessage *)inAppMessage {
  if ([inAppMessage isKindOfClass:[ABKInAppMessageImmersive class]]) {
    super.inAppMessage = inAppMessage;
  } else {
    NSLog(@"ABKInAppMessageImmersiveViewController only accepts in-app message with type ABKInAppMessageImmersive. Setting in-app message fails.");
  }
}

- (UIView *)bottomViewWithNoButton {
  return nil;
}

#pragma mark - Animation

- (void)moveInAppMessageViewOnScreen {
  self.view.alpha = 1.0f;
}

- (void)moveInAppMessageViewOffScreen {
  self.view.alpha = 0.0f;
}

#pragma mark - Button Actions

- (IBAction)dismissInAppMessage:(id)sender {
  ABKInAppMessageWindowController *parentViewController = (ABKInAppMessageWindowController *)self.parentViewController;
  if ([parentViewController.inAppMessageUIDelegate respondsToSelector:@selector(onInAppMessageDismissed:)]) {
    [parentViewController.inAppMessageUIDelegate onInAppMessageDismissed:self.inAppMessage];
  }
  [super hideInAppMessage:self.inAppMessage.animateOut];
}

- (IBAction)buttonClicked:(ABKInAppMessageUIButton *)button {
  ABKInAppMessageWindowController *parentViewController = (ABKInAppMessageWindowController *)self.parentViewController;
  parentViewController.clickedButtonId = button.inAppButtonModel.buttonID;
  // Calls the delegate method for button click if it has been implemented.
  if ([parentViewController.inAppMessageUIDelegate respondsToSelector:@selector(onInAppMessageButtonClicked:button:)]) {
    if ([parentViewController.inAppMessageUIDelegate
           onInAppMessageButtonClicked:(ABKInAppMessageImmersive *)self.inAppMessage
                                button:button.inAppButtonModel]) {
      NSLog(@"No in-app message click action will be performed by Braze as inAppMessageUIDelegate %@ returned YES in onInAppMessageButtonClicked:", parentViewController.inAppMessageUIDelegate);
      return;
    }
  }
  [parentViewController inAppMessageClickedWithActionType:button.inAppButtonModel.buttonClickActionType
                                                      URL:button.inAppButtonModel.buttonClickedURI
                                         openURLInWebView:button.inAppButtonModel.buttonOpenUrlInWebView];
}

#pragma mark - Get In-App Message

- (ABKInAppMessageImmersive *)getInAppMessage {
  return (ABKInAppMessageImmersive *)self.inAppMessage;
}

#pragma mark - Dealloc

- (void)dealloc {
  if ([ABKUIUtils objectIsValidAndNotEmpty:[self getInAppMessage].buttons]) {
    [self.leftInAppMessageButton removeTarget:self action:nil forControlEvents:UIControlEventAllEvents];
    [self.rightInAppMessageButton removeTarget:self action:nil forControlEvents:UIControlEventAllEvents];
  }
}

@end
