#!/usr/bin/perl
# $Id: menuselect.pl,v 1.3 2004/03/21 08:21:28 ctrondlp Exp $
#

use Win32::GuiTest qw(MenuSelect);

system "start notepad";
sleep 2;
MenuSelect("&Archivo|&Salir");
