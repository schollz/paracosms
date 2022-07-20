GreyholeFX {

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

		SynthDef("defGreyhole",{
			arg outBus=0,inBus,amp=1.0,
            delayTime=2.0,damp=0.0,size=1.0,diff=0.707,feedback=0.9,modDepth=0.1,modFreq=2.0;
			var snd;
            snd=Greyhole.ar(In.ar(inBus,2), 
                delayTime: delayTime, 
                damp: damp, 
                size: size, 
                diff: diff, 
                feedback: feedback, 
                modDepth: modDepth, 
                modFreq: modFreq
            );
			Out.ar(outBus,snd*amp);
		}).send(server);

	}

	toggle {
		arg on;
		if (on==1,{
			var pars=[\outBus,busOut,\inBus,busIn,\buf,buf];
			params.keysValuesDo({ arg pk,pv; 
				pars=pars++[pk,pv];
			});
			pars.postln;
			syn=Synth.tail(group,"defGreyhole",pars);
			NodeWatcher.register(syn);
			"greyhole: running".postln;
		},{
			["greyhole: stopped"].postln;
			if (syn.notNil,{
				if (syn.isRunning,{
					["greyhole: freed"].postln;
					syn.free;
				});
			});
		})
	}

	set {
		arg k,v;
		["greyhole: putting",k,v].postln;
		params.put(k,v);
		if (syn.notNil,{
			if (syn.isRunning,{
				["greyhole: setting",k,v].postln;
				syn.set(k,v)
			});
		});
	}

	free {
		syn.free;
		buf.free;
	}

}
