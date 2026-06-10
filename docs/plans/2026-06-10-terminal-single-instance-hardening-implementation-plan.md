# Terminal Single Instance Hardening Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Harden Finder toolbar terminal launches so Ghostty, Kaku, and iTerm2 open new terminal surfaces without creating extra Dock app instances.

**Architecture:** Keep `PathBridgeLauncher` as the request entry point. Move Ghostty away from `OpenCommandLauncher` to AppleScript, move Kaku to a service-first strategy with guarded executable fallback, and add tests around launch command generation.

**Tech Stack:** Swift, AppKit, NSAppleScript, NSPasteboard Services, XCTest, Tuist/Xcode.

---

### Task 1: Ghostty AppleScript tests

**Files:**
- Modify: `Packages/TerminalAdapters/Tests/TerminalAdapterRegistryTests.swift`
- Modify: `Packages/TerminalAdapters/Sources/GhosttyAdapter.swift`

**Steps:**
1. Write failing tests for `GhosttyAdapter.makeAppleScript(mode:cwd:)`.
2. Verify the tests fail because the script builder does not exist yet.
3. Implement the minimal script builder and AppleScript runner.
4. Run the focused terminal adapter tests.

### Task 2: Kaku service and position tests

**Files:**
- Modify: `Packages/TerminalAdapters/Tests/TerminalAdapterRegistryTests.swift`
- Modify: `Packages/TerminalAdapters/Sources/KakuAdapter.swift`

**Steps:**
1. Write failing tests for Kaku service names by open mode.
2. Write failing tests that `kaku-gui start` includes `--position x,y` when available.
3. Implement service-first launch and position-aware strategy generation.
4. Add guarded long-running fallback behavior when Kaku is already running.

### Task 3: Verification and packaging readiness

**Files:**
- Modify: `tasks/todo.md`
- Modify: `tasks/lessons.md`

**Steps:**
1. Run focused terminal adapter tests.
2. Run launcher build.
3. Run local command-level checks for Ghostty and Kaku where safe.
4. Record verification evidence and lessons.
