=pod
 - This script has been written by Jarek Jurasz jurasz@imb.uni-karlsruhe.de
=cut
use Win32::GuiTest qw(GetCursorPos);

while (1)
{
  ($x, $y) = GetCursorPos();
  print "\rx:$x  y:$y   ";
  sleep 1;
}

