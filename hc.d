module hc;

import tangled.reactor;
import tangled.http;
import tangled.protocol;

int main() {
  auto addr = new InternetAddress("127.0.0.1", 7070);
  auto f = new SimpleHTTPClientFactory!(Client)(addr, "/booyah");
  auto listener = reactor.tcpConnect(addr, f);
  auto http = reactor.tcpConnect(addr);
  
}

class Client : HTTPClient {
  void handleResponseEnd() {
    log.trace(format(">>> Got response: {}", resBuffer));
  }
}