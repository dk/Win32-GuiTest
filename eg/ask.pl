#!/usr/bin/perl
# $Id: ask.pl,v 1.2 2004/03/21 08:05:06 ctrondlp Exp $
#

use Win32::GuiTest::Cmd ':ALL';

Pause("Press ENTER to start the setup...");

print "GO!\n" if YesOrNo("Setup networking component?");

my $address = AskForIt("What's your new ip address?", 
    "122.122.122.122");

my $dir = AskForDir("Where should I put the new files?", 
    "c:\\temp");

my $exe = AskForExe("Where is your net setup program?", 
    "/foo/bar.exe");

print "\nAddress '$address'\n";
print "Dir     '$dir'\n";
print "Exe     '$exe'\n";

