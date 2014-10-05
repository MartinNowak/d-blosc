/*
    Copyright (C) 2014  Francesc Alted
    http://blosc.org
    License: MIT (see LICENSE.txt)

    Example program demonstrating use of the Blosc filter from C code.

    To compile this program:

    gcc simple.c -o simple -lblosc -lpthread

    or, if you don't have the blosc library installed:

    gcc -O3 -msse2 simple.c ../blosc/*.c -I../blosc -o simple -lpthread

    Using MSVC on Windows:

    cl /Ox /Fesimple.exe /Iblosc simple.c blosc\*.c

    To run:

    $ ./simple
    Blosc version info: 1.4.2.dev ($Date:: 2014-07-08 #$)
    Compression: 4000000 -> 158494 (25.2x)
    Decompression succesful!
    Succesful roundtrip!

*/

import std.stdio;
import deimos.blosc;

enum SIZE = 100*100*100;
//#define SHAPE = {100,100,100}
//#define CHUNKSHAPE = {1,100,100}

int main(){
  __gshared float data[SIZE];
  __gshared float data_out[SIZE];
  __gshared float data_dest[SIZE];
  int isize = SIZE*float.sizeof, osize = SIZE*float.sizeof;
  int dsize = SIZE*float.sizeof, csize;
  int i;

  for(i=0; i<SIZE; i++){
    data[i] = i;
  }

  /* Register the filter with the library */
  writef("Blosc version info: %s (%s)\n",
	 BLOSC_VERSION_STRING, BLOSC_VERSION_DATE);

  /* Initialize the Blosc compressor */
  blosc_init();

  /* Compress with clevel=5 and shuffle active  */
  csize = blosc_compress(5, 1, float.sizeof, isize, data.ptr, data_out.ptr, osize);
  if (csize < 0) {
    writef("Compression error.  Error code: %d\n", csize);
    return csize;
  }

  writef("Compression: %d -> %d (%.1fx)\n", isize, csize, (1.*isize) / csize);

  /* Decompress  */
  dsize = blosc_decompress(data_out.ptr, data_dest.ptr, dsize);
  if (dsize < 0) {
    writef("Decompression error.  Error code: %d\n", dsize);
    return dsize;
  }

  writef("Decompression succesful!\n");

  /* After using it, destroy the Blosc environment */
  blosc_destroy();

  for(i=0;i<SIZE;i++){
    if(data[i] != data_dest[i]) {
      writef("Decompressed data differs from original!\n");
      return -1;
    }
  }

  writef("Succesful roundtrip!\n");
  return 0;
}
