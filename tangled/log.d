module tangled.log;


template SimpleLogger(alias name) {
  import tango.util.log.Log;
  import tango.text.convert.Layout;
  import tango.util.log.ConsoleAppender;
  import tango.util.log.DateLayout;

  private Logger log;
  private Layout!(char) format;

  static this(){
    log = Log.getLogger(name);
    log.addAppender(new ConsoleAppender(new DateLayout()));
    format = new Layout!(char)();
  }
}

