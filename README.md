# pacundo

You know those times when you install some ArchLinux upgrades and it breaks your
system, and now you have to go in and downgrade those packages? It's a pain
ain't it? Well, this should make it slightly less of a pain (you may still have
to boot from a USB depending on just how broken it is).

## Installation

Dependencies:

- Perl 5
- `File::ReadBackwards` module
- PAR Packager (for compiling)
- GNU Makefile

You can install these packages with the following command:

```console
# pacman -S perl perl-file-readbackwards perl-par-packer
```

## License

This project is licensed under the terms & conditions of the Zlib license.
