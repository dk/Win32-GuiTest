use Win32::GuiTest qw(FindWindowLike SetForegroundWindow 
    SendMouse);

# Draw a triangle in MS Paint.
system("start /max mspaint");
sleep 2;
@windows = FindWindowLike(0, "Paint", "");
if ( $windows[0] != 0 ) {
    SetForegroundWindow($windows[0]);
    sleep 2;

    #Using high-level functions
    Win32::GuiTest::SendMouse ( "{LEFTDOWN}" );
    for ( $i = 0; $i < 100; $i++ )
    { SendMouse ( "{REL1,1}" );  }
    for ( $i = 0; $i < 100; $i++ )
	{ SendMouse ( "{REL1,-1}" ); }
    for ( $i = 0; $i < 200; $i++ )
	{ SendMouse ( "{REL-1,0}" ); }
    SendMouse ( "{LEFTUP}" );
    
    #Using low level functions
    Win32::GuiTest::SendMouseMoveRel(5,20);

    Win32::GuiTest::SendLButtonDown();
    for ( $i = 0; $i < 100; $i++ )
    { Win32::GuiTest::SendMouseMoveRel(1,1);  }
    for ( $i = 0; $i < 100; $i++ )
	{ Win32::GuiTest::SendMouseMoveRel(1,-1); }
    for ( $i = 0; $i < 200; $i++ )
	{ Win32::GuiTest::SendMouseMoveRel(-1,0); }
    Win32::GuiTest::SendLButtonUp();

 }
