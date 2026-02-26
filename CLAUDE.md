# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**go2shell Pro** is a macOS enhancement tool that improves upon the original go2shell by providing multiple terminal support, configurable workflows, and enhanced Finder integration. The project is currently in the planning phase with comprehensive documentation complete.

- **Language**: Swift (Tuist + SPM)
- **Platform**: macOS 14/15 (Intel + Apple Silicon)
- **Distribution**: DMG (Phase 1), Homebrew (Phase 2)

## Build Commands

Once the project is scaffolded with Tuist:

```bash
# Tuist setup and project generation
tuist install
tuist generate

# Build and archive
xcodebuild archive

# Go module management (if Go components are added)
go mod tidy
go build ./...
go test ./...
go test -cover ./...
go fmt ./...
go vet ./...
```

## Architecture

### Core Components
- **FinderSync Extension**: Captures Finder context and initiates actions
- **Host App**: Menu bar application (LSUIElement) for settings and logs
- **Core Module**: Path resolution, strategy engine, error classification
- **TerminalAdapters**: Individual terminal implementations with fallback strategies

### Communication
- **Primary**: App Group + XPC (extension ↔ main app)
- **Fallback**: Extension executes minimal actions directly when main app unavailable

### Key Protocols

```swift
// TerminalAdapter - unified interface for terminal control
protocol TerminalAdapter {
    var id: String { get }
    var displayName: String { get }
    func isInstalled() -> Bool
    func capabilities() -> TerminalCapabilities
    func open(paths: [URL], mode: OpenMode, command: String?) -> ExecutionResult
}

// OpenMode - how to open terminal
enum OpenMode {
    case newWindow
    case newTab
    case reuseCurrent
}
```

### Terminal Adapter Layers (reliability hierarchy)
1. **Layer A**: Official CLI (most stable, preferred)
2. **Layer B**: URL Scheme
3. **Layer C**: `open -a <App> <path>` (universal fallback)
4. **Layer D**: AppleScript (only when tab/window control required)

### Terminal Support Matrix

| Terminal | Priority | Primary Method | Fallback |
|----------|----------|----------------|----------|
| Terminal | P0 | AppleScript/CLI | `open -a Terminal` |
| iTerm2 | P0 | AppleScript | `open -a iTerm` |
| Warp | P0 | URL/CLI | `open -a Warp` |
| Kaku | P1 | `kaku cli spawn` | `open -a Kaku` |
| WezTerm | P1 | `wezterm start --cwd` | `open -a WezTerm` |
| Ghostty | P1 | URL/CLI | `open -a Ghostty` |

- **P0**: Must pass real device testing in v0.1.0
- **P1**: Fallback must work at minimum

## Project Structure (Planned)

```
Apps/Go2ShellProApp          # Main app (settings, menu bar, logs)
Extensions/FinderSyncExtension  # Finder extension entry point
Packages/Core                # Path resolution, action executor, logging
Packages/TerminalAdapters    # Terminal adapter protocol and implementations
Packages/Shared              # Models and App Group communication protocol
```

## Finder Entry Points (Priority Order)

1. **Toolbar button** (highest priority, required for v0.1.0)
2. **Right-click menu** (secondary)
3. **Service menu** (optional, evaluate at end of Phase 1)

## Default Behaviors

- **Multi-selection across directories**: Default to multiple windows (user configurable)
- **Multi-selection same directory**: Aggregate to single directory open
- **File selected**: Auto-resolve to parent directory
- **Success feedback**: Silent by default (optional debug notifications)
- **Failure feedback**: Must be visible with actionable guidance

## Workflow Orchestration

### 1. Planning by Default
- For any non-trivial task (3+ steps or architectural decisions), enter planning mode
- If things go off track, stop immediately and re-plan—don't push through
- Planning mode is for validation too, not just building phases
- Write detailed specs upfront to reduce ambiguity

### 2. Subagent Strategy
- Freely use subagents to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, invest more compute via subagents
- Each subagent focuses on a single task

### 3. Self-Improvement Loop
- After any user correction: update patterns to `tasks/lessons.md`
- Write rules for yourself to prevent repeating the same mistakes
- Ruthlessly iterate on these lessons until error rate drops
- Review lessons relevant to current project at session start

### 4. Verify Before Completion
- Never mark a task complete without proving it works
- Compare main version vs your modified behavior where relevant
- Ask yourself: "Would a senior engineer accept this?"
- Run tests, check logs, prove correctness

### 5. Pursue Elegance (Balance)
- For non-trivial changes: pause and ask "Is there a more elegant way?"
- If a fix feels like a band-aid: "Given everything I now know, implement an elegant solution"
- Skip this for simple, obvious fixes—don't over-engineer
- Challenge your work before completion

### 6. Autonomous Bug Fixing
- When receiving a bug report: fix it directly, don't seek hand-holding
- Point to logs, errors, failed tests—then resolve them
- User shouldn't need to context switch
- Proactively fix failing CI tests without being told how

## Task Management

7. **Plan first**: Write plan to `tasks/todo.md` with checkable items
8. **Validate plan**: Confirm before starting implementation
9. **Track progress**: Mark items when completed
10. **Explain changes**: Provide high-level summary at each step
11. **Record results**: Add review section in `tasks/todo.md`
12. **Capture lessons**: Update `tasks/lessons.md` after corrections

## Core Principles

- **Simplicity first**: Make each change as simple as possible, affecting minimal code
- **No shortcuts**: Find root causes, no band-aid fixes, maintain senior developer standards
- **Minimal impact**: Changes should touch only what's necessary, avoid introducing bugs

## Release Pipeline (DMG)

Release gates (all must pass before release):
1. Feature complete
2. Integration testing passed (Finder extension + main app + terminal adapters)
3. Regression testing passed

CI stages:
```bash
tuist install && tuist generate
xcodebuild archive
# Export .app, generate .zip and .dmg
# Developer ID signing + notarization
# Gatekeeper verification
```

Pre-release verification:
```bash
codesign --verify --deep --strict --verbose=2 <App.app>
spctl --assess --type execute --verbose <App.app>
xcrun stapler validate <App.app>
```

## Key Constraints

- **No cloud telemetry**: Logs are local only
- **Command templates**: Disabled by default; show risk warning when enabled (shell injection boundary)
- **Performance target**: P95 response time < 1000ms
- **Concurrency**: Serial queue for action execution (prevent window storms)
- **Debounce**: 500ms for same directory operations
- **Timeout**: 3s per adapter execution, then fallback

## Documentation

- Product plan: `docs/go2shell-pro-plan.md`
- Technical design: `docs/go2shell-pro-technical-design.md`
- Interaction spec: `docs/go2shell-pro-interaction-spec.md`
- Terminal matrix: `docs/go2shell-pro-terminal-matrix.md`
