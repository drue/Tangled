module libevent.http;

import libevent.event;

/* Response codes */
const int HTTP_OK =		200;
const int HTTP_NOCONTENT =	204;
const int HTTP_MOVEPERM =	301;
const int HTTP_MOVETEMP =	302;
const int HTTP_NOTMODIFIED =	304;
const int HTTP_BADREQUEST =	400;
const int HTTP_NOTFOUND =	404;
const int HTTP_SERVUNAVAIL =	503;

alias void *evhttp;
alias void *event_base;
alias void *evhttp_connection;
alias extern (C) void function(evhttp_request *req, void *user) evhttp_cb;

extern (C) evhttp evhttp_new(event_base base);

extern (C) int evhttp_bind_socket(evhttp http,  char *address, ushort port);
extern (C) void evhttp_free(evhttp http);
extern (C) void evhttp_set_cb(evhttp http,  char *uri, evhttp_cb cb, void *user);
extern (C) void evhttp_set_gencb(evhttp http, evhttp_cb cb, void *user);
extern (C) void evhttp_send_error(evhttp_request *req, int error,  char *reason);
extern (C) void evhttp_send_reply(evhttp_request *req, int code,
				   char *reason, evbuffer *databuf);

/* Low-level response interface, for streaming/chunked replies */
extern (C) void evhttp_send_reply_start(evhttp_request *req, int code, char *reason);
extern (C) void evhttp_send_reply_chunk(evhttp_request *req, evbuffer *buf);
extern (C) void evhttp_send_reply_end(evhttp_request *req);

enum evhttp_cmd_type { EVHTTP_REQ_GET, EVHTTP_REQ_POST, EVHTTP_REQ_HEAD };
enum evhttp_request_kind { EVHTTP_REQUEST, EVHTTP_RESPONSE };

struct evhttp_request {
  struct next {
    evhttp_request *tqe_next;
    evhttp_request **tqe_prev;
  };
  evhttp_connection *evcon;
  int flags;
  const int EVHTTP_REQ_OWN_CONNECTION = 0x0001;
  const int EVHTTP_PROXY_REQUEST = 0x0002;
 
  evkeyvalq *input_headers;
  evkeyvalq *output_headers;
  
  /* address of the remote host and the port connection came from */
  char *remote_host;
  ushort remote_port;
  
  evhttp_request_kind kind;
  evhttp_cmd_type type;
  
  char *uri;			/* uri after HTTP request was parsed */
  
  char major;			/* HTTP Major number */
  char minor;			/* HTTP Minor number */
  
  int got_firstline;
  int response_code;		/* HTTP Response code */
  char *response_code_line;	/* Readable response */
  
  evbuffer *input_buffer;	/* read data */
  long ntoread;
  int chunked;
  
  evbuffer *output_buffer;	/* outgoing post or data */
  
  /* Callback */
  void function(evhttp_request *req, void *user) cb;
  void *cb_arg;
  
  /*
   * Chunked data callback - call for each completed chunk if
   * specified.  If not specified, all the data is delivered via
   * the regular callback.
   */
  void function(evhttp_request *req, void *user) ccb; 
};
