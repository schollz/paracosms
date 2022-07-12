Paracosms {

	var server;
	var busOut;
	var busPhasor;
	var syns;
	var bufs;
	var doDelete;
	var watching;

	*new {
		arg serverName,argBusOut;
		^super.new.init(serverName,argBusOut);
	}

	init {
		arg serverName,argBusOut;
		server=serverName;
		busOut=argBusOut;
		syns=Dictionary.new();
		bufs=Dictionary.new();
		doDelete=Dictionary.new();
		watching=0;
		busPhasor=Bus.audio(server,1);
		(1..2).do({arg ch;
			SynthDef("defPlay"++ch,{
				arg amp=0.01,ampLag=0.2,
				lpf=20000,lpfLag=0.2,
				offset=0,offsetLag=0.0,
				id=0,dataout=0,fadeInTime=0.1,bufnum,busPhase,out;
				var snd;
				var frames=BufFrames.ir(bufnum);
				var duration=BufDur.ir(bufnum);
				var seconds=(In.ar(busPhase)+offset).mod(duration);
				amp=VarLag.kr(amp,ampLag,warp:\sine);
				snd=BufRd.ar(ch,bufnum,seconds/duration*frames,interpolation:4);
				snd=snd*amp*EnvGen.ar(Env.new([0,1],[fadeInTime],curve:\sine));
				snd=RLPF.ar(snd,VarLag.kr(lpf.log,lpfLag,warp:\sine).exp,0.707);
				SendTrig.kr(Impulse.kr((dataout>0)*10),id,seconds);
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
		if (watching>0,{
			syns.at(watching).set(\dataout,0);
		});
		watching=id;
		syns.at(watching).set(\dataout,1);
	}

	add {
		arg id,fnameOriginal,bpm_source,bpm_target;
		var fname=PathName.tmp +/+ ("paracosms"++PathName.new(fnameOriginal).fileName);
		if (bpm_source==bpm_target,{
			fname=fnameOriginal;
		},{
			var cmd="sox"+fnameOriginal+fname+"tempo -m "+(bpm_target/bpm_source);
			if (fnameOriginal.contains("drums-"),{
				cmd="sox"+fnameOriginal+fname+"speed "+(bpm_target/bpm_source)+"rate -v 48k";
			});
			cmd.postln;
			cmd.systemCmd;
			doDelete.put(id,1);
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

	set {
		arg id,key,val,valLag;
		var makeSynth=false;
		if (syns.at(id).notNil,{
			if (syns.at(id).isRunning,{},{
				makeSynth=true;
			});
		},{
			makeSynth=true;
		});
		if (makeSynth,{
			"making synth".postln;
			syns.put(id,Synth.after(syns.at("phasor"),"defPlay"++bufs.at(id).numChannels,
				[\id,id,\out,busOut,\busPhase,busPhasor,\bufnum,bufs.at(id),\dataout,1,\fadeInTime,valLag,key,val,key++"Lag",valLag]
			).onFree({["freed"+id].postln}));
			NodeWatcher.register(syns.at(id));
			// TODO: put all the current parameters into it
		},{
			syns.at(id).set(key,val,key++"Lag",valLag);
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
			if (doDelete.at(id).notNil,{
				File.delete(val.path).postln;
			});
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
