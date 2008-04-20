module tangled.http;

import tango.core.Exception;
import tango.io.Buffer;
import tango.io.Console;
import tango.math.Math;
import tango.net.SocketConduit;
import tango.net.http.HttpClient;
import tango.net.Uri;
import tango.text.Ascii;
import tango.text.convert.Layout;
import tango.text.stream.LineIterator;

import txt = tango.text.Util;
import Integer = tango.text.convert.Integer;

import tangled.failure;
import tangled.protocol;
import tangled.conduit;

static Layout!(char) format;

static this() {
  format = new Layout!(char)();
}

/*
class OHTTPClient : BaseProtocol {
  ulong contentLength;
  bool gotLength = false;
  bool firstLine = true;
  char[] resBuffer = null;
  IBuffer buf;

  void sendLine(char[] line) {
    buf.append(line);
    buf.append("\r\n").flush;
  }

  void sendCommand(char[] command, char[] path) {
    sendLine(format("{0} {1} HTTP/1.0", command, path));
  }
  
  void sendHeader(char[] name, char[] value) {
    sendLine(format("{0}: {1}", name, value));
  }
  
  void endHeaders() {
    sendLine("");
  }
  
  void makeConnection(ASocketConduit t)  {
    super.makeConnection(t);
    buf = new Buffer(transport);
    auto lines = new LineIterator!(char)(buf.input);
    foreach(line; lines) {
      if (firstLine) {
	firstLine = false;
	auto i = txt.locate(line, ' ');
	if (i == line.length) {
	  transport.shutdown();
	  return;
	}
	auto vers = line[0..i];
	auto status = line[++i..length];
	i = txt.locate(status, ' ');
	char[] message;
	if (i != status.length) {
	  message = status[i+1..length];
	  status = status[0..i];
	}
	else {
	  message = "";
	}
	handleStatus(vers, status, message);
	return;
      }
      else if (line.length) {
	auto n = txt.locate(line, ':');
	if (n == line.length) {
	  transport.shutdown();
	  return;
	}
	char[] key = line[0..n];
	char[] val = txt.trim(line[++n..length]);
	handleHeader(key, val);
	if (toLower(key.dup) == "content-length") {
	  this.contentLength = Integer.parse(val);
	  gotLength = true;
	}
      }
      else {
	resBuffer = "";
	handleEndHeaders();
	break;
      }
    }
    int c;
    char[4096] b;
    while(c != Eof) {
      c = buf.input.read(b);
      if(c && c != Eof)
	rawDataReceived(b[0..c]);
    }
  }
  
  void connectionLost(Failure reason) {
    handleResponseEnd();
  }

  void handleResponseEnd() {
    if (resBuffer !is null) {
      handleResponse(resBuffer);
      resBuffer = null;
    }
  }

  void handleResponsePart(char[] data) {
    resBuffer ~= data;
  }

  void handleStatus(char[] vers, char[] status, char[] message) {
  }
  
  void handleHeader(char[] key, char[] val) {
  }

  void handleEndHeaders() {
  }

  void handleResponse(char[] data) {
  }

  void rawDataReceived(char[] data) {
    char[] d, rest;
    if (gotLength) {
      d = data[0..min(contentLength, data.length)];
      if (data.length > contentLength) {
	rest = data[contentLength..data.length];
      }
      contentLength -= d.length;
    }
    else {
      d = data;
    }
    handleResponsePart(d);

    if (gotLength && contentLength == 0) {
      handleResponseEnd();
    }
  }
}

*/

class AHttpClient : HttpClient {
  this (RequestMethod method, Uri uri) {
    super(method, uri);
  }

  this (RequestMethod method, char[] url) {
    super(method, url);
  }

  protected SocketConduit createSocket() {
    return new ASocketConduit();
  }
}



/*
unittest {
  class Foo : HTTPClient {
    char[] buf;
    void handleResponse (char[] data) {
      buf = data;
    }
  }
  auto z = "HTTP/1.0 200 OK\r\n"
    "Date: Wed, 28 Mar 2007 01:00:38 GMT\r\n"
    "Content-length: 46\r\n"
    "Content-type: text/plain\r\n"
    "Pragma: no-cache\r\n"
    "Server: hypertracker/0.4\r\n"
    "\r\n"
    "d8:intervali329e12:min intervali365e5:peers0:e";
    
  auto x = new Foo();
  x.dataReceived(z);
  assert(x.buf.length == 46);
}
*/