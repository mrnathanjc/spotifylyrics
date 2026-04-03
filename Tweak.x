#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// Exact class names from live Frida view hierarchy dump.
// Two lyrics surfaces exist:
//   1. LyricsContainerView  — the small preview that auto-plays on the album art
//   2. CardView (Lyrics_NPVCommunicatorImpl) — the full scrollable lyrics card

static NSArray *lyricsClassNames(void) {
    return @[
        @"NowPlaying_ContentLayersImpl.LyricsContainerView",
        @"Lyrics_TextComponentImpl.LyricsView",
        @"Lyrics_NPVCommunicatorImpl.CardView",
        @"Lyrics_NPVCommunicatorImpl.LyricsOnlyView",
        @"Lyrics_NPVCommunicatorImpl.CardHeaderView",
        @"Lyrics_TextElementImpl.LyricsTextView",
        @"Lyrics_TextElementImpl.LyricsLabelsView",
        @"Lyrics_TextElementImpl.LyricsCell",
        @"Lyrics_TextComponentImpl.LyricsCell",
    ];
}

static BOOL isLyricsClass(UIView *view) {
    if (!view) return NO;
    NSString *cls = NSStringFromClass([view class]);
    for (NSString *name in lyricsClassNames()) {
        if ([cls isEqualToString:name]) return YES;
    }
    return NO;
}

static void sweepAllWindows(void) {
    UIApplication *app = [UIApplication sharedApplication];
    for (UIWindowScene *scene in app.connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) continue;
        for (UIWindow *window in [(UIWindowScene *)scene windows]) {
            // BFS sweep - faster and safer than recursion for deep RN hierarchies
            NSMutableArray *queue = [NSMutableArray arrayWithObject:window];
            while (queue.count > 0) {
                UIView *view = queue[0];
                [queue removeObjectAtIndex:0];
                if (isLyricsClass(view)) {
                    if (!view.hidden) view.hidden = YES;
                    if (view.alpha != 0.0) view.alpha = 0.0;
                    // Don't descend into lyrics views
                    continue;
                }
                [queue addObjectsFromArray:view.subviews];
            }
        }
    }
}

%hook UIApplication

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    BOOL result = %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [NSTimer scheduledTimerWithTimeInterval:0.5
                                        target:[NSBlockOperation blockOperationWithBlock:^{
            sweepAllWindows();
        }]
                                      selector:@selector(main)
                                      userInfo:nil
                                       repeats:YES];
    });
    return result;
}

%end
