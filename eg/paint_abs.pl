#!/usr/bin/perl
# $Id: paint_abs.pl,v 1.2 2004/03/21 08:05:06 ctrondlp Exp $
#

use Win32::GuiTest qw(FindWindowLike SetForegroundWindow 
    SendMouse);

system("start /max mspaint");
sleep 2;
@windows = FindWindowLike(0, "Paint", "");
if ( $windows[0] != 0 ) {
    SetForegroundWindow($windows[0]);
    sleep 2;

    #Using low level functions
    Win32::GuiTest::MouseMoveAbsPix(100,100);
    Win32::GuiTest::SendLButtonDown();
    Win32::GuiTest::MouseMoveAbsPix(500,500);
    Win32::GuiTest::SendLButtonUp();

    sleep 1;

    Win32::GuiTest::MouseMoveAbsPix(100,500);
    Win32::GuiTest::SendLButtonDown();
    Win32::GuiTest::MouseMoveAbsPix(500,100);
    Win32::GuiTest::SendLButtonUp();
    
    sleep 1;
    
    Win32::GuiTest::MouseMoveAbsPix(100,100);
    Win32::GuiTest::SendLButtonDown();
    Win32::GuiTest::MouseMoveAbsPix(500,100);
    Win32::GuiTest::MouseMoveAbsPix(500,500);
    Win32::GuiTest::MouseMoveAbsPix(100,500);
    Win32::GuiTest::MouseMoveAbsPix(100,100);
    Win32::GuiTest::SendLButtonUp();


 }
