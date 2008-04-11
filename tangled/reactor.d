module tangled.reactor;

import tango.text.convert.Layout;
import tango.util.log.Log;
import tango.net.InternetAddress;
import tango.stdc.stringz;

import libevent.event;
import libevent.http;

import tangled.defer;
import tangled.evhttp;
import tangled.failure;
import tangled.fiber;
import tangled.interfaces;
import tangled.time;


version(build) {
  pragma(link, "event");
}

Reactor reactor;
Logger log;
static Layout!(char) format;

static this(){
  reactor = new Reactor();
  log = Log.getLogger("tangled.reactor");
  //log.addAppender(new ConsoleAppender(new DateLayout()));
  format = new Layout!(char)();
}


class Reactor : IReactorCore
{
    FiberPool fibers;
    event_base evbase;

    this() {
      evbase = event_init();
    }

    IDeferred!(char[]) resolve(char[] name, int timeout) {
      assert(0);
      return new Deferred!(char[]);
    }

    void run() {
      assert(0);
    }

    void crash() { 
      assert(0);
    }

    void iterate(double delay) {
      assert(0);
    }

    void fireSystemEvent(SystemEvent event) {
      assert(0);
    }

    IHTTPServer httpListen(InternetAddress bind) {
      return new EVHServer(evbase, bind);
    }
}
