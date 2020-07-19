module image.svg;

import std.file : deleteme, write, remove;
import std.process : executeShell;
import imageformats;

class Svg
{
  public string source;

  this(string source)
  {
    this.source = source;
  }

  public IFImage render(ColFmt format)()
  {
    assert(executeShell("convert --version").status == 0, "Imagemagick is not installed");

    string tempSvgFile = deleteme ~ ".svg";
    string tempBmpFile = deleteme ~ ".bmp";
    scope (exit)
    {
      tempSvgFile.remove;
      tempBmpFile.remove;
    }

    tempSvgFile.write(source);
    executeShell("convert " ~ tempSvgFile ~ " -rotate 90 " ~ tempBmpFile);
    IFImage image = read_image(tempBmpFile, format);

    return image;
  }
}
