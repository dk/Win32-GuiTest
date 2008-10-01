#!perl -w
BEGIN {
	print "1..0 # Skip win32 required\n" and exit unless $^O =~ /win32|cygwin/i;
	$| = 1;
}

# Do some tricks with the calculator
# $Id: 02_calc.t,v 1.2 2008/10/01 11:10:12 int32 Exp $

use strict;
use Test::More qw(no_plan);

use Win32::GuiTest qw(:ALL);

my $desk = GetDesktopWindow();

# It seems that if the calculator opens as Standard then even if we 
# select Scientific mode we cannot find the Hex button.
# If the calculater already opens as Scientific then things work OK.
# Moreover (at least on XP) the calculator always opens in the same mode
# as it was when you closed it so first we open the calculator, make sure
# to select Scientific mode, close it and then open it again hoping that
# it is now really in scientific mode.
{
	system("cmd /c start calc");
	my ($calc) = WaitWindowLike($desk, undef, "^SciCalc\$"); 
	# hmm, It seems the SciCalc is the name of the class for both the Standard and the 
	# Scientific version of the calculator

	ok(IsWindow($calc));
	SetForegroundWindow($calc);

	MenuSelect("&View|&Scientific");
	SendKeys("%{F4}");
}

system("cmd /c start calc");
my ($calc) = WaitWindowLike($desk, undef, "^SciCalc\$"); 

SendKeys("1969");
my $edit;
SKIP: {
	($edit) = FindWindowLike($calc, undef, "Edit|Static");
	ok(defined $edit, "found editor") or skip "could not find Edit window", 1;
	ok(IsWindow($edit), "Editor is a window");
	is(WMGetText($edit), "1969. ", "1969 found");
}

#Find the Hex radio button
my $hex;
SKIP: {
	($hex) = FindWindowLike($calc, "Hex");
	ok(defined $hex, "hex found") or skip "could not find Hex", 2;
	ok(IsWindow($hex), "Hex is a window");
	ok(!IsCheckedButton($hex), "Hex is not checked");
}

#Find the Bin, Oct and Dec radio buttons
my $bin;
SKIP: {
	($bin) = FindWindowLike($calc, "Bin");
	ok(IsWindow($bin)) or skip "could not find Bin", 1;
	ok(!IsCheckedButton($bin), "Bin is not checked");
}

my $oct;
SKIP: {
	($oct) = FindWindowLike($calc, "Oct");
	ok(IsWindow($oct), "Oct window found") or skip "could not find Oct", 1;
	ok(!IsCheckedButton($oct), "Oct is not checked");
}
my $dec;
SKIP: {
	($dec) = FindWindowLike($calc, "Dec");
	ok(IsWindow($dec)) or skip "could not find Dec", 1;
	ok(IsCheckedButton($dec), "Dec is checked");
}

# Click on the Hex radio button
SKIP: {
	skip "No Hex button, no tests", 1 if not defined $hex;

	my ($wx, $wy) = GetWindowRect($hex);
	my ($cx, $cy) = GetCursorPos();
	MouseMoveAbsPix($wx+1,$wy+1);
	sleep 1;
	SendLButtonDown();
	SendLButtonUp();
	sleep 1;
	MouseMoveAbsPix($cx,$cy);
	is(WMGetText($edit), "7B1 ", "1969 in hex found");
}

# try out pushing on window by caption
SKIP: {
	skip "No Dec/bin/Oct/Hex button(s)", 9 if not ($dec and $bin and $oct and $hex);
	PushButton("Dec"); sleep 1;
	is(WMGetText($edit), "1969. ", "1969 in dec found");
	ok(IsCheckedButton($dec));

	PushButton("Hex"); sleep 1;
	is(WMGetText($edit), "7B1 ", "1969 in hex found");
	ok(IsCheckedButton($hex));

	PushButton("Oct"); sleep 1;
	is(WMGetText($edit), "3661 ", "1969 in oct found");
	ok(IsCheckedButton($oct));

	PushButton("Bin"); sleep 1;
	is(WMGetText($edit), "11110110001 ", "1969 in bin found");
	ok(IsCheckedButton($bin));
	ok(!IsCheckedButton($dec));
}

# Close calc
SendKeys("%{F4}");

ok(1, "Is window closed ?"); 

