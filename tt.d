module tt;

import tango.core.Thread;
import tango.net.InternetAddress;
import tango.io.Buffer;
import tango.text.stream.LineIterator;

import tangled.conduit;
import tangled.interfaces;
import tangled.protocol;
import tangled.reactor;
import tangled.evhttp;

import libevent.http;

int main() {
  auto f =  new SimpleFactory!(Echo)();
  auto addr = new InternetAddress("127.0.0.1", 6060);
  auto listener = reactor.tcpListen(addr, f);
  auto http = reactor.httpListen(new InternetAddress("127.0.0.1", 7070));
  auto fh = new SimpleHTTPFactory!(HEcho)();
  http.registerGenericHandler(fh);
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
    t.write("Welcome to the Echo Server!\r\n");
    auto buf = new Buffer(transport);
    foreach (line; new LineIterator!(char)(buf.input)) {
      buf.append(line ~ "\r\n").flush;
    }
  }
}

class HEcho : BaseHTTPProtocol {
  this(IHTTPProtocolFactory f){
    super(f);
  }

  void handleRequest(IHTTPRequest req) {
    super.handleRequest(req);
    req.sendPage(HTTP_OK, "OK", format("Gotcha! : {}\r\n", req.remoteHost()));
  }

}
