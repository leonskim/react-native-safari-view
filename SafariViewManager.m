
#import "SafariViewManager.h"
#import <React/RCTUtils.h>
#import <React/RCTLog.h>
#import <React/RCTConvert.h>
#import <React/RCTBundleURLProvider.h>
#import <React/RCTRootView.h>

@implementation SafariViewManager
{
    bool hasListeners;
    RCTRootView *overlayView;
}

RCT_EXPORT_MODULE()

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

- (void)startObserving
{
    hasListeners = YES;
}

- (void)stopObserving
{
    hasListeners = NO;
}

- (NSArray<NSString *> *)supportedEvents
{
    return @[@"SafariViewOnShow", @"SafariViewOnDismiss"];
}

RCT_EXPORT_METHOD(show:(NSDictionary *)args resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    // Error if no url is passed
    if (!args[@"url"]) {
        reject(@"E_SAFARI_VIEW_NO_URL", @"You must specify a url.", nil);
        return;
    }

    NSURL *url = [NSURL URLWithString:args[@"url"]];
    BOOL readerMode = [args[@"readerMode"] boolValue];
    UIColor *tintColorString = args[@"tintColor"];
    UIColor *barTintColorString = args[@"barTintColor"];
    BOOL fromBottom = [args[@"fromBottom"] boolValue];

    // Initialize the Safari View
    self.safariView = [[SFSafariViewController alloc] initWithURL:url entersReaderIfAvailable:readerMode];
    self.safariView.delegate = self;

    // Set tintColor if available
    if (tintColorString) {
        UIColor *tintColor = [RCTConvert UIColor:tintColorString];
        if ([self.safariView respondsToSelector:@selector(setPreferredControlTintColor:)]) {
            [self.safariView setPreferredControlTintColor:tintColor];
        } else {
            [self.safariView.view setTintColor:tintColor];
        }
    }

    // Set barTintColor if available
    if (barTintColorString) {
        UIColor *barTintColor = [RCTConvert UIColor:barTintColorString];
        if ([self.safariView respondsToSelector:@selector(setPreferredBarTintColor:)]) {
            [self.safariView setPreferredBarTintColor:barTintColor];
        }
    }

    // Set modal transition style
    if (fromBottom) {
        self.safariView.modalPresentationStyle = UIModalPresentationOverFullScreen;
    }

    // Add RN view as a subview
    NSString *heading = args[@"heading"];
    NSString *name = args[@"name"];
    NSString *address = args[@"formattedAddress"];
    NSString *logoUrl = args[@"logoUrl"];

    NSURL *jsCodeLocation = [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index.ios" fallbackResource:nil];
    overlayView = [[RCTRootView alloc] initWithBundleURL: jsCodeLocation
                                              moduleName:@"RetailerLoading"
                                       initialProperties:
                                           @{
                                             @"heading": heading,
                                             @"name": name,
                                             @"address": address,
                                             @"logoUrl": logoUrl,
                                             }
                                           launchOptions: nil];

    // Attach overlay view to the very front window
    [[UIApplication sharedApplication].keyWindow addSubview:overlayView];

    // get the view controller closest to the foreground
    UIViewController *ctrl = RCTPresentedViewController();
    
    // Display the Safari View
    [ctrl presentViewController:self.safariView animated:YES completion:nil];

    [overlayView.superview bringSubviewToFront: overlayView];

    if (hasListeners) {
        [self sendEventWithName:@"SafariViewOnShow" body:nil];
    }

    resolve(@YES);
}

RCT_EXPORT_METHOD(isAvailable:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    if ([SFSafariViewController class]) {
        // SafariView is available
        resolve(@YES);
    } else {
        reject(@"E_SAFARI_VIEW_UNAVAILABLE", @"SafariView is unavailable", nil);
    }
}

RCT_EXPORT_METHOD(dismiss)
{
    [self safariViewControllerDidFinish:self.safariView];
}

-(void)safariViewControllerDidFinish:(nonnull SFSafariViewController *)controller
{
    [overlayView removeFromSuperview];
    [controller dismissViewControllerAnimated:true completion:nil];
    NSLog(@"[SafariView] SafariView dismissed.");

    if (hasListeners) {
        [self sendEventWithName:@"SafariViewOnDismiss" body:nil];
    }
}

- (void)safariViewController:(SFSafariViewController *)controller didCompleteInitialLoad:(BOOL)didLoadSuccessfully
{
    [overlayView removeFromSuperview];
}
@end
