GreyholeFX {

	var server;
	var busIn;
    var busInNSC;
    var busSC;
	var busOut;
	var params;
	var syn;
	var group;


	*new {
		arg serverName,argGroup,argBusIn,argBusInNSC,argBusSC,argBusOut;
		^super.new.init(serverName,argGroup,argBusIn,argBusInNSC,argBusSC,argBusOut);
	}

	init {
		arg serverName,argGroup,argBusIn,argBusInNSC,argBusSC,argBusOut;

		// set arguments
		server=serverName;
		group=argGroup;
		busIn=argBusIn;
        busInNSC=argBusInNSC;
        busSC=argBusSC;
		busOut=argBusOut;

		params=Dictionary.new();

		SynthDef("defGreyhole",{
			arg  outBus=0,inBusNSC,inSC,sidechain_mult=2,compress_thresh=0.1,compress_level=0.1,compress_attack=0.01,compress_release=1,inBus,amp=1.0,
            delayTime=2.0,damp=0.0,size=1.0,diff=0.707,feedback=0.9,modDepth=0.1,modFreq=2.0;
			var snd,sndSC,sndNSC,snd2;
			snd=In.ar(inBus,2);
			sndNSC=In.ar(inBusNSC,2);
			sndSC=In.ar(inSC,2);
            snd = Compander.ar(snd, sndSC*sidechain_mult, 
            	compress_thresh, 1, compress_level, 
            	compress_attack, compress_release);
            snd = snd + sndNSC;
            snd=Greyhole.ar(snd, 
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
			var pars=[\outBus,busOut,\inBus,busIn,\inBusNSC,busInNSC,\inSC,busSC];
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
	}

}
