module tangled.reactor;

import tango.core.Thread;
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

extern (C) void listen_cb(int fd, short reason, void *usr) {
  IListener s = *cast(IListener *)usr;
  auto c = s.accept();
  auto p = s.factory.buildProtocol();
  reactor.callInFiber(&p.makeConnection, c);
}


class Reactor : IReactorCore
{
    event_base evbase;

    this() {
      evbase = event_init();
    }

    IDeferred!(char[]) resolve(char[] name, int timeout) {
      assert(0);
      return new Deferred!(char[]);
    }

    void run() {
      event_dispatch();
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

    IListener tcpListen(InternetAddress bind, IProtocolFactory f) {
      auto c = new AServerSocket(bind);
      auto t = new TCPListener(bind, c, f);
      this.startListening(t);
      f.doStart();
      return t;
    }

    void callInFiber(Callable, Args...)(Callable f, Args args) {
      void x() {
	f(args);
      }
      auto fiber = new Fiber(&x, false);
      fiber.call();
    }

    DelayedTypeGroup!(Delegate, Args).TDelayedCall callLater(Delegate, Args...)(double delay, Delegate cmd, Args args){
      auto ti = time();
      auto t = (ti + delay);
      auto c = new DelayedTypeGroup!(Delegate, Args).TDelayedCall(t, cmd, args);
      event ev;
      timeval tv = {floor(delay), (delay - floor(delay)) * 1000000};

      event_set(ev, -1, 0, event_cb, arg);
      event_add(ev, &tv);
      return c;
    }

    void startListening(IListener s) {
      // need stop listening
	event ev;
	timeval tv;
	auto f = s.factory();
	event_set(&ev, s.fileHandle, EV_READ, &listen_cb, &f);
	event_add(&ev, &tv);
    }

    void registerRead(IASelectable s, bool once=true) {
      if (once)
	event_once(s.fileHandle, EV_READ, &socket_cb, &s, null);
      else {
	event ev;
	timeval tv;
	event_set(&ev, s.fileHandle, EV_READ, &socket_cb, &s);
	event_add(&ev, &tv);
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

class TCPListener : IListener {
  IProtocolFactory f;
  AServerSocket s;
  InternetAddress addr;

  this(InternetAddress addr, AServerSocket s, IProtocolFactory f) {
    this.addr = addr;
    this.s = s;
    this.f = f;
  }
  
  InternetAddress remoteAddr() {
    return addr;
  }

  int fileHandle() {
    return s.socket.fileHandle;
  }

  IProtocolFactory factory() {
    return f;
  }
  
  IAConduit accept() {
    return cast(IAConduit)s.accept();
  }
}
