BEGIN { $| = 1; }

use strict;

use Win32::GuiTest::Cmd ':CPL';
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
    GetForegroundWindow
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

sub waitcome {
    my $me = shift;
    my $max = shift || 100;
    my $count;
    select(undef, undef, undef, 0.10) 
      while GetForegroundWindow() != $me and $count++ < $max;
}

sub waitgo {
    my $me = shift;
    my $max = shift || 100;
    my $count;
    select(undef, undef, undef, 0.10) 
      while GetForegroundWindow() == $me and $count++ < $max;
}

sub closewnd {
    my $me = shift;
    my $key = shift || "{ESC}";
    select(undef, undef, undef, 0.40);
    waitgo($me);
    SendKeys($key);
    waitcome($me);
}


open( ME, $0 ) || die $!;
my $bugs = grep( /^test\(/, <ME> );
close( ME );

print "1..$bugs\n";

my $me = GetForegroundWindow();

Console();
closewnd($me);
test(1);

Accessibility();
closewnd($me);
test(1);

AppWizard();
closewnd($me);
test(1);

DateTime();
closewnd($me);
test(1);

Display();
closewnd($me);
test(1);

Exchange();
closewnd($me);
test(1);

FindFast();
closewnd($me);
test(1);

Internet();
closewnd($me);
test(1);

#Joystick();
#closewnd($me);
#test(1);

Modem(); 
closewnd($me, "%{F4}");
test(1);

Mouse();
closewnd($me);
test(1);

Multimedia();
closewnd($me);
test(1);

Network();
closewnd($me, "%{F4}");
test(1);

Odbc(); 
closewnd($me);
test(1);

Pcmcia(); 
closewnd($me);
test(1);

Ports(); 
closewnd($me);
test(1);

Ras();
closewnd($me);
test(1);

Regional();
closewnd($me);
test(1);

Server();
closewnd($me);
test(1);

System();
closewnd($me);
test(1);

Telephony();
closewnd($me);
test(1);

Ups();
closewnd($me);
test(1);

Users();
closewnd($me, "%{F4}");
test(1);

