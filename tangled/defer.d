module tangled.defer;

import tango.core.Thread;
import tango.core.Traits;
import tango.util.collection.LinkSeq;
 
import tangled.interfaces;
import tangled.log;

auto name = "tangled.defer";

mixin SimpleLogger!(name);

public class Deferred (T...) : IDeferred!(T)
{
  alias LinkSeq!(Return delegate(T)) LinkSeqT;
  bool called = false;
  private LinkSeqT callbacks;
  private LinkSeq!(Fiber) waiters;
  static if(T.length != 0)
    private T[0] result;

  this(){
    callbacks = new LinkSeqT();
    waiters = new LinkSeq!(Fiber);
    called = false;
  }

  public void addCallback(Return delegate(T) f)
  {
    this.callbacks.append(f);
    if (this.called)
      static if(T.length != 0)
	this.result = f(this.result);
      else
	f();
  }

  public void callBack(T res)
  {
    if (!this.called) {
      static if(T.length != 0)
	this.result = res[0];
      this.called = true;
      this.runCallbacks(res);
    }
  }

  public void callback(T res) {
    callBack(res);
  }
  
  private void runCallbacks(T res) {
    static if(T.length != 0)
      T[0] tmp = res[0];
    foreach (cb; this.callbacks){
      static if(T.length != 0)
	tmp = cb(tmp);
      else
	cb();
    }
    foreach (waiter; this.waiters) {
      waiter.call();
    }
    waiters = null;
  }

  public Return yieldForResult() {
    if (this.called) {
      static if(T.length != 0)
	return this.result;
      else
	return;
    }
    waiters.append(Fiber.getThis());
    Fiber.yield();
    // XXX check for exception and throw if necessary
    static if(T.length != 0)
      return this.result;
    else
      return;
  }

  public uint numWaiters() {
    return waiters.length;
  }

  unittest
    {
      int result; 

      alias Deferred!(int) DT;
      auto d = new DT();
      d.addCallback(delegate int(int a){result = a; return a;});
      d.callBack(3);
      assert (result == 3);

      result = 0;
      d = new DT();
      d.callBack(3);
      d.addCallback(delegate int(int a){result = a; return a;});
      assert (result == 3);

      Deferred!(int) foo() {
	auto df = new Deferred!(int)();
	df.callBack(9);
	return df;
      }
      
      auto x = foo();
      x.addCallback(delegate int(int a){assert (a == 9); return a;});

      auto t = Fiber.getThis();
    }
}

template DelayedTypeGroup(Delegate, Args...) {
  template ReturnTypeOf(Fn) {
    static if( is( Fn Ret == return ) )
        alias Ret ReturnTypeOf;
    else
      alias void ReturnTypeOf;
  }
  alias ReturnTypeOf!(Delegate)          RealReturn;
  alias ParameterTupleOf!(Delegate)  Params;
  // this compile time code makes this work for both functions and delegates
  static if (is(Delegate == delegate))
    alias RealReturn delegate(Params) Callable;
  else
    alias RealReturn function(Params) Callable;
  // handle void return values
  static if(RealReturn.stringof != void.stringof)
    alias RealReturn Return;
  else
    alias void * Return ;
  alias DelayedCall!(Return, Callable, Params) TDelayedCall;
}

class DelayedCall(Return, Callable, U...) : IDelayedCall {
  double t;
  Callable f;
  U args;
  bool _active;
  bool called;
  Deferred!(Return) df;

  this( double t, Callable f, U args){
    this.t = t;
    this.f = f;
    foreach(i,a; args) {
      this.args[i] = a;
    }
    _active = true;
    df = new Deferred!(Return)();
  }

  void call() {
    log.trace("delayedcall call");
    called = true;
    Return x;
    static if(Return.stringof != (void*).stringof) {
      log.trace(format("return {}", args));
      x = this.f(this.args);
    }
    else {
      log.trace("void return");
      this.f(this.args);
    }
    df.callback(x);
  }

  Return yieldForResult() {
    return df.yieldForResult();
  }

  int opCmp(IDelayedCall o) {
    if (time > o.time)
      return 1;
    else if (time < o.time)
      return -1;
    return 0;
  }

  double time(){
    return this.t;
  }

  void cancel() {
    this._active = false;
  }

  bool active(){
    return this._active;
  }

}
