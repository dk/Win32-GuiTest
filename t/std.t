#!perl -w
BEGIN { $| = 1; }

use strict;
use Test::More qw(no_plan);

use Win32::GuiTest qw/
    GetDesktopWindow
    IsWindow
    /;

# Standard Check
ok(IsWindow(GetDesktopWindow()));
