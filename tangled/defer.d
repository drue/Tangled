module tangled.defer;

import tangled.reactor;
import tango.util.collection.LinkSeq;
import tango.core.Thread;

public class Deferred(T)
{
  alias LinkSeq!(T delegate(T)) LinkSeqT;
  
  bool called = false;
  private LinkSeqT callbacks;
  private T result;
  private LinkSeq!(Fiber) waiters;

  this(){
    callbacks = new LinkSeqT();
    waiters = new LinkSeq!(Fiber);
    called = false;
  }

  public void addCallback(T delegate(T) f)
  {
    this.callbacks.append(f);
    if (this.called)
      this.result = f(this.result);     
  }

  public void callBack(T res)
  {
    if (!this.called) {
      this.result = res;
      this.called = true;
      this.runCallbacks(this.result);
    }
  }

  public void callback(T res) {
    callBack(res);
  }

  private void runCallbacks(T res) {
    T tmp = res;
    foreach (cb; this.callbacks){
      tmp = cb(tmp);
    }
    foreach (waiter; this.waiters) {
      waiter.call();
      reactor.fibers.ret(waiter);
    }
    waiters = null;
  }

  public T yieldForResult() {
    if (this.called)
      return this.result;
    waiters.append(Fiber.getThis());
    Fiber.yield();
    // XXX check for exception and throw if necessary
    return this.result;
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