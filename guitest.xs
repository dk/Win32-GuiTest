/* 
 *  $Id: guitest.xs,v 1.3 2004/03/17 02:20:55 ctrondlp Exp $
 *
 *  The SendKeys function is based on the Delphi sourcecode
 *  published by Al Williams <http://www.al-williams.com/awc/> 
 *  in Dr.Dobbs <http://www.ddj.com/ddj/1997/careers1/wil2.htm>
 *	
 *  Copyright (c) 1998-2002 by Ernesto Guisado <erngui@acm.org>
 *
 *  You may distribute under the terms of either the GNU General Public
 *  License or the Artistic License.
 *
 */

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <commctrl.h>
#include "dibsect.h"


#ifdef __cplusplus
//extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
//}
#endif




int cvtkey(
	const char* s,
	int i, 
	int *key,
    int *count, 
	int* len,
    int* letshift,
    int* shift, 
	int* letctrl,
    int* ctrl, 
	int* letalt,
    int* alt, 
	int* shiftlock
	);


#ifndef TRUE
#define TRUE 1
#endif

#ifndef FALSE
#define FALSE 0
#endif


/*  Find the virtual keycode (Windows VK_* constants) given a 
 *  symbolic name.
 *  Returns 0 if not found.
 */
int findvkey(const char* name, int* key) 
{
    /* symbol table record */
    typedef struct tokentable {
        char *token;
        int vkey;
    } tokentable;

    /* global symbol table */
    static tokentable tbl[]  = {
        "BAC", VK_BACK,
        "BS" , VK_BACK,
        "BKS", VK_BACK,
        "BRE", VK_CANCEL,
        "CAP", VK_CAPITAL,
        "DEL", VK_DELETE,
        "DOW", VK_DOWN,
        "END", VK_END,
        "ENT", VK_RETURN,
        "ESC", VK_ESCAPE,
        "HEL", VK_HELP,
        "HOM", VK_HOME,
        "INS", VK_INSERT,
        "LEF", VK_LEFT,
        "NUM", VK_NUMLOCK,
        "PGD", VK_NEXT,
        "PGU", VK_PRIOR,
        "PRT", VK_SNAPSHOT,
        "RIG", VK_RIGHT,
        "SCR", VK_SCROLL,
        "TAB", VK_TAB,
        "UP",  VK_UP,
        "F1",  VK_F1,
        "F2",  VK_F2,
        "F3",  VK_F3,
        "F4",  VK_F4,
        "F5",  VK_F5,
        "F6",  VK_F6,
        "F7",  VK_F7,
        "F8",  VK_F8,
        "F9",  VK_F9,
        "F10",  VK_F10,
        "F11",  VK_F11,
        "F12",  VK_F12,
        "F13",  VK_F13,
        "F14",  VK_F14,
        "F15",  VK_F15,
        "F16",  VK_F16,
        "F17",  VK_F17,
        "F18",  VK_F18,
        "F19",  VK_F19,
        "F20",  VK_F20,
        "F21",  VK_F21,
        "F22",  VK_F22,
        "F23",  VK_F23,
        "F24",  VK_F24,
	"SPC",  VK_SPACE,
	"SPA",  VK_SPACE,
        "LWI",  VK_LWIN,
        "RWI",  VK_RWIN,
        "APP",  VK_APPS,
    };
    int i;
    for (i=0;i<sizeof(tbl)/sizeof(tokentable);i++) {
        if (strcmp(tbl[i].token, name)==0) {
            *key=tbl[i].vkey;
            return 1;
	}
    }
    return 0;
}

/* Get a number from the input string */
int GetNum(
    const char*s ,
    int i,
    int* len
    )
{
    int res;
    int pos = 0;  
    char* tmp = (char*)safemalloc(strlen(s)+1);
    strcpy(tmp, s);
    while (s[i]>='0' && s[i]<='9') {
	tmp[pos++] = s[i++];
	(*len)++;
    }
    tmp[pos] = '\0';
    res = atoi(tmp);
    free(tmp);
    return res;
}



/* Process braced characters */
void procbrace(
	const char* s, 
	int i,
    int *key, 
	int *len,
    int *count, 
	int *letshift,
    int *letctrl,
	int *letalt,
    int *shift,
	int *ctrl,
    int *alt,
	int *shiftlock)
{
    int j,k,m;
	char* tmp = (char*)safemalloc(strlen(s)+1);
    strcpy(tmp, s);

    *count=1;
	/* 3 cases: x, xxx, xxx ## */
	/* if single character case */
	if (s[i+2]=='}' || s[i+2]==' ') {
		if (s[i+2]==' ') {      /* read count if present */
			*count=GetNum(s,i+3,len);
			(*len)++;
		}
		(*len)+=2;
		/* convert quoted key */
		*key= s[i+1];
		/* convert key -- pass -1 to prevent special interp. */
		cvtkey(s,-1,key,count,len,letshift,shift,
			letctrl,ctrl,letalt,alt,shiftlock);
    }
    else {  /* multicharacter sequence */
	
		*letshift=FALSE;
		*letctrl =FALSE;
		*letalt  =FALSE;
		
		/* find next brace or space */
		j=1;
		m = 0;
		while (s[i+j]!=' ' && s[i+j]!='}') {
		  tmp[m++]= s[i+j];
		  j++;
		  (*len)++;
		}
		tmp[m]='\0';
		
		if (s[i+j]==' ') {  /* read count */
		  *count=GetNum(s,i+j+1,len);
		  (*len)++;
		}
		(*len)++;
		
		/*check for special tokens*/
		for (k=0;k<(int)strlen(tmp); k++)
			tmp[k]=toupper(tmp[k]);
		
		/* chop token to 3 characters or less */
		if (strlen(tmp)>3) 
			tmp[3]='\0';

		/* handle pause specially */
		if (strcmp(tmp,"PAU")==0) {
            OutputDebugString("Found PAUSE\n");
OutputDebugString(tmp);
OutputDebugString("\n");
			Sleep(*count);
			*key=0;
			free(tmp);
			return;
		}
		
		/* find entry in table */
		*key=0;
        findvkey(tmp, key);
		/* if key=0 here then something is bad */
	} /* end of token processing */

	free(tmp);
}

/* Wrapper around kebyd_event */
void KeyUp(UINT vk)
{
    BYTE scan = MapVirtualKey(vk, 0);
    keybd_event(vk, scan, KEYEVENTF_KEYUP, 0);
}

void KeyDown(UINT vk)
{
    BYTE scan=MapVirtualKey(vk, 0);
    keybd_event(vk, scan, 0, 0);
}

int cvtkey(
    const char* s,
    int i, 
    int *key,
    int *count, 
    int* len,
    int* letshift,
    int* shift, 
    int* letctrl,
    int* ctrl, 
    int* letalt,
    int* alt, 
    int* shiftlock)
{
    int rv;
    char c;
    int Result=FALSE;
	
    /* if i==-1 then supress special processing */
    if (i!=-1) { 
        *len=1;
        *count=1;
    }
    if (i!=-1)
        c=s[i];
    else 
        c=0;

    /* scan for special character */
    switch (c) {
    case '{': 
        procbrace(s,i,key,len,count,letshift,
                  letctrl,letalt,shift,ctrl,alt,shiftlock);
        if (*key==0)
            return TRUE;
        break;
    case '~': *key=VK_RETURN; break;
    case '+': *shift=TRUE; Result=TRUE; break;
    case '^': *ctrl=TRUE; Result=TRUE; break;
    case '%': *alt=TRUE; Result=TRUE; break;
    case '(': *shiftlock=TRUE; Result=TRUE; break;
    case ')': *shiftlock=FALSE; Result=TRUE; break;
    default:
        if (c==0)
            c=(char)*key;
        rv=VkKeyScan(c);  /* normal character */
        *key=rv & 0xFF;
        *letshift=((rv & 0x100)==0x100);
        *letctrl =((rv & 0x200)==0x200);
        *letalt  =((rv & 0x400)==0x400);
    };

    return Result;
}


typedef struct windowtable {
    int size;
    HWND* windows/*[1024]*/;
} windowtable; 


BOOL CALLBACK AddWindowChild(
    HWND hwnd,    // handle to child window
    LPARAM lParam // application-defined value
    )
{
    HWND* grow;
    windowtable* children = (windowtable*)lParam;
    /* Need to grow the table to make space for the next entry */
    if (children->windows)
        grow = (HWND*)saferealloc(children->windows, (children->size+1)*sizeof(HWND));
    else
        grow = (HWND*)safemalloc((children->size+1)*sizeof(HWND));
    if (grow == 0)
        return FALSE;
    children->windows = grow;
    children->size++;
    children->windows[children->size-1] = hwnd;
    return TRUE;
}

/* 

Phill Wolf <pbwolf@bellatlantic.net> 
 
Although mouse_event is documented to take a unit of "pixels" when moving 
to an absolute location, and "mickeys" when moving relatively, on my 
system I can see that it takes "mickeys" in both cases.  Giving 
mouse_event an absolute (x,y) position in pixels results in the cursor 
going much closer to the top-left of the screen than is intended.
 
Here is the function I have used in my own Perl modules to convert from screen coordinates to mickeys.

*/

void ScreenToMouseplane(POINT *p)
{
    p->x = MulDiv(p->x, 0x10000, GetSystemMetrics(SM_CXSCREEN));
    p->y = MulDiv(p->y, 0x10000, GetSystemMetrics(SM_CYSCREEN));
}
 

/*  Same as mouse_event but without wheel and with time-out.
 */
VOID simple_mouse(
  DWORD dwFlags, // flags specifying various motion/click variants
  DWORD dx,      // horizontal mouse position or position change
  DWORD dy      // vertical mouse position or position change
 )
{
    char dstr[256];
    sprintf(dstr, "simple_mouse(%d, %d, %d)\n", dwFlags, dx, dy);
    OutputDebugString(dstr);
    mouse_event(dwFlags, dx, dy, 0, 0);
    Sleep (10);
}

/* JJ Utilities for thread-specific window functions */

BOOL AttachWin(HWND hwnd, BOOL fAttach)
{
  DWORD dwThreadId = GetWindowThreadProcessId(hwnd, NULL);
  DWORD dwMyThread = GetCurrentThreadId();
  return AttachThreadInput(dwMyThread, dwThreadId, fAttach);
}


SV*
GetTextHelper(HWND hwnd, int index, UINT lenmsg, UINT textmsg)
{
    SV* sv = 0;
    int len = SendMessage(hwnd, lenmsg, index, 0L);
    char* text = (char*)safemalloc(len+1);
    if (text != 0) {
        SendMessage(hwnd, textmsg, index, (LPARAM)text);
        sv = newSVpv(text, len);
        safefree(text);        
    }
    return sv;
}



MODULE = Win32::GuiTest		PACKAGE = Win32::GuiTest		

PROTOTYPES: DISABLE

void
GetCursorPos()
INIT:
  POINT pt;
PPCODE:
  pt.x = pt.y = -1;
  GetCursorPos(&pt);
  XPUSHs(sv_2mortal(newSVnv(pt.x)));
  XPUSHs(sv_2mortal(newSVnv(pt.y)));


void
SendLButtonUp()
    CODE:
    simple_mouse(MOUSEEVENTF_LEFTUP, 0, 0);

void
SendLButtonDown()
	CODE:
        simple_mouse(MOUSEEVENTF_LEFTDOWN, 0, 0);

void
SendMButtonUp()
	CODE:
        simple_mouse(MOUSEEVENTF_MIDDLEUP, 0, 0);

void
SendMButtonDown()
	CODE:
        simple_mouse(MOUSEEVENTF_MIDDLEDOWN, 0, 0);

void
SendRButtonUp()
	CODE:
        simple_mouse(MOUSEEVENTF_RIGHTUP, 0, 0);

void
SendRButtonDown()
	CODE:
        simple_mouse(MOUSEEVENTF_RIGHTDOWN, 0, 0);

void
SendMouseMoveRel(x,y)
    int x;
    int y;
	CODE:
        simple_mouse(MOUSEEVENTF_MOVE, x, y);

void
SendMouseMoveAbs(x,y)
	int x;
    int y;
	CODE:
        simple_mouse(MOUSEEVENTF_MOVE|MOUSEEVENTF_ABSOLUTE, x, y);

void
MouseMoveAbsPix(x,y)
	int x;
    int y;
    PREINIT:
        int mickey_x = MulDiv(x, 0x10000, GetSystemMetrics(SM_CXSCREEN));
        int mickey_y = MulDiv(y, 0x10000, GetSystemMetrics(SM_CYSCREEN));
	CODE:
        simple_mouse(MOUSEEVENTF_MOVE|MOUSEEVENTF_ABSOLUTE, mickey_x, mickey_y);


void
SendKeysImp(s, wait)
     char* s
     DWORD wait
     PREINIT:
	int i,j;
	char c;
	int key;
	int count;

	/* init */
	int len=1;
	int shiftlock=FALSE;
	int letalt=FALSE;
	int alt=FALSE;
	int letctrl=FALSE;
	int ctrl=FALSE;
	int letshift=FALSE;
	int shift=FALSE;
	
    CODE:
     	
	/* for each character in string */
	for (i = 0; i < (int)strlen(s); i++) {
            if (len!=1) {  /* skip characters on request */
		len--;
		continue;
	    }
	    c=s[i];
		
	    /* convert key */
	    if (cvtkey(s,i,&key,&count,&len,&letshift,&shift,
                       &letctrl,&ctrl,&letalt,&alt,&shiftlock))
                continue;
		
            /* fake modifier keys */
	    if (shift || letshift) 
		KeyDown(VK_SHIFT);
	    if (ctrl || letctrl)
		KeyDown(VK_CONTROL);
	    if (alt || letalt)
		KeyDown(VK_MENU);
		
            /* do requested number of keystrokes */
	    for (j=0; j<count; j++) {
                KeyDown(key);
		KeyUp(key);
		Sleep(wait);
            }

            /* clear modifiers unless locked */
	    if (alt || letalt && !shiftlock)
                KeyUp(VK_MENU);
	    if (ctrl || letctrl && !shiftlock)
		KeyUp(VK_CONTROL);
	    if (shift || letshift && !shiftlock)
		KeyUp(VK_SHIFT);
	    if (!shiftlock) {
		alt=FALSE;
		ctrl=FALSE;
		shift=FALSE;
	    }
	}

HWND
GetDesktopWindow()
    CODE:
        RETVAL = GetDesktopWindow();
    OUTPUT:
        RETVAL


HWND
GetWindow(hwnd, uCmd)
    HWND hwnd
    UINT uCmd
    CODE:
        RETVAL = GetWindow(hwnd, uCmd);
    OUTPUT:
	RETVAL


SV*
GetWindowText(hwnd)
    HWND hwnd
    CODE:
        SV* sv;
        char text[255];
        int r;
        r = GetWindowText(hwnd, text, 255);
        RETVAL = newSVpv(text, r);
    OUTPUT:
        RETVAL

SV*
GetClassName(hwnd)
    HWND hwnd
    CODE:
        SV* sv;
        char text[255];
        int r;
        r = GetClassName(hwnd, text, 255);
        RETVAL = newSVpv(text, r);
    OUTPUT:
        RETVAL

HWND
GetParent(hwnd)
    HWND hwnd
    CODE:
        RETVAL = GetParent(hwnd);
    OUTPUT:
        RETVAL

long
GetWindowLong(hwnd, index)
    HWND hwnd
    int index
    CODE:
        RETVAL = GetWindowLong(hwnd, index);
    OUTPUT:
        RETVAL
        
    
BOOL 
SetForegroundWindow(hWnd)
    HWND hWnd
    CODE:
        RETVAL = SetForegroundWindow(hWnd);
    OUTPUT:
        RETVAL

HWND 
SetFocus(hWnd)
    HWND hWnd
    CODE:
        RETVAL = SetFocus(hWnd);
    OUTPUT:
        RETVAL

void
GetChildWindows(hWnd)
    HWND hWnd;
    PREINIT:
        BOOL enum_ok;          
        windowtable children;
        int i;
        char buf[512];
    PPCODE:
        children.size    = 0;
        children.windows = 0;
        EnumChildWindows(hWnd, (WNDENUMPROC)AddWindowChild, (LPARAM)&children);
        for (i = 0; i < children.size; i++) {
            XPUSHs(sv_2mortal(newSViv((IV)children.windows[i])));
        }
	safefree(children.windows);
        

SV*
WMGetText(hwnd)
    HWND hwnd
    CODE:
        SV* sv;
        char* text;
        int len = SendMessage(hwnd, WM_GETTEXTLENGTH, 0, 0L); 
        text = (char*)safemalloc(len+1);
        if (text != 0) {
            SendMessage(hwnd, WM_GETTEXT, (WPARAM)len + 1, (LPARAM)text); 
            RETVAL = newSVpv(text, len);
            safefree(text);
        } else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

int
WMSetText(hwnd, text)
  HWND hwnd
  char * text
CODE:
  RETVAL = SendMessage(hwnd, WM_SETTEXT, 0, (LPARAM) text);
OUTPUT:
  RETVAL

BOOL
IsChild(hWndParent, hWnd)
    HWND hWndParent
    HWND hWnd
    CODE:
        RETVAL = IsChild(hWndParent, hWnd);
    OUTPUT:
        RETVAL

DWORD
GetChildDepth(hAncestor, hChild)
    HWND hAncestor
    HWND hChild
    PREINIT:
        DWORD depth = 1;
    CODE:
        while ((hChild = GetParent(hChild)) != 0) {
            depth++;
            if (hChild == hAncestor) {
                break;
            }
        }
        RETVAL = depth;
    OUTPUT:
        RETVAL

int
SendMessage(hwnd, msg, wParam, lParam)
  HWND hwnd
  UINT msg
  WPARAM wParam
  LPARAM lParam
CODE:
  RETVAL = SendMessage(hwnd, msg, wParam, lParam);
OUTPUT:
  RETVAL
  
int
PostMessage(hwnd, msg, wParam, lParam)
  HWND hwnd
  UINT msg
  WPARAM wParam
  LPARAM lParam
CODE:
  RETVAL = PostMessage(hwnd, msg, wParam, lParam);
OUTPUT:
  RETVAL

void
CheckButton(hwnd)
    HWND hwnd
CODE:
    SendMessage(hwnd, BM_SETCHECK, BST_CHECKED, 0);

void
UnCheckButton(hwnd)
    HWND hwnd
CODE:
    SendMessage(hwnd, BM_SETCHECK, BST_UNCHECKED, 0);

void
GrayOutButton(hwnd)
    HWND hwnd
CODE:
    SendMessage(hwnd, BM_SETCHECK, BST_INDETERMINATE, 0);

BOOL
IsCheckedButton(hwnd)
    HWND hwnd
CODE:
    RETVAL = SendMessage(hwnd, BM_GETCHECK, 0, 0) == BST_CHECKED;
OUTPUT:
    RETVAL

BOOL
IsGrayedButton(hwnd)
    HWND hwnd
CODE:
    RETVAL = SendMessage(hwnd, BM_GETCHECK, 0, 0) == BST_INDETERMINATE;
OUTPUT:
    RETVAL
    
BOOL
IsWindow(hwnd)
    HWND hwnd
CODE:
    RETVAL = IsWindow(hwnd);
OUTPUT:
    RETVAL

void
ScreenToClient(hwnd, x, y)
    HWND hwnd
    int x
    int y
INIT:
    POINT pt;
PPCODE:
    pt.x = x;
    pt.y = y;
    if (ScreenToClient(hwnd, &pt)) {
        XPUSHs(sv_2mortal(newSViv((IV)pt.x)));
        XPUSHs(sv_2mortal(newSViv((IV)pt.y)));
    }

void
ClientToScreen(hwnd, x, y)
    HWND hwnd
    int x
    int y
INIT:
    POINT pt;
PPCODE:
    pt.x = x;
    pt.y = y;
    if (ClientToScreen(hwnd, &pt)) {
        XPUSHs(sv_2mortal(newSViv((IV)pt.x)));
        XPUSHs(sv_2mortal(newSViv((IV)pt.y)));
    }

void
GetCaretPos(hwnd)
  HWND hwnd
INIT:
  POINT pt;
PPCODE:
  AttachWin(hwnd, TRUE);
  pt.x = pt.y = -1;
  if (GetCaretPos(&pt))
  {
    XPUSHs(sv_2mortal(newSVnv(pt.x)));
    XPUSHs(sv_2mortal(newSVnv(pt.y)));
  }
  AttachWin(hwnd, FALSE);

HWND 
GetFocus(hwnd)
  HWND hwnd;
CODE:
  AttachWin(hwnd, TRUE);
  RETVAL = GetFocus();
  AttachWin(hwnd, FALSE);
OUTPUT:
  RETVAL

HWND 
GetActiveWindow(hwnd)
  HWND hwnd;
CODE:
  AttachWin(hwnd, TRUE);
  RETVAL = GetActiveWindow();
  AttachWin(hwnd, FALSE);
OUTPUT:
  RETVAL

HWND 
GetForegroundWindow()
CODE:
  RETVAL = GetForegroundWindow();
OUTPUT:
  RETVAL

HWND
SetActiveWindow(hwnd)
  HWND hwnd;
CODE:
  AttachWin(hwnd, TRUE);
  RETVAL = SetActiveWindow(hwnd);
  AttachWin(hwnd, FALSE);
OUTPUT:
  RETVAL

BOOL
EnableWindow(hwnd, fEnable)
  HWND hwnd
  BOOL fEnable
CODE:
  RETVAL = EnableWindow(hwnd, fEnable);
OUTPUT:
  RETVAL

BOOL
IsWindowEnabled(hwnd)
  HWND hwnd
CODE:
  RETVAL = IsWindowEnabled(hwnd);
OUTPUT:
  RETVAL

BOOL
IsWindowVisible(hwnd)
  HWND hwnd
CODE:
  RETVAL = IsWindowVisible(hwnd);
OUTPUT:
  RETVAL

BOOL
ShowWindow(hwnd, nCmdShow)
  HWND hwnd
  int nCmdShow
CODE:
  AttachWin(hwnd, TRUE);
  RETVAL = ShowWindow(hwnd, nCmdShow);
  AttachWin(hwnd, FALSE);
OUTPUT:
  RETVAL        
    
void 
ScreenToNorm(x,y)
    int x;
    int y;
    PREINIT:
        int hor,ver;
    PPCODE:
        hor = GetSystemMetrics(SM_CXSCREEN);
        ver = GetSystemMetrics(SM_CYSCREEN);
        x = MulDiv(x, 65536, hor);
        y = MulDiv(y, 65536, ver);
        XPUSHs(sv_2mortal(newSViv((IV)x)));
        XPUSHs(sv_2mortal(newSViv((IV)y)));    


void 
NormToScreen(x,y)
    int x;
    int y;
    PREINIT:
        int hor,ver;
    PPCODE:
        hor = GetSystemMetrics(SM_CXSCREEN);
        ver = GetSystemMetrics(SM_CYSCREEN);
        x = MulDiv(x, hor, 65536);
        y = MulDiv(y, ver, 65536);
        XPUSHs(sv_2mortal(newSViv((IV)x)));
        XPUSHs(sv_2mortal(newSViv((IV)y)));

void
GetScreenRes()
    PREINIT:
        int hor,ver;
    PPCODE:
        hor = GetSystemMetrics(SM_CXSCREEN);
        ver = GetSystemMetrics(SM_CYSCREEN);
        XPUSHs(sv_2mortal(newSViv((IV)hor)));
        XPUSHs(sv_2mortal(newSViv((IV)ver)));

void 
GetWindowRect(hWnd)
    HWND hWnd;
    PREINIT:
        RECT rect;
    PPCODE:
        GetWindowRect(hWnd,&rect);
        XPUSHs(sv_2mortal(newSViv((IV)rect.left)));
        XPUSHs(sv_2mortal(newSViv((IV)rect.top)));
        XPUSHs(sv_2mortal(newSViv((IV)rect.right)));
        XPUSHs(sv_2mortal(newSViv((IV)rect.bottom))); 



SV*
GetComboText(hwnd, index)
    HWND hwnd;
    int index
    CODE:
        RETVAL = GetTextHelper(hwnd, index, CB_GETLBTEXTLEN, CB_GETLBTEXT);
    OUTPUT:
        RETVAL

SV*
GetListText(hwnd, index)
    HWND hwnd;
    int index
    CODE:
        RETVAL = GetTextHelper(hwnd, index, LB_GETTEXTLEN, LB_GETTEXT);
    OUTPUT:
        RETVAL

void 
GetComboContents(hWnd)
    HWND hWnd;
PPCODE:
    int nelems = SendMessage(hWnd, CB_GETCOUNT, 0, 0);
    int i;
    for (i = 0; i < nelems; i++) {
        XPUSHs(sv_2mortal(GetTextHelper(hWnd, i, CB_GETLBTEXTLEN, CB_GETLBTEXT)));
    }

void 
GetListContents(hWnd)
    HWND hWnd;
PPCODE:
    int nelems = SendMessage(hWnd, LB_GETCOUNT, 0, 0);
    int i;
    for (i = 0; i < nelems; i++) {
        XPUSHs(sv_2mortal(GetTextHelper(hWnd, i, LB_GETTEXTLEN, LB_GETTEXT)));
    }

BOOL
IsKeyPressed(name)
    char* name;
    CODE:
    int vkey;
    int found;
    int len = strlen(name);
    if (len >= 3) 
        name[3]='\0';
    found = findvkey(name, &vkey);
    if (found) {
        OutputDebugString("Trying key\n");
        RETVAL = GetAsyncKeyState(vkey);
    } else if (strlen(name)==1 && (isdigit(*name) || isalpha(*name))) {
        OutputDebugString("Trying alphanum\n");
        RETVAL = GetAsyncKeyState(toupper(*name));
    }else {
        OutputDebugString("No key\n");
        RETVAL = 0;
    }
    OUTPUT:
        RETVAL


HMENU
GetSubMenu(hMenu, nPos)
    HMENU hMenu;
    int nPos;
CODE:
    RETVAL = GetSubMenu(hMenu, nPos);
OUTPUT:
    RETVAL

    
int
GetMenuItemIndex(hm, sitem)
    HMENU hm;
    char *sitem;
CODE:
    int mi = 0;
    int mic = 0;
    MENUITEMINFO minfo;
    char buff[256] = ""; /* Menu Data Buffer */
    BOOL found = FALSE;

    RETVAL = -1;

    mic = GetMenuItemCount(hm);
    if (mic != -1) {
        /* Look at each item to determine if it is the one we want */
        for (mi = 0; mi < mic; mi++) {
	    /* Refresh menu item info structure */
	    memset(buff, 0, sizeof(buff));
	    minfo.cbSize = sizeof(MENUITEMINFO);
	    minfo.fMask = MIIM_DATA | MIIM_TYPE;
	    minfo.dwTypeData = buff;
	    minfo.cch = sizeof(buff);
	    if (GetMenuItemInfo(hm, mi, TRUE, &minfo) &&
                minfo.fType == MFT_STRING &&
                minfo.dwTypeData != NULL &&
                strnicmp(minfo.dwTypeData, sitem, strlen(sitem)) == 0) {
                /* Got what we came for, so return index. */
                RETVAL = mi;
                break;
            }
	}
    }
OUTPUT:
    RETVAL

HMENU
GetSystemMenu(hWnd, bRevert)
    HWND hWnd;
    BOOL bRevert;
CODE:
    RETVAL = GetSystemMenu(hWnd, bRevert);
OUTPUT:
    RETVAL

UINT
GetMenuItemID(hMenu, nPos)
    HMENU hMenu;
    int nPos;
CODE:
    RETVAL = GetMenuItemID(hMenu, nPos);
OUTPUT:
    RETVAL
 
HMENU
GetMenu(hWnd)
    HWND hWnd;
CODE:
    RETVAL = GetMenu(hWnd);
OUTPUT:
    RETVAL

 
BOOL
SetWindowPos(hWnd, hWndInsertAfter, X, Y, cx, cy, uFlags)
  HWND hWnd;
  HWND hWndInsertAfter;
  int X;
  int Y;
  int cx;
  int cy;
  UINT uFlags;
CODE:
    RETVAL = SetWindowPos(hWnd, hWndInsertAfter, X, Y, cx, cy, uFlags);
OUTPUT:
    RETVAL

void
TabCtrl_SetCurFocus(hWnd, item)
    HWND hWnd
    int item
    CODE:
       TabCtrl_SetCurFocus(hWnd, item);

int
TabCtrl_GetCurFocus(hWnd)
    HWND hWnd
    CODE:
        RETVAL = TabCtrl_GetCurFocus(hWnd);
    OUTPUT:
        RETVAL

int
TabCtrl_SetCurSel(hWnd, item)
    HWND hWnd
    int item
    CODE:
        RETVAL = TabCtrl_SetCurSel(hWnd, item);
    OUTPUT:
        RETVAL

int
TabCtrl_GetItemCount(hWnd)
    HWND hWnd
    CODE:
        RETVAL = TabCtrl_GetItemCount(hWnd);
    OUTPUT:
        RETVAL

void 
SendRawKey(vk, flags)
    UINT vk;
    DWORD flags;
CODE:
    BYTE scan = MapVirtualKey(vk, 0);
    keybd_event(vk, scan, flags, 0);




MODULE = Win32::GuiTest		PACKAGE = Win32::GuiTest::DibSect

PROTOTYPES: DISABLE

DibSect *
DibSect::new()

void
DibSect::DESTROY()

bool
DibSect::CopyClient(hwnd, rect=0)
  HWND hwnd
  SV  *rect
CODE:
  RECT r, *pr = 0;
  if (rect)
  {
    if (!(SvROK(rect) &&  (rect = SvRV(rect)) && SvTYPE(rect) == SVt_PVAV))
	    croak("Second argument to CopyClient() must be a reference to array");
    AV * av = (AV*) rect;
    int len = av_len(av) + 1;
    if (len != 4)
      croak("Rectangle requires 4 elements, not %d", len);
    pr = &r;
    SetRectEmpty(pr);
    LONG * p = (LONG *) pr;
    for(int i = 0 ; i < len; i++, p++)
    {
      SV ** psv = av_fetch(av, i, 0);
      if (psv)
        *p = SvIV(*psv);
    }
  }
  RETVAL = THIS->CopyWndClient(hwnd, pr) != 0;
OUTPUT:
  RETVAL

bool
DibSect::CopyWindow(hwnd)
  HWND hwnd
CODE:
  RECT r;
  GetWindowRect(hwnd, &r);
  RETVAL = THIS->CopyWndClient(GetDesktopWindow(), &r) != 0;
OUTPUT:
  RETVAL


bool
DibSect::SaveAs(szFile)
	char *	szFile
CODE:
	RETVAL = THIS->SaveAs(szFile);
OUTPUT:
RETVAL

bool 
DibSect::Invert()
CODE:
	RETVAL = THIS->Invert();
OUTPUT:
RETVAL


bool 
DibSect::ToGrayScale()
CODE:
	RETVAL = THIS->ToGrayScale();
OUTPUT:
RETVAL

bool 
DibSect::Destroy()
CODE:
	RETVAL = THIS->Destroy();
OUTPUT:
RETVAL

bool 
DibSect::ToClipboard()
CODE:
	RETVAL = THIS->ToClipboard();
OUTPUT:
RETVAL
