#!perl -w
use strict;

# Based on the spy--.pl within the distribution
# Written by Gabor Szabo <gabor@pti.co.il>

# $Id: spy.pl,v 1.2 2004/07/15 19:38:02 szabgab Exp $


use Win32::GuiTest qw(:ALL);
my %seen;
my $desktop = GetDesktopWindow();
my $root = 0;

my $format = "%-10s %-10s, '%-25s', %-10s, Rect:%-3s,%-3s,%-3s,%-3s   '%s'\n";
printf $format,
		"Depth",
		"WindowID",
		"ClassName",
		"ParentID",
		"WindowRect","","","",
		"WindowText";


parse_tree(0);



sub GetImmediateChildWindows {
	my $WinID = shift;
	grep {GetParent($_) eq $WinID} GetChildWindows $WinID;
}

sub parse_tree {
	my $w = shift;
	if ($seen{$w}++) {
		print "loop $w\n";
		return;
	}

	prt($w);
	#foreach my $child (GetChildWindows($w)) {
	#	parse_tree($child);
	#}
	foreach my $child (GetImmediateChildWindows($w)) {
		print "------------------\n" if $w == 0;
		parse_tree($child);
	}
}

# GetChildDepth is broken so here is another version, this might work better.
 
# returns the real distance between two windows
# returns 0 if the same windows were provides
# returns -1 if one of the values is not a valid window
# returns -2 if the given "ancestor" is not really an ancestor of the given "descendant"
sub MyGetChildDepth {
	my ($ancestor, $descendant) = @_;
	return -1 if $ancestor and (not IsWindow($ancestor) or not IsWindow($descendant));
	return 0 if $ancestor == $descendant;
	my $depth = 0;
	while ($descendant = GetParent($descendant)) {
		$depth++;
		last if $ancestor == $descendant;
	}
	return $depth + 1 if $ancestor == 0;
}


sub prt {
	my $w = shift;
	my $depth = MyGetChildDepth($root, $w);
	printf $format,
		(0 <= $depth ? "+" x $depth : $depth),
		$w, 
		($w ? GetClassName($w) : ""),
		($w ? GetParent($w) : "n/a"),
		($w ? GetWindowRect($w) : ("n/a", "", "", "")),
		($w ? GetWindowText($w) : ""); 
}

