BEGIN { $| = 1; }

use strict;

use Win32::GuiTest qw/
    GetDesktopWindow
    IsWindow
    /;

my $testnum = 1;
sub test {
    print "not " unless shift;
    print "ok $testnum\n";
    $testnum++;
}

open( ME, $0 ) || die $!;
my $bugs = grep( /^test\(/, <ME> );
close( ME );

print "1..$bugs\n";

# Standard Check
test(IsWindow(GetDesktopWindow()));
