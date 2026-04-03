#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// ---------------------------------------------------------------------------
// Timer-based approach: instead of hooking into the view lifecycle (which
// races with React Native's render cycle and causes crashes on track change),
// we run a gentle repeating timer that sweeps the window hierarchy and hides
// any lyrics-related views it finds. This plays nicely with RN's recycling.
// ---------------------------------------------------------------------------

static NSArray *lyricsKeywords(void) {
    return @[
        @"lyrics",
        @"Lyrics",
        @"lyric",
        @"Lyric",
        @"lyricsPreview",
        @"lyricsTickerBar",
        @"NowPlayingLyrics",
        @"LyricsPreview",
        @"nowPlayingBar.lyrics",
        @"LyricsInterstitial",
        @"LyricsView",
        @"LyricsBar",
        @"lyricsBanner",
        @"LyricsBanner",
        @"lyricsLine",
        @"LyricsLine",
    ];
}

static BOOL isLyricsRelatedView(UIView *view) {
    if (!view) return NO;
    NSString *accId     = view.accessibilityIdentifier ?: @"";
    NSString *accLabel  = view.accessibilityLabel      ?: @"";
    NSString *className = NSStringFromClass([view class]) ?: @"";
    for (NSString *kw in lyricsKeywords()) {
        if ([accId containsString:kw] ||
            [accLabel containsString:kw] ||
            [className containsString:kw]) {
            return YES;
        }
    }
    return NO;
}

static void hideLyricsInHierarchy(UIView *root) {
    if (!root) return;
    if (isLyricsRelatedView(root)) {
        if (!root.hidden) root.hidden = YES;
        if (root.alpha != 0.0) root.alpha = 0.0;
        return;
    }
    for (UIView *sub in [root.subviews copy]) {
        hideLyricsInHierarchy(sub);
    }
}

static void sweepAllWindows(void) {
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        hideLyricsInHierarchy(window);
    }
}

// ---------------------------------------------------------------------------
// Start the timer once when the app finishes launching.
// 0.5s interval is fast enough to catch lyrics before they're visible,
// slow enough to not hammer the main thread.
// ---------------------------------------------------------------------------
%hook UIApplication

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    BOOL result = %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [NSTimer scheduledTimerWithTimeInterval:0.5
                                        target:[NSBlockOperation blockOperationWithBlock:^{ sweepAllWindows(); }]
                                      selector:@selector(main)
                                      userInfo:nil
                                       repeats:YES];
    });
    return result;
}

%end

// ---------------------------------------------------------------------------
// Also hook UIWindow makeKeyAndVisible so we catch the window being set up,
// and run an initial sweep then too.
// ---------------------------------------------------------------------------
%hook UIWindow

- (void)makeKeyAndVisible {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        sweepAllWindows();
    });
}

%end
