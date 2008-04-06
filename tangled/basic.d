module tangled.basic;

import tango.io.Console;
import tangled.protocol;
import txt = tango.text.Util;
import tango.text.convert.Layout;

import tango.io.Stdout;


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
    while(line_mode) {
      auto line = txt.head(__buffer, "\r\n", __buffer);
      if(!__buffer) {
	__buffer = line;
	if(__buffer.length > MAX_LENGTH) {
	  line = __buffer;
	  __buffer = "";
	  return lineLengthExceeded(line);
	}
	break;
      }
      else {
	if(line.length > MAX_LENGTH) {
	  auto exceeded = line ~ __buffer;
	  __buffer =  "";
	  return lineLengthExceeded(exceeded);
	}
	lineReceived(line);
      }
    }
    if(!line_mode) { 
      auto x = __buffer;
      __buffer = "";
      if (x.length)
	rawDataReceived(x);
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
    
    // first check behavior of txt processing funcs
    auto foo = "this\r\nis\r\na\r\ntest\r\n";
    assert(txt.split(foo, "\r\n").length == 5);
    assert(txt.split(foo, "\r\n")[length-1] == "");
    auto boo = "this\r\nis\r\na\r\ntest\r\n\r\n";
    assert(txt.split(boo, "\r\n").length == 6);
    assert(txt.split(boo, "\r\n")[length-1] == "");
    assert(txt.split(boo, "\r\n")[length-2] == "");
    assert(txt.split(boo, "\r\n")[length-3] == "test");
    auto moo = txt.split("\r\n", "\r\n");
    assert(moo.length == 2);
    assert(moo[0] == "");
    assert(moo[1] == "");

    char[] a, b;
    char[] w = "\r\n";
    a = txt.head(w, "\r\n", b);
    assert(a == "");
    assert(b == "");
    
    w = w~w;
    a = txt.head(w, "\r\n", b);
    assert(a == "");
    assert(b == "\r\n");
    

    auto x = new myreceiver();
    assert(x.line_mode);
    x.dataReceived(foo);
    assert(x.line_mode);
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

    assert(x.line_mode);
    x.dataReceived("\r\n");
    assert(!x.line_mode);

    x = new myreceiver();
    auto bar = "HTTP/1.0 OK\r\nKey: Value\r\n\r\nStuff\r\n";
    assert(txt.split(bar, "\r\n").length == 5);
    x.dataReceived(bar);
    assert(x.line_mode == false);
    assert(x.gotlines.length == 2);

    //Stdout.format(">> length {} {}\n", x.data.length, x.data).flush;
    
    assert(x.data[0..5] == "Stuff");
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
