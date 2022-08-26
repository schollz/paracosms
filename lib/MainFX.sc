MainFX {

	var server;
	var busIn;
    var busInSC;
	var busOut;
	var syn;
	var group;


	*new {
		arg serverName,argGroup,argBusIn,argBusInSC,argBusOut;
		^super.new.init(serverName,argGroup,argBusIn,argBusInSC,argBusOut);
	}

	init {
		arg serverName,argGroup,argBusIn,argBusInSC,argBusOut;

		// set arguments
		server=serverName;
		group=argGroup;
		busIn=argBusIn;
        busInSC=argBusInSC;
		busOut=argBusOut;

		SynthDef("defMain",{
			arg outBus=0,inBusSC,thresh=0.1,compression=0.1,attack=0.01,release=1,inBus;
			var snd,snd2;
			snd=In.ar(inBus,2);
			sndSC=In.ar(inBusSC,2);
            snd = Compander.ar(snd, sndSC, thresh, 1, compression, attack, release);
			Out.ar(outBus,snd);
		}).send(server);

        server.sync;
        syn=Synth.tail(group,"defMain",[\outBus,0,\inBus,busIn,\inBusSC,busInSC]);
	}

	set {
		arg k,v;
		["Main: putting",k,v].postln;
		if (syn.notNil,{
			if (syn.isRunning,{
				["Main: setting",k,v].postln;
				syn.set(k,v)
			});
		});
	}

	free {
		syn.free;
	}

}
