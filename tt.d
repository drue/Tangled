module tt;

import tango.net.InternetAddress;

import tangled.interfaces;
import tangled.protocol;
import tangled.reactor;

int main() {
  auto listener = reactor.tcpListen(new InternetAddress("127.0.0.1", 6060), new SimpleFactory!(Echo)());
  reactor.run();
  return 0;
}

class Echo : BaseProtocol {
  void makeConnection(IAConduit transport) {
    char[] buf;
    transport.write("Welcome to the Echo Server\n");
    while(1) {
      transport.read(buf);
      transport.write(buf);
    }
  }
}
