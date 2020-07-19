module image.image;

import std.range : chunks;
import std.algorithm : map;
import std.array : array;

import image.bitmaps;
import image.svg;


import imageformats;

class RGBAImage
{
  ubyte[] pixels;
  ulong width, height;

  public this()
  {
  }

  public static RGBAImage fromSvg(Svg svg)
  {
    RGBAImage result = new RGBAImage();
    const IFImage image = svg.render!(ColFmt.RGBA);
    result.width = image.w;
    result.height = image.h;
    result.pixels = image.pixels.dup;
    return result;
  }

  public ubyte[] to1BitBlue()
  {
    return pixels.chunks(4).map!(a => a[2]).array.conv8BitTo1Bit;
  }

  public ubyte[] to1BitRed()
  {
    return pixels.chunks(4).map!(a => a[0]).array.conv8BitTo1Bit;
  }
}