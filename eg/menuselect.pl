#!perl -w
# $Id: menuselect.pl,v 1.6 2004/07/22 20:01:24 szabgab Exp $

# Example how to get the names of the menues
# Dows not work yet as the backend is not there yet !

use strict;

use Win32::GuiTest qw(:ALL);

system "start notepad";
sleep 1;

my $menu = GetMenu(GetForegroundWindow());
print "Menu: $menu\n";
my $submenu = GetSubMenu($menu, 0);
print "Submenu: $submenu\n";
print "Count:", GetMenuItemCount($menu), "\n";

use Data::Dumper;

my %h = GetMenuItemInfo($menu, 1);   # Edit on the main menu
print Dumper \%h;
%h = GetMenuItemInfo($submenu, 1);   # Open in the File menu
print Dumper \%h;
%h = GetMenuItemInfo($submenu, 4);   # Separator in the File menu
print Dumper \%h;



#MenuSelect("&Archivo|&Salir");

# Close the menu and notepad
SendKeys("{ESC}%{F4}");
