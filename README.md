# pacundo

You know those times when you install some ArchLinux upgrades and it breaks your
system, and now you have to go in and downgrade those packages? It's a pain
ain't it? Well, this should make it slightly less of a pain (you may still have
to boot from a USB depending on just how broken it is).

## Installation

### Dependencies

- Perl 5
- `File::ReadBackwards` module
- GNU Makefile

You can install these packages with the following command:

```console
# pacman -S perl perl-file-readbackwards
```

### Compiling & Installing

The script is compiled and installed using GNU Makefile. Therefore you can use
`make install` to build and install the script and its man-page as expected.
They are installed (by default) to `/usr/local`. To change this to a different
directory simply prepend the `PREFIX=<path>` to your `make install` command.

## Usage

The first concept to understand is that of a transaction. A transaction is
defined in the pacman logs as package operations done during a single use of the
command (or so it seems, at least). If you look at the logs
(`/var/log/pacman.log`) this would be everything between the lines `[ALPM]
transaction started` and `[ALPM] transaction completed`. You can set how many
transactions to list/undo by using the `-t` argument.

There are two modes for undoing pacman transactions:

- Interactive (`-i`, default): will show you a numbered list with all the package
  operations of the selected transactions.
- Automatic (`-r`): will automatically undo all package operations of the
  selected transactions.

Look at the man-page (`man pacundo`) for more information.

### Supported AUR Helpers

- [yay](https://github.com/Jguer/yay)

## License

This project is licensed under the terms & conditions of the Zlib license.
