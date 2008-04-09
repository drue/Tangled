module tangled.conduit;

import tango.net.SocketConduit;


class TangledSocketConduit : SocketConduit
{
  uint read(void[] dst) {
    return 0;
  }

  uint write(void[] src) {
    return 0;
  }
}
