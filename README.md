
![NewtonKit Logo](https://github.com/turbolent/NewtonKit/raw/master/logo.png =92x87)

---

[![Build Status](https://travis-ci.org/turbolent/NewtonKit.svg?branch=master)](https://travis-ci.org/turbolent/NewtonKit)

An implementation of the Apple Newton Dock protocol in Swift.


## Usage


On your computer, run:

```sh
swift run <path-to-serial-device>
```

Where `<path-to-serial-device>` is the path to the serial device the Newton is connected to. On macOS, you should use the `/dev/cu.usbserial-*` device which appears when a USB-to-serial adapter is used. On Linux, the device name is likely `/dev/ttyUSB*` or `/dev/ttyS*`.

Once you see `Connecting ...` start the Dock application on your Newton and initiate a serial connection.
The connection is succesfully established once `Connected` appears, at which point you may enter a command.


Commands:

- `keyboard`: Start keyboard passthrough. Enter `.stop` to stop and return to the command prompt.
- `info`: Get Newton system information
- `backup`: Start backup (work in progress)
    - Notes are exported as HTML files to `~/Library/Application Support/Newton/Backups/Notes/`

Currently only Newton OS 2.x devices (MessagePad 130/2000/2100 and eMate) are supported.



## Development

### Einstein

NewtonKit works with the [Einstein](https://github.com/pguyot/Einstein) Newton OS emulator.
Make sure to use at least the [pre-release version with serial port emulation](https://github.com/pguyot/Einstein/releases/tag/2017.2.extr).

Once you have Einstein running, use [socat](http://www.dest-unreach.org/socat/) to create a PTY device for the named pipes created by Einstein:

```sh
socat -d -d PTY,raw,mode=666,echo=0,link=$HOME/einstein \
    PIPE:$HOME/Library/Application\ Support/Einstein\ Emulator/ExtrSerPortSend\!\!PIPE:$HOME/Library/Application\ Support/Einstein\ Emulator/ExtrSerPortRecv
```

Then start the NewtonKit command line tool:

```
swift run $HOME/einstein
```
