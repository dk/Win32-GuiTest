#!/usr/bin/perl
# $Id: fonts.pl,v 1.2 2004/03/21 08:05:06 ctrondlp Exp $
# Use Win32::GuiTest to get a list of supported fonts from a
# dialog box.
# By Ernesto Guisado (erngui@acm.org).

use Win32::GuiTest qw/SendKeys FindWindowLike GetComboContents/;

sub FontTxt { "Fuente"; } # i18n
sub OpenFont { "%ef"; }   # i18n

# Let's see notepad
system("start notepad.exe");
sleep 1;

# Open the Font dialog
SendKeys(OpenFont);

# Find the Font dialog using the title and window class
# The Font dialog isn't a child of the notepad window
my ($fontdlg) = FindWindowLike(0, FontTxt, "#32770");
die "Where is the Font dialog?\n" unless $fontdlg;

# Find the right combo using it's control id
my ($combo) = FindWindowLike($fontdlg, "", "ComboBox", 0x470);
die "Where is the combo with the font names?" unless $combo;

# Print all the font names
for (GetComboContents($combo)) {
    print "'$_'" . "\n";
}

# Close the dialog and notepad
SendKeys("{ESC}%{F4}");
