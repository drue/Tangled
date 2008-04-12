module tangled.reactor;

import tango.core.Memory;
import tango.core.Thread;
import tango.math.Math;
import tango.net.InternetAddress;
import tango.stdc.stringz;
import tango.text.convert.Layout;
import tango.util.log.Log;
import tango.util.log.model.ILevel;
import tango.util.log.ConsoleAppender;
import tango.util.log.DateLayout;
import tango.text.convert.Layout;
import tango.util.collection.ArrayBag;

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
  log = Log.getLogger("tangled.reactor");
  log.addAppender(new ConsoleAppender(new DateLayout()));
  format = new Layout!(char)();
  log.info("Creating reactor.");
  reactor = new Reactor();
}

extern (C) {

  void socket_cb(int fd, short reason, void *usr) {
    IASelectable s = *cast(IASelectable *)usr;
    switch (reason) {
    case EV_READ:
      reactor.callInFiber(&s.readyToRead);
    case EV_WRITE:
      reactor.callInFiber(&s.readyToWrite);
    case EV_TIMEOUT:
      reactor.callInFiber(&s.timeout);
    case EV_SIGNAL:
      reactor.callInFiber(&s.signal);
    }
  }

  void listen_cb(int fd, short reason, void *usr) {
    log.trace(">>> listen_cb");
    IListener s = *cast(IListener *)usr;
    log.trace(">>> accepting");
    IAConduit c;

    try {
      c = s.accept();
    }
    catch (Exception e){
      log.error(format("Caught exception {}", e));
      return;
    }

    log.trace(">>> accepted");
    auto p = s.factory.buildProtocol();
    log.trace(">>> built");
    reactor.callInFiber(&p.makeConnection, c);
    log.trace(">>> connection made");
  }

  void log_cb(int severity, char *msg) {
    log.append(cast(ILevel.Level)severity, fromStringz(msg));
  }

}

class Reactor : IReactorCore
{
    event_base evbase;
    ArrayBag!(event) events;

    this() {
      evbase = event_init();
      events = new ArrayBag!(event);
      event_set_log_callback(&log_cb);
    }

    IDeferred!(char[]) resolve(char[] name, int timeout) {
      assert(0);
      return new Deferred!(char[]);
    }

    void run() {
      log.info("Entering main event loop.");
      event_base_dispatch(evbase);
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
      log.trace(">>> tcpListen");
      auto c = new AServerSocket(bind);
      c.socket.blocking(false);
      auto t = new TCPListener(bind, c, f);
      this.startListening(t);
      f.doStart();
      return t;
    }

    void callInFiber(Callable, Args...)(Callable f, Args args) {
      log.trace(">>> callInFiber");
      void x() {
	f(args);
      }
      auto fiber = new Fiber(&x, false);
      fiber.call();
    }

    void callInFiber(Callable)(Callable f) {
      log.trace(">>> callInFiber");
      void x() {
	f();
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
      //GC.addRoot(&ev);
      //GC.addRoot(&tv);

      event_set(&ev, -1, 0, event_cb, arg);
      event_add(&ev, &tv);
      return c;
    }

    void startListening(IListener s) {
      // need stop listening
	event *ev = new event;
	//events.add(ev);
	auto f = s.factory();
	//GC.addRoot(&ev);
	//GC.addRoot(&f);
	event_set(ev, s.fileHandle, EV_READ|EV_PERSIST, &listen_cb, &f);
	event_base_set(evbase, ev);
	if(int i = event_add(ev, null) != 0)
	  log.error(format(">> startListening failed to add event code {}", i));
	else
	  log.trace(">>> startListening event added");
    }

    void registerRead(IASelectable s, bool once=true) {
      log.trace(">>> registerRead");
      if (once)
	event_once(s.fileHandle, EV_READ, &socket_cb, &s, null);
      else {
	event ev;
	timeval tv;
	GC.addRoot(&ev);
	GC.addRoot(&tv);
	event_set(&ev, s.fileHandle, EV_READ, &socket_cb, &s);
	event_add(&ev, &tv);
      }
    }
    
    void registerWrite(IASelectable s, bool once=true) {
      log.trace(">>> registerWrite");
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
