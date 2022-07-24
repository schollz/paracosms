TapedeckFX {

	var server;
	var busIn;
	var busOut;
	var params;
	var syn;
	var buf;
	var group;


	*new {
		arg serverName,argGroup,argBusIn,argBusOut;
		^super.new.init(serverName,argGroup,argBusIn,argBusOut);
	}

	init {
		arg serverName,argGroup,argBusIn, argBusOut;

		// set arguments
		server=serverName;
		group=argGroup;
		busIn=argBusIn;
		busOut=argBusOut;
		buf=Buffer.alloc(server,server.sampleRate*180,2);

		params=Dictionary.new();

		SynthDef("defTapedeck",{
			arg outBus=0,inBus,amp=0.5,tape_wet=0.8,tape_bias=0.8,saturation=0.8,drive=0.8,
			tape_oversample=2,mode=0,
			dist_wet=0,drivegain=0.5,dist_bias=0,lowgain=0.1,highgain=0.1,
			shelvingfreq=600,dist_oversample=1,
			wowflu=1.0,
			wobble_rpm=33, wobble_amp=0.05, flutter_amp=0.03, flutter_fixedfreq=6, flutter_variationfreq=2,
			hpf=60,hpfqr=0.6,
			lpf=18000,lpfqr=0.6,
			buf;
			var snd;
			var pw,pr,sndr,rate,switcher;
			var wow = wobble_amp*SinOsc.kr(wobble_rpm/60,mul:0.1);
			var flutter = flutter_amp*SinOsc.kr(flutter_fixedfreq+LFNoise2.kr(flutter_variationfreq),mul:0.02);
			rate= 1 + (wowflu * (wow+flutter));		
			snd=In.ar(inBus,2);
			
			// write to tape and read from
			pw=Phasor.ar(0, BufRateScale.ir(buf), 0, BufFrames.ir(buf));
			pr=DelayL.ar(Phasor.ar(0, BufRateScale.ir(buf)*rate, 0, BufFrames.ir(buf)),0.2,0.2);
			BufWr.ar(snd,buf,pw);
			sndr=BufRd.ar(2,buf,pr,interpolation:4);
			switcher=Lag.kr(wowflu>0,1);
			snd=SelectX.ar(switcher,[snd,sndr]);
			
			snd=snd*amp;
			
			snd=SelectX.ar(Lag.kr(tape_wet,1),[snd,AnalogTape.ar(snd,tape_bias,saturation,drive,tape_oversample,mode)]);
			
			snd=SelectX.ar(Lag.kr(dist_wet/10,1),[snd,AnalogVintageDistortion.ar(snd,drivegain,dist_bias,lowgain,highgain,shelvingfreq,dist_oversample)]);			
			
			snd=RHPF.ar(snd,hpf,hpfqr);
			snd=RLPF.ar(snd,lpf,lpfqr);
			
			Out.ar(outBus,snd);
		}).send(server);

	}

	toggle {
		arg on;
		var alreadyOff=true;
		if (on==1,{
			if (syn.notNil,{
				if (syn.isRunning,{
					alreadyOff=false;
				});
			});
			if (alreadyOff,{
				var pars=[\outBus,busOut,\inBus,busIn,\buf,buf];
				params.keysValuesDo({ arg pk,pv; 
					pars=pars++[pk,pv];
				});
				pars.postln;
				syn=Synth.tail(group,"defTapedeck",pars);
				NodeWatcher.register(syn);
				"tapedeck: running with buffer:".postln;
				buf.postln;
			});
		},{
			["tapedeck: stopped"].postln;
			if (syn.notNil,{
				if (syn.isRunning,{
					["tapedeck: freed"].postln;
					syn.free;
				});
			});
		})
	}

	set {
		arg k,v;
		["tapedeck: putting",k,v].postln;
		params.put(k,v);
		if (syn.notNil,{
			if (syn.isRunning,{
				["tapedeck: setting",k,v].postln;
				syn.set(k,v)
			});
		});
	}

	free {
		syn.free;
		buf.free;
	}

}
