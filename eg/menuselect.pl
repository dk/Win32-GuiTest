use Win32::GuiTest qw/MenuSelect/;

system "start notepad";
sleep 2;
MenuSelect("&Archivo|&Salir");
