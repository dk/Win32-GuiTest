#!perl -w
BEGIN { $| = 1; }

# $Id: std.t,v 1.3 2004/07/19 20:17:58 szabgab Exp $

use strict;
use Test::More qw(no_plan);

use Win32::GuiTest qw/
    GetDesktopWindow
    IsWindow
    /;

# Standard Check
ok(IsWindow(GetDesktopWindow()));
