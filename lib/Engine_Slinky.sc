// Engine_Slinky

// Inherit methods from CroneEngine
Engine_Slinky : CroneEngine {

    // Slinky specific v0.1.0
    var slinky;
    var fnOSC;
    // Slinky ^

    *new { arg context, doneCallback;
        ^super.new(context, doneCallback);
    }

    alloc {
        // Slinky specific v0.0.1
        slinky=Slinky.new(context.server,0);

        fnOSC= OSCFunc({
            arg msg, time;
            if (msg[2]>0,{
                // cursor ID, POSITION
                NetAddr("127.0.0.1", 10111).sendMsg("data",msg[2],msg[3]);
            });
        },'/tr', context.server.addr);

        this.addCommand("add","isff", { arg msg;
            slinky.add(msg[1],msg[2].asString,msg[3],msg[4]);
        });
        this.addCommand("watch","i", { arg msg;
            slinky.watch(msg[1]);
        });
        this.addCommand("set","isff", { arg msg;
            slinky.set(msg[1],msg[2],msg[3],msg[4]);
        });



        // ^ Slinky specific

    }

    free {
        // Slinky Specific v0.0.1
        slinky.free;
        fnOSC.free;
        // ^ Slinky specific
    }
}
