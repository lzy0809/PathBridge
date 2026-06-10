# Terminal Single Instance Hardening Design

## Goal

Finder toolbar launches must create terminal windows or tabs inside the existing terminal application instance. They must not create extra macOS application instances or additional Dock icons for Ghostty, Kaku, or iTerm2.

## Constraints

- Keep the Finder toolbar and `PathBridgeLauncher` architecture unchanged.
- Do not globally rewrite `OpenCommandLauncher` behavior until each shared caller has a terminal-specific replacement.
- Prefer terminal-native control APIs over generic `/usr/bin/open`.
- Preserve existing directory behavior: the opened terminal must start in the Finder directory.
- Window offset should use native launch parameters when available, with Accessibility movement only as a fallback.

## Approach

### Ghostty

Ghostty 1.3.1 exposes a scripting dictionary with `new window`, `new tab`, and `new surface configuration`. The adapter should use AppleScript to create a surface with `initial working directory`, then create a new Ghostty window or tab through the existing application instance. This removes the current `OpenCommandLauncher` dependency and eliminates `open -n` for Ghostty.

### Kaku

Kaku 0.10.0 does not expose a usable scripting dictionary, but it registers macOS Services for `New Kaku Tab Here` and `New Kaku Window Here`. The adapter should try those services first with an `NSPasteboard` carrying the Finder directory. If Services are unavailable, fall back to the existing `kaku-gui start --cwd` strategy.

Kaku's `start --help` exposes `--position`, so new-window launches should include a position derived from the previous focused Kaku window when available. Accessibility movement remains as a fallback for service launches or when native positioning cannot be computed.

The fallback must avoid silently accepting a long-running `kaku-gui start` when Kaku is already running, because that is exactly how an accidental second GUI instance can appear. If an existing-instance handoff does not complete quickly, the adapter should fail that strategy instead of leaving a duplicate app process alive.

### iTerm2

iTerm2 already uses AppleScript and should stay on that path. The implementation only needs tests/logging to make it obvious when the `iterm2` adapter is hit and to ensure it does not regress to generic `open -n`.

## Verification

- Unit tests for pure launch builders and script generation.
- Build `PathBridgeLauncher` to verify the packaged runtime path.
- Local process-count checks before and after Finder-style launches for Ghostty and Kaku.
- Manual note: existing duplicate Dock icons from old runs must be quit before judging the new build, because the fix prevents new duplicates but cannot merge already-running extra app instances.
