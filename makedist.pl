# $Id: makedist.pl,v 1.1 2004/03/16 01:37:20 ctrondlp Exp $
# Compile everything (including things in the eg directory) and
# generate the Win32::GuiTest distribution.
#
sub sys {
  my $s = shift;
  `echo --- $s --- >>makedist.log`;
  system("$s >>makedist.log 2>&1")==0 or die "Cannot '$s'\n";
}

unlink("makedist.log");
sys("perl makefile.pl");
sys("nmake");
open(MAN, "<manifest");
while (<MAN>) {
  sys("perl -wc $_") if /\.(p[l|m]|t)$/i;
}
close(MAN);
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

