// Engine_Paracosms

// Inherit methods from CroneEngine
Engine_Paracosms : CroneEngine {

    // Paracosms specific v0.1.0
    var paracosms;
    var ouroboros;
    var tapedeck;
    var greyhole;
    var grains;
    var main;
    var fnOSC;
    var oscPhase;
    var startup;
    var startupNum;
    var busPhasor;
    var busTapedeck;
    var busGrains;
    var busGreyhole;
    var busMain;
    var busSC;
    var busTapedeckNSC;
    var busGrainsNSC;
    var busGreyholeNSC;
    var busMainNSC;
    var groupSynths;
    var groupEffects;
    // Paracosms ^

    *new { arg context, doneCallback;
        ^super.new(context, doneCallback);
    }

    alloc {
        // Paracosms specific v0.0.1
        busPhasor=Bus.audio(context.server,1);
        busTapedeck=Bus.audio(context.server,2);
        busGrains=Bus.audio(context.server,2);
        busGreyhole=Bus.audio(context.server,2);
        busMain=Bus.audio(context.server,2);
        busTapedeckNSC=Bus.audio(context.server,2);
        busGrainsNSC=Bus.audio(context.server,2);
        busGreyholeNSC=Bus.audio(context.server,2);
        busMainNSC=Bus.audio(context.server,2);
        busSC=Bus.audio(context.server,2);
        groupSynths=Group.new;
        context.server.sync;
        groupEffects=Group.new(groupSynths,\addAfter);
        context.server.sync;

        // startup systems
        startup=0;
        startupNum=1.0.neg;

        fnOSC= OSCFunc({
            arg msg, time;
            if (msg[2]>2000,{
                NetAddr("127.0.0.1", 10111).sendMsg("progress",msg[2]-2000,msg[3]);
            },{
                if (msg[2]>0,{
                    // cursor ID, POSITION
                    NetAddr("127.0.0.1", 10111).sendMsg("data",msg[2],msg[3]);
                });
            });
        },'/tr', context.server.addr);

        oscPhase=OSCFunc({ |msg| 
            NetAddr("127.0.0.1", 10111).sendMsg("phase",msg[3],msg[3]);            
        },'/phase');

        context.server.sync;
        paracosms=Paracosms.new(context.server,groupSynths,busPhasor,busSC,busMain,busTapedeck,busGrains,busGreyhole,busMainNSC,busTapedeckNSC,busGrainsNSC,busGreyholeNSC,"/home/we/dust/data/paracosms/cache");
        ouroboros=Ouroboros.new(context.server,groupSynths,busPhasor,0);
        tapedeck=TapedeckFX.new(context.server,groupEffects,busTapedeck,0);
        grains=GrainsFX.new(context.server,groupEffects,busGrains,0);
        greyhole=GreyholeFX.new(context.server,groupEffects,busGreyhole,0);
        main=MainFX.new(context.server,groupEffects,busMain,busMainNSC,busSC,0);
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
            paracosms.watch(msg[1].asInteger);
        });
        this.addCommand("play","if", { arg msg;
            paracosms.play(msg[1].asInteger,msg[2],0);
        });
        this.addCommand("stutter","ifff", { arg msg;
            paracosms.stutter(msg[1].asInteger,msg[2],msg[3],msg[4]);
        });
        this.addCommand("cut","ifff", { arg msg;
            paracosms.cut(msg[1].asInteger,msg[2],msg[3],msg[4]);
        });
        this.addCommand("cut_fade","f", { arg msg;
            paracosms.cut_fade(msg[1]);
        });
        this.addCommand("stop","if", { arg msg;
            paracosms.stop(msg[1].asInteger,msg[2]);
        });
        this.addCommand("set","isf", { arg msg;
            paracosms.set(msg[1].asInteger,msg[2],msg[3],1);
        });
        this.addCommand("set_silent","isf", { arg msg;
            paracosms.set(msg[1].asInteger,msg[2],msg[3],0);
        });
        this.addCommand("resetPhase","", { arg msg;
            paracosms.resetPhase();
        });
        this.addCommand("pattern","if", { arg msg;
            paracosms.pattern(msg[1].asInteger,msg[2].asFloat);
        });
        this.addCommand("record_start","i",{ arg msg;
            var id=msg[1].asInteger;
            ouroboros.recordStart(id);
        });
        this.addCommand("record","isffffiif", { arg msg;
            var id=msg[1].asInteger;
            var filename=msg[2].asString;
            var seconds=msg[3];
            var crossfade=msg[4];
            var threshold=msg[5];
            var preDelay=msg[6];
            var startImmedietly=msg[7];
            var playWhenFinished=msg[8];
            var allowRotation=msg[9];
            ouroboros.record(id,seconds,crossfade,threshold,preDelay,startImmedietly,allowRotation,{
            },{ arg buf;
                ["done",buf,"writing",filename].postln;
                buf.write(filename,headerFormat: "wav", sampleFormat: "int16", completionMessage:{
                    ["wrote",buf].postln;
                    // a small delay is needed for the file to be finished writing
                    Routine {
                        0.2.wait;
                        NetAddr("127.0.0.1", 10111).sendMsg("recorded",id,filename);
                        if (playWhenFinished>0,{
                            paracosms.add(id,filename.asString,1);
                        });
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

        // grains
        this.addCommand("grains_toggle","i",{arg msg;
            grains.toggle(msg[1]);
        });
        this.addCommand("grains_set","sf",{arg msg;
            grains.set(msg[1],msg[2]);
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
        grains.free;
        fnOSC.free;
        busGreyhole.free;
        busGrains.free;
        busTapedeck.free;
        busPhasor.free;
        oscPhase.free;
        // ^ Paracosms specific
    }
}
