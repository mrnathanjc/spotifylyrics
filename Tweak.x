#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// Hook 1: Hide lyrics view
static void (*orig_viewDidLayoutSubviews)(id self, SEL _cmd);

static void hooked_viewDidLayoutSubviews(id self, SEL _cmd) {
    orig_viewDidLayoutSubviews(self, _cmd);
    UIView *view = [(UIViewController *)self view];
    view.hidden = YES;
}

// Hook 2: Remove bottom cards
static NSInteger (*orig_numberOfItemsInSection)(id self, SEL _cmd, id cv, NSInteger section);

static NSInteger hooked_numberOfItemsInSection(id self, SEL _cmd, id cv, NSInteger section) {
    return 0;
}

// Hook 3: Hide audio/video switch button only
static void (*orig_setHidden)(id self, SEL _cmd, BOOL hidden);

static void hooked_setHidden(id self, SEL _cmd, BOOL hidden) {
    UIView *view = (UIView *)self;
    if ([view.accessibilityIdentifier isEqualToString:@"nowplaying-npv-musicvideos-switch"]) {
        orig_setHidden(self, _cmd, YES);
    } else {
        orig_setHidden(self, _cmd, hidden);
    }
}

%ctor {
    // Lyrics VC
    Class lyricsClass = objc_getClass("Lyrics_TextComponentImpl.LyricsViewControllerImplementation");
    if (lyricsClass) {
        Method m = class_getInstanceMethod(lyricsClass, @selector(viewDidLayoutSubviews));
        orig_viewDidLayoutSubviews = (void *)method_getImplementation(m);
        method_setImplementation(m, (IMP)hooked_viewDidLayoutSubviews);
    }

    // Bottom cards
    Class scrollMgr = objc_getClass("NowPlaying_ScrollImpl.ScrollCollectionViewManagerWithDynamicSizingImplementation");
    if (scrollMgr) {
        Method m = class_getInstanceMethod(scrollMgr, @selector(collectionView:numberOfItemsInSection:));
        orig_numberOfItemsInSection = (void *)method_getImplementation(m);
        method_setImplementation(m, (IMP)hooked_numberOfItemsInSection);
    }

    // Audio/video switch button
    Class buttonClass = objc_getClass("NSKVONotifying__TtCCO22NowPlaying_ElementsKit10NowPlaying6Button7Primary");
    if (buttonClass) {
        Method m = class_getInstanceMethod(buttonClass, @selector(setHidden:));
        orig_setHidden = (void *)method_getImplementation(m);
        method_setImplementation(m, (IMP)hooked_setHidden);
    }
}