/*
    Copyright (C) 2014  Francesc Alted
    http://blosc.org
    License: MIT (see LICENSE.txt)

    Example program demonstrating use of the Blosc filter from C code.

    To compile this program using gcc or clang:

    gcc/clang multithread.c -o multithread -lblosc -lpthread

    or, if you don't have the blosc library installed:

    gcc -O3 -msse2 multithread.c ../blosc/*.c  -I../blosc -o multithread -lpthread

    Using MSVC on Windows:

    cl /Ox /Femultithread.exe /Iblosc multithread.c blosc\*.c
    
    To run:

    $ ./multithread
    Blosc version info: 1.4.2.dev ($Date:: 2014-07-08 #$)
    Using 1 threads (previously using 1)
    Compression: 4000000 -> 158494 (25.2x)
    Succesful roundtrip!
    Using 2 threads (previously using 1)
    Compression: 4000000 -> 158494 (25.2x)
    Succesful roundtrip!
    Using 3 threads (previously using 2)
    Compression: 4000000 -> 158494 (25.2x)
    Succesful roundtrip!
    Using 4 threads (previously using 3)
    Compression: 4000000 -> 158494 (25.2x)
    Succesful roundtrip!

*/

import std.stdio;
import deimos.blosc;

enum SIZE = 100*100*100;
//#define SHAPE {100,100,100}
//#define CHUNKSHAPE {1,100,100}

int main(){
  __gshared float data[SIZE];
  __gshared float data_out[SIZE];
  __gshared float data_dest[SIZE];
  int isize = SIZE*float.sizeof, osize = SIZE*float.sizeof;
  int dsize = SIZE*float.sizeof, csize;
  int nthreads, pnthreads, i;

  for(i=0; i<SIZE; i++){
    data[i] = i;
  }

  /* Register the filter with the library */
  writef("Blosc version info: %s (%s)\n",
	 BLOSC_VERSION_STRING, BLOSC_VERSION_DATE);

  /* Initialize the Blosc compressor */
  blosc_init();

  /* Tell Blosc to use some number of threads */
  for (nthreads=1; nthreads <= 4; nthreads++) {

    pnthreads = blosc_set_nthreads(nthreads);
    writef("Using %d threads (previously using %d)\n", nthreads, pnthreads);

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

    /* After using it, destroy the Blosc environment */
    blosc_destroy();

    for(i=0;i<SIZE;i++){
      if(data[i] != data_dest[i]) {
	writef("Decompressed data differs from original!\n");
	return -1;
      }
    }

    writef("Succesful roundtrip!\n");
  }

  return 0;
}
