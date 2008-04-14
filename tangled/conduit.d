module tangled.conduit;

import tango.net.SocketConduit;
import tango.net.ServerSocket;
import tango.net.Socket;

import tangled.defer;
import tangled.failure;
import tangled.interfaces;
import tangled.reactor;

enum : uint {Eof = uint.max};

class ASocketConduit : SocketConduit, IASelectable, IAConduit
{
  IDeferred!() readDF;
  IDeferred!() writeDF;

  uint read(void[] dst) {
    while(1) {
      if(!readDF) {
	readDF = new Deferred!();
	reactor.registerRead(this);
      }
      auto x = readDF;
      x.yieldForResult();
      if (!readDF) {
	// first to wake up
	if (x.numWaiters > 1) {
	  readDF = new Deferred!();
	  reactor.registerRead(this);
	}
	break;
      }
    }

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
    log.trace(format(">>> readyToRead {}", readDF));
    if (readDF) {
      auto x = readDF;
      readDF = null; // callbacks depend in this being set to null
      x.callBack();
    }
  }

  uint write(void[] src) {
    log.trace(">>> conduit write");
    while(1) {
      if(!writeDF) {
	writeDF = new Deferred!();
	reactor.registerWrite(this);
      }
      auto x = writeDF;
      x.yieldForResult();
      if (!writeDF) {
	// first to wake up
	if (x.numWaiters > 1) {
	  writeDF = new Deferred!();
	  reactor.registerWrite(this);
	}
	break;
      }
    }

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
    log.trace(format(">>> readyToWrite {}", writeDF));
    if (writeDF) {
      auto x = writeDF;
      writeDF = null;
      x.callBack();
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

  protected int _read(void[] dst) {
    return socket.receive(dst);
  }

  protected int _write(void[] src) {
    return socket.send(src);
  }
}

