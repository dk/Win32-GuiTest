#!perl -w
use strict;

# $Id: get_child_depth.pl,v 1.1 2004/07/15 19:37:09 szabgab Exp $

# get any two windowID numbers and let us know what GetChildDepth() returns
# Later we might add this to the test suit.
# Written by Gabor Szabo <gabor@pti.co.il>

use Win32::GuiTest qw(:ALL);
if (@ARGV != 2) {
	die "Usage: $0 AncestorID DescendentID\n";
}


print GetChildDepth(@ARGV), "\n";


