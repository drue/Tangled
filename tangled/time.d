module tangled.time;

import tango.sys.Common;

// simple decimal seconds since unix epoch, like god intended
double time() {
  double n;
  timeval tv;
  gettimeofday(&tv, null);
  return tv.tv_sec + (tv.tv_usec / 1000000.0);
}
