Tapedeck {

	var server;
	var busIn;
	var busOut;
	var params;
	var syn;
	var buf;


	*new {
		arg serverName,argBusIn,argBusOut;
		^super.new.init(serverName,argBusIn,argBusOut);
	}

	init {
		arg serverName,argBusIn, argBusOut;

		// set arguments
		server=serverName;
		busIn=argBusIn;
		busOut=argBusOut;

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
			var pw,pr,sndr,rate,switch;
			var wow = wobble_amp*SinOsc.kr(wobble_rpm/60,mul:0.1);
			var flutter = flutter_amp*SinOsc.kr(flutter_fixedfreq+LFNoise2.kr(flutter_variationfreq),mul:0.02);
			rate= 1 + (wowflu * (wow+flutter));		
			snd=In.ar(inBus,2);
			
			// write to tape and read from
			pw=Phasor.ar(0, BufRateScale.kr(buf), 0, BufFrames.kr(buf));
			pr=DelayL.ar(Phasor.ar(0, BufRateScale.kr(buf)*rate, 0, BufFrames.kr(buf)),0.2,0.2);
			BufWr.ar(snd,buf,pw);
			sndr=BufRd.ar(2,buf,pr,interpolation:4);
			switch=Lag.kr(wowflu>0,1);
			snd=SelectX.ar(switch,[snd,sndr]);
			
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
		if (on==1,{
			var pars=[\outBus,busOut,\inBus,busIn,\buf,buf];
			params.keysValuesDo({ arg pk,pv; 
				pars=pars++[pk,pv];
			});
			buf=Buffer.alloc(server,48000*180,2);
			syn=Synth.tail(server,"defTapedeck",server,pars);
			NodeWatcher.register(syn);
			["tapedeck running"].postln;
		},{
			if (syn.notNil,{
				if (syn.isRunning,{
					syn.free;
					buf.free;
				})
			})
			["tapedeck stopped"].postln;
		})
	}

	set {
		arg k,v;
		params.put(k,v);
		if (syn.notNil,{
			if (syn.isRunning,{
				syn.set(k,v)
			});
		});
	}

	free {
		syn.free;
		buf.free;
	}

}
