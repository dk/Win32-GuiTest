#!perl -w
# $Id: makedist.pl,v 1.5 2009/10/19 16:04:15 int32 Exp $

# Compile everything (including things in the eg directory) and
# generate the Win32::GuiTest distribution.

use strict;
use File::Path;
use File::Copy;

use FindBin qw($Bin);
sub sys {
  my $s = shift;
  `echo --- $s --- >>makedist.log`;
  system("$s >>makedist.log 2>&1")==0 or die "Cannot '$s'\n";
}

unlink("makedist.log");
sys("nmake clean") if -e "makefile";
sys("perl eg/make_eg.pl");
sys("perl makefile.pl");
sys("nmake");

open(MAN, "<manifest");
my @manifest = <MAN>;
close(MAN);

$ENV{PERL5LIB}="$Bin/blib/lib;$Bin/blib/arch";
foreach my $file (@manifest) {
  next if $file =~ /Examples.pm/;
}
sys("nmake test");
sys("makepod GuiTest");
sys("makepod Examples");
sys("copy guitest.txt README");
sys("copy guitest.html README.html");

# this will enable ppm to install the HTML files in the regular HTMl tree
mkpath "blib/html/site/lib/Win32/GuiTest";
copy "guitest.html", "blib/html/site/lib/Win32/";
copy "Examples.html", "blib/html/site/lib/Win32/GuiTest";

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

