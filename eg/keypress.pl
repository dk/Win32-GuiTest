# $Id: keypress.pl,v 1.1 2004/03/16 01:37:20 ctrondlp Exp $
#
# This example shows an easy way to check for certain keystrokes.
# The IsKeyPressed function takes a string with the name of the key.
# This names are the same ones as for SendKeys. 
use Win32::GuiTest qw/SendKeys IsKeyPressed/;

# Wait until user presses several
# specified keys
@keys = qw/ESC F5 F11 F12 A B 8 DOWN/;

for (@keys) {
  until (IsKeyPressed($_)) {
    print "Please press $_...\n";
    SendKeys "{PAUSE 200}";
  }
}


