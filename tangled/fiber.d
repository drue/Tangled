module tangled.fiber;

import tango.core.Thread;
import tango.util.collection.HashSet;
import tango.io.Console;
import tango.text.convert.Layout;

static Layout!(char) format;

static this(){
  format = new Layout!(char)();
}

class FiberPool {
  HashSet!(Fiber) pool;
  HashSet!(Fiber) all;
  void delegate() dg;
  
  this(void delegate() dg) {
    this.dg = dg;
    pool = new HashSet!(Fiber)();
    all = new HashSet!(Fiber)();
  }

  void call() {
    Fiber f;
    if(pool.size) {
      f = pool.take();
    }
    else {
      f = new Fiber(dg);
      all.add(f);
      if (all.size % 100 == 0) {
	Cout(format("fiber pool size now {0}\n", all.size));Cout.flush;
      }
    }
    f.call();
    ret(f);
  }
  
  void ret(Fiber f) in {
    assert(all.contains(f));
  } 
  body {
    if(f.state == Fiber.State.TERM) {
      f.reset();
      pool.add(f);
    }
  }

  unittest {
    int i;
    void delegate() dg = {i++;};
    
    auto f = new FiberPool(dg);
    
    assert(i == 0);
    assert(f.all.size == 0);
    assert(f.pool.size == 0);
    
    
  }
}