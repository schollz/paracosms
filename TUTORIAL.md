
# tutorial

paracosms is a sample player, recorder, and sequencer.

you can manipulate up to 112 samples. 

each sample can be used as a loop or as a "oneshot". a oneshot plays until it reaches the end setpoint.

one of the main features of paracosms is that it tries to keep everything in synchrony.

## loading a sample /// three methods

no matter how the sample is used, it can be loaded three different ways.

### 1. recording

paracosms can record samples directly.

recordings are automatically crossfaded so that they loop seamlessly - without clicks or pops. this is done by recording a little extra and then cutting that extra recording and fading it out with the original front of the recording fading in. 

the crossfading is done automatically. all you need to do is set the number of beats that you want to record.

press K2 to find the screen with "record beats". then use E3 to change the number of beats. you can also edit this from the `PARAMS` menu.

once satisfied with the number of beats to record you can prime recording by pressing K1+K3. a primed recording will wait to record until the incoming audio exceeds a set threshold. the threshold is set in the parameters menu. 

once the threshold is past, then recording starts. however, it usually takes 5-20 milliseconds to detect audio so initial transients can be lost. to compensate, paracosms actually is recording before recording starts and the start point of the final recording and be manipulated with a "latency" parameter in `PARAMS > RECORDING`.

if your recording is primed, you can play to start recording. you can also start recording immediately by pressing K1+K3 again. 

after recording, the file is automatically loaded. 

the start of the recording occurs where in the number of the beats you are. this can be seen with the little bouncing square. you can also edit a parameter "RECORDING > rec start beat 1" which will produce a recording with the first transients aligned with the first beat.


#### fix synchronizing + metronome


the recording is guaranteed to be the correct length (whatever length you set it to) but it is not guaranteed to start in the perfect start position.

if your recording is not in sync it is possible you might want to re-record it - the metronome can be turned up to help with recording.

if your recording is not in sync, you can also change how the recording aligns with others by modifying one parameter - the `offset`. the `offset` is found in the `PARAMS` and also on the recording screen. you can modulate this and it will nudge the recording into sync. to check against a constant source, you can use the metronome.

### 2. load a file / automatic warping

you can load a file directly into paracosms through the `PARAMS` menu. any `wav` or `flac` file can be loaded. 

loading a file will activate another feature of paracosms - automatic warping. warping audio in this context means changing the tempo of the audio without affecting the pitch. 

audio files are *only* warped in two scenarios. 

first scenario: magic in the filename. if the filename has `bpm<number>` somewhere then the tempo is extracted from the filename and then used to warp the audio to the new tempo.

second scenario: the parameter "guess bpm" is activated. "guess bpm" needs to be activated *before* loading the file to work. if "guess bpm" is activated, then the tempo of the file is guessed based on the length of the file and assumptions about the number of beats in the file. this doesn't always work, but if you have audio loops that clipped to multiples of 4 beats than it works pretty well.


### 3. load a bank

there is one final way of loading samples. this is the way to load samples in bulk, at startup. this is especially useful to create preset banks of samples.

to do this you should open up maiden and load `paracosms.lua`.

you can edit this file directly, or copy everything in the file and paste it into a new one. 

this file lets you tell paracosms whole folders of files to load. you can load up to seven folders of audio files. each folder that contains audio files are loaded, up to 16, alphabetically into slots of paracosms. 

each row will load into each set of 16 slots. so the first folder goes into slots 1-16. the second folder goes into slots 17-32. even if their are no samples. 

_helpful hint:_ if you have lots of empty slots, you can easily find samples by holding K1 while turning E1. turning E1 alone will scroll through each slot, while K1+E1 will scroll through all the slots that have samples loaded.

one more special thing about this section. each of the seven banks can have their parameters altered *at startup*. this is especially useful if you have a bunch of oneshots or you want all the samples to have a specific volume, or envelope. for example, lets load up the 909 samples as one-shots.

first we set the folder to the folder of one-shots. audio samples are automatically loaded as loops. in this case we want oneshot so we shall set that parameter to the 2nd entry, "oneshot". we can also set it up so it uses tapedeck as the only send. we can also set it up so it pans randomly and modify the envelope (attack and release).

```lua
{folder="/home/we/dust/audio/x0x/909",params={oneshot=2,send_main=0,send_tape=1,attack=0.002,release=0.2,pan=math.random()-0.5}},
```


we can load up another row and have them guess the bpm. in this second row we will load some drum samples. we will also change the "type" of this sample to "drum" (number 2). when the type is drum then instead warping to keep the pitch constant, the warping is done by changing the pitch. for drums the changing of the pitch isn't as important, and it can actually be a fun effect to pitch up/down drums while keeping them in time.

```lua
{folder="/home/we/dust/audio/tehn",params={type=2,guess=2}}
```
