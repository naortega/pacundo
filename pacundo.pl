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

my $VERSION = "1.0";
my $PROG_NAME = "pacundo";

my $r_flag = 0;
my $dry_run = 0;

sub print_version {
	print("$PROG_NAME v$VERSION\n");
}

sub print_help {
	&print_version();
	print("A time machine to return your ArchLinux machine back to a working state.\n");
	print("\nUSAGE:
	$PROG_NAME [-i|-r] [-d]
	$PROG_NAME -h
	$PROG_NAME -v

OPTIONS:
	-i   Enter interactive mode to select packages to downgrade [default behavior]
	-r   Automatically downgrade all packages from last upgrade
	-d   Dry run, i.e. don't actually do anything
	-h   Show this help information
	-v   Print program version\n");
}

getopts("irdvh", \my %opts);

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
}

$r_flag = 1 if ($opts{'r'});
$dry_run = 1 if ($opts{'d'});
