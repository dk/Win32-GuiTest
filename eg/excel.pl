#!/usr/bin/perl
# $Id: excel.pl,v 1.2 2004/03/21 08:05:06 ctrondlp Exp $
#

use Win32::GuiTest qw(FindWindowLike GetWindowText SetForegroundWindow);

$Win32::GuiTest::debug = 0;

my @windows = FindWindowLike(0, "Excel", "", 0, 1);

for (@windows) {
    print "$_>\t'", GetWindowText($_), "'\n";
}

print "------------\n";

@windows = FindWindowLike(0, "^Microsoft Excel", "^XLMAIN\$");
for (@windows) {
    print "$_>\t'", GetWindowText($_), "'\n";
    SetForegroundWindow($_);
}

print "------------\n";

die "You should start Excel before running this example.\n"
    unless @windows;

my @children = FindWindowLike($windows[0]);
for (@children) {
    print "$_>\t'", GetWindowText($_), "'\n";
}

