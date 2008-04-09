module tangled.reactor;

import tango.text.convert.Layout;
import tango.util.log.Log;
import tango.net.InternetAddress;
import tango.stdc.stringz;

import libevent.event;
import libevent.http;

import tangled.defer;
import tangled.failure;
import tangled.fiber;
import tangled.interfaces;
import tangled.time;


version(build) {
  pragma(link, "event");
}

Reactor reactor;
Logger log;
static Layout!(char) format;

static this(){
  reactor = new Reactor();
  log = Log.getLogger("tangled.reactor");
  //log.addAppender(new ConsoleAppender(new DateLayout()));
  format = new Layout!(char)();
}

extern (C) void http_cb(evhttp_request *req, void *user){
  reactor.handleHTTP(req, *cast(IProtocolFactory *)user);
}

class Reactor : IReactorCore
{
    FiberPool fibers;
    event_base evbase;

    this() {
      evbase = event_init();
    }

    IDeferred!(char[]) resolve(char[] name, int timeout) {
      assert(0);
      return new Deferred!(char[]);
    }

    void run() {
      assert(0);
    }

    void crash() { 
      assert(0);
    }

    void iterate(double delay) {
      assert(0);
    }

    void fireSystemEvent(SystemEvent event) {
      assert(0);
    }

    evhttp httpListen(InternetAddress bind) {
      evhttp http = evhttp_new(evbase);
      if (!evhttp_bind_socket(http, bind.toAddrString.ptr, bind.port)) {
	// return value is undocumented!
	assert(0);
      }
      return http;
    }
    
    void httpRegisterURI(evhttp http, char[] URI, IProtocolFactory fac) {
      evhttp_set_cb(http, URI.ptr, &http_cb, &fac);
    }

    void handleHTTP(evhttp_request *req, IProtocolFactory fac) {
      // this should be in a fiber
      auto protocol = fac.buildProtocol(new InternetAddress(fromStringz(req.remote_host), req.remote_port));
      //protocol.makeConnection(t);
    }
}
