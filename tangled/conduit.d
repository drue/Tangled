module tangled.conduit;

import tango.net.SocketConduit;
import tango.net.ServerSocket;
import tango.net.Socket;

import tangled.defer;
import tangled.failure;
import tangled.interfaces;
import tangled.reactor;

class ASocketConduit : SocketConduit, IASelectable
{
  IDeferred!(int) readDF;
  IDeferred!(int) writeDF;

  uint read(void[] dst) {
    if(readDF) {
      throw new Exception("TangledSocketConduit already in read");
    }
    else {
      readDF = new Deferred!(int);
      reactor.registerRead(this);
      readDF.yieldForResult();
    }
    auto c = socket.receive(dst);
    if (c <= 0) {
      // handle disconnect
      return Eof;
    }
    return c;
  }

  void readyToRead() {
    if (readDF) {
      readDF.callBack(0);
      readDF = null;
    }
  }

  uint write(void[] src) {
    if(writeDF) {
      throw new Exception("TangledSocketConduit already in write");
    }
    else {
      writeDF = new Deferred!(int);
      reactor.registerWrite(this);
      writeDF.yieldForResult();
    }
    auto c = socket.send(src);
    if (c <= 0) {
      // handle disconnect
      return Eof;
    }
    return c;
  }

  void readyToWrite() {
    if (writeDF) {
      readDF.callBack(0);
      writeDF = null;
    }
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

}


class AServerSocket : ServerSocket {
  this(InternetAddress bind) {
    super(bind);
  }
  protected ASocketConduit create (){
    return new ASocketConduit();
  }
  
  ASocketConduit accept() {
    return cast(ASocketConduit)super.accept();
  }
}
