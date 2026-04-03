# NoSpotifyLyrics

Disables the autoplay lyrics preview on Spotify's Now Playing view on iOS 15 (rootless jailbreak / Dopamine).

## Get the .deb without building locally

1. Fork this repo on GitHub
2. Go to **Actions** tab → **Build NoSpotifyLyrics .deb** → **Run workflow**
3. Once the action finishes, download the `.deb` from the **Artifacts** section
4. Transfer the `.deb` to your iPad and install via Dopamine/Sileo or:
   ```
   dpkg -i com.nathannw.nospotifylyrics_1.0_iphoneos-arm64.deb
   ```
5. Respring

## Build locally (needs Theos on Mac)

```bash
export THEOS=~/theos
make package FINALPACKAGE=1
# .deb ends up in packages/
```

## How it works

Three layers:

- **UIView hook** — hides any view the moment it's inserted whose class name or accessibility identifier contains lyrics-related keywords
- **UIViewController hook** — sweeps the Now Playing controller's entire view hierarchy on every layout pass
- **NSUserDefaults hook** — intercepts Spotify's feature flag keys and always returns NO/disabled for lyrics-related toggles
