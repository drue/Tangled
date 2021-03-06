/* THIS FILE GENERATED BY bcd.gen */
module libevent.event;
align(4):
public import tango.net.Socket;

extern (C) {
  const int EVLIST_TIMEOUT = 0x01;
  const int EVLIST_INSERTED = 0x02;
  const int EVLIST_SIGNAL = 0x04;
  const int EVLIST_ACTIVE = 0x08;
  const int EVLIST_INTERNAL = 0x10;
  const int EVLIST_INIT = 0x80;
  const int EV_TIMEOUT = 0x01;
  const int EV_READ = 0x02;
  const int EV_WRITE = 0x04;
  const int EV_SIGNAL = 0x08;
  const int EV_PERSIST = 0x10;
  const int _EVENT_LOG_DEBUG = 0;
  const int _EVENT_LOG_MSG = 1;
  const int _EVENT_LOG_WARN = 2;
  const int _EVENT_LOG_ERR = 3;
  const int EVLOOP_ONCE = 0x01;
  const int EVLOOP_NONBLOCK = 0x02;
  const int EVBUFFER_READ = 0x01;
  const int EVBUFFER_WRITE = 0x02;
  const int EVBUFFER_EOF = 0x10;
  const int EVBUFFER_ERROR = 0x20;
  const int EVBUFFER_TIMEOUT = 0x40;
  alias void function(bufferevent *, short, void *) _BCD_func__272;
  alias _BCD_func__272 everrorcb;
  alias void function(bufferevent *, void *) _BCD_func__273;
  alias _BCD_func__273 evbuffercb;
  alias void function(evbuffer *, uint, uint, void *) _BCD_func__383;
  alias extern(C) void function(int, char *) _BCD_func__303;
  alias _BCD_func__303 event_log_cb;
  alias void * function() _BCD_func__433;
  alias int function(void *, event *) _BCD_func__434;
  alias int function(void *, void *, int) _BCD_func__435;
  alias int function(void *, void *, timeval *) _BCD_func__436;
  alias extern(C) void function(int fd, short reason, void *user) _BCD_func__388;
  void evbuffer_setcb(evbuffer *, _BCD_func__383, void *);
  char * evbuffer_find(evbuffer *, char *, uint);
  int evbuffer_read(evbuffer *, int, int);
  int evbuffer_write(evbuffer *, int);
  void evbuffer_drain(evbuffer *, uint);
  int evbuffer_add_printf(evbuffer *, char *, ...);
  int evbuffer_add_buffer(evbuffer *, evbuffer *);
  char * evbuffer_readline(evbuffer *);
  int evbuffer_remove(evbuffer *, void *, uint);
  int evbuffer_add(evbuffer *, void *, uint);
  int evbuffer_expand(evbuffer *, uint);
  void evbuffer_free(evbuffer *);
  evbuffer * evbuffer_new();
  void bufferevent_settimeout(bufferevent *, int, int);
  int bufferevent_disable(bufferevent *, short);
  int bufferevent_enable(bufferevent *, short);
  uint bufferevent_read(bufferevent *, void *, uint);
  int bufferevent_write_buffer(bufferevent *, evbuffer *);
  int bufferevent_write(bufferevent *, void *, uint);
  void bufferevent_free(bufferevent *);
  int bufferevent_priority_set(bufferevent *, int);
  bufferevent * bufferevent_new(int, _BCD_func__273, _BCD_func__273, _BCD_func__272, void *);
  int event_priority_set(event *, int);
  int event_base_priority_init(void *, int);
  int event_priority_init(int);
  char * event_get_method();
  char * event_get_version();
  int event_pending(event *, short, timeval *);
  void event_active(event *, int, short);
  int event_del(event *);
  int event_add(event *, timeval *);
  int event_once(int fd, short which, _BCD_func__388, void *user, timeval *tv);
  void event_set(event *, int, short, _BCD_func__388, void *);
  int event_base_loopexit(void *, timeval *);
  int event_loopexit(timeval *);
  int event_base_loop(void *, int);
  int event_loop(int);
  int event_base_set(void *, event *);
  void event_set_log_callback(_BCD_func__303);
  int event_base_dispatch(void *);
  int event_dispatch();
  void * event_init();

  struct event_watermark {
    uint low;
    uint high;
  }

  struct bufferevent {
    event ev_read;
    event ev_write;
    evbuffer * input;
    evbuffer * output;
    event_watermark wm_read;
    event_watermark wm_write;
    _BCD_func__273 readcb;
    _BCD_func__273 writecb;
    _BCD_func__272 errorcb;
    void * cbarg;
    int timeout_read;
    int timeout_write;
    short enabled;
  }

  struct evbuffer {
    char * buffer;
    char * orig_buffer;
    uint misalign;
    uint totallen;
    uint off;
    _BCD_func__383 cb;
    void * cbarg;
  }

  struct eventop {
    char * name;
    _BCD_func__433 init;
    _BCD_func__434 add;
    _BCD_func__434 del;
    _BCD_func__435 recalc;
    _BCD_func__436 dispatch;
  }

  struct N5event3__3E {
    event * tqe_next;
    event * * tqe_prev;
  }

  struct N5event3__4E {
    event * tqe_next;
    event * * tqe_prev;
  }

  struct N5event3__5E {
    event * tqe_next;
    event * * tqe_prev;
  }

  struct N5event3__6E {
    event * rbe_left;
    event * rbe_right;
    event * rbe_parent;
    int rbe_color;
  }

  struct event {
    N5event3__3E ev_next;
    N5event3__4E ev_active_next;
    N5event3__5E ev_signal_next;
    uint min_heap_idx;
    void *ev_base;
    int ev_fd;
    short ev_events;
    short ev_ncalls;
    short * ev_pncalls;
    timeval ev_timeout;
    int ev_pri;
    _BCD_func__388 ev_callback;
    void * ev_arg;
    int ev_res;
    int ev_flags;
  }

  struct evkeyval {
    evkeyvalq next;
    char *key;
    char *value;
  };

  struct evkeyvalq {
    evkeyval *tqh_first;
    evkeyval **tqh_last;
  };

}
