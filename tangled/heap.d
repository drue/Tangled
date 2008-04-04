// this was translated from Kevin O'Connor's code in the Python standard library

module tangled.heap;

import tango.util.collection.ArraySeq;
import tango.io.Stdout;

class Heap(T) : ArraySeq!(T)
{
  void push(T item){
    this.append(item);
    this.siftdown(0, this.size-1);
  }

  T pop(){
    T returnitem;
    T lastelt = this.tail;
    this.removeTail();

    if (this.size) {
      returnitem = this.head;
      this.replaceHead(lastelt);
      this.siftup(0);
    }
    else {
      returnitem = lastelt;
    }
    return returnitem;
  }
  
  T replace(T item) {
    // pop smallest, push item, faster than doing pop();push()
    T returnitem = this.head;
    this.replaceHead(item);
    this.siftup(0);
    return returnitem;
  }

  void heapify() {
    // use this if you use any modification other than push/pop/replace
    // handy if you do a mass (more than N/2) set of changes/additions on a heap
    for (int i; i >= 0; i--) {
      siftup(i);
    }
  }

  protected void siftdown(int startpos, int pos) {
    int parentpos;
    T parent;
    
    T newitem = this.get(pos);
    while (pos > startpos) {
      parentpos = (pos - 1) >> 1;
      parent = this.get(parentpos);
      if (parent <= newitem)
	break;
      this.replaceAt(pos, parent);
      pos = parentpos;
    }
    this.replaceAt(pos, newitem);
  }

  protected void siftup(int pos) {
    int endpos = this.size;
    int startpos = pos;
    T newitem = this.get(pos);
    int childpos = 2 * pos + 1;
    int rightpos;

    while (childpos < endpos) {
      rightpos = childpos + 1;
      if (rightpos < endpos && this.get(rightpos) <= this.get(childpos)) {
	childpos = rightpos;
      }
      this.replaceAt(pos, this.get(childpos));
      pos = childpos;
      childpos = 2 * pos + 1;
    }
    this.replaceAt(pos, newitem);
    this.siftdown(startpos, pos);
  }

  unittest {
    auto h = new Heap!(int)();
    int d[] = [1, 3, 5, 7, 9, 2, 4, 6, 8, 0];

    foreach (i; d) {
      h.push(i);
    }
  
    d.sort;
    foreach(i; d) {
      assert(i == h.pop());
    }

    h = new Heap!(int)();
    foreach (i;d)
      h.append(i);
    h.heapify();
    foreach(i;d)
      assert(i == h.pop());
  }
}
