module tangled.defer;

import tango.core.Thread;
import tango.util.collection.LinkSeq;
import tango.core.Traits;

import tangled.interfaces;

public class Deferred (T) : IDeferred!(T)
{
  static if(typeof(T).stringof != void.stringof)
    alias LinkSeq!(T delegate(T)) LinkSeqT;
  else
    alias LinkSeq!(T delegate()) LinkSeqT;
  
  bool called = false;
  private LinkSeqT callbacks;

  static if(typeof(T).stringof != void.stringof)
    private T result;

  private LinkSeq!(Fiber) waiters;

  this(){
    callbacks = new LinkSeqT();
    waiters = new LinkSeq!(Fiber);
    called = false;
  }

  static if(typeof(T).stringof != void.stringof) {
    public void addCallback(T delegate(T) f) {
    this.callbacks.append(f);
    if (this.called)
	this.result = f(this.result);     
    }
  }
  else {
    public void addCallback(T delegate() f) {
      if (this.called)
	f();     
    }
  }
  
  static if(typeof(T).stringof != void.stringof) {
    public void callBack(T res) {
      if (!this.called) {
	this.result = res;
	this.called = true;
	this.runCallbacks(this.result);
      }
    }
  }   
  else {
    public void callBack() {
      if (!this.called) {
	this.called = true;
	this.runCallbacks();
      }
    }
  }
  
  static if(typeof(T).stringof != void.stringof) {
    public void callback(T res) {
	callBack(res);
    }
  }
  else {
    public void callback() {
	callBack();
    }
  }

  static if(typeof(T).stringof != void.stringof) {
    private void runCallbacks(T res) {
      T tmp = res;
      foreach (cb; this.callbacks){
	tmp = cb(tmp);
      }
      foreach (waiter; this.waiters) {
	waiter.call();
      }
      waiters = null;
    }
  }
  else {
    private void runCallbacks() {
      foreach (cb; this.callbacks){
	  cb();
      }
      foreach (waiter; this.waiters) {
	waiter.call();
      }
      waiters = null;
    }
  }
  

  public T yieldForResult() {
    if (this.called)
      static if(typeof(T).stringof != void.stringof)
	return this.result;
      else
	return;
    waiters.append(Fiber.getThis());
    Fiber.yield();
    // XXX check for exception and throw if necessary
    static if(typeof(T).stringof != void.stringof)
      return this.result;
    else
      return;
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
    alias _void Return ;
  alias DelayedCall!(Return, Callable, Params) TDelayedCall;
}

template DelayedTypeGroup(Delegate) {
  template ReturnTypeOf(Fn) {
    static if( is( Fn Ret == return ) )
      alias Ret ReturnTypeOf;
    else
      alias void ReturnTypeOf;
  }
  alias ReturnTypeOf!(Delegate)          RealReturn;
  // this compile time code makes this work for both functions and delegates
  static if (is(Delegate == delegate))
    alias RealReturn delegate() Callable;
  else
    alias RealReturn function() Callable;
  // handle void return values
  static if(RealReturn.stringof != void.stringof)
    alias RealReturn Return;
  else
    alias _void Return ;
  alias DelayedCall!(Return, Callable) TDelayedCall;
}

typedef int _void;

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
    called = true;
    static if(Return.stringof != _void.stringof) {
      Return x = this.f(this.args);
    }
    else {
      this.f(this.args);
      _void x;
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
