module tangled.conduit;

import tango.net.SocketConduit;
import tango.net.ServerSocket;
import tango.net.Socket;
import tango.text.convert.Layout;

import tangled.defer : Deferred;
import tangled.failure;
import tangled.interfaces;
import tangled.reactor;
import tangled.queue;

enum : uint {Eof = uint.max};

private Layout!(char) format;

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
      registerRead(this);
    readQ.append(readDF);
    readDF.yieldForResult();
    
    auto c = _read(dst);
    if (c <= 0) {
      // handle disconnect
      return Eof;
    }
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
      registerRead(this);
  }

  uint write(void[] src) {
    auto writeDF = new Deferred!();
    if(writeQ.empty) {
	registerWrite(this);
    }
    writeQ.append(writeDF);
    writeDF.yieldForResult();

    auto c = _write(src);
    if (c <= 0) {
      // handle disconnect
      return Eof;
    }
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
      registerWrite(this);
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

