Slinky {

	var server;
	var busOut;
	var busPhasor;
	var syns;
	var bufs;
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
		watching=0;
		busPhasor=Bus.audio(server,1);
		(1..2).do({arg ch;
			SynthDef("defPlay"++ch,{
				arg amp=0,ampLag=0.2,
				lpf=20000,lpfLag=0.2,
				offset=0,offsetLag=0.0,
				id=0,dataout=0,bufnum,busPhase,out;
				var snd;
				var frames=BufFrames.ir(bufnum);
				var duration=BufDur.ir(bufnum);
				var seconds=(In.ar(busPhase)+offset).mod(duration);
				snd=BufRd.ar(ch,bufnum,seconds/duration*frames);
				snd=snd*VarLag.kr(amp,ampLag,warp:\sine);
				snd=RLPF.ar(snd,VarLag.kr(lpf.log,lpfLag,warp:\sine).exp,0.707);
				SendTrig.kr(Impulse.kr((dataout>0)*10),id,seconds);
				SendTrig.kr(Impulse.kr(10),200+id,Amplitude.kr(snd));
				Out.ar(out,snd);
			}).send(server);
		});

		SynthDef("defPhasor",{
			arg out,rate=1,rateLag=0.2;
			Out.ar(out,Phasor.ar(0,Lag.kr(rate,rateLag)/server.sampleRate,0,120000.0));
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
		var fname=PathName.tmp +/+ ("slinky"++PathName.new(fnameOriginal).fileName);
		var cmd="sox"+fnameOriginal+fname+"tempo -m "+(bpm_target/bpm_source);
		if (fnameOriginal.contains("drums-"),{
			cmd="sox"+fnameOriginal+fname+"speed "+(bpm_target/bpm_source)+"rate -v 48k";
		});
		if (bpm_source==bpm_target,{
			cmd="cp"+fnameOriginal+fname;
		});
		cmd.postln;
		cmd.systemCmd;
		if (bufs.at(fname).isNil,{
			Buffer.read(server,fname,action:{arg buf;
				bufs.put(fname,buf);
				syns.put(id,Synth.after(syns.at("phasor"),"defPlay"++bufs.at(fname).numChannels,
					[\id,id,\out,busOut,\busPhase,busPhasor,\bufnum,bufs.at(fname),\amp,0]
				));
				NetAddr("127.0.0.1", 10111).sendMsg("ready",id,id);
			});
		},{
			if (syns.at(id).isNil,{
				syns.put(id,Synth.after(syns.at("phasor"),"defPlay"++bufs.at(fname).numChannels,
					[\id,id,\out,busOut,\busPhase,busPhasor,\bufnum,bufs.at(fname),\amp,0]
				));
			});
		});
	}

	set {
		arg id,key,val,valLag;
		if (syns.at(id).notNil,{
			[key.asSymbol,val].postln;
			syns.at(id).set(key,val,key++"Lag",valLag);
		});
	}

	setRate {
		arg rate,rateLag;
		syns.at("phasor").set(\rate,rate,\rateLag,rateLag);
	}

	free {
		bufs.keysValuesDo({ arg buf, val;
			File.delete(val.path).postln;
			val.free;
		});
		syns.keysValuesDo({ arg note, val;
			val.free;
		});
	}

}
