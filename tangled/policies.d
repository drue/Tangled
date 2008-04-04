module tangled.policies;
import tangled.defer;

template Timeout () {
  // timeout mixin for protocols
  uint toTimeOut;
  IDelayedCall toCall = null;
  
  void resetTimeout() {
    if(toCall !is null) {
      toCall.cancel();
      toCall = reactor.callLater(cast(double)toTimeOut, &this.toTimedOut);
    }
  }
  
  uint setTimeout(uint period) {
    auto prev = toTimeOut;
    toTimeOut = period;

    if(prev != period && toCall !is null) {
      toCall.cancel();
      if (!period)
	toCall = null;
      else
	toCall = reactor.callLater(cast(double)toTimeOut, &this.toTimedOut);
    }
    else if (period != 0)
      toCall = reactor.callLater(cast(double)toTimeOut, &this.toTimedOut);
    return prev;
  }

  void toTimedOut() {
    if (toCall !is null && !df.called) {
      toCall = null;
      timeoutConnection();
    }
  }

  void timeoutConnection() {
    transport.loseConnection();
  }
}


template DeferredResult (T) {
  // mixin for protocols that return a result
  Deferred!(T) _df;

  Deferred!(T) df() {
    if (_df is null)
      _df = new Deferred!(T)();
    return _df;
  }
}