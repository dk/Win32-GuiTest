#!/usr/bin/perl
# $Id: notepad_text.pl,v 1.2 2004/03/21 08:05:06 ctrondlp Exp $
#

use Win32::GuiTest qw(FindWindowLike);

# If you have a notepad window open this prints the contents.
my @windows = FindWindowLike(0, "", "Notepad");
die "More than one notepad open" 
    unless scalar @windows == 1;
$notepad = $windows[0];
my @edits = FindWindowLike($notepad, "", "Edit");
die "More than one edit inside notepad" .  (scalar @edits) 
    unless scalar @edits == 1;
print "----------------------------------------------------------\n";
print WMGetText($edits[0]);
print "----------------------------------------------------------\n";


