#!perl -w
# $Id: menuselect.pl,v 1.4 2004/07/19 20:20:58 szabgab Exp $

use strict;

use Win32::GuiTest qw(:ALL);

system "start notepad";
sleep 1;

my $menu = GetMenu(GetForegroundWindow());
print "$menu\n";
print GetSubMenu($menu, 0),"\n";
print "Count:", GetMenuItemCount($menu), "\n";
exit;


#MenuSelect("&Archivo|&Salir");

# Close the menu and notepad
SendKeys("{ESC}%{F4}");
