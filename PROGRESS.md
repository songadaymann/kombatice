# Ice Slip - Progress Log

## Project Overview
A rhythm game where the player controls Sub-Zero to shoot ice at an ICE agent, timed to the beat of the music. The game features 24 levels that cycle every 8 beats, with the target beat being the 5th beat of each 8-beat cycle (the "1" of every other measure).

## Current State: HTML Version Deployed to Vercel

**Live URL (HTML)**: https://html-version-six.vercel.app
**Test Room**: https://html-version-six.vercel.app/test.html
**Godot Version (deprecated)**: https://kombatice-nine.vercel.app
**GitHub**: https://github.com/songadaymann/kombatice

### What's Been Built

#### Game Flow (HTML Version)
1. **Loading Screen**: Sub-Zero idle animation with "KOMBAT ICE" title (red MK font with glow), loading bar, and START button
2. **Intro Phase**: Click START to play `intro-video.mp4` (initializes Web Audio context)
3. **Gameplay Phase**: After intro, switches to sprite-based levels with music (95 seconds / 1:35)
4. **Beat System**: 144 BPM, target every 8 beats (beat 5 in cycle)
5. **Shooting**: Tap/click or spacebar to fire ice - timing scored against target beat
6. **Level Cycling**: 24 background levels, each displayed for 8 beats (cycles back after 24)
7. **End Screen**: Shows score, accuracy, and breakdown - tap/click to play again

#### Project Structure
```
ice-slip/
├── html-version/              # ACTIVE - HTML5/JavaScript version
│   ├── index.html             # Main game (vanilla JS + Canvas + Web Audio API)
│   ├── test.html              # Position test room with sliders
│   ├── vercel.json            # Vercel deployment config
│   └── assets/
│       ├── intro-video.mp4    # Intro video (MP4 for web compatibility)
│       ├── agent/             # ICE agent frames (100 PNGs with alpha)
│       ├── levels/            # 24 level background images
│       ├── music/KombatIce.mp3# Gameplay music (144 BPM)
│       ├── idle/              # Sub-Zero idle animation (11 frames)
│       ├── ice/               # Ice projectile animation (6 frames)
│       ├── special/           # Sub-Zero attack animation (3 frames)
│       └── Font/              # Mortal Kombat fonts (mk2.ttf)
│
├── [DEPRECATED - Godot version below]
├── project.godot              # Godot 4.5 project file (1080x1920 portrait)
├── assets/                    # Original Godot assets
├── build/web/                 # Godot HTML5 export
├── resources/                 # Godot SpriteFrames
├── scenes/                    # Godot scenes
└── scripts/                   # Godot scripts
```

#### HTML Architecture (Layer Order Back-to-Front)
- **#game-container** - Main container (1080x1920 scaled to fit)
- **#intro-video** - HTML5 video element for intro
- **#level-bg** - Background image cycling through 24 levels
- **#ice** - Ice projectile sprite (animated, rotated 92deg)
- **#agent** - ICE agent sprite (100-frame animation at 30fps)
- **#subzero** - Sub-Zero sprite (idle + attack animations)
- **#beat-indicator** - Canvas element for beat visualization
- **#timing-label** - PERFECT/GOOD/OK/MISS feedback
- **#end-screen** - End game results panel
- **#loading-screen** - Loading screen with Sub-Zero, title, and START button
- **Audio** - Web Audio API with AudioContext for precise timing

### Input
- **Tap/Click/Spacebar**: Shoot ice (also restarts from end screen)
- **START Button**: Begins intro video (required for Web Audio context initialization)

### Beat Tracking System
- **BPM**: 144 (configurable via export)
- **Beats per cycle**: 8
- **Target beat**: 5 (the "1" of every other measure)
- **Timing windows** (in beats):
  - PERFECT: ±0.15 beats (~62ms) = +100 points
  - GOOD: ±0.3 beats (~125ms) = +50 points
  - OK: ±0.5 beats (~208ms) = +25 points
  - MISS: outside windows

### Beat Indicator UI
- **Inner circle** (filled, blue): Pulses on every beat
- **Outer ring** (white outline): Closes in over 5 beats (beats 1-5)
- Ring starts fully open at beat 1, becomes flush at target beat 5
- Ring turns gold as it approaches target
- Ring stays flush during beats 6-8 until next cycle

### Gameplay Positions (HTML Version)
- **Sub-Zero**: { x: 200, y: 1400, scale: 1.6 }
- **Ice target**: { x: 535, y: 1746, rotation: 92deg, scale: 1.7 }
- **Beat indicator**: { x: 535, y: 1746, size: 297 }
- **Agent**: { y: 500, width: 467 }

---

## What Still Needs To Be Done

### Immediate
- [ ] Fine-tune audio offset if music still feels off-beat
- [ ] Add visual feedback when agent is hit (flash, shake, etc.)

### Optional Enhancements
- [ ] Add sound effects (ice shooting, hit, miss)
- [ ] Agent reaction animation when hit
- [ ] mann.cool integration (virtual controller support)
- [ ] Custom domain for Vercel deployment

---

## Technical Notes

### Video Conversion
Godot 4 works best with .ogv (Theora) format:
```bash
ffmpeg -i input.mp4 -c:v libtheora -q:v 7 -c:a libvorbis -q:a 4 output.ogv
```

### Agent Frame Export (DaVinci Resolve)
Exported as PNG sequence with alpha transparency:
- Format: PNG
- Export Alpha: checked
- 100 frames total (agent_00108958.png to agent_00109057.png)
- Loaded at runtime into SpriteFrames at 30fps

### Level System
- 24 JPEG backgrounds loaded at runtime
- Each level displays for 8 beats (~3.33 seconds at 144 BPM)
- Total duration: 24 × 3.33s = ~80 seconds

### Audio Sync (HTML Version)
- Beat tracking uses Web Audio API `AudioContext.currentTime` for precise timing
- Unlike Godot's web export, Web Audio API provides accurate, low-latency timing
- `FIRST_BEAT_OFFSET`: Time in seconds from audio start to beat 1
- Music starts immediately when gameplay begins (after intro video ends)
- AudioContext must be initialized on user interaction (START button click)

### Test Room
A separate test.html page provides interactive position calibration:
- **URL**: https://html-version-six.vercel.app/test.html
- Sliders for all game element positions, scales, and rotations
- Drag-and-drop support for visual positioning
- "Copy Coordinates" button exports settings for CONFIG
- Live animations playing to preview positions

---

## Session Log

### Session 1 (Jan 16, 2026) - Morning
- Created Godot 4 project scaffold
- Set up 1080x1920 portrait viewport
- Created SpriteFrames resources for Sub-Zero and ice
- Converted video to .ogv format
- Extracted all video frames for reference
- Built animation system with AnimationPlayer
- Keyframed Sub-Zero's position throughout video
- Simplified to two-phase design (intro video + gameplay loop)

### Session 2 (Jan 16, 2026) - Afternoon
- Converted intro-video.mp4 and test-video.mp4 to .ogv
- Implemented beat tracking system (144 BPM)
- Added BeatIndicator with pulsing inner circle and closing outer ring
- Target beat: 5th beat of each 8-beat cycle
- Beat-relative timing windows (PERFECT/GOOD/OK/MISS)
- Added debug placement mode (P key, S to switch, click to place)
- Switched from video-based to sprite-based gameplay:
  - 24 level backgrounds (JPEG) cycling every 8 beats
  - 100-frame ICE agent animation with alpha (PNG sequence)
  - Frames loaded at runtime into SpriteFrames
- Added music (KombatIce.mp3) that plays when gameplay starts
- Fixed layer ordering: ice projectile renders below agent
- Ice resets (disappears) at start of each new cycle
- Sub-Zero properly resets to gameplay position after intro

### Session 3 (Jan 16, 2026) - Evening
- Fixed SubZero sizing: scale 5x during intro, 7x during gameplay
- Added intro special animation trigger: SubZero plays "attack" at frame 44 (~1.47s)
- Disabled debug logging at top of screen by default (debug_show_beat_info = false)
- Updated timing feedback label:
  - Font: Mortal Kombat font (mk2.ttf)
  - Size: 80px (up from 48px)
  - Wider container for larger text
- Replaced intro video with RealIntroVideo.mp4 (converted to .ogv)
- Added .gitignore and .gdignore for human-materials-ignore folder
- Added varied feedback messages:
  - PERFECT: "PERFECT!", "FLAWLESS!", "TOASTY!", "EXCELLENT!"
  - GOOD: "GOOD!", "NICE!", "SOLID!", "WELL DONE!"
  - OK: "OK", "ALMOST!", "CLOSE!", "NOT BAD"
  - MISS: "MISS", "TOO SLOW!", "TRY AGAIN!", "NOPE!"
- Added result tracking (perfect_count, good_count, ok_count, miss_count)
- Added end-game summary screen:
  - Shows "FINISH HIM!" header
  - Displays final score and breakdown of each result type
  - Shows accuracy percentage
  - Press SPACE to restart and play again
  - Uses MK font with gold text
- Re-converted intro video with audio (RealIntroVideo1.mp4)
- Fixed end screen to appear at 80 seconds (not when music stops)
- Enhanced beat indicator with color feedback:
  - Gold expanding ring on PERFECT
  - Green on GOOD
  - Cyan on OK
  - Red on MISS
- Added camera shake on MISS and OK results
- Added timing calibration system:
  - `first_beat_offset` export variable to sync beat 1
  - Press D to toggle debug beat info
  - Press T to print timing debug to console
  - Instructions in progress.md for calibration

### Session 4 (Jan 16, 2026) - Late Evening
- Updated game end time from 80 seconds (1:20) to 95 seconds (1:35)
- Added loading screen:
  - Sub-Zero idle animation (scale 10x, centered)
  - "KOMBAT ICE" title in red MK font
  - Animated red loading bar (3 second duration)
  - Loading screen shows on initial load and restart
- Set up Vercel deployment:
  - Created vercel.json with COOP/COEP headers for Godot 4 web
  - Set up Git LFS for large .pck and .wasm files
  - Created GitHub repo: github.com/songadaymann/kombatice
- Optimized build size:
  - Removed unused assets (frames/, test-video.ogv, agent-slip1.*)
  - Reduced .pck from 340MB to 118MB
- Added touch/click input support for mobile/web:
  - Tap/click now works for shooting, skipping intro, and restarting
  - Works alongside spacebar input
- Fixed audio sync for web:
  - Added AudioServer latency compensation
  - Formula: `get_playback_position() + get_time_since_last_mix() - get_output_latency()`
- Fixed beat indicator ring animation:
  - Ring now starts fully open (0%) at beat 1
  - Closes to flush (100%) at target beat 5
  - Stays flush during beats 6-8 until next cycle
  - Previous behavior started at 50% which was confusing

### Session 5 (Jan 16, 2026) - Night: HTML Rebuild
- **Major Decision**: Rebuilt entire game in HTML/JavaScript due to Godot web audio timing issues
  - Godot's `AudioServer.get_output_latency()` returns 0 on web browsers
  - Web Audio API `AudioContext.currentTime` provides precise timing
- Created `/html-version/` folder with complete vanilla JS + Canvas implementation
- Converted intro-video.ogv to MP4 for Safari compatibility
- Built test room (`test.html`) for interactive position calibration:
  - Sliders for Sub-Zero position/scale
  - Agent position/width sliders
  - Beat indicator position/size sliders
  - Ice projectile with rotation (-180 to 180) and scale controls
  - Drag-and-drop support
  - "Copy Coordinates" button for easy CONFIG export
- Calibrated game element positions from test room:
  - Sub-Zero: scale 1.6
  - Ice: rotation 92deg, scale 1.7
  - Beat indicator: x: 535, y: 1746, size: 297
  - Agent: y: 500, width: 467
- Added proper loading screen:
  - Sub-Zero idle animation (animated in JS)
  - "KOMBAT ICE" title in red MK font with glow effect
  - Loading bar that fills as assets load
  - START button (required for Web Audio context initialization)
- Copied new intro video from GADtrailers/introVIDEOWEB.mp4
- Deployed HTML version to Vercel: https://html-version-six.vercel.app
- Deprecated Godot version (still accessible at https://kombatice-nine.vercel.app)

### Deployment Notes
- **HTML version** (recommended):
  ```bash
  cd html-version && vercel --prod --yes
  ```
- Godot version has LFS issues with GitHub-based deploys
