# paracosms

> construct imaginary worlds.

![image](https://user-images.githubusercontent.com/6550035/179411170-6295d18b-ab4c-44a7-a2ae-e313dd24c0ba.png)

*paracosms* is a sampler that can playback or record audio. drive-by features:

- can load up to **112 stereo samples**
- recorded samples have **gapless playback**
- imported samples have **automatic warping**
- **one-shot samples can be sequenced** with euclidean sequencer
- **looped samples are quantized** to the clock and synced together
- each sample has **filters, pan+amp lfos, timestretching**
- global **tapedeck and clouds effects** with per-sample sends 


https://vimeo.com/730684724

<details><summary><strong>why?</strong></summary>

in about April 2022 I put away all my instruments (except the norns) and took a "sampling sabbatical". basically I decided to pretty much just use SuperCollider+sox and make non-realtime music with samples. after [developing an album](https://infinitedigits.bandcamp.com/album/paracosms) through this effort (more on that [here](https://llllllll.co/t/paracosms/56683)) I started thinking about whether I could make this approach more *real-time*. so I put together a SuperCollider class I called "[paracosms](https://github.com/schollz/paracosms/blob/main/lib/Paracosms.sc)". initially I took a bunch of samples I collected and threw them into the grid with a thin norns wrapper around my class. it was [very fun](https://www.instagram.com/p/CfogWyBFZ-V/). during this self-imposed sabbatical I also played around with making a SuperCollider class to make a multi-head playback/recorder that can do crossfading recordings (like softcut). this became "[ouroborus](https://github.com/schollz/paracosms/blob/main/lib/Ouroboros.sc)". without intending, I realized that I could combine ourborous with paracosms into a great sampler/looper thing. norns became the glue for that - and it is this *paracosms* script.

</details>
<br>









## Requirements

- norns
- grid (optional)

## Documentation

![norns](https://user-images.githubusercontent.com/6550035/179410985-0ee42e5b-49e2-420d-8ef0-8107e49b42eb.jpg)


### Todo

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

then install

```
;install https://github.com/schollz/paracosms
```
