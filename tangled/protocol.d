module tangled.protocol;

import tango.net.InternetAddress;
import tango.io.model.IConduit;

import tangled.interfaces;
import tangled.failure;
import tangled.conduit;

class BaseProtocol : IProtocol {
  ASocketConduit transport;
  IProtocolFactory factory;

  this (IProtocolFactory f){
    factory = f;
  }

  void makeConnection(ASocketConduit transport) {
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

class BaseHTTPProtocol : IHTTPProtocol {
  IHTTPRequest req;
  IHTTPProtocolFactory factory;

  this (IHTTPProtocolFactory f) {
    factory = f;
  }

  void handleRequest(IHTTPRequest req) {
    this.req = req;
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
  IProtocol buildProtocol() {
    return new Protocol(this);
  }
  void doStart() {
  }
  void doStop() {
  }
}

class SimpleHTTPFactory(Protocol) : IHTTPProtocolFactory {
  IHTTPProtocol buildProtocol() {
    return new Protocol(this);
  }
  void doStart() {
  }
  void doStop() {
  }
}
