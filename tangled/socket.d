module tangled.socket;

import tango.net.ServerSocket;
import tango.net.SocketConduit;
import tango.net.Socket;

import tangled.reactor;
import tangled.conduit;

class AServerSocket : ServerSocket {
  this(InternetAddress bind) {
    super(bind);
  }

  SocketConduit create (){
    return new ASocketConduit();
  }
  
  ASocketConduit accept() {
    auto a = super.accept();
    log.trace(format(">>> accept: {}", typeof(a).stringof));
    return cast(ASocketConduit)a;
  }
}
