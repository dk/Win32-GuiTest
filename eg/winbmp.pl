=pod
 - This script has been written by Jarek Jurasz jurasz@imb.uni-karlsruhe.de
 - Save a given window as BMP file
 - Copy the contents to the clipboard
=cut


use Win32::GuiTest qw(:ALL);

($w) = FindWindowLike(0, "^Calc");
$w = GetDesktopWindow unless $w;

$ds = new Win32::GuiTest::DibSect;
$ds->CopyWindow($w);
#$ds->CopyClient(GetDesktopWindow(), \@{[GetWindowRect($w)]});
# $ds->Invert();
#$ds->CopyClient(GetDesktopWindow(), \@{[GetWindowRect($w)]});
# $ds->Invert();
#$ds->ToGrayScale();
$ds->SaveAs("bla.bmp");
$ds->ToClipboard();
