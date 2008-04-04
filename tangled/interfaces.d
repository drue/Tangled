module tangled.interfaces;

import tango.net.InternetAddress;
import tango.io.selector.model.ISelector;
import tangled.defer;
import tangled.failure;
import tangled.time;

enum SystemEvent { startup, shutdown, persist };
enum Phase {before, during, after };

alias Deferred!(bool) StopListeningRes;

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


interface IReactorCore {
  Deferred!(char[]) resolve(char[] name, int timeout);
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
  void makeConnection(ITransport transport);
  void dataReceived(char[] data);
  void connectionLost(Failure reason);
  void connectionMade();
  void connectionFlushed();
}

interface IProtocolFactory {
  IProtocol buildProtocol(InternetAddress addr);
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

