#!perl -w
use strict;

# Based on the spy--.pl within the distribution
# Written by Gabor Szabo <gabor@pti.co.il>

# $Id: spy.pl,v 1.1 2004/07/14 19:40:56 szabgab Exp $


use Win32::GuiTest qw(:ALL);
my %seen;
my $desktop = GetDesktopWindow();
my $root = 0;

parse_tree(0);


sub parse_tree {
	my $w = shift;
	if ($seen{$w}++) {
		print "loop $w\n";
		return;
	}

	prt($w);
	foreach my $child (GetChildWindows($w)) {
		parse_tree($child);
	}
}



sub prt {
	my $w = shift;
	printf "%-8s %-10s, '%-25s', Rect:%-3s,%-3s,%-3s,%-3s   '%s'\n", 
		"+" x GetChildDepth($root, $w),
		$w, 
		GetClassName($w),
		GetWindowRect($w),
		GetWindowText($w); 
}


