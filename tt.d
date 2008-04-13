module tt;

import tango.core.Thread;
import tango.net.InternetAddress;

import tangled.conduit;
import tangled.interfaces;
import tangled.protocol;
import tangled.reactor;
import tangled.evhttp;

int main() {
  auto f =  new SimpleFactory!(Echo)();
  auto addr = new InternetAddress("127.0.0.1", 6060);
  auto listener = reactor.tcpListen(addr, f);
  auto http = reactor.httpListen(new InternetAddress("127.0.0.1", 7070));
  http.registerGenericHandler(new SimpleHTTPFactory!(HEcho)());
  reactor.callLater(2.0, delegate(){log.error("CallLater Works.");});
  reactor.run();
  return 0;
}

class Echo : BaseProtocol {
  this(IProtocolFactory f){
    super(f);
  }

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

class HEcho : BaseHTTPProtocol {
  this(IHTTPProtocolFactory f){
    super(f);
  }

  void handleRequest(IHTTPRequest req) {
    char[256] buf;
    char[] input;
    
    super.handleRequest(req);
    /*while(1) {
      auto c = transport.read(buf);
      if(c == Eof)
	break;
	input.append(buf[0..c]);
	}*/
    log.trace("got http request!!");
  }

}
