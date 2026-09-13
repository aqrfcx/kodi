# Kodi Evolution for JARVIS OS

This document defines the Kodi-first evolution path for the `aqrfcx/kodi` tree.

The goal is to make Kodi a stronger, more general-purpose 10-foot entertainment shell **before** any hard integration with the JARVIS repository.

## Product direction

Kodi remains the primary user experience:

- Home
- Movies
- TV Shows
- Music
- Pictures
- Live TV / PVR
- Games
- Applications
- Browser
- Files
- Downloads
- Settings
- JARVIS (later integration)

The interface should remain remote/controller/keyboard friendly, fast, content-first, and usable on a TV as well as a desktop display.

## Upgrade pillars

### 1. Unified launcher model

Create one conceptual launcher model for applications, games, media sources and web applications. Items should expose:

- stable id
- display name
- icon/artwork
- category
- launch target
- optional arguments
- capabilities
- favorite/pinned state
- last-used timestamp

The model should not require the JARVIS backend.

### 2. Game Center

Treat games as a first-class Kodi content type rather than a collection of unrelated launchers. The future implementation should support:

- native Linux games
- Steam
- Proton/Wine launch targets
- emulators
- controller metadata
- artwork and metadata
- per-game launch arguments
- performance profiles
- recently played / favorites

Integration with individual stores must remain optional.

### 3. Browser / Web Apps

Add a first-class browser entry point without making a browser engine a hard Kodi dependency. Kodi should own the launcher, favorites and presentation layer while a browser implementation remains replaceable.

### 4. System Center

Expose a TV-friendly system dashboard for:

- CPU / memory
- storage
- network
- audio output
- display
- power state
- controllers / USB
- updates

The dashboard must not require root privileges for read-only information.

### 5. Search architecture

Evolve global search into a provider model. A search provider can contribute results from:

- media library
- files
- games
- applications
- web bookmarks
- add-ons
- future AI services

Providers should be independently enableable and should not block the UI if one provider is unavailable.

### 6. Context-aware home

The home screen should be able to surface:

- Continue Watching
- Recently Added
- Recently Played
- Recommended
- Favorites
- Installed Games
- Applications
- Music in progress

The recommendation engine must remain deterministic and local by default. AI ranking can be layered on later.

### 7. Reliability

Any new feature must fail closed and preserve the existing media-center experience. A failed browser, game launcher, metadata provider or optional service must not prevent Kodi from starting.

## JARVIS boundary

JARVIS is deliberately **not required** for these Kodi enhancements. Later, JARVIS can consume the same launcher/search/system contracts through a dedicated bridge.

This keeps Kodi useful as a standalone product and avoids coupling the media center to a particular AI runtime.

## Implementation order

1. Launcher/content abstractions
2. Global search provider interfaces
3. Game Center model and UI integration
4. System Center read-only dashboard
5. Browser/Web App launcher abstraction
6. Home recommendations and Continue Watching improvements
7. Performance/reliability instrumentation
8. JARVIS bridge as a separate integration layer

## Licensing

Kodi is GPLv2 licensed. Changes to this repository must preserve the existing license notices and third-party license requirements. Optional integrations should be isolated so their licensing does not contaminate unrelated components.
