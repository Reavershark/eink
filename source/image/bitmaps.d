module image.bitmaps;

import std.range : chunks, retro;
import std.array : array;
import std.process : executeShell;
import imageformats;

ubyte[] conv8BitTo1Bit(ubyte[] input)
{
  ubyte[] result;
  foreach (pixel; input.chunks(8))
  {
      pixel = pixel.retro.array;
      ubyte b = 0;
      for (int i = 0; i < 8; ++i)
          if (pixel[i] > 63)
              b |= 1 << i;
      result ~= b;
  }
  return result;
}