// Engine_Paracosms

// Inherit methods from CroneEngine
Engine_Paracosms : CroneEngine {

    // Paracosms specific v0.1.0
    var paracosms;
    var fnOSC;
    // Paracosms ^

    *new { arg context, doneCallback;
        ^super.new(context, doneCallback);
    }

    alloc {
        // Paracosms specific v0.0.1
        fnOSC= OSCFunc({
            arg msg, time;
            if (msg[2]>0,{
                // cursor ID, POSITION
                NetAddr("127.0.0.1", 10111).sendMsg("data",msg[2],msg[3]);
            });
        },'/tr', context.server.addr);
        context.server.sync;
        paracosms=Paracosms.new(context.server,0,"/home/we/dust/data/paracosms/cache");
        context.server.sync;

        this.addCommand("add","is", { arg msg;
            paracosms.add(msg[1],msg[2].asString);
        });
        this.addCommand("watch","i", { arg msg;
            paracosms.watch(msg[1]);
        });
        this.addCommand("set","isff", { arg msg;
            paracosms.set(msg[1],msg[2],msg[3],msg[4]);
        });
        this.addCommand("resetPhase","", { arg msg;
            paracosms.resetPhase();
        });
	

        // ^ Paracosms specific

    }

    free {
        // Paracosms Specific v0.0.1
        paracosms.free;
        fnOSC.free;
        // ^ Paracosms specific
    }
}
