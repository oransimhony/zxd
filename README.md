# ZXD

Zig heX Dump - a simple colorful hexdump utility written in Zig.

## Installation
```console
$ git clone https://github.com/oransimhony/zxd.git
$ cd zxd
$ zig build
```

## Usage

Perform either of the following two:

```console
$ zig build run -- <filename>...
```

```console
$ ./zig-out/bin/zxd <filename>...
```

You can also hexdump STDIN if use pass `-` as the path, this can be useful when piping commands:

```console
$ echo -e "Some\nSample\tText\f\n" | zxd -
```
