module tangled.http;

import tango.io.Console;
import tango.text.convert.Layout;
import Integer = tango.text.convert.Integer;
import tango.text.Ascii;
import tango.core.Exception;
import tango.math.Math;
import txt = tango.text.Util;

import tangled.basic;
import tangled.failure;

static Layout!(char) format;

static this() {
  format = new Layout!(char)();
}

class HTTPClient : LineReceiver {
  ulong contentLength;
  bool gotLength = false;
  bool firstLine = true;
  char[] resBuffer = null;

  void sendCommand(char[] command, char[] path) {
    sendLine(format("{0} {1} HTTP/1.0", command, path));
  }
  
  void sendHeader(char[] name, char[] value) {
    sendLine(format("{0}: {1}", name, value));
  }
  
  void endHeaders() {
    sendLine("");
  }
  
  void lineReceived(char[] line) {
    if (firstLine) {
      firstLine = false;
      auto i = txt.locate(line, ' ');
      if (i == line.length) {
	transport.loseConnection();
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
	transport.loseConnection();
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
      setRawMode();
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
      setLineMode(rest);
    }
  }
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
}

