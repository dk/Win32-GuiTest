#!perl -w
# $Id: menuselect.pl,v 1.5 2004/07/21 17:47:31 szabgab Exp $

# Example how to get the names of the menues
# Dows not work yet as the backend is not there yet !

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
