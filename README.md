# NewtonKit

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


Currently only Newton OS 2.x devices (MessagePad 130/2000/2100 and eMate) are supported.
