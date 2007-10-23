#!perl -w
use strict;

# this script was included in the makedist.pl to generate the Examples.pm file
# every time building a new distribtion.
# We should also make sure the file is included in the distribution and
# installed on the target machines.
 
# Written by Gabor Szabo <gabor@pti.co.il>


open my $out, ">lib/Win32/GuiTest/Examples.pm" or die "Cannot open lib/Win32/GuiTest/Examples.pm:$!\n";
print $out <<END;
package Win32::GuiTest::Examples;
1;

=head1 NAME

Win32::GuiTest::Examples - collection of the scripts from eg

=head1 Synopsis

This module was autogenerated from the files in the eg directory of
the distribution. For detailed (cough) documenataion see L<Win32::GuiTest>.
To run the examples either copy-paste them from here or download and unpack
the distribution and take the files from the eg directory.

=head1 Examples

END


open(MAN, "<manifest");
my @manifest = <MAN>;
close(MAN);

foreach my $file (@manifest)  {
	chomp $file;
	next if $file !~ m{eg/.*\.pl};

	print $out "\n=head2 $file\n\n";
	open my $fh, "<", $file;
	my @lines = <$fh>;
	for ( @lines) {
		next if /^#\s*\$Id/;
		print $out "    $_";
	}
}

print $out <<END;



=cut

END

