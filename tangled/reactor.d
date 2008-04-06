module tangled.reactor;

import tango.core.Exception;
import tango.core.Traits;
import tango.io.Console;
import tango.io.selector.EpollSelector;
import tango.io.selector.SelectorException;
import tango.io.selector.model.ISelector;
import tango.net.InternetAddress;
import tango.net.ServerSocket;
import tango.net.Socket;
import tango.net.SocketConduit;
import tango.sys.Pipe;
import tango.util.collection.HashMap;
import tango.util.collection.LinkSeq;
import tango.util.log.ConsoleAppender;
import tango.util.log.DateLayout;
import tango.text.convert.Layout;
import tango.util.log.Log;
import tango.util.log.model.ILevel;

import tangled.failure;
import tangled.heap;
import tangled.interfaces;
import tangled.defer;
import tangled.time;
import tangled.fiber;

extern (C) int printf(char *str, ...);

Reactor reactor;
Logger log;
static Layout!(char) format;

static this(){
  reactor = new Reactor();
  log = Log.getLogger("tangled.reactor");
  //log.addAppender(new ConsoleAppender(new DateLayout()));
  format = new Layout!(char)();
}

class Reactor : IReactorTCP, IReactorCore
{
  ISelector selector;
  bool done;
  HashMap!(int, IProtocolFactory) listening_handlers;
  HashMap!(int, SingleSocket) singlesockets;
  HashMap!(int, ServerSocket) serversockets;
  Heap!(IDelayedCall) calls;
  PipeConduit wakeSink, wakeSource;
  bool woken;
  FiberPool fibers;

  this() 
    {
      selector = new EpollSelector();
      selector.open(4, 4);
      calls = new Heap!(IDelayedCall)();
      listening_handlers = new HashMap!(int, IProtocolFactory)();
      singlesockets = new HashMap!(int, SingleSocket)();
      
      auto pipe = new Pipe(256);
      wakeSink = pipe.sink();
      wakeSource = pipe.source();
      this.registerRead(wakeSource);
      fibers = new FiberPool(&popAndCall);
    }
  
  void runOnce() {
    this.iterate(0);
  }
  
  ServerSocket listenTCP(InternetAddress bind, IProtocolFactory factory, int backlog=5)
  {
    auto s = new ServerSocket(bind, backlog);
    this.registerRead(s);
    this.listening_handlers.add(s.fileHandle(), factory);
    factory.doStart();
    return s;
  }
  
  void connectTCP(InternetAddress dest, IProtocol protocol, int timeout=30, InternetAddress bind=null)
  {
    if (bind is null)
      bind = new InternetAddress("127.0.0.1", 0);
    auto socket = new SocketConduit();
    socket.socket.blocking(false);
    assert(socket.socket.blocking() == false);
    socket.connect(dest);
    auto ss = new SingleSocket(socket, protocol, bind, dest);
    singlesockets.add(socket.fileHandle, ss);
    registerRead(socket);
    callLater(0.0, &protocol.makeConnection, ss);
    callLater(0.0, &protocol.connectionMade);
  }
  
  void stopListeningTCP(ISelectable s) {
    this.unregister(s);
  }

  DelayedTypeGroup!(Delegate, Args).TDelayedCall
    callLater(Delegate, Args...)(double delay, Delegate cmd, Args args){
    auto ti = time();
    auto t = (ti + delay);
    auto c = new DelayedTypeGroup!(Delegate, Args).TDelayedCall(t, cmd, args);
    calls.push(c);
    wakeSelect();
    return c;
  }
  
  IDeferred!(char[]) resolve(char[] name, int timeout){
    assert(0);
  }

  void run(){
    this.done = false;
    while (!this.done) {
      this.iterate();
    }
  }

  void stop() {
    this.done = true;
    wakeSelect();
  }

  void crash(){
    assert(0);
  }

  void popAndCall() {
    log.trace("popping a call");
    auto c = this.calls.pop();
    if (c.active) {
      log.trace("active call");
      try {
	c.call();
      }
      catch(Exception e){
	log.warn(format("Exception in call:\n{0}\n", e.toString()));
      }
      catch {
	log.warn(format("Catch All Exception in call {0}\n", c.stringof));      
	  }
      log.trace("call done");
    }
  }

  void iterate(double delay=1000000.0){
    uint nevents;
    ISelectionSet events;

    try {
      // pop externally added
      log.trace("calculate delay to next call");
      if(this.calls.size){
	delay = (this.calls.get(0).time() - time());
      }
      if(delay < 0)
	delay = 0;


      // check doneness
      if (this.done)
	return 0;

      log.trace("select network events");
      nevents = this.selector.select(delay);
      log.trace("select exited");
      // execute pending calls
      while (this.calls.size ) {
	auto c = this.calls.get(0);
	if(c.time() > time())
	  break;
	if(!c.active) {
	  this.calls.pop();
	  continue;
	} else {
	  fibers.call();
	}
      }
      // close dead
      
      // handle network events
      if (nevents > 0) {
	events = this.selector.selectedSet();
	this.handleEvents(nevents, events);
      }
      // check doneness
      // close dead
    }
    finally {
    }
  }

  void handleEvents(uint nevents, ISelectionSet events) {
    char[1024 * 128] buffer;
    int count;

    log.trace("entering handleEvents");
    foreach (SelectionKey key; events){
      if (!key.isError()) {
	SingleSocket ss;
	try {
	  ss = singlesockets.get(key.conduit.fileHandle);
	}
	catch (NoSuchElementException) { 
	  if (key.conduit is wakeSource) {
	    log.trace("wakesource");
	    count = wakeSource.read(buffer);
	    woken = false;
	    this.registerRead(key.conduit);
	    log.trace("reregistered");
	    continue;
	  }
	  if (this.listening_handlers.containsKey(key.conduit.fileHandle)) {
	    log.trace("accepting");
	    // server socket, need to accept
	    auto c = (cast(ServerSocket)key.conduit).accept();
	    c.socket.blocking(false);
	    auto handler = this.listening_handlers.get(key.conduit.fileHandle);
	    auto remote = cast(InternetAddress)c.socket().remoteAddress();
	    auto protocol = handler.buildProtocol(remote);
	    auto local = cast(InternetAddress)c.socket().localAddress();
	    auto nss = new SingleSocket(c, protocol, local, remote);
	    this.singlesockets.add(c.fileHandle(), nss);
	    this.registerRead(c);
	    callLater(0.0, &protocol.makeConnection, nss);
	    callLater(0.0, &protocol.connectionMade);
	    log.trace("accepted");
	  }
	  continue;
	}
	ss.connected = true;
	if (key.isReadable()) {
	  log.trace("reading");
	  // not a server socket
	  count = (cast(SocketConduit)key.conduit).read(buffer);
	  log.trace("red");
	  if (count != IConduit.Eof) {
	    callLater(0.0, &ss.protocol.dataReceived, buffer[0..count].dup);
	    if(key.conduit.fileHandle() <=0){
	      this.disconnected(ss);
	      callLater(0.0, &ss.protocol.connectionLost, new Failure("bad read"));
	    }
	    else
	      this.registerRead(key.conduit);
	  }
	  else {
	    log.trace(">>> disconnecting... EOF");
	    this.disconnected(ss);
	    callLater(0.0, &ss.protocol.connectionLost, new Failure("connection closed by remote host"));
	  }
	}
	if(key.isWritable()) {
	  ss.tryWrite();
	  if (ss.isFlushed()){
	    callLater(0.0, &ss.protocol.connectionFlushed);
	  }
	}
      }
      else {
	this.unregister(key.conduit);
	try {
	  log.trace(">>> disconnecting... ERROR");
	  auto ss = singlesockets.get(key.conduit.fileHandle);
	  this.disconnected(ss);
	  callLater(0.0, &ss.protocol.connectionLost, new Failure("connection closed by remote host"));
	}
	catch (NoSuchElementException) {}
      }
    }
  }

  void yieldFor(double seconds) {
    callLater(seconds, delegate void() {}).yieldForResult();
  }


  void yieldFor(int seconds) {
    callLater(cast(double)seconds, delegate void() {}).yieldForResult();
  }


  void fireSystemEvent(SystemEvent event){
    assert(0);
  }


  void wakeSelect() {
    if (!woken) {
      wakeSink.write("X");
      woken = true;
    }
  }

  void registerRead(ISelectable s) {
    try {
      selector.reregister(s, Event.Read);
    }
    catch (UnregisteredConduitException e) {
      selector.register(s, Event.Read);
    }
  }

  void registerReadWrite(ISelectable s) {
    try {
      selector.reregister(s, Event.Read|Event.Write);    
    }
    catch (UnregisteredConduitException e) {
      selector.register(s, Event.Read|Event.Write);
    }
  }

  void unregister(ISelectable s) {
    try {
      selector.unregister(s);
    }
    catch (UnregisteredConduitException e) {
    }
  }

  void deadFromWrite(SingleSocket s) {
    this.disconnected(s);
    callLater(0.0, &s.protocol.connectionLost, new Failure("Bad write."));
  }

  void disconnected(SingleSocket s) {
    if (s.connected == false)
      return;
    s.connected = false;
    try {
      reactor.unregister(s.sock);
    }
    catch (SelectorException e) {}
    singlesockets.removeKey(s.sock.fileHandle);
    s.sock.shutdown();
    s.sock.close();
  }
}

class SingleSocket : ITransport {
  SocketConduit sock;
  bool connected;
  IProtocol protocol;
  private LinkSeq!(char[]) buffer;
  InternetAddress host, peer;

  this(SocketConduit sock, IProtocol handler, InternetAddress host, InternetAddress peer) {
    this.sock = sock;
    this.protocol = handler;
    this.host = host;
    this.peer = peer;
    this.buffer = new LinkSeq!(char[]);
  }

  void write(char[] data){
    this.buffer.append(data);
    if (this.buffer.size == 1)
      this.tryWrite();
  }

  void writeSequence(char[][] data){
    foreach (seq; data){
      this.write(seq);
    }
  }

  void loseConnection() {
    reactor.disconnected(this);
  }

  bool isFlushed() {
    return this.buffer.size == 0;
  }

  InternetAddress getPeer(){
    return this.peer;
  }

  InternetAddress getHost(){
    return this.host;
  }

  void tryWrite(){
    int amount;
    log.trace("try write");
    if (connected) {
      while (this.buffer.size > 0) {
	auto buf = this.buffer.head();
	log.trace("writing");
	
	amount = this.sock.socket.send(buf);
	if (amount != buf.length) {
	  if (amount > 0) {
	    this.buffer.replaceHead(buf[amount..buf.length]);
	  }
	  else if (amount <=0 ) {
	    log.trace(">>> disconnecting, dead from write");
	    reactor.deadFromWrite(this);
	    return;
	  }
	  break;
	}
	this.buffer.removeHead();
      }
    }
    if (this.buffer.size == 0) {
      log.trace("register readonly");
      reactor.registerRead(this.sock);
    }
    else {
      log.trace("register readwrite");
      reactor.registerReadWrite(this.sock);
    }
    log.trace("trywrite exit");
  }
}



// template magic to allow statically checked variable argument callLater
// see also definition for reactor.callLater

template DelayedTypeGroup(Delegate, Args...) {
  alias ReturnTypeOf!(Delegate)          RealReturn;
  alias ParameterTupleOf!(Delegate)  Params;
  // this compile time code makes this work for both functions and delegates
  static if (is(Delegate == delegate))
    alias RealReturn delegate(Params) Callable;
  else
    alias RealReturn function(Params) Callable;
  // handle void return values
  static if(RealReturn.stringof != void.stringof)
    alias RealReturn Return;
  else
    alias _void Return ;
  alias DelayedCall!(Return, Callable, Params) TDelayedCall;
}


typedef int _void;

class DelayedCall(Return, Callable, U...) : IDelayedCall {
  double t;
  Callable f;
  U args;
  bool _active;
  bool called;
  Deferred!(Return) df;

  this( double t, Callable f, U args){
    this.t = t;
    this.f = f;
    foreach(i,a; args) {
      this.args[i] = a;
    }
    _active = true;
    df = new Deferred!(Return)();
  }

  void call() {
    called = true;
    static if(Return.stringof != _void.stringof) {
      Return x = this.f(this.args);
    }
    else {
      this.f(this.args);
      _void x;
    }
    df.callback(x);
  }

  Return yieldForResult() {
    return df.yieldForResult();
  }

  int opCmp(IDelayedCall o) {
    if (time > o.time)
      return 1;
    else if (time < o.time)
      return -1;
    return 0;
  }

  double time(){
    return this.t;
  }

  void cancel() {
    this._active = false;
  }

  bool active(){
    return this._active;
  }

}
