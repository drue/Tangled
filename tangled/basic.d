module tangled.basic;

import tango.io.Console;
import tangled.protocol;
import txt = tango.text.Util;
import tango.text.convert.Layout;


static Layout!(char) format;

static this(){
  format = new Layout!(char)();
}

class LineReceiver : BaseProtocol {
  bool line_mode = true;
  char[] __buffer = "";
  const char[] delimiter = "\r\n";
  const uint MAX_LENGTH = 16384;
  
  void clearLineBuffer() {
    __buffer = "";
  }

  void dataReceived(char[] data) {
    __buffer = __buffer ~ data;
    if (line_mode) {
      uint keep_last = 1;
      if (__buffer[length-delimiter.length..length] == delimiter)
	keep_last = 0;

      auto lines = txt.split(__buffer, delimiter);
      if (keep_last)
	__buffer = lines[length-1];
      else
	__buffer = "";
      if (lines.length == 1 && lines[0].length > MAX_LENGTH)
	return lineLengthExceeded(lines[0]);
      int i;
      for(i=0;i < (lines.length - keep_last) && line_mode; i++) {
	auto line = lines[i];
	if (line.length > MAX_LENGTH)
	  lineLengthExceeded(line);
	lineReceived(line);
	if (!line_mode) {
	  break;
	}
      }
      if (!line_mode) {
	__buffer = "";
	i += 1;
	for(i=i;i < lines.length;i++) {
	  if(i < lines.length - 1 || !keep_last)
	    __buffer ~= lines[i] ~ delimiter;
	  else
	    __buffer ~= lines[i];
	}
	rawDataReceived(__buffer);
	__buffer = "";
      }
    }
    else {
      data = __buffer;
      __buffer = "";
      if (data.length)
	rawDataReceived(data);
    }
  }
  
  void setLineMode(char[] extra="") {
    line_mode = true;
    if (extra.length)
      dataReceived(extra);
  }

  void setRawMode() {
    line_mode = false;
  }

  void lineLengthExceeded(char[] line) {
    return transport.loseConnection();
  }

  void lineReceived(char[] line) {
  }
  
  void rawDataReceived(char[] data) {
  }
  
  void sendLine(char[] line) {
    transport.write(line ~ delimiter);
  }


  unittest {

    class myreceiver : LineReceiver {
      char [][] gotlines;
      char[] data;
      void lineReceived(char[] line) {
	if(line == "")
	  setRawMode();
	else
	  gotlines ~= [line];
      }
      void rawDataReceived(char[] data) {
	this.data ~= data;
      }
    }

    auto x = new myreceiver();
    auto foo = "this\r\nis\r\na\r\ntest\r\n";
    x.dataReceived(foo);
    assert(x.gotlines.length == 4);
    assert(x.gotlines[0]=="this");
    assert(x.gotlines[1]=="is");
    assert(x.gotlines[2]=="a");
    assert(x.gotlines[3]=="test");

    x = new myreceiver();
    x.dataReceived("testing\r\nagain");
    assert(x.gotlines.length == 1);
    assert(x.gotlines[0] == "testing");
    assert(x.__buffer == "again");
    x.dataReceived("yes\r\n");
    assert(x.gotlines.length == 2);
    assert(x.gotlines[1] == "againyes");
    assert(x.__buffer.length == 0);

    x = new myreceiver();
    auto bar = "HTTP/1.0 OK\r\nKey: Value\r\n\r\nStuff\r\n";
    x.dataReceived(bar);
    assert(x.line_mode == false);
    assert(x.gotlines.length == 2);
    assert(x.data.length == 7);

    auto z = "HTTP/1.0 200 OK\r\n"
      "Date: Wed, 28 Mar 2007 01:00:38 GMT\r\n"
      "Content-length: 46\r\n"
      "Content-type: text/plain\r\n"
      "Pragma: no-cache\r\n"
      "Server: hypertracker/0.4\r\n"
      "\r\n"
      "d8:intervali329e12:min intervali365e5:peers0:e";
    
    x = new myreceiver();
    x.dataReceived(z);
    assert(x.gotlines.length == 6);
    assert(x.data.length == 46);
  }
}