#!perl -w
# $Id: makedist.pl,v 1.3 2004/07/21 21:35:30 szabgab Exp $

# Compile everything (including things in the eg directory) and
# generate the Win32::GuiTest distribution.

use strict;

use FindBin qw($Bin);
sub sys {
  my $s = shift;
  `echo --- $s --- >>makedist.log`;
  system("$s >>makedist.log 2>&1")==0 or die "Cannot '$s'\n";
}

unlink("makedist.log");
sys("perl makefile.pl");
sys("perl make_eg.pl");
sys("nmake");

open(MAN, "<manifest");
my @manifest = <MAN>;
close(MAN);

$ENV{PERL5LIB}="$Bin/blib/lib;$Bin/blib/arch";
while (@manifest) {
  sys("perl -wc $_") if /\.(p[l|m]|t)$/i;
}
sys("nmake test");
sys("makepod GuiTest");
sys("copy guitest.txt README");
sys("copy guitest.html README.html");
#sys("call makepod lib\win32\guitest\cpl");
#sys("call makepod lib\win32\guitest\which");
unlink("Win32-GuiTest.tar.gz");
sys("tar cvf Win32-GuiTest.tar blib");
sys("gzip --best Win32-GuiTest.tar");
sys("nmake ppd");

local($^I, @ARGV) = ('.bak', 'Win32-GuiTest.ppd');
while (<>) {
    s|<CODEBASE HREF=""\s*/>|<CODEBASE HREF="Win32-GuiTest.tar.gz"/>|;
    print;
    close ARGV if eof;
}

sys("nmake zipdist");
sys("notepad makedist.log");

