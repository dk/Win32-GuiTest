use Win32::GuiTest qw/:FUNC :VK/;

while (1) {
    SendRawKey(VK_DOWN, KEYEVENTF_EXTENDEDKEY); 
    SendKeys "{PAUSE 200}";
}
