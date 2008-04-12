module tangled.conduit;

import tango.net.SocketConduit;
import tango.net.ServerSocket;
import tango.net.Socket;

import tangled.defer;
import tangled.failure;
import tangled.interfaces;
import tangled.reactor;

class ASocketConduit : SocketConduit, IASelectable, IAConduit
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
    log.trace(">>> attempting receive");
    auto c = socket.receive(dst);
    if (c <= 0) {
      log.trace(">>> disconnected");
      // handle disconnect
      return Eof;
    }
    else
      log.trace(">>> sent");

    return c;
  }

  void readyToRead() {
    log.trace(format(">>> readyToRead {}", readDF));
    if (readDF) {
      readDF.callBack(0);
      readDF = null;
    }
  }

  uint write(void[] src) {
    log.trace(">>> conduit write");
    if(writeDF) {
      throw new Exception("TangledSocketConduit already in write");
    }
    else {
      writeDF = new Deferred!(int);
      reactor.registerWrite(this);
      writeDF.yieldForResult();
    }
    log.trace(">>> attempting send");
    auto c = socket.send(src);
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
    log.trace(format(">>> readyToWrite {}", writeDF));
    if (writeDF) {
      writeDF.callBack(0);
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
  
  char[] toString() {
    return format("ASocketConduit: {}", fileHandle);
  }
}
