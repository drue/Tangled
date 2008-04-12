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

  protected ASocketConduit create (){
    return new ASocketConduit();
  }
  
  char[] toString() {
    return format("AServerSocket: {}", socket.fileHandle);
  }
}
