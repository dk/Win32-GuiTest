BEGIN { $| = 1; }

use strict;

use Win32::GuiTest::Cmd qw(WhichExe TempFileName);

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

# These programs should always be on the path, so we should be 
# able to find them
test(WhichExe("regedit") =~ /regedit/i);
test(WhichExe("winfile") =~ /winfile/i);
test(WhichExe("progman") =~ /progman/i);
test(WhichExe("explorer") =~ /explorer/i);
test(WhichExe("non-existing-program-name") !~ /non-existing-program-name/i);

# See if the temp file thing works
my $n1 = TempFileName();
test(!-e $n1);
open(OUT,">$n1");
close(OUT);
my $n2 = TempFileName();
test($n1 ne $n2);
test(!-e $n2);
unlink("$n1");


