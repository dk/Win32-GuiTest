#!/usr/bin/perl
# $Id: tab.pl,v 1.2 2004/03/21 08:05:06 ctrondlp Exp $
#

use Win32::GuiTest qw/:FUNC :VK/;

SendRawKey(VK_MENU, 0);
SendKeys("{TAB}{PAU 1000}{TAB}{PAU 1000}{TAB}");
SendRawKey(VK_MENU, KEYEVENTF_KEYUP);

