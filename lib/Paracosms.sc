Paracosms {

	var server;
	var dirCache;
	var busOut1;
	var busOut2;
	var busOut3;
	var busOut4;
	var busPhasor;
	var syns;
	var synsFinished;
	var synMetronome;
	var bufs;
	var params;
	var watching;
	var group;
	var cut_fade;

	*new {
		arg serverName,argGroup,argBusOut1,argBusOut2,argBusOut3,argBusOut4,argDirCache;
		^super.new.init(serverName,argGroup,argBusOut1,argBusOut2,argBusOut3,argBusOut4,argDirCache);
	}

	init {
		arg serverName,argGroup,argBusOut1,argBusOut2,argBusOut3,argBusOut4,argDirCache;

		// set arguments
		server=serverName;
		group=argGroup;
		busOut1=argBusOut1;
		busOut2=argBusOut2;
		busOut3=argBusOut3;
		busOut4=argBusOut4;
		dirCache=argDirCache;

		syns=Dictionary.new();
		synsFinished=List.new(300);
		bufs=Dictionary.new();
		params=Dictionary.new();
		cut_fade=0.2;

		watching=0;
		busPhasor=Bus.audio(server,1);
		(1..2).do({arg ch;
			SynthDef("defPlay2"++ch,{
				arg amp=1.0,pan=0,
				lpf=20000,lpfqr=0.707,
				hpf=20,hpfqr=0.707,
				offset=0,t_sync=1,t_manu=0,
				oneshot=0, cut_fade=0.2,
				rate=1.0,rateLag=0.0,
				sampleStart=0,sampleEnd=1.0,
				ts=0,tsSeconds=0.25,tsSlow=1,
				pan_period=16,pan_strength=0,
				amp_period=16,amp_strength=0,
				id=0,dataout=0,attack=0.001,release=1,gate=0,bufnum,busPhase,
				out1=0,out2,out3,out4,send1=1.0,send2=0,send3=0,send4=0;

				var snd,pos,seconds,tsWindow;
				var pos1,pos2,pos1trig,pos2trig,pos2trig_in,readHead_changed;
				var framesEnd,framesStart;
				var readHead=0;
				var readHead_in=0;
				var localin_data;
				var sampleStartOriginal=sampleStart;
				var sampleEndOriginal=sampleEnd;

				// determine constants
				var frames=BufFrames.ir(bufnum);
				var duration=BufDur.ir(bufnum);

				// determine triggers
				var syncTrig=Trig.ar(t_sync+((1-ts)*Changed.kr(ts))+Changed.kr
					(offset)+Changed.kr(rate)+Changed.kr(sampleStart)+Changed.kr(sampleEnd),0.01);
				var manuTrig=Trig.ar(t_manu,0.01);
				var syncPos=SetResetFF.ar(syncTrig,manuTrig)*Latch.ar((In.ar(busPhase)+offset).mod(duration)/duration*frames,syncTrig);
				var manuPos=SetResetFF.ar(manuTrig,syncTrig)*Wrap.ar(syncPos+Latch.ar(t_manu*frames,t_manu),0,frames);
				var resetPos=syncPos+manuPos;
				var syncOrManuTrig=syncTrig+manuTrig;

				// figure out the rate
				rate=rate*BufRateScale.ir(bufnum)*((sampleStart<sampleEnd)*2-1); // TODO: test whether this works to reverse rate
				// swap the sample start/end
				framesEnd=sampleEnd*frames;
				framesStart=sampleStart*frames;


				// determine the reset pos
				resetPos=((1-oneshot)*resetPos)+(oneshot*framesStart); // if one-shot then start at the beginning
				resetPos=Wrap.ar(resetPos,framesStart,framesEnd);
				resetPos=((1-(syncOrManuTrig>0))*framesStart)+((syncOrManuTrig>0)*resetPos);

				// lag the volume
				amp=(amp*oneshot)+((1-oneshot)*VarLag.kr(amp,0.2,warp:\sine));

				// crossfade the time stretching
				tsSlow=SelectX.kr(ts,[1,tsSlow]);

				localin_data=LocalIn.ar(2);
				readHead_changed=localin_data[0];
				readHead_in=localin_data[1];

				pos1=Phasor.ar(
					trig:readHead_changed*(1-readHead_in),
					rate:rate/tsSlow,
					start:framesStart,
					end:(rate>0)*frames,
					resetPos:resetPos,
				);
				pos1trig=Trig.ar((pos1>framesEnd)*(1-readHead_in),0.01)*(rate>0);
				pos1trig=pos1trig+(Trig.ar((pos1<framesEnd)*(1-readHead_in),0.01)*(rate<0));
				pos2=Phasor.ar(
					trig:readHead_changed*(readHead_in),
					rate:rate/tsSlow,
					start:framesStart,
					end:(rate>0)*frames,
					resetPos:resetPos,
				);
				pos2trig=Trig.ar((pos2>framesEnd)*readHead_in,0.01)*(rate>0);
				pos2trig=pos2trig+(Trig.ar((pos2<framesEnd)*readHead_in,0.01)*(rate<0));
				readHead=ToggleFF.ar(pos1trig+syncOrManuTrig+pos2trig);

				pos=Select.ar(readHead,[pos1,pos2]);
				LocalOut.ar([Changed.ar(readHead),readHead]);

				tsWindow=Phasor.ar(
					trig:manuTrig+manuTrig,
					rate:rate,
					start:pos,
					end:pos+(tsSeconds/duration*frames),
					resetPos:pos,
				);
				snd=BufRd.ar(ch,bufnum,pos1,interpolation:2);
				snd=SelectX.ar(Lag.ar(readHead,cut_fade),[snd,BufRd.ar(ch,bufnum,pos2,interpolation:2)]);

				snd=((1-ts)*snd)+(ts*BufRd.ar(ch,bufnum,
					tsWindow,
					loop:1,
					interpolation:1
				));

				// balance the two channels
				pan=Clip.kr(pan+SinOsc.kr(1/pan_period,phase:rrand(0,3),mul:pan_strength),-1,1);
				snd=Pan2.ar(snd,0.0);
				snd=Pan2.ar(snd[0],1.neg+(2*pan))+Pan2.ar(snd[1],1+(2*pan));
				snd=Balance2.ar(snd[0],snd[1],pan);

				amp=Clip.kr(amp+SinOsc.kr(1/amp_period,phase:rrand(0,3),mul:amp_strength),0,5);
				snd=snd*amp;

				// one-shot envelope
				snd=snd*EnvGen.ar(Env.new([1-oneshot,1,1,1-oneshot],[0.005,(duration*(sampleEnd-sampleStart)/rate)-0.015,0.005]),doneAction:oneshot*2);

				snd=RLPF.ar(snd,VarLag.kr(lpf.log,0.2,warp:\sine).exp,lpfqr);
				snd=RHPF.ar(snd,VarLag.kr(hpf.log,0.2,warp:\sine).exp,hpfqr);

				// main envelope
				snd=snd*EnvGen.ar(Env.asr(attack,1.0,release,\sine),gate,doneAction:2);



				SendTrig.kr(Impulse.kr((dataout>0)*10),id,pos/frames*duration);
				SendTrig.kr(Impulse.kr(10),200+id,Amplitude.kr(snd));
				Out.ar(out1,snd*send1);
				Out.ar(out2,snd*send2);
				Out.ar(out3,snd*send3);
				Out.ar(out4,snd*send4);
			}).send(server);
		});

		(1..2).do({arg ch;
			SynthDef("defPlay1"++ch,{
				arg amp=1.0,pan=0,
				lpf=20000,lpfqr=0.707,
				hpf=20,hpfqr=0.707,
				offset=0,t_sync=1,t_manu=0,
				oneshot=0, cut_fade=0.2,
				rate=1.0,rateLag=0.0,
				sampleStart=0,sampleEnd=1.0,
				ts=0,tsSeconds=0.25,tsSlow=1,
				pan_period=16,pan_strength=0,
				amp_period=16,amp_strength=0,
				id=0,dataout=0,attack=0.001,release=1,gate=0,bufnum,busPhase,
				out1=0,out2,out3,out4,send1=1.0,send2=0,send3=0,send4=0;

				var snd,pos,seconds,tsWindow;
				var pos1,pos2,pos1trig,pos2trig,pos2trig_in;
				var readHead=0;
				var readHead_in=0;
				var localin_data;

				// determine constants
				var frames=BufFrames.ir(bufnum);
				var framesEnd=frames*sampleEnd;
				var duration=BufDur.ir(bufnum);

				// determine triggers
				var syncTrig=Trig.ar(t_sync+((1-ts)*Changed.kr(ts))+Changed.kr
					(offset)+Changed.kr(rate)+Changed.kr(sampleStart)+Changed.kr(sampleEnd));
				var manuTrig=Trig.ar(t_manu);
				var syncPos=SetResetFF.ar(syncTrig,manuTrig)*Latch.ar((In.ar(busPhase)+offset).mod(duration)/duration*frames,syncTrig);
				var manuPos=SetResetFF.ar(manuTrig,syncTrig)*Wrap.ar(syncPos+Latch.ar(t_manu*frames,t_manu),0,frames);
				var resetPos=syncPos+manuPos;
				var syncOrManuTrig=syncTrig+manuTrig;
				resetPos=((1-oneshot)*resetPos)+(oneshot*sampleStart*frames); // if one-shot then start at the beginning
				resetPos=Wrap.ar(resetPos,sampleStart*frames,sampleEnd*frames);

				amp=(amp*oneshot)+((1-oneshot)*VarLag.kr(amp,0.2,warp:\sine));
				tsSlow=SelectX.kr(ts,[1,tsSlow]);
				rate=rate*BufRateScale.ir(bufnum);

				pos=Phasor.ar(
					trig:syncOrManuTrig,
					rate:rate/tsSlow,
					start:sampleStart*frames,
					end:frames,
					resetPos:resetPos,
				);
				

				tsWindow=Phasor.ar(
					trig:manuTrig+manuTrig,
					rate:rate,
					start:pos,
					end:pos+(tsSeconds/duration*frames),
					resetPos:pos,
				);
				snd=BufRd.ar(ch,bufnum,pos,interpolation:2);

				snd=((1-ts)*snd)+(ts*BufRd.ar(ch,bufnum,
					tsWindow,
					loop:1,
					interpolation:1
				));

				// balance the two channels
				pan=Clip.kr(pan+SinOsc.kr(1/pan_period,phase:rrand(0,3),mul:pan_strength),-1,1);
				snd=Pan2.ar(snd,0.0);
				snd=Pan2.ar(snd[0],1.neg+(2*pan))+Pan2.ar(snd[1],1+(2*pan));
				snd=Balance2.ar(snd[0],snd[1],pan);

				amp=Clip.kr(amp+SinOsc.kr(1/amp_period,phase:rrand(0,3),mul:amp_strength),0,5);
				snd=snd*amp;

				// one-shot envelope
				snd=snd*EnvGen.ar(Env.new([1-oneshot,1,1,1-oneshot],[0.005,(duration*(sampleEnd-sampleStart)/rate)-0.015,0.005]),doneAction:oneshot*2);

				snd=RLPF.ar(snd,VarLag.kr(lpf.log,0.2,warp:\sine).exp,lpfqr);
				snd=RHPF.ar(snd,VarLag.kr(hpf.log,0.2,warp:\sine).exp,hpfqr);

				// main envelope
				snd=snd*EnvGen.ar(Env.asr(attack,1.0,release,\sine),gate,doneAction:2);



				SendTrig.kr(Impulse.kr((dataout>0)*10),id,pos/frames*duration);
				SendTrig.kr(Impulse.kr(10),200+id,Amplitude.kr(snd));
				Out.ar(out1,snd*send1);
				Out.ar(out2,snd*send2);
				Out.ar(out3,snd*send3);
				Out.ar(out4,snd*send4);
			}).send(server);
		});
		SynthDef("defMetronome",{
			arg bpm=120,busPhase,note=60,amp=1.0,t_free=0;
			var snd,pos,phase,phaseMeasure,freq;
			note=Lag.kr(note);
			amp=Lag.kr(amp);
			pos=In.ar(busPhase,1);
			phase=pos.mod(60/bpm)-(60/bpm/2);
			phaseMeasure=pos.mod(4*60/bpm)-(2*60/bpm);
			note=(note+(Trig.kr(phaseMeasure<0,60/bpm)*12));
			freq=[note-0.03,note+0.04].midicps;
			snd=MoogFF.ar(Pulse.ar(freq,0.5),1000);
			snd=snd*EnvGen.ar(Env.perc(releaseTime:60/bpm),phase<0);
			Out.ar(0,snd*amp*EnvGen.ar(Env.new([1,0],[1]),t_free,doneAction:2));
		}).send(server);

		SynthDef("defPhasor",{
			arg out,rate=1.0,rateLag=0.2,t_sync=0;
			Out.ar(out,Phasor.ar(t_sync,Lag.kr(rate,rateLag)/server.sampleRate,0,120000.0));
		}).send(server);

		SynthDef("defPattern",{
			arg offset=0.0,duration=8,id=0,busPhase,phaseStart=0.0;
			var phase=In.ar(busPhase);
			var syncPos=(phase+offset).mod(duration);
			var pos=(DC.ar(phase)+offset).mod(duration);
			// SendTrig.kr(Impulse.kr(0.5),444,pos);
			// SendTrig.kr(TDelay.kr(Impulse.kr(0.5),0.5),444,syncPos);
			// SendTrig.kr(TDelay.kr(Impulse.kr(0.5),1.0),444,pos);
			SendTrig.ar(Changed.ar(pos>syncPos)*(pos>syncPos),444,pos);
		}).send(server);


		server.sync;

		syns.put("phasor",Synth.head(group,"defPhasor",[\out,busPhasor]));

	}

	pattern {
		arg id,duration;
		Synth.tail(group,"defPattern",[\duration,duration,\id,id,\busPhase,busPhasor]);
	}

	watch {
		arg id;
		if (syns.at(id).notNil,{
			if (watching>0,{
				if (syns.at(watching).isRunning,{
					syns.at(watching).set(\dataout,0);
				});
			});
			watching=id;
			syns.at(watching).set(\dataout,1);
		});
	}

	metronome {
		arg bpm,note,amp;
		var doSet=false;
		[bpm,note,amp].postln;
		if (synMetronome.notNil,{
			if (synMetronome.isRunning,{
				doSet=true;
				if (note<1,{
					synMetronome.set(\t_free,1);
				});
			},{
				synMetronome.free;
			})
		});
		if (note>1,{
			if (doSet,{
				synMetronome.set(\bpm,bpm,\note,note,\amp,amp);
			},{
				synMetronome=Synth.after(syns.at("phasor"),"defMetronome",
					[\busPhase,busPhasor,\bpm,bpm,\amp,amp,\note,note]);
				NodeWatcher.register(synMetronome);
			});
		});
	}


	stop {
		arg id, fadeOut;
		if (syns.at(id).notNil,{
			synsFinished.add(syns.at(id));
			if (syns.at(id).isRunning,{
				syns.at(id).set(\gate,0,\release,fadeOut);
			});
		});
	}

	cut_fade {
		arg val;
		cut_fade=val;
		syns.keysValuesDo({ arg note, val;
			if (val.isRunning,{
				val.set(\cut_fade,cut_fade);
			});
		});
	}

	// cut will crossfade to a new position in the sample
	// IF the sample is playing
	cut {
		arg id,sampleStart,sampleEnd,xfade;
		var defPlay=1;
		if (params.at(id).notNil,{
			if (bufs.at(id).notNil,{
				if (syns.at(id).notNil,{
					if (syns.at(id).isRunning,{
						var pars=[\id,id,\out1,busOut1,\out2,busOut2,\out3,busOut3,\out4,busOut4,\busPhase,busPhasor,\bufnum,bufs.at(id),\dataout,1,\gate,1,\attack,xfade,\cut_fade,cut_fade];

						params.at(id).put("sampleStart",sampleStart);
						params.at(id).put("sampleEnd",sampleEnd);
						params.at(id).keysValuesDo({ arg pk,pv; 
							pars=pars++[pk,pv];
						});
						if (sampleStart>0,{
							defPlay=2;
						});
						if (sampleEnd<1,{
							defPlay=2;
						});
						if (params.at(id).at("oneshot").notNil,{
							if (params.at(id).at("oneshot")>0,{
								defPlay=1;
							});
						});
						("cutting synth"+id).postln;
						syns.at(id).set(\release,xfade,\gate,0);
						syns.put(id,Synth.after(syns.at("phasor"),
							"defPlay"++defPlay++bufs.at(id).numChannels,pars,
						).onFree({["freed"+id].postln}));
						NodeWatcher.register(syns.at(id));
					});
				});
			});
		});
	}

	play {
		arg id,fadeIn,forceNew;
		var defPlay=1;
		["play",id,fadeIn].postln;
		if (params.at(id).notNil,{
			if (bufs.at(id).notNil,{
				var makeNew=true;
				var pars=[\id,id,\out1,busOut1,\out2,busOut2,\out3,busOut3,\out4,busOut4,\busPhase,busPhasor,\bufnum,bufs.at(id),\dataout,1,\gate,1,\attack,fadeIn,\cut_fade,cut_fade];
				params.at(id).keysValuesDo({ arg pk,pv; 
					pars=pars++[pk,pv];
				});

				if (syns.at(id).notNil,{
					if (syns.at(id).isRunning,{
						makeNew=false;
						if (forceNew>0,{
							("releasing current synth"+id).postln;
							syns.at(id).set(\release,0.05,\gate,0);
							makeNew=true;
						});
						if (params.at(id).at("oneshot").notNil,{
							if (params.at(id).at("oneshot")>0,{
								("retriggering synth"+id).postln;
								syns.at(id).set(\release,0.05,\gate,0);
								makeNew=true;
							});
						});
					});
				});
				if (params.at(id).at("sampleStart").notNil,{
					if (params.at(id).at("sampleStart")>0,{
						defPlay=2;
					});
				});
				if (params.at(id).at("sampleEnd").notNil,{
					if (params.at(id).at("sampleEnd")<1,{
						defPlay=2;
					});
				});
				if (params.at(id).at("oneshot").notNil,{
					if (params.at(id).at("oneshot")>0,{
						defPlay=1;
					});
				});

				if (makeNew,{
					("making synth"+id+defPlay).postln;
					syns.put(id,Synth.after(syns.at("phasor"),
						"defPlay"++defPlay++bufs.at(id).numChannels,pars,
					).onFree({["freed"+id].postln}));
					NodeWatcher.register(syns.at(id));
				},{
					("updating synth"+id).postln;
					syns.at(id).set(\gate,1,\attack,fadeIn);
				});
			});
		});
	}

	add {
		arg id,fname,playOnLoad;
		var doRead=true;
		["add",id,fname,playOnLoad].postln;
		if (bufs.at(id).notNil,{
			if (bufs.at(id).path==fname,{
				doRead=false;
				["already loaded ",id,fname].postln;
			});
		});
		if (doRead,{
			Buffer.read(server,fname,action:{arg buf;
				var fadeIn=playOnLoad>0;
				var oldBuf=nil;
				if (bufs.at(id).notNil,{
					oldBuf=bufs.at(id);
				});
				if (syns.at(id).notNil,{
					if (syns.at(id).isRunning,{
						syns.at(id).set(\dataout,0);
						stop(id);
						fadeIn=true;
					});
				});

				bufs.put(id,buf);
				("loaded"+PathName(fname).fileName).postln;
				NetAddr("127.0.0.1", 10111).sendMsg("ready",id,id);

				// free the old buf after some time (in case it is playing and fading out)
				if (oldBuf.notNil,{
					Routine{
						5.sleep;
						oldBuf.free;
					}.play;
				});
				if (params.at(id).isNil,{
					params.put(id,Dictionary.new());
				});
				// fade in the synth
				if (fadeIn,{ this.play(id,1,1); }); // GOTCHA: this.play is needed instead of just "play"
			});
		});
	}


	set {
		arg id,key,val,doupdate;
		if (params.at(id).isNil,{
			params.put(id,Dictionary.new());
		});
		//[id,key,val].postln;
		// GOTCHA: if not "asString" then it can be manually polled using at("something")
		params.at(id).put(key.asString,val);
		if (doupdate>0,{
			if (syns.at(id).notNil,{
				if (syns.at(id).isRunning,{
					syns.at(id).set(key,val);
				});
			});
		});
	}

	setRate {
		arg rate,rateLag;
		syns.at("phasor").set(\rate,rate,\rateLag,rateLag);
	}

	resetPhase {
		syns.at("phasor").set(\t_sync,1);		
		syns.keysValuesDo({ arg note, val;
			val.set(\t_sync,1);
		});
	}

	free {
		syns.keysValuesDo({ arg note, val;
			val.free;
		});
		bufs.keysValuesDo({ arg buf, val;
			val.free;
		});
		// make sure things are freed
		synsFinished.do({ arg item, i;
			item.free;
		});
		busPhasor.free;
		busOut1.free;
		busOut2.free;
		busOut3.free;
		busOut4.free;
		synMetronome.free;
		syns.free;
		bufs.free;
	}

}
