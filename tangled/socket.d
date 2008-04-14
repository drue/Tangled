module tangled.socket;

import tango.net.ServerSocket;
import tango.net.SocketConduit;
import tango.net.Socket;

import tangled.reactor;
import tangled.conduit;

class AServerSocket (T) : ServerSocket {
  this(InternetAddress bind) {
    super(bind);
  }

  protected T create (){
    return new T();
  }
  
  char[] toString() {
    return format("AServerSocket / {} : {}", T.stringof, socket.fileHandle);
  }
}
