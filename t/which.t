#!perl -w
BEGIN { $| = 1; }

# $Id: which.t,v 1.3 2004/07/19 20:17:58 szabgab Exp $

use strict;
use Test::More qw(no_plan);

use Win32::GuiTest::Cmd qw(WhichExe TempFileName);

# These programs should always be on the path, so we should be 
# able to find them
like(WhichExe("regedit"),  qr/regedit/i,  "regedit");

# SZABGAB: What is this ?
# like(WhichExe("winfile"),  qr/winfile/i,  "winfile");

like(WhichExe("progman"),  qr/progman/i,  "progman");
like(WhichExe("explorer"), qr/explorer/i, "explorer");

# SZABGAB: is this really expected to give back the string ?
# currently it does not.
#like(WhichExe("non-existing-program-name"), qr/non-existing-program-name/i, "non existing");

# See if the temp file thing works
{
	my $n1 = TempFileName();
	ok(!-e $n1, "Tempfile does not exist");
	open(OUT,">$n1");
	close(OUT);
	ok(-e $n1, "Tempfile exist after we create it");

	my $n2 = TempFileName();
	isnt($n1, $n2, "File names are not equal");
	ok(!-e $n2, "Second file does not exist either");
	unlink($n1);
}


