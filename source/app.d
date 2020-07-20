import std.stdio;

import board;
import image.svg;
import image.image;

import std.range;
import std.algorithm;
import std.array;
import std.stdio;
import std.file : readText;

import std.json;
import std.net.curl;
import std.conv : to;
import std.math : round;
import std.datetime;

void main()
{
  EinkBoard board = new EinkBoard();

  writeln("Clearing screen");
  board.clearScreen();

  writeln("Generating image");
  Svg svg = new Svg(readText("template.svg"));

  string data = weatherRequest();
  JSONValue[] j = parseJSON(data).arrayNoRef();

  foreach (i, forecast; j[0 .. 10])
  {
    string original = "${" ~ (i + 1).to!string ~ "}";

    SysTime utcDate = SysTime.fromISOExtString(forecast["observation_time"]["value"].str());
    string hour = utcDate.toLocalTime().hour().to!string ~ "u";
    if (hour.length == 2)
      hour = hour ~ " ";

    string value = forecast["precipitation"]["value"].to!string;
    if (value != "0")
      value = (round(value.to!double * 1000.0) / 1000.0).to!string;

    svg.source = svg.source.replace(original, hour ~ " - " ~ value);
  }

  svg.source.writeln;

  RGBAImage image = RGBAImage.fromSvg(svg);
  ubyte[] blackImage = image.to1BitBlue();

  writeln("Drawing image");
  board.displayBlackImage(blackImage.idup);
}

string weatherRequest()
{
  string data = "";
  auto http = HTTP();
  http.url = "https://api.climacell.co/v3/weather/forecast/hourly" ~ "?"
    ~ "lat=51.2082905" ~ "&" ~ "lon=3.2261497";
  http.method = HTTP.Method.get;
  http.addRequestHeader("content-type", "application/json");
  http.addRequestHeader("apikey", "LhFe6mM09Z8CTwUjGgYiSuAjc5SSOVYa");
  http.onReceive = (ubyte[] msg) { data ~= cast(string) msg.dup; return msg.length; };
  http.perform();
  return data;
}
