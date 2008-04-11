module tangled.protocol;

import tango.net.InternetAddress;
import tango.io.model.IConduit;

import tangled.interfaces;
import tangled.failure;


class BaseProtocol : IProtocol {
  IAConduit transport;

  void makeConnection(IAConduit transport) {
    this.transport = transport;
  }

  /*
  void dataReceived(char[] data) {
  }
  void connectionLost(Failure reason){
  }
  void connectionMade(){
  }
  void connectionFlushed(){
  }*/
}

class SimpleFactory(Protocol) : IProtocolFactory {
  Protocol buildProtocol() {
    return new Protocol();
  }
  void doStart() {
  }
  void doStop() {
  }
}
