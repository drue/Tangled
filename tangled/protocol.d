module tangled.protocol;

import tangled.interfaces;
import tangled.failure;

import tango.net.InternetAddress;

class BaseProtocol : IProtocol {
  ITransport transport;

  void makeConnection(ITransport transport) {
    this.transport = transport;
  }

  void dataReceived(char[] data) {
  }
  void connectionLost(Failure reason){
  }
  void connectionMade(){
  }
  void connectionFlushed(){
  }
}

class SimpleFactory(Protocol) : IProtocolFactory {
  Protocol buildProtocol(InternetAddress addr, IConduit socket) {
    return new Protocol();
  }
  void doStart() {
  }
  void doStop() {
  }
}
