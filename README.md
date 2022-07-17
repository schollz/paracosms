# paracosms

> construct imaginary worlds.

![image](https://user-images.githubusercontent.com/6550035/179411170-6295d18b-ab4c-44a7-a2ae-e313dd24c0ba.png)

*paracosms* is a sampler that can playback or record audio. drive-by features:

- can load up to **112 stereo samples**
- **samples are quantized** to the clock and synced together
- recorded samples have **gapless playback** using crossfades
- imported samples are **automatic warped** to current bpm
- **one-shot samples can be sequenced** with euclidean sequencer
- each sample has **filters, pan+amp lfos, timestretching**
- global **tapedeck and clouds effects** with per-sample sends 


https://vimeo.com/730684724

<details><summary><strong>why?</strong></summary>

in about April 2022 I put away all my instruments (except the norns) and took a "sampling sabbatical". basically I decided to pretty much just use SuperCollider+sox and make non-realtime music with samples. after [developing an album][DevelopingAnAlbum] through this effort (more on that [here][]) I started thinking about whether I could make this approach more *real-time*. so I put together a SuperCollider class I called "[paracosms][]". 

initially I took a bunch of samples I collected and threw them into the grid with a thin norns wrapper around this SuperCollider paracosms class. it was [very fun][VeryFun]. during this self-imposed sabbatical I also played around with making a SuperCollider class to make a multi-head playback/recorder that can do crossfading recordings (like softcut). this became "[ouroborus][]". without intending, I realized that I could combine ourborous with paracosms into a great sampler/looper thing. norns became the glue for that - and it is this *paracosms* script.

</details>
<br>



## Requirements

- norns
- grid (optional)

## Documentation

![norns](https://user-images.githubusercontent.com/6550035/179410985-0ee42e5b-49e2-420d-8ef0-8107e49b42eb.jpg)

### playing

E1 will select sample. K1+E1 will select sample *that is playing*.

K3 will play a sample. 

if it is a looping sample then the longer you hold K3 will increase the fade time for toggling the sample. if it is a one-shot sample it plays once.

### recording

K1+K3 will record a sample. 

by default it will wait until audio crosses a threshold to start recording. you can start recording immedietly by pressing K1+K3 again. you can change the threshold for recording, the amount of crossfading, and the amount of latency (when automatically detecting) in the params.

### parameters on the go

K2 will cycle through parameters. 

E2/E3 or K1+(E2/E3) will modulate the current parameters.

there are tons of sample-specific parameters in the parameters menu. some of these are broken out into the main UI to make it easier to access and manipulate them on the fly.

### effects

there are two global effects - clouds and tapedeck. their parameters are editable in the main parameters menu. every parameter for clouds is controlled by an LFO. every sample has its own send to the main bus (no fx) and to these two effects.

### automatic warping

automatic warping of imported audio is conducted *whenever bpmX is in the filename*. if your sample is called "`cool_sound_bpm120.wav`" then it will assume a bpm of 120 and stretch it to match the current norns clock. _note:_ if you change the norns clock after starting *paracosms* then the samples will not be warped to fit anymore.  

additionally, if you include "`drum`" in the filename, then it is warped without using pitch-compensation when changing the speed. otherwise samples are assumed to be melodic and be pitch-compensated so that they stay in the same key when warping them to the new tempo.

you can change the warping at any time by going to the sample and editing the warping parameters. a new warped file is automatically generated and loaded when editing any parameter. all the warped files are stored in the `data/paracosms` folder. 

### gapless playback

**recorded samples:** gapless playback is achieved in recorded samples by recording post-roll audio and crossfading that back into the beginning.

**imported samples:** imported samples are assumed to already have been processed for gapless playback. read the tutorial below to edit your samples for gapless playback:

<details><summary>a tutorial on making audio with gapless playback.</summary>

to aid this, I created [a tool to automatically make seamless loops][AToolToAutomaticallyMakeSeamless] out of audio. to use this tool simply rename your file to include `bpmX` in the filename (where `X` is the source bpm of the file). for example, a 120 bpm file, "`drums.wav`" would be renamed "`drums_bpm120.wav`". then install `seamlessloop` by running this in maiden:

```
os.execute("wget -P /tmp/ https://github.com/schollz/seamlessloop/releases/download/v0.1.1/seamlessloop_0.1.1_Linux-RaspberryPi.deb && sudo dpkg --install /tmp/seamlessloop*.deb && seamlessloop --version")
```

now you can run `seamlessloop` on folders or files. for example:

```
os.execute("seamlessloop --in-folder ~/dust/audio/loops --out-folder ~/dust/audio/quantized-loops")
```

</details>

### Todo

- retrigger option for one-shot playback
- add pattern recorded
- logarithm hold length?
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


## Install

first install the 3rd-party engines:

```
;install https://github.com/schollz/supercollider-plugins
```

**very important**: it is very important that you now open the supercollider-plugins script and click to install to finish installation.*

now install

```
;install https://github.com/schollz/paracosms
```

[DevelopingAnAlbum]: https://infinitedigits.bandcamp.com/album/paracosms
[here]: https://llllllll.co/t/paracosms/56683
[paracosms]: https://github.com/schollz/paracosms/blob/main/lib/Paracosms.sc
[VeryFun]: https://www.instagram.com/p/CfogWyBFZ-V/
[ouroborus]: https://github.com/schollz/paracosms/blob/main/lib/Ouroboros.sc
[AToolToAutomaticallyMakeSeamless]: https://github.com/schollz/seamlessloop
