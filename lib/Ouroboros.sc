Ouroboros {
	var server;
	var busOut;
	var synRecord;
	var synRecordTrigger;
	var fnXFader;
	var preDelay;
	var busStartFrame;
	var busEndFrame;
	var busPhaseOffset;
	var busPhasor;
	var group;

	*new {
		arg argServer,argGroup,argBusPhasor,argBusOut;
		^super.new.init(argServer,argGroup,argBusPhasor,argBusOut);
	}

	init {
		arg argServer,argGroup,argBusPhasor,argBusOut;
		group=argGroup;
		busPhasor=argBusPhasor;
		server=argServer;
		busOut=argBusOut;
		preDelay=0;

		busStartFrame=Bus.control(server,1);
		busEndFrame=Bus.control(server,1);
		busPhaseOffset=Bus.control(server,1);

		SynthDef("defRecordTrigger",{
			arg threshold=(-60), volume=0.0, id=0;
			var input,onset;
			input = Mix.new(SoundIn.ar([0, 1]))*EnvGen.ar(Env.new([0,1],[0.2]));
			FreeSelf.kr(Trig.kr(Coyote.kr(input,fastLag:0.05,fastMul:0.9,thresh:threshold.dbamp,minDur:0.05)));
			Silent.ar();
		}).send(server);


		SynthDef("defRecordLoop",{
			arg bufnum, delayTime=0.01, recLevel=1.0, preLevel=0.0,t_trig=0,run=0,loop=1,
			recordingTime=0;
			var imp=Impulse.kr(5)*(recordingTime>0);
			SendTrig.kr(imp,777,(recordingTime>0)*Stepper.kr(trig:imp,max:1000000,step:1,reset:Trig.kr(Changed.kr(recordingTime)))/recordingTime/5.0*100.0);
			RecordBuf.ar(
				inputArray: SoundIn.ar([0,1])*2,
				bufnum:bufnum,
				recLevel:recLevel,
				preLevel:preLevel,
				run:run,
				trigger:t_trig,
				loop:loop,
				doneAction:2,
			);
			FreeSelf.kr(TDelay.kr(Changed.kr(recordingTime),recordingTime));
		}).send(server);


		SynthDef("defRecord",{
			arg id, busPhase,bufnum, delayTime=0.01, recLevel=1.0, preLevel=0.0,t_trig=0,run=0,loop=1,recordingFrames=0,
			startFrameBus,endFrameBus,phaseOffsetBus,t_record=0,threshold=60.neg,duration=1;
			var input=SoundIn.ar([0,1]);
			var inputForTrigger=Mix.new(input)*EnvGen.ar(Env.new([0,1],[0.2]));
			var coyoteTrig=Trig.kr(Coyote.kr(inputForTrigger,fastLag:0.05,fastMul:0.9,thresh:threshold.dbamp,minDur:0.05));
			var recordTrig=Latch.kr(DC.kr(1),coyoteTrig+t_record);
			var imp=Impulse.kr(5)*recordTrig;
			var pos=Phasor.ar(
				rate:1,
				start:0,
				end:28800000, // 10 minutes
			);
			var startFrame=Latch.kr(pos,recordTrig);
			var phaseOffset=Latch.ar(In.ar(busPhase).mod(duration),recordTrig);
			var endFrame=(recordTrig*(startFrame+recordingFrames))+((1-recordTrig)*28800000);
			BufWr.ar(
				inputArray: input*EnvGen.ar(Env.new([0,1],[0.05])),
				bufnum:bufnum,
				phase:pos,
			);
			// TODO: USE SENDREPLY INSTEAD
// (
// {
//     SendReply.kr(Impulse.kr(3), '/the_answer', [40, 41, 42, 43] + MouseX.kr, 1905);
// }.play(s);
// )

// o = OSCFunc({ |msg| msg.postln }, '/the_answer');

			// send the startFrame
			Out.kr(startFrameBus,startFrame);
			// send the endFrame
			Out.kr(endFrameBus,endFrame);
			// send the offset 
			Out.kr(phaseOffsetBus,phaseOffset);
			// send the current position in the recording
			SendTrig.kr(imp,2000+id,(pos-startFrame)/(endFrame-startFrame)*100);
			// free self when the position passes the end frame
			FreeSelf.kr(pos>endFrame);
		}).send(server);


		// https://fredrikolofsson.com/f0blog/buffer-xfader/
		fnXFader ={|inBuffer, frames= 2, curve= -2, rotation=0, action|
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
					var resultFinal= arr.copyRange(0, arr.size-1-interleavedFrames);
					interleavedFrames.do{|i|
						var fadeIn= i.lincurve(0, interleavedFrames-1, 0, 1, curve);
						var fadeOut= i.lincurve(0, interleavedFrames-1, 1, 0, 0-curve);
						result[i]= (startArr[i]*fadeIn)+(endArr[i]*fadeOut);
					};
					["rotation",rotation,"frames",frames].postln;
					(arr.size-interleavedFrames).do{|i|
						var j=i+(rotation*inBuffer.numChannels);
						if (j>(arr.size-interleavedFrames-1),{
							j=j-(arr.size-interleavedFrames);
						});
						resultFinal[j]=result[i];
					};
					outBuffer.loadCollection(resultFinal, 0, action);
				});
			});
		};
	}

	recordStart {
		if (synRecord.notNil,{
			if (synRecord.isRunning,{
				// force recording and set predelay to 0
				preDelay=0;
				synRecord.set(\t_record,1);
			});
		});
	}

	record {
		arg argID,argSeconds, argCrossfade, argThreshold, argPreDelay, argStart, actionStart, action;
		var id=argID;
	    var valStartTime=0;
    	var valTriggerTime=0;
		preDelay=argPreDelay;
		// first allocate buffer
		Buffer.alloc(server,server.sampleRate*180,2,{
			arg buf1;
			"ouroborous: buffer ready".postln;
			// start the recording
			synRecord=Synth.tail(group,"defRecord",
				[\busPhase,busPhasor,\id,id,\bufnum,buf1,
				\startFrameBus,busStartFrame,\endFrameBus,busEndFrame,
				\phaseOffsetBus,busPhaseOffset,\t_record,argStart,\duration,argSeconds,
				\recordingFrames,(argSeconds+argCrossfade)*server.sampleRate,\threshold,argThreshold]
			).onFree({
				arg syn;
				var frameStart=busStartFrame.getSynchronous-(preDelay*server.sampleRate).round; 
				var frameEnd=busEndFrame.getSynchronous;
				var frameOffset=(busPhaseOffset.getSynchronous*server.sampleRate).round;
				var frameTotal=(frameEnd-frameStart).round.asInteger;
				if (frameStart<0,{
					frameStart=0;
				});
				("ouroborous: done recording."+(frameTotal/server.sampleRate)+"seconds").postln;
				["frameStart",frameStart,"frameTotal",frameTotal].postln;
				Buffer.alloc(server, frameTotal, buf1.numChannels, {|buf2|
					["alloced",buf2].postln;
					buf1.loadToFloatArray(
						index:frameStart,
						count:frameTotal,
						action:{|arr|
							// try to rotate the array?
							buf2.loadCollection(arr,0,action:{ arg buf3;
								var crossfadeFrames=frameTotal-((argSeconds*server.sampleRate).round.asInteger);
								["frameTotal",frameTotal,"((argSeconds*server.sampleRate).round.asInteger)",((argSeconds*server.sampleRate).round.asInteger)].postln;
								["frameOffset",frameOffset].postln;
								["loaded",buf3].postln;
								["argSeconds",argSeconds,"argCrossfade",argCrossfade,"crossfadeFrames",crossfadeFrames].postln;
								fnXFader.value(buf3,crossfadeFrames,-2,frameOffset,{ arg buf4;
									["faded",buf4].postln;
									action.value(buf4);
									buf1.free;
									buf2.free;
									buf3.free;
									Routine {
										3.wait;
										buf4.free;
									}.play;
								});
							});
						}
					);
				});
			});

			// // start the recording trigger
			// synRecordTrigger=Synth.new("defRecordTrigger",[\threshold,argThreshold]).onFree({arg v;
			// 	valTriggerTime=SystemClock.seconds;
			// 	// start the timer to release the recording buffer
			// 	[argSeconds,preDelay,argCrossfade].postln;
			// 	actionStart.value();
			// 	synRecord.set(\recordingTime,argSeconds-preDelay+argCrossfade);
			// 	("ouroborous: recording for"+(argSeconds-preDelay+argCrossfade)+"seconds").postln;
			// });

		});
	}


	free {
        synRecord.free;
        busOut.free;
        busStartFrame.free;
        busEndFrame.free;
        busPhaseOffset.free;
	}
}