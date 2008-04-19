module tangled.conduit;

import tango.net.SocketConduit;
import tango.net.ServerSocket;
import tango.net.Socket;

import tangled.defer;
import tangled.failure;
import tangled.interfaces;
import tangled.reactor;
import tangled.queue;

enum : uint {Eof = uint.max};

class ASocketConduit : SocketConduit, IASelectable, IAConduit
{
  Queue!(IDeferred!()) readQ;
  Queue!(IDeferred!()) writeQ;

  this() {
    super();
    readQ = new Queue!(IDeferred!());
    writeQ = new Queue!(IDeferred!());
  }
  
  protected this (SocketType type, ProtocolType protocol, bool create=true){
    super(type, protocol, create);
    readQ = new Queue!(IDeferred!());
    writeQ = new Queue!(IDeferred!());
  }

  uint read(void[] dst) {
    auto readDF = new Deferred!();
    if(readQ.empty)
      reactor.registerRead(this);
    readQ.append(readDF);
    readDF.yieldForResult();
    
    log.trace(">>> attempting receive");
    auto c = _read(dst);
    if (c <= 0) {
      log.trace(">>> disconnected");
      // handle disconnect
      return Eof;
    }
    else
      log.trace(">>> received");
    return c;
  }

  void readyToRead() {
    try {
      auto df = readQ.take();
      df.callBack();
    }
    catch (EmptyQueueException e) {
    }
    if(!readQ.empty)
      reactor.registerRead(this);
  }

  uint write(void[] src) {
    log.trace(">>> conduit write");
    auto writeDF = new Deferred!();
    if(writeQ.empty) {
	reactor.registerWrite(this);
    }
    writeQ.append(writeDF);
    writeDF.yieldForResult();

    log.trace(">>> attempting send");
    auto c = _write(src);
    if (c <= 0) {
      log.trace(">>> disconnected");
      // handle disconnect
      return Eof;
    }
    else
      log.trace(">>> sent");
    return c;
  }

  void readyToWrite() {
    try {
      auto df = writeQ.take();
      df.callBack();
    }
    catch (EmptyQueueException e) {
    }
    if(!writeQ.empty)
      reactor.registerWrite(this);
  }

  OutputStream flush() {
    return this;
  }

  void timeout() {
  }
  
  void signal() {
  }

  InternetAddress remoteAddr() {
    auto a = cast(IPv4Address)socket.remoteAddress;
    return new InternetAddress(a.toAddrString, a.port);
  }
  
  char[] toString() {
    return format("ASocketConduit: {}", fileHandle);
  }

  protected int _read(void[] dst) {
    return socket.receive(dst);
  }

  protected int _write(void[] src) {
    return socket.send(src);
  }
}

