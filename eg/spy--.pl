#!/usr/bin/perl
# $Id: spy--.pl,v 1.2 2004/03/21 08:05:06 ctrondlp Exp $
# MS has a very nice tool (Spy++).
# This is Spy--
#

use Win32::GuiTest qw/FindWindowLike GetWindowText GetClassName
    GetChildDepth GetDesktopWindow/;

for (FindWindowLike()) {
    $s = sprintf("0x%08X", $_ );
    $s .= ", '" .  GetWindowText($_) . "', " . GetClassName($_);
    print "+" x GetChildDepth(GetDesktopWindow(), $_), $s, "\n";
}
