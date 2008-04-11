module tangled.evhttp;

import tango.net.InternetAddress;
import tango.stdc.stringz;

import tangled.conduit;
import tangled.interfaces;
import tangled.reactor;

import libevent.http;


extern (C) void accept_cb(evhttp_request *req, void *user){
  IHTTPProtocolFactory fac =  *cast(IHTTPProtocolFactory *)user;
  reactor.callInFiber(&fac.buildProtocol, new EVHRequest(*req));
}

class EVHServer : IHTTPServer {
  evhttp ctx;

  this(event_base evbase, InternetAddress bind) {
    ctx = evhttp_new(evbase);
    if (!evhttp_bind_socket(ctx, bind.toAddrString.ptr, bind.port)) {
      // return value is undocumented!
      assert(0);
    }
  }

  void registerURI(char[] URI, IHTTPProtocolFactory fac) {
    fac.doStart();
    evhttp_set_cb(ctx, URI.ptr, &accept_cb, &fac);
  }
  
}

class EVHRequest : IHTTPRequest {
  evhttp_request req;
  this(evhttp_request nreq) {
    req = nreq;
  }

  char[] remoteHost(){
    return fromStringz(req.remote_host);
  }
}
