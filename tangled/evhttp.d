module tangled.evhttp;

import tango.net.InternetAddress;
import tango.stdc.stringz;

import tangled.conduit;
import tangled.interfaces;
import tangled.reactor;

import libevent.event;
import libevent.http;


extern (C) void accept_cb(evhttp_request *req, void *user){
  IHTTPProtocolFactory fac =  cast(IHTTPProtocolFactory)user;
  reactor.callInFiber(delegate(){fac.buildProtocol().handleRequest(new EVHRequest(req));});
}

class EVHServer : IHTTPServer {
  evhttp ctx;

  this(event_base evbase, InternetAddress bind) {
    ctx = evhttp_new(evbase);
    if (evhttp_bind_socket(ctx, toStringz(bind.toAddrString), bind.port)) {
      // return value is undocumented!
      assert(0);
    }
  }

  void registerURI(char[] URI, IHTTPProtocolFactory fac) {
    fac.doStart();
    evhttp_set_cb(ctx, toStringz(URI), &accept_cb, cast(void *)fac);
  }

  void registerGenericHandler(IHTTPProtocolFactory fac) {
    fac.doStart();
    evhttp_set_gencb(ctx, &accept_cb, cast(void *)fac);
  }
  
}

class EVHRequest : IHTTPRequest {
  evhttp_request *req;
  evbuffer *buf;
  this(evhttp_request *nreq) {
    req = nreq;
    buf = evbuffer_new();
  }

  char[] remoteHost(){
    return fromStringz(req.remote_host);
  }
  
  void sendReply(int code, char[] reason, char[]data) {
    evbuffer_add(buf, data.ptr, data.length);
    evhttp_send_reply(req, code, toStringz(reason), buf);
  }
}

