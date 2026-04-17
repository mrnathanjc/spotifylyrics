#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static void (*orig_viewDidLayoutSubviews)(id self, SEL _cmd);
static void hooked_viewDidLayoutSubviews(id self, SEL _cmd) {
    orig_viewDidLayoutSubviews(self, _cmd);
    UIView *view = [(UIViewController *)self view];
    view.hidden = YES;
}

static void (*orig_viewDidAppear)(id self, SEL _cmd, BOOL animated);
static void hooked_viewDidAppear(id self, SEL _cmd, BOOL animated) {
    orig_viewDidAppear(self, _cmd, animated);
    UIView *view = [(UIViewController *)self view];
    view.hidden = YES;
}

static NSInteger (*orig_numberOfItemsInSection)(id self, SEL _cmd, id cv, NSInteger section);
static NSInteger hooked_numberOfItemsInSection(id self, SEL _cmd, id cv, NSInteger section) {
    return 0;
}

%ctor {
    Class lyricsClass = objc_getClass("Lyrics_TextComponentImpl.LyricsViewControllerImplementation");
    if (lyricsClass) {
        Method m1 = class_getInstanceMethod(lyricsClass, @selector(viewDidLayoutSubviews));
        orig_viewDidLayoutSubviews = (void *)method_getImplementation(m1);
        method_setImplementation(m1, (IMP)hooked_viewDidLayoutSubviews);

        Method m2 = class_getInstanceMethod(lyricsClass, @selector(viewDidAppear:));
        orig_viewDidAppear = (void *)method_getImplementation(m2);
        method_setImplementation(m2, (IMP)hooked_viewDidAppear);
    }

    Class scrollMgr = objc_getClass("NowPlaying_ScrollImpl.ScrollCollectionViewManagerWithDynamicSizingImplementation");
    if (scrollMgr) {
        Method m = class_getInstanceMethod(scrollMgr, @selector(collectionView:numberOfItemsInSection:));
        orig_numberOfItemsInSection = (void *)method_getImplementation(m);
        method_setImplementation(m, (IMP)hooked_numberOfItemsInSection);
    }
}