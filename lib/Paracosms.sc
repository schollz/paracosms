Paracosms {

	var server;
	var dirCache;
	var busOut;
	var busPhasor;
	var syns;
	var bufs;
	var params;
	var watching;

	*new {
		arg serverName,argBusOut,argDirCache;
		^super.new.init(serverName,argBusOut,argDirCache);
	}

	init {
		arg serverName,argBusOut,argDirCache;

		// set arguments
		server=serverName;
		busOut=argBusOut;
		dirCache=argDirCache;

		syns=Dictionary.new();
		bufs=Dictionary.new();
		params=Dictionary.new();

		watching=0;
		busPhasor=Bus.audio(server,1);
		(1..2).do({arg ch;
			SynthDef("defPlay"++ch,{
				arg amp=0.01,ampLag=0.2,
				lpf=20000,lpfLag=0.2,
				offset=0,offsetLag=0.0,
				t_sync=1,t_syncLag=0.0,
				t_manu=0,t_manuLag=0.0,
				ts=0,tsLag=0.0,
				tsSeconds=0.25,tsSecondsLag=0.0,
				tsSlow=1,tsSlowLag=0.0,
				id=0,dataout=0,fadeInTime=0.1,bufnum,busPhase,out;
				var snd,pos,seconds,tsWindow;
				var frames=BufFrames.ir(bufnum);
				var duration=BufDur.ir(bufnum);
				var syncTrig=Trig.ar(t_sync);
				var manuTrig=Trig.ar(t_manu);
				var syncPos=SetResetFF.ar(syncTrig,manuTrig)*Latch.ar((In.ar(busPhase)+offset).mod(duration)/duration*frames,t_sync);
				//engine.set(4,"t_manu",0.000001,0)
				var manuPos=SetResetFF.ar(manuTrig,syncTrig)*Wrap.ar(syncPos+Latch.ar(t_manu*frames,t_manu),0,frames);
				// var manuPos=SetResetFF.ar(manuTrig,syncTrig)*Latch.ar(t_manu*frames,t_manu);
				var resetPos=syncPos+manuPos;
				amp=VarLag.kr(amp,ampLag,warp:\sine);

				pos=Phasor.ar(
					trig:t_sync+t_manu,
					rate:1.0*BufRateScale.ir(bufnum)/tsSlow,
					start:0.0,
					end:frames,
					resetPos:resetPos,
				);
				tsWindow=Phasor.ar(
					trig:t_sync+t_manu,
					rate:1.0*BufRateScale.ir(bufnum),
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

				snd=snd*amp*EnvGen.ar(Env.new([0,1],[fadeInTime],curve:\sine));
				snd=RLPF.ar(snd,VarLag.kr(lpf.log,lpfLag,warp:\sine).exp,0.707);
				SendTrig.kr(Impulse.kr((dataout>0)*10),id,pos/frames*duration);
				SendTrig.kr(Impulse.kr(10),200+id,Amplitude.kr(snd));
				FreeSelf.kr(Trig.kr(amp<0.01));
				Out.ar(out,snd/10);
			}).send(server);
		});

		SynthDef("defPhasor",{
			arg out,rate=1,rateLag=0.2,t_trig=0;
			Out.ar(out,Phasor.ar(t_trig,Lag.kr(rate,rateLag)/server.sampleRate,0,120000.0));
		}).send(server);

		server.sync;

		syns.put("phasor",Synth.head(server,"defPhasor",[\out,busPhasor]));

	}

	watch {
		arg id;
		if (syns.at(id).notNil,{
			if (watching>0,{
				syns.at(watching).set(\dataout,0);
			});
			watching=id;
			syns.at(watching).set(\dataout,1);
		});
	}

	addMod {
		arg id,fnameOriginal,bpm_source,bpm_target;
		var fname=fnameOriginal;
		if (bpm_source!=bpm_target,{
			fname=(PathName(dirCache)+/+PathName(fnameOriginal).fileName);
			fname=fname.fullPath++"_newbpm"++bpm_target.asInteger++".flac";
			if (File.exists(fname)==false,{
				var cmd="sox"+fnameOriginal+fname+"tempo -m "+(bpm_target/bpm_source)+"rate -v 48k";
				if (fnameOriginal.contains("drum"),{
					cmd="sox"+fnameOriginal+fname+"speed "+(bpm_target/bpm_source)+"rate -v 48k";
				});
				cmd.postln;
				cmd.systemCmd;
			});
		});
		if (bufs.at(id).notNil,{
			bufs.at(id).free;
		});
		if (syns.at(id).notNil,{
			syns.at(id).free;
		}); 
		Buffer.read(server,fname,action:{arg buf;
			bufs.put(id,buf);
			NetAddr("127.0.0.1", 10111).sendMsg("ready",id,id);
		});
	}

	add {
		arg id,fname;
		if (bufs.at(id).notNil,{
			bufs.at(id).free;
		});
		if (syns.at(id).notNil,{
			syns.at(id).free;
		});
		Buffer.read(server,fname,action:{arg buf;
			bufs.put(id,buf);
			("loaded"+PathName(fname).fileName).postln;
			NetAddr("127.0.0.1", 10111).sendMsg("ready",id,id);
		});
	}

	set {
		arg id,key,val,valLag;
		if (bufs.at(id).notNil,{
			var makeSynth=false;
			if (syns.at(id).notNil,{
				if (syns.at(id).isRunning,{},{
					makeSynth=true;
				});
			},{
				makeSynth=true;
			});
			if (makeSynth,{
				var pars=[\id,id,\out,busOut,\busPhase,busPhasor,\bufnum,bufs.at(id),\dataout,1,\fadeInTime,valLag,key,val,key++"Lag",valLag];
				if (params.at(id).notNil,{
					params.at(id).keysValuesDo({ arg pk,pv; 
						pars=pars++[pk,pv];
					});
				},{
					params.put(id,Dictionary.new());
				})
				"making synth".postln;
				syns.put(id,Synth.after(syns.at("phasor"),
					"defPlay"++bufs.at(id).numChannels,pars,
				).onFree({["freed"+id].postln}));
				NodeWatcher.register(syns.at(id));
				// TODO: put all the current parameters into it
			},{
				params.at(id).put(key,val);
				syns.at(id).set(key,val,key++"Lag",valLag);
			});
		});
	}

	setRate {
		arg rate,rateLag;
		syns.at("phasor").set(\rate,rate,\rateLag,rateLag);
	}

	resetPhase {
		syns.at("phasor").set(\t_trig,1);
	}

	free {
		bufs.keysValuesDo({ arg buf, val;
			val.free;
		});
		syns.keysValuesDo({ arg note, val;
			val.free;
		});
		syns.free;
		bufs.free;
		busPhasor.free;
	}

}
