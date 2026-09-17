# Loop Foundry

A Max for Live MIDI Generator for four-bar sample-chop and drum patterns in Ableton Live 12. Inspired by the repeated fragments, abrupt phrase endings, and contrasting rhythmic placement in J Dilla's **Workinonit**.

Loop Foundry uses original rules and 14 synthesized sounds. It does not contain audio from the record or a transcription of its arrangement.

## Quick start

1. Download or clone this repository and keep its folder structure intact.
2. Open **Loop Foundry Demo Project/Loop Foundry.als** in Ableton Live.
3. Launch a clip on the first track to hear the kit at 94 BPM.
4. Add the repository folder to Live's browser under **Places → Add Folder** for easy access to the device and kit.

The Live Set contains the saved working patterns. The standalone MIDI file and WAV preview demonstrate the initial generator settings. The preview was rendered offline, so envelopes and levels differ slightly from Live playback. The demo tempo is a creative starting point, not a measurement of the reference track.

## Generate a pattern

1. Load **Loop Foundry Kit.adg** onto a MIDI track.
2. Create an empty MIDI clip: **Position 1.1.1, Length 4.0.0, End 5.1.1**. Set Groove to None.
3. Open the clip and double-click **Loop Foundry 1.0.amxd** in Live's browser. It appears in the clip's **MIDI Generators** panel.
4. Click **Generate / Apply**. The result is ordinary, editable MIDI.
5. Enable **Auto** while adjusting the controls. Use **NEW** for another idea or **VARY** for changes near phrase endings.

This is a **clip MIDI Generator**, not a MIDI effect inserted into a track's device chain. No Remote Script, external plug-in, or network connection is needed to use it.

After committing a generation operation or deselecting its notes, generating again can layer notes over the existing pattern. Use an empty clip, or clear its notes before generating a replacement. Duplicate a clip first to keep a pattern you like.

## Controls

| Control | Function |
| --- | --- |
| Chop seed | Chooses the chop motif; default 1729 |
| Drum seed | Chooses drum placements and accents; default 2718 |
| Repeat | Amount of repeated chops and phrase-ending retriggers |
| Change | Tendency toward changes in bars 2 and 4, ghost notes, and accents |
| Feel | Timing differences between kicks, snares, hats, and chops; 0 is tight |
| Density | Kick and offbeat hi-hat density |
| Lock chops | Preserves chops when using NEW or VARY |
| Lock drums | Preserves drums and accents when using NEW or VARY |
| NEW | Advances unlocked seeds and resets their variation counters |
| VARY | Changes unlocked phrase endings while retaining the main motif |

Defaults: **Repeat 58 · Change 35 · Feel 42 · Density 64**. The same settings, seeds, and variation counters produce the same notes. A VARY action can sometimes leave the pattern unchanged. Locks apply to NEW and VARY; manually changing Feel or other shared controls still affects the locked part.

## Replace sounds or listen to drums only

Drag a new audio file onto the waveform of a pad's **Simpler** to replace its sound. The next note uses the new sound; no MIDI regeneration is required. Preserve the pad assignments and choke groups, and adjust the sample level as needed.

| MIDI note | Live label | Sound |
| --- | --- | --- |
| 36 / 38 | C1 / D1 | Kick / Snare |
| 42 / 46 | F#1 / A#1 | Closed / Open Hat |
| 48–55 | C2–G2, chromatically | Chop 01–08 |
| 60 / 61 | C3 / C#3 | Signal / Accent |

Chops share choke group 1, and hats share choke group 2. A new chop cuts off the previous one. Prepare eight short fragments yourself when using a longer recording; automatic audio slicing is not included.

To hear only the drums, duplicate a clip and remove notes 48–55, 60, and 61. All clips on the same track share its Drum Rack, so duplicate the **track** if you also want independent sounds.

## Requirements and limitations

Tested with **Ableton Live 12 Suite 12.4.5**, bundled **Max 9.1.5**, and macOS. The device uses Max 9's `v8.codebox`; older Max versions have not been tested.

Generation is fixed to the first four bars of a 4/4 clip. Arbitrary selection ranges, other time signatures, and full-song arrangement generation are not implemented.

Live loading, MIDI generation, kit playback, and Set saving were verified. The initial 73 generated notes matched the engine's expected pitches, timings, and velocities; demo playback peaked at approximately −6.4 dB. The current saved Set may contain later variations and edits.

The engine passes 300 deterministic-pattern checks covering bounds, duplicate note onsets, backbeats, chop overlap, and both locks. NEW/VARY processing and patch wiring were inspected; clicking those buttons in Live was not verified because of a UI automation limitation.

## Files and development

- **Loop Foundry 1.0.amxd** — self-contained generator with embedded JavaScript
- **Loop Foundry Kit.adg**, **Samples/** — Drum Rack and 14 original sounds
- **Loop Foundry Demo Project/Loop Foundry.als** — saved Live Set
- **Demo - 4 bars.mid**, **Demo - 94 BPM.wav** — initial-pattern examples
- **Loop Foundry.maxpat** — editable Max patch
- **engine.js** — generation rules and Max adapter
- **sample-map.json** — MIDI-to-sample mapping

With Node.js installed, run from the repository root:

```sh
npm test
npm run build
```

There are no npm dependencies. Edit `engine.js` for musical behavior and `Loop Foundry.maxpat` for the interface and wiring. The build embeds `engine.js` into the patch and repackages the `.amxd`; it does not regenerate the samples, Drum Rack, or Live Set. Reload the device in Live after rebuilding.

The sample references use relative paths. Move the entire repository folder together so the kit and Set can find their samples.
