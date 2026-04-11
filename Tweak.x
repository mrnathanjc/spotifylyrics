#import <UIKit/UIKit.h>

@interface Lyrics_TextComponentImpl_LyricsViewControllerImplementation : UIViewController
@end

%hook Lyrics_TextComponentImpl_LyricsViewControllerImplementation

- (void)viewDidLayoutSubviews {
    %orig;
    self.view.hidden = YES;
}

%end