module board;

import std.conv : to;
import std.process : executeShell;
import std.stdio : writeln;

// See http://wiringpi.com/reference/
// Core
extern (C) int wiringPiSetupSys();
extern (C) void digitalWrite(int pin, ubyte value);
extern (C) ubyte digitalRead(int pin);
// Timing
extern (C) void delay(uint howLong);
// SPI
extern (C) int wiringPiSPISetup(int channel, int speed);
extern (C) int wiringPiSPIDataRW(int channel, ubyte* data, int len);

struct Pin
{
  string name;
  int number;
  bool isOutput;
}

const PIN_RST = 17;
const PIN_DC = 25;
const PIN_CS = 8;
const PIN_BUSY = 24;

const Pin[] pins = [
  {"RST", PIN_RST, true}, {"DC", PIN_DC, true}, {"CS", PIN_CS, true},
  {"BUSY", PIN_BUSY, false}
];

const DISPLAY_WIDTH = 104;
const DISPLAY_HEIGHT = 212;

class EinkBoard
{
  this()
  {
    exportGpioPins();
    wiringPiSetupSys();
    wiringPiSPISetup(0, 10_000_000);
    initializeBoard();
  }

  private void exportGpioPins()
  {
    foreach (Pin pin; pins)
      executeShell("gpio export" ~ pin.number.to!string ~ " " ~ pin.isOutput ? "out" : "in");
  }

  void reset()
  {
    digitalWrite(PIN_CS, 1);
    digitalWrite(PIN_RST, 1);
    delay(1000);
    digitalWrite(PIN_RST, 0);
    delay(10);
    digitalWrite(PIN_RST, 1);
    delay(10);
  }

  void sendCommand(ubyte command)
  {
    digitalWrite(PIN_DC, 0);
    digitalWrite(PIN_CS, 0);
    wiringPiSPIDataRW(0, &command, 1);
    digitalWrite(PIN_CS, 1);
  }

  void sendData(ubyte data)
  {
    digitalWrite(PIN_DC, 1);
    digitalWrite(PIN_CS, 0);
    wiringPiSPIDataRW(0, &data, 1);
    digitalWrite(PIN_CS, 1);
  }

  void waitForBusyRelease()
  {
    while (true)
    {
      sendCommand(0x71); // Unknown
      if (digitalRead(PIN_BUSY) == 0x00)
        break;
    }
    delay(200);
  }

  private void initializeBoard()
  {
    reset();
    delay(10);

    sendCommand(0x04); // Unknown
    waitForBusyRelease();

    sendCommand(0x00); // "Panel setting"
    sendData(0x0f); // "LUT from OTP, 128x296"
    sendData(0x89); // "Temperature sensor, boost and other related timing settings"

    sendCommand(0x61); // "Resolution setting"
    sendData(0x68);
    sendData(0x00);
    sendData(0xD4);

    // "Vcom and data interval setting"
    // WBmode:  VBDF 17|D7      VBDW 97  VBDB 57
    // WBRmode: VBDF F7 VBDW 77 VBDB 37  VBDR B7;
    sendCommand(0x50);
    sendData(0x77);
  }

  void refreshDisplay()
  {
    sendCommand(0x12); // "Display refresh"
    delay(100);
    waitForBusyRelease();
  }

  void sleep()
  {
    sendCommand(0x50); // Unknown
    sendData(0xf7);

    sendCommand(0x02); // "Power off"
    waitForBusyRelease();
    sendCommand(0x07); // "Deep sleep"
    sendData(0xA5);
  }

  void clearScreen()
  {
    immutable ushort width = (DISPLAY_WIDTH % 8 == 0) ? (DISPLAY_WIDTH / 8) : (DISPLAY_WIDTH / 8 + 1);
    immutable ushort height = DISPLAY_HEIGHT;

    // Black data
    sendCommand(0x10);
    foreach (i; 0 .. height)
      foreach (j; 0 .. width)
        sendData(0xFF);

    // Red data
    sendCommand(0x13);
    foreach (i; 0 .. height)
      foreach (j; 0 .. width)
        sendData(0xFF);

    refreshDisplay();
  }

  void displayImage(const ubyte* blackimage, const ubyte* redimage)
  {
    immutable ushort width = (DISPLAY_WIDTH % 8 == 0) ? (DISPLAY_WIDTH / 8) : (DISPLAY_WIDTH / 8 + 1);
    immutable ushort height = DISPLAY_HEIGHT;

    // Black data
    sendCommand(0x10);
    foreach (i; 0 .. height)
      foreach (j; 0 .. width)
        sendData(blackimage[j + i * width]);

    // Red data
    sendCommand(0x13);
    foreach (i; 0 .. height)
      foreach (j; 0 .. width)
        sendData(redimage[j + i * width]);

    refreshDisplay();
  }
}
