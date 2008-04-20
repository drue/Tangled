module tangled.socket;

import tango.net.ServerSocket;
import tango.net.Socket;
import tango.text.convert.Layout;

private Layout!(char) format;

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
