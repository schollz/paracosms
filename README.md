# paracosms

> construct imaginary worlds.

![image](https://user-images.githubusercontent.com/6550035/179411170-6295d18b-ab4c-44a7-a2ae-e313dd24c0ba.png)

*paracosms* is a sampler that can playback or record synchronized audio. main features:

- can load/record up to **112 stereo or mono samples**
- **sample playback is synchronized** by default
- recorded samples have **gapless playback** by crossfading post-roll
- imported samples can be **automatically warped** to current bpm
- **one-shot samples can be sequenced** with euclidean sequencer or gestures
- each sample has **filters, pan+amp lfos, timestretching, other fx**
- global **tapedeck, greyhole and clouds fx** with per-sample sends 
- the grid (optional) can **pattern record sample playback or record splicing**
- a keyboard (optional) opens a **tracker that can sequence and record external synths**

https://vimeo.com/730684724

[throw loops](https://vimeo.com/726814753), [slice loops](https://vimeo.com/735651917), [write and record loops](https://vimeo.com/735651656).

<details><summary><strong>why?</strong></summary><br>

between april and june 2022 I made music primarily with [scripts][], SuperCollider, sox and random pre-recorded samples from other musicians. this endeavor culminated in [an album of 100 songs][DevelopingAnAlbum]. (more on that [here][]).

during this time I put together a SuperCollider class I called "[paracosms][]" which is essentially allowed unlimited synchronized turntables that can be switched between one-shots and synchronized loops. initially I took a bunch of samples I collected and threw them into the grid with a thin norns wrapper around this SuperCollider paracosms class. it was [very fun][VeryFun]. 

also during this time I was thinking about recording perfectly seamless loops of audio. I added [a new function to do this easily in softcut](https://github.com/monome/softcut-lib/compare/main...schollz:softcut-lib:rec-once4). but I realized I wanted to do it with SuperCollider too. I ended up making "[ouroborus][]" which allows recording of seamless loops directly to disk by [fading in a post-roll](https://fredrikolofsson.com/f0blog/buffer-xfader/) to the beginning of a recording.

without intending, I realized that I could combine ourborous with paracosms together into sampler/looper. its basically a thing that excels at recording and playing perfect audio loops. norns became the glue for these two supercollider classes which is now this *paracosms* script. 




</details>
<br>



## Requirements

- norns
- grid (optional)
- crow (optional)
- keyboard (optional)

## Documentation



### playing loops

![norns](https://user-images.githubusercontent.com/6550035/181917591-51062ba1-773e-49ae-b06f-aba82b34d5f4.jpg)


**E1 will select sample. K1+E1 will select sample *that is loaded*.**

**K3 will play a sample.** holding K3 will fade the sample (in or out dependong on whether its playing). 

the start/end points can be changed (press K2 to find the menu or use PARAMS). the loops always try to play in sync no matter the length. with the grid you can sequence the loop positions for chopping things (more below).

_note:_ loops appear on the screen as single channel even if they are stereo.

### playing one shots

![oneshot](https://user-images.githubusercontent.com/6550035/181917889-229fdfb0-6e63-484e-b44f-f4c1b0e6e644.jpg)

loops can be placed into "oneshot" mode. press K2 until you reach the screen with "mode", "offset", "start", and "end". then hold K1 and turn E2 to modify the mode to "oneshot" or "loop".

![oneshot](https://user-images.githubusercontent.com/6550035/181917685-d45c22a0-ed07-4c64-b296-b5f9e0720d06.jpg)

**K3 plays a sample** in oneshot mode. if you hold K3 it will toggle the euclidean sequencer (which can also be toggled by the parameters menu or in one of the K2 parameter screens).

### recording

![recording](https://user-images.githubusercontent.com/6550035/181917817-7bf6e49c-f941-4df5-994a-5214a8c19301.jpg)

**K1+K3 will prime a recording.** you always can skip waiting and **you can start recording immediately by pressing K1+K3 again.**

by default *paracosms* will wait to record until audio crosses a threshold to start recording. once recording is detected, it records the full length specified by the sample parameters (in beats, plus the crossfade post-roll). *paracosms* uses a latency term to capture the milliseconds right before recording (because there is an inherent delay in starting recording after detecting it) and this can be changed in the parameters. generally this latency should be really small (<20 ms). 


### parameters on the go

**K2/K1+K2 will cycle through parameters.** 

**E2/E3 or K1+(E2/E3) will modulate the current parameters.**

there are a bunch of sample-specific parameters: volume (+lfo), panning (+lfo), sample start/end, filters (low+high), fx sends, timestretching. these are all available in the `PARAMS` menu, but they are also accessible from the main screen to avoid some menu-diving. us K2 to cycle through them and hold K1 to see the other alt parameters on each screen..

### effects

there are three global effects - greyhole, clouds and tapedeck. their parameters are editable in the main parameters menu. every parameter for clouds is controlled by an LFO. every sample has its own send to the main bus (no fx) and to these two effects.

### automatic warping

imported audio is automatically warped when either the `guess bpm` parameter is activated (i.e. from the startup script), or when "`bpmX`" occurs in the filename. for example of this latter case: if your sample is called "`cool_sound_bpm120.wav`" then it will assume a bpm of 120 and automatically stretch it to match the current norns clock in a way that doesn't affect pitch. _note:_ if you change the norns clock after starting *paracosms* then the samples will not be warped to fit anymore.  

_another note:_ if you include "`drum`" in the filename, then warping happens without using pitch-compensation.

you can change the warping at any time by going to the sample and editing the warping parameters. a new warped file is automatically generated and loaded when editing any parameter. all the warped files are stored in the `data/paracosms` folder. this makes subsequent reloads faster.

### gapless playback

**recorded samples:** gapless playback is achieved in recorded samples by recording post-roll audio and crossfading that back into the beginning. *paracosms* takes care of this automatically.

**imported samples:** imported samples are assumed to already have been processed for gapless playback. read the tutorial below to edit your samples for gapless playback:

<details><summary>a tutorial on making audio with gapless playback.</summary><br>

I created [a tool to automatically make seamless loops][AToolToAutomaticallyMakeSeamless] out of audio. to use this tool simply **rename your file to include `bpmX`** in the filename (where `X` is the source bpm of the file). for example, a 120 bpm file, "`drums.wav`" would be renamed "`drums_bpm120.wav`". this tool is included with *paracosms* - its called `seamlessloop`. you can run `seamlessloop` on folders or files. for example:

```
os.execute("/home/we/dust/code/paracosms/lib/seamlessloop --in-folder ~/dust/audio/loops --out-folder ~/dust/audio/quantized-loops")
```

this tool does one of two things: *if* the number of determined beats is greater than a multiple of 4 then those extra beats are used to crossfade and make a seamless sample. *otherwise*, if the number determined beats is slightly less than a multiple of 4 then a gap of silence is appended to the end and the endpoints are faded by 5 ms to reduce clicks.

</details>

## the grid

the grid essentially makes it easy to toggle on/off samples. it does give special functionality to create patterns from toggles, and even create patterns from start/stop positions (making it easy to break up samples).

![images](https://user-images.githubusercontent.com/6550035/180621149-f479edee-53ea-4b89-bdce-48e25d95d0c1.png)




## keyboard / tracker

![tracker](https://user-images.githubusercontent.com/6550035/181917589-70709080-8a9c-4f12-bd71-668668f7b20c.jpg)

pushing a key on a keyboard opens the tracker. twisting an encoder closes the tracker (but it will still be running if you started it).

the keyboard layout closely follows the [renoise layout](https://tutorials.renoise.com/wiki/Playing_Notes_with_the_Computer_Keyboard).

![image](https://user-images.githubusercontent.com/6550035/181408330-395348fb-3025-4c62-9367-770914790b46.png)

the keyboard controls a sequencer. the sequencer has two dimensions. each row is a measure of 4 beats. those 4 beats are subdivided evenly across everything put onto a line. so if you put 8 things onto a line, each of those things will occur each 1/8th note. if you put 4 things, each will occur at each 1/4 note. if you put 7 things each will occur at each 1/7th note (approximately).

there are notes, note offs, and note ties. by default, anytime a note changes it will do a note off since each sequence is monophonic (though you can have as many sequences playing as you want). you can use the note ties and note offs to create syncopation. for example, the following is quarter note tied to an eight note:

```
C4 - - . . . . .
```

there are 8 things, so each thing gets 1/8th note. the C4 gets 1/8 note and its tied twice ("`- -`") and doesn't get turned off until the 4th 1/8th note hits, so it lasts only 3/8th notes.

## customization / loading sample banks

![custom](https://user-images.githubusercontent.com/6550035/182173615-c996238b-3cf9-41b4-8cc7-57ca94fdd794.PNG)

paracosms is ready to be customized. the initial script can be changed to your liking. open up `paracosms.lua` in maiden, or copy and paste its contents into a new file.

the functions `substance()` and `style()` run at the start and at the end of loading, respectively (*substance* before *style* as they say). you can use these to trigger certain behaviors or activate parameters once everything is loaded. I like to make a script for each track I'm working on where the `substance()` sets the clock speed and `style()` loads specific files into specific banks.

the "blocks" allows you to customize the startup samples. you can load up to 16 samples per line per entry, with 7 entries available. each entry has a folder and all the files in the folder will be loaded. for instance the first line will loaded into slots 1-16. the second line will load into slots 17-32. etc. you can also create parameters that are shared across each block. any parameter that is available can be updated here. for example, say you wanted to load all the 909-samples as one-shots, you could include this line:

```lua
{folder="/home/we/dust/audio/x0x/909",params={oneshot=2}}
```

where `oneshot=2` defines the oneshot parameter to be activated for all those samples (as opposed to looping). or you might want to include some loops and have *paracosms* guess the bpm for them. in this case you can do:


```lua
{folder="/home/we/dust/audio/myloops",params={guess=2}}
```

all the parameter ids are valid. for instance you can load a block of samples and have them all be used for the clouds fx:


```lua
{folder="/home/we/dust/audio/togranulate",params={send_main=0,send_tape=0,send_clouds=100}}
```

### saving / loading

saving and loading is done by writing and reading `PSET`s. the save will store all the current parameters, patterns and references to audio files. since only the audio file reference is stored, if the file is moved then your save may no longer function properly (there is a way to fix this though if it happens).

## todo

### future

- rain on a windowpane thing for composing songs from loops
- more fx (strobe)


### possible bugs

- ~~rarely a bug occurs where SuperCollider does not free all the synths when exiting.~~ (fixed, I think)
- there is a rare bug where the playback position escapes the start/stop points (maybe fixed)
- if you change the norns clock then samples will continue to play at the rate according to the clock that they were initialized with. until there is a fix for this, I suggest reloading the script after you change the norns clock, or simply goto the sample individually and modify something in its warping parameters.

## Install

```
;install https://github.com/schollz/paracosms
```

the first time you open the script it will ask to install the rest of paracosms.

## Update

update the script by deleting and reinstalling or just running this in maiden:

```
os.execute("cd /home/we/dust/code/paracosms && git fetch --all && cd /home/we/dust/code/paracosms && git reset --hard origin/paracosms
")
```

[DevelopingAnAlbum]: https://infinitedigits.bandcamp.com/album/paracosms
[here]: https://llllllll.co/t/paracosms/56683
[paracosms]: https://github.com/schollz/paracosms/blob/main/lib/Paracosms.sc
[VeryFun]: https://www.instagram.com/p/CfogWyBFZ-V/
[ouroborus]: https://github.com/schollz/paracosms/blob/main/lib/Ouroboros.sc
[AToolToAutomaticallyMakeSeamless]: https://github.com/schollz/seamlessloop
[scripts]: https://github.com/schollz/raw
[InTheseLines]: https://github.com/schollz/paracosms/blob/4338e7306809f3051c482e87a62fd55aadf4c594/paracosms.lua#L24-L30
