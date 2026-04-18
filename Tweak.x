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
static void (*orig_layoutSubviews)(id self, SEL _cmd);

static void hooked_layoutSubviews(id self, SEL _cmd) {
    orig_layoutSubviews(self, _cmd);
    UIView *view = (UIView *)self;
    if ([view.accessibilityIdentifier isEqualToString:@"nowplaying-npv-musicvideos-switch"]) {
        view.hidden = YES;
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
    Class buttonClass = objc_getClass("_TtCO22NowPlaying_ElementsKit10NowPlaying6Button");
    if (buttonClass) {
        Method m = class_getInstanceMethod(buttonClass, @selector(layoutSubviews));
        orig_layoutSubviews = (void *)method_getImplementation(m);
        method_setImplementation(m, (IMP)hooked_layoutSubviews);
    }
}