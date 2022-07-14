Ouroborus {
	var server;
	var busOut;
	var synRecord;
	var fnXFader;

	*new {
		arg argServer,argBusOut;
		^super.new.init(argServer,argBusOut);
	}

	init {
		arg argServer,argBusOut;
		server=argServer;
		busOut=argBusOut;

		SynthDef("defRecordTrigger",{
			arg threshold=(-60), volume=0.0, id=0;
			var input,onset;
			input = Mix.new(SoundIn.ar([0, 1]))*EnvGen.ar(Env.new([0,1],[0.2]));
			FreeSelf.kr(Trig.kr(Coyote.kr(input,fastLag:0.05,fastMul:0.9,thresh:threshold.dbamp,minDur:0.05)));
			Silent.ar();
		}).send(server);


		SynthDef("defRecordLoop",{
			arg bufnum, delayTime=0.01, recLevel=1.0, preLevel=0.0,t_trig=0,run=0,loop=1;
			var input;
			RecordBuf.ar(
				inputArray: SoundIn.ar([0,1]),
				bufnum:bufnum,
				recLevel:recLevel,
				preLevel:preLevel,
				run:run,
				trigger:t_trig,
				loop:loop,
				doneAction:2,
			);
		}).send(server);


		// https://fredrikolofsson.com/f0blog/buffer-xfader/
		fnXFader ={|inBuffer, duration= 2, curve= -2, action|
			var frames= duration*inBuffer.sampleRate;
			if(frames>inBuffer.numFrames, {
				"xfader: crossfade duration longer than half buffer - clipped.".warn;
			});
			frames= frames.min(inBuffer.numFrames.div(2)).round.asInteger;
			Buffer.alloc(inBuffer.server, inBuffer.numFrames-frames, inBuffer.numChannels, {|outBuffer|
				inBuffer.loadToFloatArray(action:{|arr|
					var interleavedFrames= frames*inBuffer.numChannels;
					var startArr= arr.copyRange(0, interleavedFrames-1);
					var endArr= arr.copyRange(arr.size-interleavedFrames, arr.size-1);
					var result= arr.copyRange(0, arr.size-1-interleavedFrames);
					interleavedFrames.do{|i|
						var fadeIn= i.lincurve(0, interleavedFrames-1, 0, 1, curve);
						var fadeOut= i.lincurve(0, interleavedFrames-1, 1, 0, 0-curve);
						result[i]= (startArr[i]*fadeIn)+(endArr[i]*fadeOut);
					};
					outBuffer.loadCollection(result, 0, action);
				});
			});
		};
	}

	record {
		arg argSeconds, argCrossfade, argThreshold, action;
	    var valStartTime=0;
    	var valTriggerTime=0;
		var preDelay=0.03;
		// first allocate buffer
		Buffer.alloc(server,server.sampleRate*180,2,{
			arg buf1;
			"ouroborous: buffer ready".postln;
			valStartTime=SystemClock.seconds;
			// start the recording
			synRecord=Synth("defRecordLoop",[\bufnum,buf1,\t_trig,1,\run,1,\loop,0]).onFree({
				arg syn;
				var valFinishTime=SystemClock.seconds;
				var frameStart=((valTriggerTime-valStartTime-preDelay)*server.sampleRate).round.asInteger;
				var frameTotal=((valFinishTime-valTriggerTime)*server.sampleRate).round.asInteger;
				if (frameStart<0,{
					frameStart=0;
				});
				("ouroborous: done recording."+(valFinishTime-valTriggerTime)+"seconds recorded after waiting"+(valTriggerTime-valStartTime)+"seconds").postln;
				["frameStart",frameStart,"frameTotal",frameTotal].postln;
				Buffer.alloc(server, frameTotal, buf1.numChannels, {|buf2|
					buf1.loadToFloatArray(
						index:frameStart,
						count:frameTotal,
						action:{|arr|
							buf2.loadCollection(arr,0,action:{ arg buf3;
								buf3.postln;
								argSeconds.postln;
								fnXFader.value(buf3,buf3.duration-argSeconds,-2,{ arg buf4;
									action.value(buf4);
								});
							});
						}
					);
				});
			});

			// start the recording trigger
			Synth.new("defRecordTrigger",[\threshold,argThreshold]).onFree({arg v;
				valTriggerTime=SystemClock.seconds;
				// start the timer to release the recording buffer
				Routine {
					[argSeconds,preDelay,argCrossfade].postln;
					("ouroborous: recording for"+(argSeconds-preDelay+argCrossfade)+"seconds").postln;
					(argSeconds-preDelay+argCrossfade).wait;
					synRecord.free;
				}.play;
			});

		});
	}


	free {
        if (synRecord.notNil,{
            synRecord.free;
        });
	}
}