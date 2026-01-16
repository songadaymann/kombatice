# Ice Slip - Progress Log

## Project Overview
A rhythm game where the player controls Sub-Zero to shoot ice at an ICE agent, timed to the beat of the music. The game features 24 levels that cycle every 8 beats, with the target beat being the 5th beat of each 8-beat cycle (the "1" of every other measure).

## Current State: Sprite-Based Gameplay with Beat Tracking

### What's Been Built

#### Game Flow
1. **Intro Phase**: `intro-video.ogv` plays with Sub-Zero's keyframed position animation
2. **Gameplay Phase**: After intro, switches to sprite-based levels with music
3. **Beat System**: 144 BPM, target every 8 beats (beat 5 in cycle)
4. **Shooting**: Press spacebar to fire ice - timing scored against target beat
5. **Level Cycling**: 24 background levels, each displayed for 8 beats

#### Project Structure
```
ice-slip/
├── project.godot              # Godot 4.5 project file (1080x1920 portrait)
├── assets/
│   ├── intro-video.ogv        # Intro video with Sub-Zero animation
│   ├── agent/                 # ICE agent frames (100 PNGs with alpha)
│   │   └── agent_00108958.png - agent_00109057.png
│   ├── levels/                # 24 level background images
│   │   └── level1.jpeg - level24.jpeg
│   ├── music/
│   │   └── KombatIce.mp3      # Gameplay music (144 BPM)
│   ├── idle/                  # Sub-Zero idle animation (12 frames)
│   ├── ice/                   # Ice projectile animation (6 frames)
│   └── special/               # Sub-Zero attack animation (3 frames)
├── resources/
│   ├── subzero_frames.tres    # SpriteFrames for Sub-Zero (idle + attack)
│   └── ice_frames.tres        # SpriteFrames for ice projectile
├── scenes/
│   └── main.tscn              # Main game scene
└── scripts/
    ├── game.gd                # Main game logic
    └── beat_indicator.gd      # Beat visualization (pulsing circles)
```

#### Scene Nodes (Layer Order Back-to-Front)
- **Main** (Node2D) - Root with game script
- **IntroVideo** (VideoStreamPlayer) - Plays intro-video.ogv
- **LevelBackground** (Sprite2D) - Cycles through 24 level textures
- **IceProjectile** (AnimatedSprite2D) - Ice that flies to target (below agent)
- **Agent** (AnimatedSprite2D) - ICE agent with 100-frame animation (loaded at runtime)
- **SubZero** (AnimatedSprite2D) - Player character, scale 7x
- **PositionAnimator** (AnimationPlayer) - Sub-Zero's intro animation
- **AudioPlayer** (AudioStreamPlayer) - KombatIce.mp3
- **BeatIndicator** (Node2D) - Visual beat feedback
- **UI** (CanvasLayer)
  - ScoreLabel - Debug info / score
  - TimingLabel - PERFECT/GOOD/OK/MISS feedback

### Input
- **Spacebar**: Shoot ice (also skips intro, restarts from end screen)
- **P**: Toggle placement mode (debug)
- **S**: Switch between placing Sub-Zero / ice target (in placement mode)
- **D**: Toggle debug beat info display
- **T**: Print timing debug info to console (for calibration)
- **Click**: Place selected element (in placement mode)

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
- **Outer ring** (white outline): Closes in over 8 beats
- Ring becomes flush with inner circle exactly on target beat (beat 5)
- Ring turns gold as it approaches target

### Gameplay Positions
- **Sub-Zero**: Vector2(200, 1400)
- **Ice target**: Vector2(792, 1750)

---

## What Still Needs To Be Done

### Immediate
- [ ] Fine-tune audio offset if music feels off-beat
- [ ] Test full 80-second playthrough (24 levels)
- [ ] Add visual feedback when agent is hit (flash, shake, etc.)

### Optional Enhancements
- [ ] Add touch input for mobile
- [ ] Add sound effects (ice shooting, hit, miss)
- [ ] Agent reaction animation when hit
- [ ] End game screen with final score
- [ ] mann.cool integration (virtual controller support)

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

### Audio Sync
- Beat tracking uses `AudioStreamPlayer.get_playback_position()`
- `first_beat_offset`: Time in seconds from audio start to beat 1 (adjust if beats feel early/late)
- `audio_offset`: Additional calibration for system latency
- Music starts immediately when gameplay begins

### Timing Calibration
If timing feels off:
1. Press **D** to show beat info on screen
2. Press **T** on what you feel is beat 1 to print timing info
3. Adjust `first_beat_offset` in Inspector:
   - If hits feel LATE (you're pressing too early), DECREASE the offset
   - If hits feel EARLY (you're pressing too late), INCREASE the offset
4. Common values: 0.0 to 0.5 seconds depending on the track

### Debug Placement Mode
Press P to toggle, then click to set positions. Console prints coordinates:
```
Ice target position set to: Vector2(792, 1750)
Sub-Zero position set to: Vector2(200, 1400)
```

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
