module tt;

import tango.core.Thread;
import tango.net.InternetAddress;

import tangled.conduit;
import tangled.interfaces;
import tangled.protocol;
import tangled.reactor;

int main() {
  auto f =  new SimpleFactory!(Echo)();
  auto addr = new InternetAddress("127.0.0.1", 6060);
  auto listener = reactor.tcpListen(addr, f);
  
  reactor.run();
  return 0;
}

class Echo : BaseProtocol {
  void makeConnection(ASocketConduit t) 
    in {
    assert(t, "bad conduit in makeConnection");
  } body {
    super.makeConnection(t);
    log.trace(">>> makeConnection");
    char[] buf = new char[256];
    t.write("Welcome to the Echo Server\n");
    while(1) {
      auto c = transport.read(buf);
      if (c == Eof)
	break;
      transport.write(buf[0..c]);
    }
  }
}
