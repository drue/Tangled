module hc;

import tango.io.Stdout;
import tango.net.InternetAddress;
import tango.net.http.HttpClient;
import tango.net.http.HttpHeaders;

static import tangled.reactor;
import tangled.http;
import tangled.protocol;
import tangled.log;

auto name = "hc";
mixin SimpleLogger!(name);

int main(char[][] argv) {
  log.trace("Starting");
  tangled.reactor.callLater(0.0, delegate(int x) {log.error(">>> callback");}, 0);
  tangled.reactor.callLater(0.0, &_main, argv);
  tangled.reactor.run();
  return 0;
}

void _main(char[][]argv) {
  log.trace("callback");
  Stdout("callback2");
  if (argv.length > 1) {
    auto client = new AHttpClient (HttpClient.Get, argv[1]);
    client.open();
    scope(exit) { client.close (); }
	
    void sink (void[] content) {
      Stdout(cast(char[])content).flush;
    }
	
    if (client.isResponseOK) {
      auto length = client.getResponseHeaders.getInt (HttpHeader.ContentLength, uint.max);
      Stdout(client.getResponseHeaders).newline.flush;
      client.read (&sink, length);
    }
    else
      Stderr(client.getResponse).newline;
  }
}