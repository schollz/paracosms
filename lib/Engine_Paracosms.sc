// Engine_Paracosms

// Inherit methods from CroneEngine
Engine_Paracosms : CroneEngine {

    // Paracosms specific v0.1.0
    var paracosms;
    var ouroboros;
    var tapedeck;
    var greyhole;
    var clouds;
    var fnOSC;
    var startup;
    var startupNum;
    var busTapedeck;
    var busClouds;
    var busGreyhole;
    var groupSynths;
    var groupEffects;
    // Paracosms ^

    *new { arg context, doneCallback;
        ^super.new(context, doneCallback);
    }

    alloc {
        // Paracosms specific v0.0.1
        busTapedeck=Bus.audio(context.server,2);
        busClouds=Bus.audio(context.server,2);
        busGreyhole=Bus.audio(context.server,2);
        groupSynths=Group.new;
        context.server.sync;
        groupEffects=Group.new(groupSynths,\addAfter);
        context.server.sync;

        // startup systems
        startup=0;
        startupNum=1.0.neg;

        fnOSC= OSCFunc({
            arg msg, time;
            if (msg[2]==444,{
                ["trigger",msg[3]].postln;
                NetAddr("127.0.0.1", 10111).sendMsg("trigger",msg[3],msg[3]);
            },{
                if (msg[2]==777,{
                    NetAddr("127.0.0.1", 10111).sendMsg("progress",msg[3],msg[3]);
                },{
                    if (msg[2]>0,{
                        // cursor ID, POSITION
                        NetAddr("127.0.0.1", 10111).sendMsg("data",msg[2],msg[3]);
                    });
                });
            });
        },'/tr', context.server.addr);
        context.server.sync;
        paracosms=Paracosms.new(context.server,groupSynths,0,busTapedeck,busClouds,busGreyhole,"/home/we/dust/data/paracosms/cache");
        ouroboros=Ouroboros.new(context.server,0);
        tapedeck=TapedeckFX.new(context.server,groupEffects,busTapedeck,0);
        clouds=CloudsFX.new(context.server,groupEffects,busClouds,0);
        greyhole=GreyholeFX.new(context.server,groupEffects,busGreyhole,0);
        context.server.sync;

        this.addCommand("add","isi", { arg msg;
            if (startup>0,{
                startupNum=startupNum+1.0;
                Routine {
                    (startupNum/10.0).wait;
                    paracosms.add(msg[1],msg[2].asString,msg[3]);
                }.play;
            },{
                paracosms.add(msg[1],msg[2].asString,msg[3]);
            });
        });
        this.addCommand("watch","i", { arg msg;
            paracosms.watch(msg[1]);
        });
        this.addCommand("play","i", { arg msg;
            paracosms.play(msg[1]);
        });
        this.addCommand("stop","i", { arg msg;
            paracosms.stop(msg[1]);
        });
        this.addCommand("set","isff", { arg msg;
            paracosms.set(msg[1],msg[2],msg[3],msg[4]);
        });
        this.addCommand("resetPhase","", { arg msg;
            paracosms.resetPhase();
        });
        this.addCommand("pattern","if", { arg msg;
            paracosms.pattern(msg[1],msg[2].asFloat);
        });
        this.addCommand("record_start","",{ arg msg;
            ouroboros.recordStart();
        });
        this.addCommand("record","isffff", { arg msg;
            var id=msg[1];
            var filename=msg[2];
            var seconds=msg[3];
            var crossfade=msg[4];
            var threshold=msg[5];
            var preDelay=msg[6];
            ouroboros.record(seconds,crossfade,threshold,preDelay,{
              //NetAddr("127.0.0.1", 10111).sendMsg("recording",id,filename);
            },{ arg buf;
                ["done",buf,"writing",filename].postln;
                buf.write(filename.asString,headerFormat: "wav", sampleFormat: "int16", completionMessage:{
                    ["wrote",buf].postln;
                    // a small delay is needed for the file to be finished writing
                    Routine {
                        0.2.wait;
                        NetAddr("127.0.0.1", 10111).sendMsg("recorded",id,filename);
                    }.play;
                });
            });
        });	
        this.addCommand("startup","i",{arg msg;
            startup=msg[1];
            startupNum=1.0.neg;
        });

        // tapedeck
        this.addCommand("tapedeck_toggle","i",{arg msg;
            tapedeck.toggle(msg[1]);
        });
        this.addCommand("tapedeck_set","sf",{arg msg;
            tapedeck.set(msg[1],msg[2]);
        });

        // clouds
        this.addCommand("clouds_toggle","i",{arg msg;
            clouds.toggle(msg[1]);
        });
        this.addCommand("clouds_set","sf",{arg msg;
            clouds.set(msg[1],msg[2]);
        });

        // greyhole
        this.addCommand("greyhole_toggle","i",{arg msg;
            greyhole.toggle(msg[1]);
        });
        this.addCommand("greyhole_set","sf",{arg msg;
            greyhole.set(msg[1],msg[2]);
        });

        // metronome
        this.addCommand("metronome","fff",{arg msg;
            var bpm=msg[1];
            var note=msg[2];
            var amp=msg[3];
            paracosms.metronome(bpm,note,amp);
        });


        // ^ Paracosms specific

    }

    free {
        // Paracosms Specific v0.0.1
        paracosms.free;
        ouroboros.free;
        tapedeck.free;
        greyhole.free;
        clouds.free;
        fnOSC.free;
        busGreyhole.free;
        busClouds.free;
        busTapedeck.free;
        // ^ Paracosms specific
    }
}
