
<img src="https://github.com/turbolent/NewtonKit/raw/master/logo.png" width="156" height="156" alt="NewtonKit Logo"/>

---

[![Build Status](https://travis-ci.org/turbolent/NewtonKit.svg?branch=master)](https://travis-ci.org/turbolent/NewtonKit)

An implementation of the Apple Newton Dock protocol in Swift.


## Usage


### Connection type

#### TCP

On your computer, run:

```sh
swift run tcp
```

This will start a TCP server on the Newton Dock port 3679.

Once you see `Waiting for connection ...`, start the Dock application on your Newton and initiate a TCP/IP connection.
The connection is succesfully established once `Connected` appears, at which point you may enter a command (see below).

#### Serial

On your computer, run:

```sh
swift run <path-to-serial-device>
```

Where `<path-to-serial-device>` is the path to the serial device the Newton is connected to. On macOS, you should use the `/dev/cu.usbserial-*` device which appears when a USB-to-serial adapter is used. On Linux, the device name is likely `/dev/ttyUSB*` or `/dev/ttyS*`.

Once you see `Waiting for connection ...` start the Dock application on your Newton and initiate a serial connection.
The connection is succesfully established once `Connected` appears, at which point you may enter a command.


### Commands

- `keyboard`: Start keyboard passthrough. Enter `.stop` to stop and return to the command prompt.
- `info`: Get Newton system information
- `backup`: Start backup (work in progress)
    - Notes are exported as HTML files to `~/Library/Application Support/Newton/Backups/Notes/`
- `load <path>`: Install the package at the given path

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
