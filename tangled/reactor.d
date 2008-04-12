module tangled.reactor;

import tango.core.Exception;
import tango.core.Memory;
import tango.core.Thread;
import tango.math.Math;
import tango.net.InternetAddress;
import tango.stdc.stringz;
import tango.text.convert.Layout;
import tango.text.convert.Layout;
import tango.util.collection.ArrayBag;
import tango.util.log.ConsoleAppender;
import tango.util.log.DateLayout;
import tango.util.log.Log;
import tango.util.log.model.ILevel;

import libevent.event;
import libevent.http;

import tangled.conduit;
import tangled.defer;
import tangled.evhttp;
import tangled.failure;
import tangled.fiber;
import tangled.interfaces;
import tangled.socket;
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
    IASelectable s = cast(IASelectable )usr;
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
    auto s = cast(IListener)usr;
    reactor._accept(s);
  }

  void event_cb(int fd, short reason, void *usr) {
    log.trace(">>> event_cb");
    auto s = cast(IDelayedCall)usr;
    reactor.callInFiber(&s.call);
  }

  void log_cb(int severity, char *msg) {
    log.append(cast(ILevel.Level)severity, fromStringz(msg));
  }

}

class Reactor : IReactorCore
{
    event_base evbase;

    this() {
      evbase = event_init();
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
      log.trace(format(">>> fd {}", c.socket.fileHandle));
      auto t = new TCPListener(bind, c, f);
      this.startListening(t);
      f.doStart();
      return t;
    }

    void _accept(IListener s) {
      log.trace(">>> accepting");
      IAConduit c;
      
      assert(s);
      try {
	c = s.accept();
	assert(c, "now it's dead");
	log.trace(format(">>> accept: {}", typeof(c).stringof));
	
      }
      catch (Exception e){
	log.error(format("Caught exception {}", e));
	return;
      }
      
      log.trace(">>> accepted");
      /*      assert(s.factory);
      auto p = s.factory.buildProtocol();
      log.trace(">>> built");
      assert(c, "bad conduit before callInFiber");
      reactor.callInFiber(&p.makeConnection, c);
      log.trace(">>> connection made");*/
    }

    void callInFiber(Callable, Args...)(Callable f, Args args) {
      log.trace(">>> callInFiber");
      try {
	auto fiber = new Fiber(delegate void() {f(args);});
	fiber.call();
      }
      catch (FiberException e) {
	log.error(format("Fiber Exception {}", e));
      }
      catch (Exception e) {
	log.error(format("Unhandled exception in fiber: {}", e));
      }
      log.trace(">>> callInFiber done");
    }

    void callInFiber(Callable)(Callable f) {
      log.trace(">>> callInFiber");
      try {
	auto fiber = new Fiber(delegate void() {f();});
	fiber.call();
      }
      catch (FiberException e) {
	log.error(format("Fiber Exception {}", e));
      }
      catch (Exception e) {
	log.error(format("Unhandled exception in fiber: {}", e));
      }
      log.trace(">>> callInFiber done");
    }

    DelayedTypeGroup!(Delegate, Args).TDelayedCall callLater(Delegate, Args...)(double delay, Delegate cmd, Args args){
      auto ti = time();
      auto t = (ti + delay);
      auto c = new DelayedTypeGroup!(Delegate, Args).TDelayedCall(t, cmd, args);
      event *ev = new event;
      timeval *tv = new timeval;
      tv.tv_sec = cast(int)floor(delay);
      tv.tv_usec = cast(int)(delay - floor(delay)) * 1000000;

      event_set(ev, -1, 0, &event_cb, cast(void *)c);
      event_add(ev, tv);
      return c;
    }

    DelayedTypeGroup!(Delegate).TDelayedCall callLater(Delegate)(double delay, Delegate cmd){
      auto ti = time();
      auto t = (ti + delay);
      auto c = new DelayedTypeGroup!(Delegate).TDelayedCall(t, cmd);
      event *ev = new event;
      timeval *tv = new timeval;
      tv.tv_sec = cast(int)floor(delay);
      tv.tv_usec = cast(int)(delay - floor(delay)) * 1000000;

      event_set(ev, -1, 0, &event_cb, cast(void *)c);
      event_add(ev, tv);
      return c;
    }

    void startListening(IListener s) {
      // need stop listening
	event *ev = new event;
	//events.add(ev);
	//GC.addRoot(&ev);
	//GC.addRoot(&f);
	event_set(ev, s.fileHandle, EV_READ|EV_PERSIST, &listen_cb, cast(void *)s);
	event_base_set(evbase, ev);
	if(int i = event_add(ev, null) != 0)
	  log.error(format(">> startListening failed to add event code {}", i));
	else
	  log.trace(">>> startListening event added");
    }

    void registerRead(IASelectable s, bool once=true) {
      log.trace(">>> registerRead");
      if (once)
	event_once(s.fileHandle, EV_READ, &socket_cb, cast(void*)s, null);
      else {
	event *ev = new event;
	event_set(ev, s.fileHandle, EV_READ, &socket_cb, cast(void *)s);
	event_add(ev, null);
      }
    }
    
    void registerWrite(IASelectable s, bool once=true) {
      log.trace(">>> registerWrite");
      if (once)
	event_once(s.fileHandle, EV_WRITE, &socket_cb, cast (void *)s, null);
      else {
	event ev;
	//event_set(ev, cast(int)s.fileHandle, EV_WRITE, &socket_cb, &s);
      }
    }

    void registerReadWrite(IASelectable s, bool once=true) {
      log.trace(">>> registerReadWrite");
      if (once)
	event_once(s.fileHandle, EV_READ | EV_WRITE, &socket_cb, cast (void *)s, null);
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
    auto a = s.accept();
    assert(a);
    log.trace(format(">>> accept: {}", typeof(a).stringof));
    auto p = f.buildProtocol();
    reactor.callInFiber(&p.makeConnection, cast(IAConduit)a);
    return cast(IAConduit)a;
  }
}
