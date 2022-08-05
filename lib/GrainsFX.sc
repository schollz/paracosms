GrainsFX {

	var server;
	var busIn;
	var busOut;
	var params;
	var syn;
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

		params=Dictionary.new();

		SynthDef("defGrains",{
			arg outBus=0,inBus,amp=0.5,
			pitMin=0,pitMax=1,pitPer=120,
			posMin=0,posMax=1,posPer=120,
			sizeMin=0,sizeMax=1,sizePer=120,
			densMin=0,densMax=1,densPer=120,
			texMin=0,texMax=1,texPer=120,
			drywetMin=0,drywetMax=1,drywetPer=120,
			in_gainMin=0,in_gainMax=1,in_gainPer=120,
			spreadMin=0,spreadMax=1,spreadPer=120,
			rvbMin=0,rvbMax=1,rvbPer=120,
			fbMin=0,fbMax=1,fbPer=120,
			grainMin=0.5,grainMax=4,grainPer=120;
			var snd;
			snd=MiGrains.ar(In.ar(inBus,2),
				pit:SinOsc.kr(1/pitPer,rrand(0,3),(pitMax-pitMin)/2,(pitMax-pitMin)/2+pitMin),
				pos:SinOsc.kr(1/posPer,rrand(0,3),(posMax-pitMin)/2,(posMax-posMin)/2+posMin),
				size:SinOsc.kr(1/sizePer,rrand(0,3),(sizeMax-sizeMin)/2,(sizeMax-sizeMin)/2+sizeMin),
				dens:SinOsc.kr(1/densPer,rrand(0,3),(densMax-densMin)/2,(densMax-densMin)/2+densMin),
				tex:SinOsc.kr(1/texPer,rrand(0,3),(texMax-texMin)/2,(texMax-texMin)/2+texMin),
				drywet:SinOsc.kr(1/drywetPer,rrand(0,3),(drywetMax-drywetMin)/2,(drywetMax-drywetMin)/2+drywetMin),
				in_gain:SinOsc.kr(1/in_gainPer,rrand(0,3),(in_gainMax-in_gainMin)/2,(in_gainMax-in_gainMin)/2+in_gainMin),
				spread:SinOsc.kr(1/spreadPer,rrand(0,3),(spreadMax-spreadMin)/2,(spreadMax-spreadMin)/2+spreadMin),
				rvb:SinOsc.kr(1/rvbPer,rrand(0,3),(rvbMax-rvbMin)/2,(rvbMax-rvbMin)/2+rvbMin),
				fb:SinOsc.kr(1/fbPer,rrand(0,3),(fbMax-fbMin)/2,(fbMax-fbMin)/2+fbMin),
				trig:Impulse.kr(SinOsc.kr(1/grainPer,rrand(0,3),(grainMax-grainMin)/2,(grainMax-grainMin)/2+grainMin)),
			);
			Out.ar(outBus,snd*amp);
		}).send(server);
	}

	toggle {
		arg on;
		if (on==1,{
			var pars=[\outBus,busOut,\inBus,busIn];
			params.keysValuesDo({ arg pk,pv; 
				pars=pars++[pk,pv];
			});
			pars.postln;
			syn=Synth.tail(group,"defGrains",pars);
			NodeWatcher.register(syn);
			"grains: running".postln;
		},{
			["grains: stopped"].postln;
			if (syn.notNil,{
				if (syn.isRunning,{
					["grains: freed"].postln;
					syn.free;
				});
			});
		})
	}

	set {
		arg k,v;
		["grains: putting",k,v].postln;
		params.put(k,v);
		if (syn.notNil,{
			if (syn.isRunning,{
				["grains: setting",k,v].postln;
				syn.set(k,v)
			});
		});
	}

	free {
		syn.free;
	}

}
