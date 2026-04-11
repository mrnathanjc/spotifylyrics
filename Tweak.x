#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static void (*orig_viewDidLayoutSubviews)(id self, SEL _cmd);

static void hooked_viewDidLayoutSubviews(id self, SEL _cmd) {
    orig_viewDidLayoutSubviews(self, _cmd);
    [(UIViewController *)self].view.hidden = YES;
}

%ctor {
    Class c = objc_getClass("Lyrics_TextComponentImpl.LyricsViewControllerImplementation");
    if (c) {
        Method m = class_getInstanceMethod(c, @selector(viewDidLayoutSubviews));
        orig_viewDidLayoutSubviews = (void *)method_getImplementation(m);
        method_setImplementation(m, (IMP)hooked_viewDidLayoutSubviews);
    }
}