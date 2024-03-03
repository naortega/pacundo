#!/usr/bin/env perl

# Copyright (C) 2024 Ortega Froysa, Nicolás <nicolas@ortegas.org> All rights reserved.
# Author: Ortega Froysa, Nicolás <nicolas@ortegas.org>
#
# This software is provided 'as-is', without any express or implied
# warranty. In no event will the authors be held liable for any damages
# arising from the use of this software.
#
# Permission is granted to anyone to use this software for any purpose,
# including commercial applications, and to alter it and redistribute it
# freely, subject to the following restrictions:
#
# 1. The origin of this software must not be misrepresented; you must not
#    claim that you wrote the original software. If you use this software
#    in a product, an acknowledgment in the product documentation would be
#    appreciated but is not required.
#
# 2. Altered source versions must be plainly marked as such, and must not be
#    misrepresented as being the original software.
#
# 3. This notice may not be removed or altered from any source
#    distribution.

use strict;
use warnings;

use Getopt::Std;
use File::ReadBackwards;

my $VERSION = "1.0";
my $PROG_NAME = "pacundo";

sub print_version {
	print("$PROG_NAME v$VERSION\n");
}

sub print_help {
	&print_version();
	print("A time machine to return your ArchLinux machine back to a working state.\n");
	print("\nUSAGE:
	$PROG_NAME [-i|-r] [-t <num>] [-d]
	$PROG_NAME -h
	$PROG_NAME -v

OPTIONS:
	-i         Enter interactive mode to select packages to downgrade [default behavior]
	-r         Automatically downgrade all packages from last upgrade
	-t <num>   Specify the number of transactions to include for undoing selection [default 1]
	-d         Dry run, i.e. don't actually do anything
	-h         Show this help information
	-v         Print program version\n");
}

getopts("irt:dvh", \my %opts);

if ($opts{'v'}) {
	&print_version();
	exit 0;
} elsif ($opts{'h'}) {
	&print_help();
	exit 0;
} elsif ($opts{'r'} && $opts{'i'}) {
	print("Improper usage. -r and -i cannot be used at the same time.\n");
	print("Use -h for help information.\n");
	exit 1;
} elsif ($opts{'t'} && !($opts{'t'} =~ /[0-9]+/)) {
	print("The argument for -t must be a positive integer.\n");
	exit 1;
}

my $r_flag = $opts{'r'} // 0;
my $dry_run = $opts{'d'} // 0;
my $num_txs = $opts{'t'} // 1;

my $pacman_log = File::ReadBackwards->new("/var/log/pacman.log") or
die("Failed to load pacman log file.\n$!");

my $found_txs = 0;
my $in_tx = 0;

my @undo_txs;

while ($found_txs < $num_txs && defined(my $line = $pacman_log->readline)) {
	# Remeber that we're reading this in reverse order
	if (!$in_tx && $line =~ /\[ALPM\] transaction completed/) {
		$in_tx = 1;
	} elsif ($in_tx) {
		if ($line =~ /\[ALPM\] transaction started/) {
			$found_txs++;
			$in_tx = 0;
		} elsif ($line =~ /\[ALPM\] (upgraded|downgraded)/) {
			my ($action, $pkg_name, $oldver, $newver) = $line =~ /\[ALPM\] (upgraded|downgraded) ([^\s]+) \((.*) -> (.*)\)/;
			push(@undo_txs,
				{
					'action' => $action,
					'pkg_name' => $pkg_name,
					'oldver' => $oldver,
					'newver' => $newver,
				}
			);
		} elsif ($line =~ /\[ALPM\] (installed|removed)/) {
			my ($action, $pkg_name) = $line =~ /\[ALPM\] (installed|removed) ([^\s]+)/;
			push(@undo_txs,
				{
					'action' => $action,
					'pkg_name' => $pkg_name,
				}
			);
		}
	}
}


# Interactive mode
if (!$r_flag) {
	print("Last changes:\n");
	my $n = 1;
	foreach my $tx (@undo_txs) {
		if ($tx->{action} =~ /(upgraded|downgraded)/) {
			format UPGRFORMAT =
 @||  @<<  @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  @<<<<<<<<<<< -> @<<<<<<<<<<<<<
$n, $tx->{action}, $tx->{pkg_name}, $tx->{oldver}, $tx->{newver}
.
			$~ = "UPGRFORMAT";
		} else {
			format INSTFORMAT =
 @||  @<<  @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$n, $tx->{action}, $tx->{pkg_name}
.
			$~ = "INSTFORMAT";
		}
		write();
		$n++;
	}

	print("Select transactions to undo (e.g. '1 2 3', '1-3')\n");
	print("> ");
	my @sel = split(' ', <STDIN>);

	foreach my $i (@sel) {
		if ($i =~ /[0-9]-[0-9]/) {
			my ($start, $end) = $i =~ /([0-9])-([0-9])/;
			push(@sel, ($start..$end));
		}
	}

	@sel = sort grep(!/[0-9]-[0-9]/, @sel);

	my @sel_undo;

	foreach my $i (@sel) {
		push(@sel_undo, $undo_txs[$i-1]);
	}

	@undo_txs = @sel_undo;
}
