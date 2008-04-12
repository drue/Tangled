module tangled.interfaces;

import libevent.http;

import tango.net.InternetAddress;
import tango.io.selector.model.ISelector;
import tangled.failure;
import tangled.time;
import tangled.conduit;

enum SystemEvent { startup, shutdown, persist };
enum Phase {before, during, after };

interface IConnector {
  void stopConnecting();
  void disconnect(); 
  void connect();
  InternetAddress getDestination();
}

interface IReactorTCP {
  ISelectable listenTCP(InternetAddress bind, IProtocolFactory factory, int backlog);
  void stopListeningTCP(ISelectable s);
  void connectTCP(InternetAddress dest, IProtocol protocol, int timeout, InternetAddress bind);
}

interface IReactorHTTP {
  IHTTPServer httpListen(InternetAddress bind);
}

interface IHTTPServer {
  void registerURI(char[] URI, IHTTPProtocolFactory fac);
}

interface IDeferred (T) {
  void addCallback(T delegate(T) f);
  void callBack(T res);
  void callback(T res);
  T yieldForResult();
}

interface IReactorCore {
  IDeferred!(char[]) resolve(char[] name, int timeout);
  void run();
  void crash();
  void iterate(double delay);
  void fireSystemEvent(SystemEvent event);
}

interface IDelayedCall {
  double time();
  void cancel();
  bool active();
  void call();
  int opCmp(IDelayedCall o);
}

interface IProtocol {
  void makeConnection(ASocketConduit transport);
  /*  void dataReceived(char[] data);
  void connectionLost(Failure reason);
  void connectionMade();
  void connectionFlushed();*/
}

interface IProtocolFactory {
  IProtocol buildProtocol();
  void doStart();
  void doStop();
}

interface IHTTPRequest {
  char[] remoteHost();
}

interface IHTTPProtocolFactory {
   IProtocol buildProtocol(IHTTPRequest req);
   void doStart();
   void doStop();
}

interface ITransport {
  void write(char[] data);
  void writeSequence(char[][] data);
  void loseConnection();
  bool isFlushed();
  InternetAddress getPeer();
  InternetAddress getHost();
}

interface IASelectable : ISelectable {
  void readyToRead();
  void readyToWrite();
  void signal();
  void timeout();
}

interface IListener {
  int fileHandle();
  ASocketConduit accept();
  IProtocolFactory factory();
}

interface IAConduit {
  InternetAddress remoteAddr();
}

