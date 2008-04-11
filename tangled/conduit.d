module tangled.conduit;

import tango.net.SocketConduit;

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
      // register for read event
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

  void timeout() {
  }
  
  void signal() {
  }
}
