# paracosms

> construct imaginary worlds.

![image](https://user-images.githubusercontent.com/6550035/179411170-6295d18b-ab4c-44a7-a2ae-e313dd24c0ba.png)

*paracosms* is a sampler that can playback or record synchronized audio. main features:

- can load up to **112 stereo samples**
- **samples are quantized** to a main clock and synced together
- recorded samples have **gapless playback** by crossfading post-roll
- imported samples are **automatic warped** to current bpm
- **one-shot samples can be sequenced** with euclidean sequencer
- each sample has **filters, pan+amp lfos, timestretching**
- global **tapedeck, greyhole and clouds fx** with per-sample sends 


https://vimeo.com/730684724

<details><summary><strong>why?</strong></summary><br>

between april and june 2022 I made music primarily with [scripts][], SuperCollider, sox and random pre-recorded samples from other musicians. this endeavor culminated in [an album of 100 songs][DevelopingAnAlbum]. (more on that [here][]).

eventually I got the itch to make my workflow with samples more interactive, more performable, more *real-time*. so I put together a SuperCollider class I called "[paracosms][]" which is essentially >100 synchronized turntables that can be switched between one-shots and quantized loops. initially I took a bunch of samples I collected and threw them into the grid with a thin norns wrapper around this SuperCollider paracosms class. it was [very fun][VeryFun]. 

for awhile now I've been thinking about how to record perfectly seamless loops of audio. I added [a new function to do this easily in sofcut](https://github.com/schollz/softcut-lib/tree/rec-once4). but around the time I was playing with samples I started played around with making a SuperCollider class to make a crossfading stereo recording system (like softcut). this became "[ouroborus][]".

without intending, I realized that I could combine ourborous with paracosms together into sampler/looper thing. its basically a thing that excells at recording and playing perfect audio loops. norns became the glue for these two supercollider classes - and it is now this *paracosms* script. 


</details>
<br>



## Requirements

- norns
- grid (optional)

## Documentation

![norns](https://user-images.githubusercontent.com/6550035/179410985-0ee42e5b-49e2-420d-8ef0-8107e49b42eb.jpg)

### playing

**E1 will select sample. K1+E1 will select sample *that is playing*.**

**K3 will play a sample.** 


samples in the looping mode will fade with a duration according to how long you hold K3. samples in the one-shot mode will play instantly.

### recording

**K1+K3 will prime a recording.** 

by default *paracosms* will wait to record until audio crosses a threshold to start recording. once recording is detected, it records the full length specified by the sample parameters (in beats, plus the crossfade post-roll). *paracosms* uses a latency term to capture the moments right before recording (because there is an inherent delay in starting recording after detecting it) and this can be changed in the parameters. also, you can skip waiting and **you can start recording immediately by pressing K1+K3 again.**

### parameters on the go

**K2/K1+K2 will cycle through parameters.** 

**E2/E3 or K1+(E2/E3) will modulate the current parameters.**

there are a bunch of sample-specific parameters: volume (+lfo), panning (+lfo), sample start/end, filters (low+high), fx sends, timestretching. these are all available in the `PARAMS` menu, but they are also accessible from the main screen to avoid some menu-diving. us K2 to cycle through them and hold K1 to see the other alt parameters on each screen..

### effects

there are two global effects - clouds and tapedeck. their parameters are editable in the main parameters menu. every parameter for clouds is controlled by an LFO. every sample has its own send to the main bus (no fx) and to these two effects.

### automatic warping

imported audio is automatically warped when either the `guess bpm` parameter is actived, or when "`bpmX`" occurs in the filename. for example of this latter case: if your sample is called "`cool_sound_bpm120.wav`" then it will assume a bpm of 120 and automaticlly stretch it to match the current norns clock in a way that doesn't affect pitch. _note:_ if you change the norns clock after starting *paracosms* then the samples will not be warped to fit anymore.  

_another note:_ if you include "`drum`" in the filename, then warping happens without using pitch-compensation.

you can change the warping at any time by going to the sample and editing the warping parameters. a new warped file is automatically generated and loaded when editing any parameter. all the warped files are stored in the `data/paracosms` folder. this makes subsequent reloads faster.

### gapless playback

**recorded samples:** gapless playback is achieved in recorded samples by recording post-roll audio and crossfading that back into the beginning. *paracosms* takes care of this automatically.

**imported samples:** imported samples are assumed to already have been processed for gapless playback. read the tutorial below to edit your samples for gapless playback:

<details><summary>a tutorial on making audio with gapless playback.</summary><br>

I created [a tool to automatically make seamless loops][AToolToAutomaticallyMakeSeamless] out of audio. to use this tool simply rename your file to include `bpmX` in the filename (where `X` is the source bpm of the file). for example, a 120 bpm file, "`drums.wav`" would be renamed "`drums_bpm120.wav`". then install `seamlessloop` by running this in maiden:

```
os.execute("wget -P /tmp/ https://github.com/schollz/seamlessloop/releases/download/v0.1.1/seamlessloop_0.1.1_Linux-RaspberryPi.deb && sudo dpkg --install /tmp/seamlessloop*.deb && seamlessloop --version")
```

now you can run `seamlessloop` on folders or files. for example:

```
os.execute("seamlessloop --in-folder ~/dust/audio/loops --out-folder ~/dust/audio/quantized-loops")
```

this tool does one of two things: *if* the number of determined beats is greater than a multiple of 4 then those extra beats are used to crossfade and make a seamless sample. *otherwise*, if the number determined beats is slightly less than a multiple of 4 then a gap of silence is appended to the end and the endpoints are faded by 5 ms to reduce clicks.

</details>

## the grid

right now the grid is simple. each key is a sample which can be toggled by pressing. the longer you hold the key, the longer the fade in/out. press times < 250 ms will not toggle the sample, they will only switch between samples (so you can switch between samples by pressing the keys quickly). 

## loading sample banks

you can load in entire folders of samples by using the sample banks.

sample banks can be loaded by editing the main script [in these lines][InTheseLines]. there are seven lines that contain information about the folders for each block (one block = 16 samples, or 1 row on the grid), along with any parameters that you want to set for that row. for example, to load the 909 samples on the norns into the first block you could set it to:

```lua
{folder="/home/we/dust/audio/x0x/909",params={oneshot=2}}
```

where `oneshot=2` defines the oneshot parameter to be activated for all those samples (as opposed to looping).

or you might want to include some loops and have *paracosms* guess the bpm for them. in this case you can do:


```lua
{folder="/home/we/dust/audio/myloops",params={guess=2}}
```

all the parameter ids are valid. for instance you can load a block of samples and have them all be used for the clouds fx:


```lua
{folder="/home/we/dust/audio/togranulate",params={send1=0,send2=0,send3=100}}
```

### known bugs

- rarely a bug occurs where SuperCollider does not free all the synths when exiting. I've found this to happen infrequently and haven't been able to reproduce it. it is unexpected behavior because [all synths and buffers are explicitly freed](https://github.com/schollz/paracosms/blob/main/lib/Paracosms.sc#L303-L308) when exiting.
- as mentioned above, if you change the norns clock then samples will continue to play at the rate according to the clock that they were initialized with. until there is a fix for this, I suggest reloading the script after you change the norns clock, or simply goto the sample individually and modify something in its warping parameters.


### todo

<details><summary>a list of done and doing.</summary>

- fix bugs
- add record countdown (using Stepper and Phasor bus that overrides the record trig)
- add pattern recorded
- logarithm hold length?
- retrigger option for one-shot playback
- ~~show/hide sample~~
- ~~record beats should be a global parameter that gets imported to the next track when recording~~
- ~~add metronome~~
- ~~add greyhole as another send~~
- ~~add option to record to a new track each time (available from ui)~~
- ~~when changing send, untoggle sends~~
- ~~try to guess bpm based on length of sample~~
- ~~add midi transports (for syncing)~~
- ~~load in the 808 kit by default as oneshot into the last row~~
- ~~add miclouds granulator~~
- ~~add euclideans~~
- ~~add global sync (syncs all synths and resets the main phasor)~~
- ~~add pan~~
- ~~add recording~~
- ~~make the first sample a metronome sample (store metronome)~~
- ~~redo grid~~
- ~~add option for number of beats to record~~
- ~~add options in for semitone change~~
- ~~add options in for speed change~~
- ~~add option to declare whether it is “drum” or “melodic”~~
- ~~when adding buf, check to see if syn is running with that id and replace its bufnum~~

</details>


## Install

this script is not available on maiden because its install process requires two steps.

first install the 3rd-party engines:

```
;install https://github.com/schollz/supercollider-plugins
```

**very important**: it is very important that you now open the supercollider-plugins script and click to install to finish installation.

now install

```
;install https://github.com/schollz/paracosms
```

and restart norns to complete!

[DevelopingAnAlbum]: https://infinitedigits.bandcamp.com/album/paracosms
[here]: https://llllllll.co/t/paracosms/56683
[paracosms]: https://github.com/schollz/paracosms/blob/main/lib/Paracosms.sc
[VeryFun]: https://www.instagram.com/p/CfogWyBFZ-V/
[ouroborus]: https://github.com/schollz/paracosms/blob/main/lib/Ouroboros.sc
[AToolToAutomaticallyMakeSeamless]: https://github.com/schollz/seamlessloop
[scripts]: https://github.com/schollz/raw
[InTheseLines]: https://github.com/schollz/paracosms/blob/4338e7306809f3051c482e87a62fd55aadf4c594/paracosms.lua#L24-L30
