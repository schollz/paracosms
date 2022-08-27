MainFX {

	var server;
	var busIn;
    var busInNSC;
    var busSC;
	var busOut;
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

		SynthDef("defMain",{
			arg outBus=0,inBusNSC,inSC,sidechain_mult=2,compress_thresh=0.1,compress_level=0.1,compress_attack=0.01,compress_release=1,inBus;
			var snd,sndSC,sndNSC;
			snd=In.ar(inBus,2);
			sndNSC=In.ar(inBusNSC,2);
			sndSC=In.ar(inSC,2);
            snd = Compander.ar(snd, sndSC*sidechain_mult, 
            	compress_thresh, 1, compress_level, 
            	compress_attack, compress_release);
            snd = snd + sndNSC;
			Out.ar(outBus,snd);
		}).send(server);

        server.sync;
        syn=Synth.tail(group,"defMain",[\outBus,0,\sidechain_mult,0.5,\inBus,busIn,\inBusNSC,busInNSC,\inSC,busSC]);
        NodeWatcher.register(syn);
	}

	set {
		arg k,v;
		["Main: putting",k,v].postln;
		if (syn.notNil,{
			if (syn.isRunning,{
				["Main: setting",k,v].postln;
				syn.set(k.asString,v);
			});
		});
	}

	free {
		syn.free;
	}

}
