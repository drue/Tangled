module tangled.queue;

import tango.core.Exception;

class EmptyQueueException : Exception {this(char[] msg) {super(msg);}};

class Queue(T) {
  protected struct elt {
    T o;
    elt *next;
    elt *prev;
  }
  protected elt *_head;
  protected elt *_tail;

  void append(T o) {
    auto e = new elt;
    e.o = o;
    if(_tail) {
      _tail.next = e;
      e.prev = _tail;
    }
    else {
      _head = e;
    }
    _tail = e;
  }
  
  T take() {
    if (!_head)
      throw new EmptyQueueException("");
    auto e = _head;
    if(!e.next) {
      _head = null;
      _tail = null;
    }
    else {
      _head = e.next;
      _head.prev = null;
    }
    return e.o;
  }

  T head() {
    if (!_head)
      throw new EmptyQueueException("");
    return _head.o;
  }

  T tail() {
    if (!_tail)
      throw new EmptyQueueException("");
    return _tail.o;
  }
  
  bool  empty() {
    return _head == null;
  }
}

unittest {
  auto q = new Queue!(int);
  assert(q.empty);
  try {
    q.take();
    assert(0);
  }
  catch (EmptyQueueException e) {
  }
  try {
    q.head();
    assert(0);
  }
  catch (EmptyQueueException e) {
  }
  try {
    q.tail();
    assert(0);
  }
  catch (EmptyQueueException e) {
  }
  q.append(1);
  assert(!q.empty);
  assert(q.head() == 1);
  assert(q.tail() == 1);
  q.append(2);
  assert(!q.empty);
  assert(q.head() == 1);
  assert(q.tail() == 2);
  q.append(3);
  assert(!q.empty);
  assert(q.head() == 1);
  assert(q.tail() == 3);

  assert(q.take() == 1);
  assert(q.head() == 2);
  assert(q.tail() == 3);
  assert(!q.empty);

  assert(q.take() == 2);
  assert(q.head() == 3);
  assert(q.tail() == 3);
  assert(!q.empty);

  assert(q.take() == 3);
  assert(q.empty);
  try {
    q.take();
    assert(0);
  }
  catch (EmptyQueueException e) {
  }
  try {
    q.head();
    assert(0);
  }
  catch (EmptyQueueException e) {
  }
  try {
    q.tail();
    assert(0);
  }
  catch (EmptyQueueException e) {
  }
  q.append(1);
  assert(!q.empty);
  assert(q.head() == 1);
  assert(q.tail() == 1);
  q.append(2);
  assert(!q.empty);
  assert(q.head() == 1);
  assert(q.tail() == 2);
  q.append(3);
  assert(!q.empty);
  assert(q.head() == 1);
  assert(q.tail() == 3);

  assert(q.take() == 1);
  assert(q.head() == 2);
  assert(q.tail() == 3);
  assert(!q.empty);

  assert(q.take() == 2);
  assert(q.head() == 3);
  assert(q.tail() == 3);
  assert(!q.empty);

  assert(q.take() == 3);
  assert(q.empty);
  try {
    q.take();
    assert(0);
  }
  catch (EmptyQueueException e) {
  }
  try {
    q.head();
    assert(0);
  }
  catch (EmptyQueueException e) {
  }
  try {
    q.tail();
    assert(0);
  }
  catch (EmptyQueueException e) {
  }
}