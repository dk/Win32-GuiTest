#!/usr/bin/perl
#
# $Id: makefile.pl,v 1.2 2004/03/21 07:59:44 ctrondlp Exp $
#

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my @make = (
    'NAME'	=> 'Win32::GuiTest',
    'VERSION_FROM' => 'GuiTest.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    'OBJECT'    => 'GuiTest$(OBJ_EXT) DibSect$(OBJ_EXT)'  ,
    'XS'	=> { 'GuiTest.xs' => 'GuiTest.cpp' },
    'TYPEMAPS'  => ['perlobject.map' ],
#    'XSOPT' => '-c++'
#    'CCFLAGS' => '-MD -DWIN32 -Z7 -DDEBUG -D_DEBUG',
#    'OPTIMIZE' => '-Od'
);


# Add additional settings for the creation of PPD files
if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    push @make, 'ABSTRACT_FROM' => 'GuiTest.pm';
    push @make, 'AUTHOR' => 'Ernesto Guisado (erngui@acm.org)';
}

WriteMakefile(@make);

# from Win32::Pipe
sub MY::xs_c {
    '
.xs.cpp:
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(XSUBPP) $(XSPROTOARG) $(XSUBPPARGS) $*.xs >xstmp.c && $(MV) xstmp.c $*.cpp
';
}
