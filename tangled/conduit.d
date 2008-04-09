module tangled.conduit;

import tango.net.SocketConduit;

import tangled.defer;
import tangled.failure;

class TangledSocketConduit : SocketConduit
{
  Deferred!(int) readDF;
  Deferred!(int) writeDF;

  uint read(void[] dst) {
    if(readDF) {
      throw new Exception("TangledSocketConduit already in read");
    }
    else {
      readDF = new Deferred!(int);
      // register for read event
      readDF.yieldForResult();
    }
    auto c = socket.receive(dst);
    if (c <= 0) {
      // handle disconnect
      return Eof;
    }
    return c;
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
}
