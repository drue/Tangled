module tangled.reactor;

import tango.math.Math;
import tango.net.InternetAddress;
import tango.stdc.stringz;
import tango.text.convert.Layout;
import tango.util.log.Log;

import libevent.event;
import libevent.http;

import tangled.conduit;
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

extern (C) void socket_cb(int fd, short reason, void *usr) {
  IASelectable s = *cast(IASelectable *)usr;
  switch (reason) {
  case EV_READ:
    // fiber s.readyToRead
  case EV_WRITE:
    // fiber s.readyToWrite
  case EV_TIMEOUT:
    // fiber s.timeout
  case EV_SIGNAL:
    // fiber s.signal
  }
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

    DelayedTypeGroup!(Delegate, Args).TDelayedCall callLater(Delegate, Args...)(double delay, Delegate cmd, Args args){
      auto ti = time();
      auto t = (ti + delay);
      auto c = new DelayedTypeGroup!(Delegate, Args).TDelayedCall(t, cmd, args);
      event ev;
      timeval tv = {floor(delay), (delay - floor(delay)) * 1000000};

      event_set(ev, -1, 0, event_cb, arg);
      event_add(ev, tv);
      return c;
    }

    void registerRead(IASelectable s, bool once=true) {
      if (once)
	event_once(s.fileHandle, EV_READ, &socket_cb, &s, null);
      else {
	event ev;
	//event_set(ev, cast(int)s.fileHandle, EV_READ, &socket_cb, &s);
      }
    }
    
    void registerWrite(IASelectable s, bool once=true) {
      if (once)
	event_once(s.fileHandle, EV_WRITE, &socket_cb, &s, null);
      else {
	event ev;
	//event_set(ev, cast(int)s.fileHandle, EV_WRITE, &socket_cb, &s);
      }
    }

    void registerReadWrite(IASelectable s, bool once=true) {
      if (once)
	event_once(s.fileHandle, EV_READ | EV_WRITE, &socket_cb, &s, null);
      else {
	event ev;
	//event_set(ev, cast(int)s.fileHandle, EV_READ | EV_WRITE, &socket_cb, &s);
      }
    }
    
    void unregister(IASelectable s) {
      
    }
}

