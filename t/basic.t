BEGIN { $| = 1; }

use strict;

use Win32::GuiTest qw/
    FindWindowLike
    GetChildDepth
    GetChildWindows
    GetClassName
    GetDesktopWindow
    GetScreenRes
    GetWindowRect
    GetWindowText
    IsCheckedButton
    IsWindow
    SendKeys
    SetForegroundWindow
    WMGetText
    MouseMoveAbsPix
    SendLButtonDown
    SendLButtonUp
    GetCursorPos
    PushButton
    WaitWindowLike
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

# Check that there are no duplicate windows in the list
my @wins = FindWindowLike();
my %found;
my $dup;
for (@wins) {
    $dup = 1 if $found{$_};
    $found{$_} = 1;
}
#print "not " unless scalar @wins && !$dup;
#print "ok 2\n";
test(scalar @wins && !$dup);

# Just use SenKeys as pause
SendKeys("{PAUSE 1000}");
test(1);

# The desktop should never be on the window list
my $root = GetDesktopWindow();
my @desks = grep { $_ == $root } @wins;
test(!scalar @desks);

# Create a notepad window and check we can find it
system("start notepad.exe guitest.pm");
my @waitwin = WaitWindowLike(0, "[gG]ui[tT]est", "Notepad");
test(scalar @waitwin == 1);
my @windows = FindWindowLike(0, "[gG]ui[tT]est", "Notepad");
test(scalar @windows == 1);
test(@waitwin == @windows);

# Find the edit window inside notepad
my $notepad = $windows[0];
my @edits = FindWindowLike($notepad, "", "Edit");
test(scalar @edits == 1);

# Get the contents (should be the GuiTest.pm file)
my $content = WMGetText($edits[0]);
SendKeys("%{F4}");
open(GUI_FILE, "<guitest.pm");
my @lines = <GUI_FILE>;
close GUI_FILE;
my $file_content = join('', @lines);
test($content =~ /Win32::GuiTest/);
test($file_content =~ /Win32::GuiTest/);

# Open a notepad and type some text into it
system("start notepad.exe");
@waitwin = WaitWindowLike(0, "", "Notepad");
test(scalar @waitwin == 1);
@windows = FindWindowLike(0, "", "Notepad");
test(scalar @windows == 1);
test(@waitwin == @windows);

SendKeys(<<EOM, 10);
    This is a test message,
    but also a little demo for the
    SendKeys function.
    3, 2, 1, 0...
    Closing Notepad...
EOM
    
SendKeys("{PAU 1000}%{F4}{TAB}{ENTER}");

# We closed it so there should be no notepad open
@windows = FindWindowLike(0, "", "Notepad");
test(scalar @windows == 0);

# Since we are looking for child windows, all of them should have
# depth of 1 or more
my $desk = GetDesktopWindow();
my @childs =  GetChildWindows($desk);
my @badchilds = grep {  GetChildDepth($desk, $_) < 1  } @childs;
test(scalar @badchilds == 0);

# If you don't specify patterns, etc, FindWindowLike is equivalent to
# GetChildWindows (meaning all the windows)
my @all = GetChildWindows($desk);
my @some = FindWindowLike($desk);
test(@all == @some);

# Look for any MFC windows and do sanity check
my @mfc = FindWindowLike($desk, "", "^[Aa]fx");
test((grep { GetClassName($_) =~ /^[aA]fx/  } @mfc) == @mfc);

# Look for any sys windows and do sanity check
my @sys = FindWindowLike($desk, "", "^Sys");
test((grep { GetClassName($_) =~ /^Sys/  } @sys) == @sys);

# Loop increasing window search depth until increasing the depth returns
# no more windows
my $depth = 1;
@wins = FindWindowLike($desk, "", "", undef, $depth);
my @next = FindWindowLike($desk, "", "", undef, $depth+1);
while (scalar(@next) > scalar(@wins)) {
    $depth++;
    @wins = @next;
    @next = FindWindowLike($desk, "", "", undef, $depth+1);
}

# The maximum reached depth should contain all the windows
test(FindWindowLike($desk, "", "", undef, $depth) == @all);

# The maximum reached depth should contain all the windows
my ($x, $y) = GetScreenRes();
test($x > 0 and $y > 0);

# Window size of the desktop should be bigger or the same as the screen resolution
# Always???
my ($left, $top, $right, $bottom) = GetWindowRect($desk);
test(($right-$left) >= $x and ($bottom-$top) >= $y);

# Do some tricks with the calculator
system("start calc");
my ($calc) = WaitWindowLike($desk, undef, "^SciCalc\$");
test(IsWindow($calc));
SetForegroundWindow($calc);
SendKeys("1969");
my ($result) = FindWindowLike($calc, "1969");
test(IsWindow($result));

#Find the Hex radio button
my ($hex) = WaitWindowLike($calc, "Hex");
test(IsWindow($hex));

#Find the Bin, Oct and Dec radio buttons
my ($bin) = FindWindowLike($calc, "Bin");
my ($oct) = FindWindowLike($calc, "Oct");
my ($dec) = FindWindowLike($calc, "Dec");

test(IsWindow($bin));
test(IsWindow($oct));
test(IsWindow($dec));
test(!IsCheckedButton($bin));
test(!IsCheckedButton($oct));
test(!IsCheckedButton($hex));
test(IsCheckedButton($dec));

# Click on the Hex radio button
my ($wx, $wy) = GetWindowRect($hex);
my ($cx, $cy) = GetCursorPos();
MouseMoveAbsPix($wx+1,$wy+1);
sleep 1;
SendLButtonDown();
SendLButtonUp();
sleep 1;
MouseMoveAbsPix($cx,$cy);

# try out pushing on window by caption
PushButton("Bin"); sleep 1;
PushButton("Oct"); sleep 1;
PushButton("Dec"); sleep 1;
PushButton("Hex"); sleep 1;

test(!IsCheckedButton($dec));
test(IsCheckedButton($hex));

# The result window contain "1969" in hex
$result = WaitWindowLike($calc, "7B1");
test(IsWindow($result));

# Close calc
SendKeys("%{F4}");

test(1); 

