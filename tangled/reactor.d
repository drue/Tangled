module tangled.reactor;

import tango.core.Exception;
import tango.core.Memory;
import tango.core.Thread;
import tango.math.Math;
import tango.net.InternetAddress;
import tango.stdc.stringz;
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

private Logger log, evlog;
private Layout!(char) format;
private  event_base evbase;



static this(){
  log = Log.getLogger("tangled.reactor");
  log.addAppender(new ConsoleAppender(new DateLayout()));
  evlog = Log.getLogger("tangled.reactor.libevent");
  evlog.addAppender(new ConsoleAppender(new DateLayout()));
  format = new Layout!(char)();
  evbase = event_init();
  event_set_log_callback(&log_cb);
}

extern (C) {

  void socket_cb(int fd, short reason, void *usr) {
    IASelectable s = cast(IASelectable )usr;
    switch (reason) {
    case EV_READ:
      callInFiber(&s.readyToRead);
      break;
    case EV_WRITE:
      callInFiber(&s.readyToWrite);
      break;
    case EV_TIMEOUT:
      callInFiber(&s.timeout);
      break;
    case EV_SIGNAL:
      callInFiber(&s.signal);
      break;
    }
  }

  void listen_cb(int fd, short reason, void *usr) {
    log.trace(">>> listen_cb");
    auto s = cast(IListener)usr;
    _accept(s);
  }

  void event_cb(int fd, short reason, void *usr) {
    auto s = cast(IDelayedCall)usr;
    callInFiber(&s.call);
  }

  void log_cb(int severity, char *msg) {
    evlog.append(cast(ILevel.Level)severity, fromStringz(msg));
  }

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

EVHServer httpListen(InternetAddress bind) {
  return new EVHServer(evbase, bind);
}

IListener tcpListen(InternetAddress bind, IProtocolFactory f) {
  log.trace(">>> tcpListen");
  auto c = new AServerSocket!(ASocketConduit)(bind);
  c.socket.blocking(false);
  auto t = new TCPListener!(AServerSocket!(ASocketConduit), ASocketConduit)(bind, c, f);
  startListening(t);
  f.doStart();
  return t;
}

/*
  IListener tcpListenEVB(InternetAddress bind, IProtocolFactory f) {
  auto c = new AServerSocket!(AEVBSocketConduit)(bind);
  }
*/

void _accept(IListener s) {
  IAConduit c;
      
  assert(s);
  try {
    c = s.accept();
	
  }
  catch (Exception e){
    log.error(format("Caught exception {}", e));
    return;
  }
}

protected void callInFiber(Callable, Args...)(Callable f, Args args) {
  try {
    auto fiber = new Fiber(delegate void() {log.trace(format("inner fiber {} {}", f, args));f(args);log.trace("inner fiber exit");});
    log.trace(">>> callInFiber calling");
    fiber.call();
    log.trace(">>> callInFiber called");
  }
  catch (FiberException e) {
    log.error(format("Fiber Exception {}", e));
  }
  catch (Exception e) {
    log.error(format("Unhandled exception in fiber: {}", e));
  }
}

DelayedTypeGroup!(Delegate, Args).TDelayedCall callLater(Delegate, Args...)(double delay, Delegate cmd, Args args){
  auto ti = time();
  auto t = (ti + delay);
  auto c = new DelayedTypeGroup!(Delegate, Args).TDelayedCall(t, cmd, args);
  event *ev = new event;
  timeval *tv = new timeval;
  tv.tv_sec = cast(int)floor(delay);
  tv.tv_usec = cast(int)(delay - floor(delay)) * 1000000;
  //GC.addRoot(ev);GC.addRoot(tv);

  event_set(ev, -1, 0, &event_cb, cast(void *)c);
  event_add(ev, tv);
  return c;
}

void startListening(IListener s) {
  // need stop listening
  event *ev = new event;
  event_set(ev, s.fileHandle, EV_READ|EV_PERSIST, &listen_cb, cast(void *)s);
  event_base_set(evbase, ev);
  //GC.addRoot(ev);
     
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
    GC.addRoot(ev);
    event_set(ev, s.fileHandle, EV_READ, &socket_cb, cast(void *)s);
    event_add(ev, null);
  }
}
    
void registerWrite(IASelectable s, bool once=true) {
  if (once)
    event_once(s.fileHandle, EV_WRITE, &socket_cb, cast (void *)s, null);
  else {
    event ev;
    //event_set(ev, cast(int)s.fileHandle, EV_WRITE, &socket_cb, &s);
  }
}

void registerReadWrite(IASelectable s, bool once=true) {
  if (once)
    event_once(s.fileHandle, EV_READ | EV_WRITE, &socket_cb, cast (void *)s, null);
  else {
    event ev;
    //event_set(ev, cast(int)s.fileHandle, EV_READ | EV_WRITE, &socket_cb, &s);
  }
}
    
void unregister(IASelectable s) {
      
}

class TCPListener(ServerSocket, SocketConduit) : IListener {
  IProtocolFactory f;
  ServerSocket s;
  InternetAddress addr;

  this(InternetAddress addr, ServerSocket s, IProtocolFactory f) {
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
  
  SocketConduit accept() {
    auto a = cast(SocketConduit)s.accept();
    assert(a);
    log.trace(format(">>> accept: {}", a));
    auto p = f.buildProtocol();
    callInFiber(&p.makeConnection, a);
    return a;
  }
}
