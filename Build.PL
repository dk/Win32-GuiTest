use strict;
use warnings;
use Module::Build;

# $Id: Build.PL,v 1.3 2005/02/08 19:02:43 ctrondlp Exp $

# preliminary version, not working yet.

my $builder = Module::Build->new(
	module_name         => 'Win32::GuiTest',
	license             => 'perl',
	dist_author         => 'Dennis K. Paulsen <ctrondlp@cpan.org>, Ernesto Guisado <erngui@acm.org>',
	dist_version_from   => 'guitest.pm',
	dynamic_config      => 1,
#	dist_abstract       => '', # should be fetched from the dist_version_from
#	create_makefile_pl  => 'traditional',
#	create_readme       => 1,
#	script_files        => ['eg/spy.pl'],
	xs_files            => { 'guitest.xs' => 'guitest.cpp' },
#	requires            => {
#		'Test::More'                => 0.47,
#	},
);

$builder->create_build_script();

__END__
# as taken from Makefile.PL :

my @make = (
    'OBJECT'    => 'GuiTest$(OBJ_EXT) DibSect$(OBJ_EXT)'  ,
    'TYPEMAPS'  => ['perlobject.map' ],
#    'XSOPT' => '-c++'
#    'CCFLAGS' => '-MD -DWIN32 -Z7 -DDEBUG -D_DEBUG',
#    'OPTIMIZE' => '-Od'
);

# from Win32::Pipe
sub MY::xs_c {
    '
.xs.cpp:
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(XSUBPP) $(XSPROTOARG) $(XSUBPPARGS) $*.xs >xstmp.c && $(MV) xstmp.c $*.cpp
';
}



