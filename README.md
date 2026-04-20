# NoSpotifyLyrics

A tweak to remove autoscrolling lyrics, cluttered UI and the 'switch to video' elements on Spotify for iOS 15 (and below?). Meaning the 'now playing' view is pretty much as clean as Apple Music's. I want to use the iPad as a giant Tesla-esque satnav in the car, with music playing in split view. But the autoscrolling lyrics were a pain, and cannot be disabled in the app on such a low Spotify version. My guess is they rolled out the UI change in Electron and pushed it to all devices, but since the verison compatible with iOS 15 is ancient at this point, the option to disable (which is present in later versions) isn't there, and never will be. Driving with lyrics constalty updating is a distraction!

## Features

- Disabled autoscrolling lyrics shown below the album artowrk (the artwork still recedes, but nothing shows now)
- Bottom scroll cards (related content, suggested tracks, etc.) are all gone. Very messy. No thanks.
- The "Switch to video" button that appears for music video tracks is also gone.

**NOTE: This was 100% vibe coded with Claude. I admit I don't have naywhere near the technical knowledge to hook elements or do any of the magic Claude was able to. Took a lot of trial and error, but it all worked.**

## How it works (summarised by Claude):

### Hook 1 — Inline lyrics (`Lyrics_TextComponentImpl.LyricsViewControllerImplementation`)

Hooks `viewDidLayoutSubviews` on the lyrics view controller and forces the view hidden after every layout pass. This is necessary because Spotify resets visibility asynchronously after the lyrics load, so a one-time hide is not sufficient.

### Hook 2 — Bottom scroll cards (`NowPlaying_ScrollImpl.ScrollCollectionViewManagerWithDynamicSizingImplementation`)

Hooks `collectionView:numberOfItemsInSection:` to always return 0, preventing the scroll cards below the player from ever rendering.

### Hook 3 — Switch to video button (`_TtCO22NowPlaying_ElementsKit10NowPlaying6Button`)

This one took some work to figure out. The investigation process:

- The button has no dedicated ObjC class — it is a pure Swift object with no exported symbols and a stripped binary, so class-dumping and symbol enumeration returned nothing useful.
- `ObjC.classes[]` lookup by the dot-notation Swift class name (`NowPlaying_ElementsKit.AudioVideoSwitchButton`) failed at the REPL level even though the class showed up in `enumerateLoadedClassesSync()`.
- The class inherits directly from `_SwiftObject`, not from any UIKit view, meaning it is a presenter/model object rather than the view itself.
- Hit testing via `hitTest:withEvent:` on the key window returned no results, likely because the button sits behind a transparent overlay or the call was not dispatched on the main thread.
- Intercepting `UIApplication -sendEvent:` and logging the view under each touch finally identified the tapped view as `NSKVONotifying__TtCCO22NowPlaying_ElementsKit10NowPlaying6Button7Primary` — a KVO-wrapped Swift class.
- Hooking `setHidden:` on the KVO subclass hid everything, including the play button and skip controls, because the same primary button class is reused across the whole player.
- The button's `accessibilityIdentifier` (`nowplaying-npv-musicvideos-switch`) provided a reliable way to target only the video switch button.
- The KVO subclass is not registered at tweak load time (`%ctor`), so hooking it directly does not work. Hooking `layoutSubviews` on the base class `_TtCO22NowPlaying_ElementsKit10NowPlaying6Button` instead fires reliably on every layout pass, at which point the identifier check singles out the correct button and forces it hidden.

## Back to human typing

Currently only tested on a 2018 iPad Pro on iOS 15. No settings are included, it's all or nothing. Feel free to fork and add them if you like!

Completely vibe coded because like heck I'd know how to do this. Claude was able to basically brute-force its way through all the UI layers and hooks. Frida was integral to this process too!
