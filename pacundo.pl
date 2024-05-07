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
use feature qw(signatures);

use Getopt::Std;
use File::ReadBackwards;

my $VERSION   = '1.0';
my $PROG_NAME = 'pacundo';

sub print_version() {
	print("$PROG_NAME v$VERSION\n");
	return;
}

sub print_help() {
	&print_version();
	print("A time machine to return your ArchLinux machine back to a working state.

USAGE:
	$PROG_NAME [-i|-r] [-t <num>] [-d]
	$PROG_NAME -h
	$PROG_NAME -v

OPTIONS:
	-i         Enter interactive mode to select package operations to undo (default behavior)
	-r         Non-interactively undo entire transactions
	-t <num>   Specify the number of transactions to include (default: 1)
	-d         Dry run, i.e. don't actually do anything
	-h         Show this help information
	-v         Print program version\n");
	return;
}

sub read_txs($num_txs = 1) {
	my $found_txs = 0;
	my $in_tx = 0;
	my @undo_txs;
	my $pacman_log = File::ReadBackwards->new('/var/log/pacman.log') or
		die("Failed to load pacman log file.\n$!\n");

	while ($found_txs < $num_txs && defined(my $line = $pacman_log->readline)) {
		unless ($in_tx) {
			# Remeber that we're reading this in reverse order
			if ($line =~ /\[ALPM\] transaction completed/) {
				$in_tx = 1;
			}
		} elsif ($line =~ /\[ALPM\] transaction started/) {
			$found_txs++;
			$in_tx = 0;
		} elsif ($line =~ /\[ALPM\] (upgraded|downgraded)/) {
			my ($action, $pkg_name, $oldver, $newver) =
				$line =~ /\[ALPM\] (upgraded|downgraded) ([^\s]+) \((.*) -> (.*)\)/;
			push(@undo_txs,
				{
					action   => $action,
					pkg_name => $pkg_name,
					oldver   => $oldver,
					newver   => $newver,
				}
			);
		} elsif ($line =~ /\[ALPM\] (installed|removed)/) {
			my ($action, $pkg_name) = $line =~ /\[ALPM\] (installed|removed) ([^\s]+)/;
			push(@undo_txs,
				{
					action   => $action,
					pkg_name => $pkg_name,
				}
			);
		}
	}

	return @undo_txs;
}

sub select_txs(@undo_txs) {
	print("Last changes:\n");

	my $n = 1;

	foreach my $tx (@undo_txs) {
		format UPGRFORMAT =
 @||  @<<  @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  @<<<<<<<<<<< -> @<<<<<<<<<<<<<
$n, $tx->{action}, $tx->{pkg_name}, $tx->{oldver}, $tx->{newver}
.
		format INSTFORMAT =
 @||  @<<  @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$n, $tx->{action}, $tx->{pkg_name}
.

		local $~ = ($tx->{action} =~ /(upgraded|downgraded)/) ? "UPGRFORMAT" : "INSTFORMAT";
		write();

		$n++;
	}

	print("Select transactions to undo (e.g. '1 2 3', '1-3')\n> ");

	my @sel = split(' ', <STDIN>);

	foreach my $i (grep({/^[0-9]+-[0-9]+$/} @sel)) {
		my ($start, $end) = $i =~ /^([0-9]+)-([0-9]+)$/;
		die("Invalid range: $start-$end\n") if ($start >= $end);
		push(@sel, ($start..$end));
	}

	@sel = sort grep({!/[0-9]+-[0-9]+/} @sel);

	my @sel_undo;
	push(@sel_undo, $undo_txs[$_-1]) foreach (@sel);

	return @sel_undo;
}

# NOTE: Currently this subroutine only works for pacman and yay. You'll have to
# add options for additional AUR helpers.
sub get_pkgmgr() {
	my $mgr = '';
	my $mgr_bin;
	my @supported_mgrs = (
		'yay',
		'pacman',
	);
	my $sudo = '';
	my $user = $ENV{LOGNAME} || $ENV{USER};

	foreach my $i (@supported_mgrs) {
		$mgr_bin = `which $i 2>&1`;
		if ($? == 0) {
			$mgr = $i;
			last;
		}
	}

	if ($mgr eq '') {
		print(STDERR "Failed to find pacman executable. Are you using an ArchLinux system?\n");
		exit 1;
	}
	chomp($mgr_bin);

	if ($mgr eq 'pacman' && $user ne 'root') {
		$sudo = 'sudo';
	}

	my %pkgmgr = (
		name           => $mgr,
		bin            => $mgr_bin,
		search         => "$mgr_bin -Ss",
		install_remote => "$sudo $mgr_bin -S",
		install_local  => "$sudo $mgr_bin -U",
		remove         => "$sudo $mgr_bin -R",
	);

	return \%pkgmgr;
}

sub find_local_pkg($pkgmgr, $pkg_name, $pkg_ver='') {
	my $pkg_file = '';
	my $aur_dir = "$ENV{'XDG_CACHE_HOME'}/yay/$pkg_name";

	if ($pkgmgr->{name} eq 'yay' && -d $aur_dir) {
		if ($pkg_ver ne '') {
			$pkg_file = `ls $aur_dir/$pkg_name-$pkg_ver-*.pkg.tar.zst | tail -n1`;
		} else {
			$pkg_file = `ls $aur_dir/$pkg_name-*.pkg.tar.zst | tail -n1`;
		}
	} else {
		if ($pkg_ver ne '') {
			$pkg_file = `ls /var/cache/pacman/pkg/$pkg_name-$pkg_ver-*.pkg.tar.zst | tail -n1`;
		} else {
			$pkg_file = `ls /var/cache/pacman/pkg/$pkg_name-*.pkg.tar.zst | tail -n1`;
		}
	}

	chomp($pkg_file);
	return $pkg_file;
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

my $r_flag  = $opts{'r'} // 0;
my $dry_run = $opts{'d'} // 0;
my $num_txs = $opts{'t'} // 1;

my $pkgmgr = &get_pkgmgr();
my @undo_txs = &read_txs($num_txs);

# Interactive mode
@undo_txs = &select_txs(@undo_txs) unless ($r_flag);

my $remove_pkgs = "";          # executed via -R
my $remote_install_pkgs = "";  # executed via -S
my $local_install_pkgs = "";   # executed via -U

foreach my $tx (@undo_txs) {
	if ($tx->{action} eq 'installed') {
		$remove_pkgs .= "$tx->{pkg_name} ";
	} elsif ($tx->{action} eq 'removed') {
		my $pkg_file = &find_local_pkg($pkgmgr, $tx->{pkg_name});
		if ($pkg_file eq '') {
			$remote_install_pkgs .= "$tx->{pkg_name} ";
		} else {
			$local_install_pkgs .= "$pkg_file ";
		}
	} else {
		my $pkg_file = &find_local_pkg($pkgmgr, $tx->{pkg_name}, $tx->{oldver});
		if ($pkg_file eq '') {
			$remote_install_pkgs .= "$tx->{pkg_name} ";
		} else {
			$local_install_pkgs .= "$pkg_file ";
		}
	}
}

if ($dry_run) {
	print("$pkgmgr->{remove} $remove_pkgs\n") if ($remove_pkgs ne '');
	print("$pkgmgr->{install_remote} $remote_install_pkgs\n") if ($remote_install_pkgs ne '');
	print("$pkgmgr->{install_local} $local_install_pkgs\n") if ($local_install_pkgs ne '');
} else {
	system("$pkgmgr->{remove} $remove_pkgs") if ($remove_pkgs ne '');
	system("$pkgmgr->{install_remote} $remote_install_pkgs") if ($remote_install_pkgs ne '');
	system("$pkgmgr->{install_local} $local_install_pkgs") if ($local_install_pkgs ne '');
}
