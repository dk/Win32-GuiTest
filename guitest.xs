/* 
 *  $Id: guitest.xs,v 1.16 2004/12/11 16:20:54 ctrondlp Exp $
 *
 *  The SendKeys function is based on the Delphi sourcecode
 *  published by Al Williams <http://www.al-williams.com/awc/> 
 *  in Dr.Dobbs <http://www.ddj.com/ddj/1997/careers1/wil2.htm>
 *	
 *  Copyright (c) 1998-2002 by Ernesto Guisado <erngui@acm.org>
 *  Copyright (c) 2004 by Dennis K. Paulsen <ctrondlpaulsden@yahoo.com>
 *
 *  You may distribute under the terms of either the GNU General Public
 *  License or the Artistic License.
 *
 */

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <commctrl.h>
#include "dibsect.h"
/* #include "afxwin.h" */


#ifdef __cplusplus
//extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
//}
#endif

#define MAX_DATA_BUF 1024
#define NUL '\0'

HINSTANCE g_hDLL = NULL;

#pragma data_seg(".shared")
// Used by hooking/injected routines
HWND g_hWnd = 0;
HHOOK g_hHook = NULL;
BOOL g_bRetVal = 0;
char g_szBuffer[MAX_DATA_BUF+1] = {NUL};
UINT WM_LV_GETTEXT = 0;
UINT WM_LV_SELBYINDEX = 0;
UINT WM_LV_SELBYTEXT = 0;
UINT WM_LV_ISSEL = 0;
UINT WM_TC_GETTEXT = 0;
UINT WM_TC_SELBYINDEX = 0;
UINT WM_TC_SELBYTEXT = 0;
UINT WM_TC_ISSEL = 0;
UINT WM_TV_SELBYPATH = 0;
UINT WM_TV_GETSELPATH = 0;
#pragma data_seg()
#pragma comment(linker, "/SECTION:.shared,RWS")

BOOL APIENTRY DllMain(HANDLE hModule, DWORD  ul_reason_for_call, 
                      LPVOID lpReserved)
{
	switch (ul_reason_for_call)
	{
	case DLL_PROCESS_ATTACH:
		// Value used by SetWindowsHookEx, etc.
		g_hDLL = (HINSTANCE)hModule;
		break;
	case DLL_THREAD_ATTACH:
		break;
	case DLL_THREAD_DETACH:
		break;
	case DLL_PROCESS_DETACH:
		break;
	}

	return TRUE;
}

// Gets a treeview item handle by name
HTREEITEM GetTVItemByName(HWND hWnd, HTREEITEM hItem,
                         char *lpItemName)
{
    // If hItem is NULL, start search from root item.
    if (hItem == NULL)
        hItem = (HTREEITEM)SendMessage(hWnd, TVM_GETNEXTITEM, TVGN_ROOT, 0);

    while (hItem != NULL)
    {
        char szBuffer[MAX_DATA_BUF+1];
        TV_ITEM item;

        item.hItem = hItem;
        item.mask = TVIF_TEXT | TVIF_CHILDREN;
        item.pszText = szBuffer;
        item.cchTextMax = MAX_DATA_BUF;
        SendMessage(hWnd, TVM_GETITEM, 0, (LPARAM)&item);

        // Did we find it?
        if (lstrcmpi(szBuffer, lpItemName) == 0)
            return hItem;

        // Check whether we have child items.
        if (item.cChildren)
        {
            // Recursively traverse child items.
            HTREEITEM hItemFound, hItemChild;

            hItemChild = (HTREEITEM)SendMessage(hWnd, TVM_GETNEXTITEM,
                                                TVGN_CHILD, (LPARAM)hItem);
            hItemFound = GetTVItemByName(hWnd, hItemChild, lpItemName);

            // Did we find it?
            if (hItemFound != NULL)
                return hItemFound;
        }

        // Go to next sibling item.
        hItem = (HTREEITEM)SendMessage(hWnd, TVM_GETNEXTITEM,
                                       TVGN_NEXT, (LPARAM)hItem);
    }

    // Not found.
    return NULL;
}

int TabCtrl_GetItemText(HWND hwnd, int iItem, char *lpString, size_t sizeStr)
{
	TCITEM tcItem;
	tcItem.pszText = lpString;
	tcItem.cchTextMax = sizeStr;
	tcItem.mask = TCIF_TEXT;
	
	assert(lpString != NULL);
	*lpString = NUL;	
	TabCtrl_GetItem(g_hWnd, iItem, &tcItem);

	return (int)strlen(lpString);
}
		
#define pCW ((CWPSTRUCT*)lParam)

// Hook procedure, does most of the work for various 32bit custom control
// routines
LRESULT HookProc (int code, WPARAM wParam, LPARAM lParam)
{	
	//// List Views ////
	if (pCW->message == WM_LV_GETTEXT) {
		*g_szBuffer = NUL;
		int iItem = pCW->wParam;
		ListView_GetItemText(g_hWnd, iItem, 0, g_szBuffer, MAX_DATA_BUF);
		UnhookWindowsHookEx(g_hHook);
	} else if (pCW->message == WM_LV_SELBYINDEX) {
		int iCount = ListView_GetItemCount(g_hWnd);
		int iSel = pCW->wParam;
		BOOL bMulti = pCW->lParam;
		// Clear out any previous selections if needed
		if (!bMulti && ListView_GetSelectedCount(g_hWnd) > 0) {
			for (int i = 0; i < iCount; i++) {
				ListView_SetItemState(g_hWnd, i, 0, LVIS_SELECTED);
			}
		}
		// Select item
		ListView_SetItemState(g_hWnd, iSel, LVIS_SELECTED | LVIS_FOCUSED, LVIS_SELECTED | LVIS_FOCUSED);
		g_bRetVal = ListView_EnsureVisible(g_hWnd, iSel, FALSE);
		UnhookWindowsHookEx(g_hHook);
	} else if (pCW->message == WM_LV_SELBYTEXT) {
		char szItem[MAX_DATA_BUF+1] = "";
		int iCount = ListView_GetItemCount(g_hWnd);
		BOOL bMulti = pCW->lParam;
		// Clear out any previous selections if needed
		if (!bMulti && ListView_GetSelectedCount(g_hWnd) > 0) {
			for (int i = 0; i < iCount; i++) {
				ListView_SetItemState(g_hWnd, i, 0, LVIS_SELECTED);
			}
		}
		// Look for item
		for (int i = 0; i < iCount; i++) {
			ListView_GetItemText(g_hWnd, i, 0, szItem, MAX_DATA_BUF);
			if (lstrcmpi(g_szBuffer, szItem) == 0) {
				// Found it, select it
				ListView_SetItemState(g_hWnd, i, LVIS_SELECTED | LVIS_FOCUSED, LVIS_SELECTED | LVIS_FOCUSED);
				g_bRetVal = ListView_EnsureVisible(g_hWnd, i, FALSE);	
				break;
			}
		}
		UnhookWindowsHookEx(g_hHook);
	} else if (pCW->message == WM_LV_ISSEL) {
		char szItem[MAX_DATA_BUF+1] = "";
		int iCount = ListView_GetItemCount(g_hWnd);
		g_bRetVal = FALSE; // Assume false
		// Are there any selected?	
		if (ListView_GetSelectedCount(g_hWnd) > 0) {
			// Look for item
			for (int i = 0; i < iCount; i++) {
				ListView_GetItemText(g_hWnd, i, 0, szItem, MAX_DATA_BUF);
				if (lstrcmpi(g_szBuffer, szItem) == 0) {
					// Found it, determine if currently selected
					if (ListView_GetItemState(g_hWnd, i, LVIS_SELECTED) & LVIS_SELECTED) {
						g_bRetVal = TRUE;
					}
				}
			}
		}
		UnhookWindowsHookEx(g_hHook);
	} else if (pCW->message == WM_TV_SELBYPATH) {
	//// Tree Views ////
		char szName[MAX_DATA_BUF+1] = "";
		size_t pos = 0, len = 0;
		HTREEITEM hItem = NULL;

		g_bRetVal = FALSE; // Assume failure

		len = strlen(g_szBuffer);
		// Move through supplied tree view path, updating hItem appropriately
		for (size_t x = 0; x < len; x++) {
			if (g_szBuffer[x] == '|') {
				if (*szName) {
					hItem = GetTVItemByName(g_hWnd, hItem, szName);
					memset(&szName, 0, MAX_DATA_BUF);
					pos = 0;
				}
			} else {
				szName[pos++] = g_szBuffer[x];
			}
		}

		if (*szName) {
			// Just a root item, no path delimiters (|)
			// OR a trailing child item?
			hItem = GetTVItemByName(g_hWnd, hItem, szName);
		}

		// Select Item if handle obtained
		g_bRetVal = hItem ? (BOOL)TreeView_SelectItem(g_hWnd, hItem) : FALSE;
		TreeView_EnsureVisible(g_hWnd, hItem);

		UnhookWindowsHookEx(g_hHook);
	} else if (pCW->message == WM_TV_GETSELPATH) {
		char szText[MAX_DATA_BUF+1] = "";
		char szTmp[MAX_DATA_BUF+1] = "";	
		TVITEM tvItem = {NUL};
		HTREEITEM hItem = TreeView_GetSelection(g_hWnd);
		*g_szBuffer = NUL;

		tvItem.mask = TVIF_TEXT;
		tvItem.pszText = szText;
		tvItem.cchTextMax = MAX_DATA_BUF;
		do {
			tvItem.hItem = hItem;
			TreeView_GetItem(g_hWnd, &tvItem);

			// Add in child path text if any
			if (*szTmp)
				lstrcat(szText, szTmp);

			hItem = TreeView_GetParent(g_hWnd, hItem);
			if (hItem) {
				// Has parent, so store delimiter and path text thus far
				sprintf(szTmp, "|%s", szText);
			} else {
				// No parent, so store complete path thus far
				lstrcpy(szTmp, szText);
			}
		} while (hItem);
		lstrcpy(g_szBuffer, szTmp);	
		UnhookWindowsHookEx(g_hHook);
	} else if (pCW->message == WM_TC_GETTEXT) {
	//// Tab Control ////
		int iItem = pCW->wParam;
		g_bRetVal = (BOOL)TabCtrl_GetItemText(g_hWnd, iItem, g_szBuffer, MAX_DATA_BUF);
		UnhookWindowsHookEx(g_hHook);
	} else if (pCW->message == WM_TC_SELBYINDEX) {
		int iItem = pCW->wParam;
		g_bRetVal = FALSE; // Assume failure
		if (iItem < TabCtrl_GetItemCount(g_hWnd)) {
			TabCtrl_SetCurFocus(g_hWnd, iItem);
			g_bRetVal = TRUE;
		}
		UnhookWindowsHookEx(g_hHook);
	} else if (pCW->message == WM_TC_SELBYTEXT) {
		char szName[MAX_DATA_BUF+1] = "";
		int iCount = TabCtrl_GetItemCount(g_hWnd);
		for (int i = 0; i < iCount; i++) {
			TabCtrl_GetItemText(g_hWnd, i, szName, MAX_DATA_BUF);
			// Is Tab item we want?
			if (lstrcmpi(g_szBuffer, szName) == 0) {
				// ... then set focus to it
				TabCtrl_SetCurFocus(g_hWnd, i);
				break;
			}
		}
		UnhookWindowsHookEx(g_hHook);
	} else if (pCW->message == WM_TC_ISSEL) {
		char szName[MAX_DATA_BUF+1] = "";
		int iItem = TabCtrl_GetCurFocus(g_hWnd);
		g_bRetVal = FALSE; // Assume false
		TabCtrl_GetItemText(g_hWnd, iItem, szName, MAX_DATA_BUF);
		if (lstrcmpi(g_szBuffer, szName) == 0) {
			// Yes, selected
			g_bRetVal = TRUE;
		}
		UnhookWindowsHookEx(g_hHook);
	}

	return CallNextHookEx(g_hHook, code, wParam, lParam);
}

// The following several routines all inject "ourself" into a remote process
// and performs some work.
int GetLVItemText(HWND hWnd, int iItem, char *lpString)
{	
	g_hWnd = hWnd;

	// Hook the thread, that "owns" our control
	g_hHook = SetWindowsHookEx(WH_CALLWNDPROC, (HOOKPROC)HookProc,
				g_hDLL, GetWindowThreadProcessId(hWnd, NULL));
	if (g_hHook == NULL) {
		*lpString = NUL;
		return 0;
	}
	
	if (WM_LV_GETTEXT == NULL)
		WM_LV_GETTEXT = RegisterWindowMessage("WM_LV_GETTEXT_RM");

	// By the time SendMessage returns, 
	// g_szBuffer already contains the text.
	SendMessage(hWnd, WM_LV_GETTEXT, iItem, 0);
	lstrcpy(lpString, g_szBuffer);

	return (int)strlen(lpString);
}

BOOL SelLVItem(HWND hWnd, int iItem, BOOL bMulti)
{
	g_hWnd = hWnd;

	g_hHook = SetWindowsHookEx(WH_CALLWNDPROC, (HOOKPROC)HookProc,
				g_hDLL, GetWindowThreadProcessId(hWnd, NULL));
	if (g_hHook == NULL)
		return FALSE;
	
	if (WM_LV_SELBYINDEX == NULL)
		WM_LV_SELBYINDEX = RegisterWindowMessage("WM_LV_SELBYINDEX_RM");

	SendMessage(hWnd, WM_LV_SELBYINDEX, iItem, bMulti);

	return g_bRetVal;
}

BOOL SelLVItemText(HWND hWnd, char *lpItem, BOOL bMulti)
{
	g_hWnd = hWnd;

	g_hHook = SetWindowsHookEx(WH_CALLWNDPROC, (HOOKPROC)HookProc,
	 			g_hDLL, GetWindowThreadProcessId(hWnd, NULL));
	if (g_hHook == NULL)
		return FALSE;
	
	if (WM_LV_SELBYTEXT == NULL)
		WM_LV_SELBYTEXT = RegisterWindowMessage("WM_LV_SELBYTEXT_RM");

	lstrcpy(g_szBuffer, lpItem);
	SendMessage(hWnd, WM_LV_SELBYTEXT, 0, bMulti);

	return g_bRetVal;
}

BOOL IsLVItemSel(HWND hWnd, char *lpItem)
{
	g_hWnd = hWnd;

	g_hHook = SetWindowsHookEx(WH_CALLWNDPROC, (HOOKPROC)HookProc,
	 			g_hDLL, GetWindowThreadProcessId(hWnd, NULL));
	if (g_hHook == NULL)
		return FALSE;
	
	if (WM_LV_ISSEL == NULL)
		WM_LV_ISSEL = RegisterWindowMessage("WM_LV_ISSEL_RM");

	lstrcpy(g_szBuffer, lpItem);
	SendMessage(hWnd, WM_LV_ISSEL, 0, 0);

	return g_bRetVal;
}

int GetLVItemCount(HWND hWnd)
{
	return ListView_GetItemCount(hWnd);
}

BOOL SelTVItemPath(HWND hWnd, char *lpPath)
{	
	g_hWnd = hWnd;

	g_hHook = SetWindowsHookEx(WH_CALLWNDPROC, (HOOKPROC)HookProc,
				g_hDLL, GetWindowThreadProcessId(hWnd, NULL));
	if (g_hHook == NULL)
		return FALSE;
	
	if (WM_TV_SELBYPATH == NULL)
		WM_TV_SELBYPATH = RegisterWindowMessage("WM_TV_SELBYPATH_RM");
	
	lstrcpy(g_szBuffer, lpPath);
	SendMessage(hWnd, WM_TV_SELBYPATH, 0, 0);
	return g_bRetVal;
}

int GetTVSelPath(HWND hWnd, char *lpPath)
{
	g_hWnd = hWnd;

	g_hHook = SetWindowsHookEx(WH_CALLWNDPROC, (HOOKPROC)HookProc,
				g_hDLL, GetWindowThreadProcessId(hWnd, NULL));
	if (g_hHook == NULL)
		return FALSE;
	
	if (WM_TV_GETSELPATH == NULL)
		WM_TV_GETSELPATH = RegisterWindowMessage("WM_TV_GETSELPATH_RM");
	
	SendMessage(hWnd, WM_TV_GETSELPATH, 0, 0);
	lstrcpy(lpPath, g_szBuffer);

	return (int)strlen(lpPath);
}

int GetTCItemText(HWND hWnd, int iItem, char *lpString)
{	
	g_hWnd = hWnd;

	g_hHook = SetWindowsHookEx(WH_CALLWNDPROC, (HOOKPROC)HookProc,
				g_hDLL, GetWindowThreadProcessId(hWnd, NULL));
	if (g_hHook == NULL) {
		*lpString = NUL;
		return 0;
	}
	
	if (WM_TC_GETTEXT == NULL)
		WM_TC_GETTEXT = RegisterWindowMessage("WM_TC_GETTEXT_RM");

	SendMessage(hWnd, WM_TC_GETTEXT, iItem, 0);
	lstrcpy(lpString, g_szBuffer);

	return (int)strlen(lpString);
}

BOOL SelTCItem(HWND hWnd, int iItem)
{	
	g_hWnd = hWnd;

	g_hHook = SetWindowsHookEx(WH_CALLWNDPROC, (HOOKPROC)HookProc,
				g_hDLL, GetWindowThreadProcessId(hWnd, NULL));
	if (g_hHook == NULL)
		return FALSE;
	
	if (WM_TC_SELBYINDEX == NULL)
		WM_TC_SELBYINDEX = RegisterWindowMessage("WM_TC_SELBYINDEX_RM");
	
	SendMessage(hWnd, WM_TC_SELBYINDEX, iItem, 0);
	return g_bRetVal;
}

BOOL SelTCItemText(HWND hWnd, char *szText)
{	
	g_hWnd = hWnd;

	// Hook the thread, that "owns" our control
	g_hHook = SetWindowsHookEx(WH_CALLWNDPROC, (HOOKPROC)HookProc,
				g_hDLL, GetWindowThreadProcessId(hWnd, NULL));
	if (g_hHook == NULL)
		return FALSE;
	
	if (WM_TC_SELBYTEXT == NULL)
		WM_TC_SELBYTEXT = RegisterWindowMessage("WM_TC_SELBYTEXT_RM");
	
	lstrcpy(g_szBuffer, szText);
	SendMessage(hWnd, WM_TC_SELBYTEXT, 0, 0);
	return g_bRetVal;
}


BOOL IsTCItemSel(HWND hWnd, char *lpItem)
{
	g_hWnd = hWnd;

	g_hHook = SetWindowsHookEx(WH_CALLWNDPROC, (HOOKPROC)HookProc,
	 			g_hDLL, GetWindowThreadProcessId(hWnd, NULL));
	if (g_hHook == NULL)
		return FALSE;
	
	if (WM_TC_ISSEL == NULL)
		WM_TC_ISSEL = RegisterWindowMessage("WM_TC_ISSEL_RM");

	lstrcpy(g_szBuffer, lpItem);
	SendMessage(hWnd, WM_TC_ISSEL, 0, 0);

	return g_bRetVal;
}

int GetTCItemCount(HWND hWnd)
{
	return TabCtrl_GetItemCount(hWnd);
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
    tmp[pos] = NUL;
    res = atoi(tmp);
    safefree(tmp);
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
		tmp[m]=NUL;
		
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
			tmp[3]=NUL;

		/* handle pause specially */
		if (strcmp(tmp,"PAU")==0) {
            OutputDebugString("Found PAUSE\n");
OutputDebugString(tmp);
OutputDebugString("\n");
			Sleep(*count);
			*key=0;
			safefree(tmp);
			return;
		}
		
		/* find entry in table */
		*key=0;
        findvkey(tmp, key);
		/* if key=0 here then something is bad */
	} /* end of token processing */

	safefree(tmp);
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
GetListViewContents(hWnd)
	HWND hWnd
PPCODE:
	char szItem[MAX_DATA_BUF+1] = "";
	int iCount = GetLVItemCount(hWnd);
	for (int i = 0; i < iCount; i++) {
		GetLVItemText(hWnd, i, szItem);
        XPUSHs(sv_2mortal(newSVpv(szItem, 0)));
	}

BOOL
SelListViewItem(hWnd, iItem, bMulti=FALSE)
	HWND hWnd
	int iItem
	BOOL bMulti
CODE:
	RETVAL = SelLVItem(hWnd, iItem, bMulti);
OUTPUT:
	RETVAL

BOOL
SelListViewItemText(hWnd, lpItem, bMulti=FALSE)
	HWND hWnd
	char *lpItem
	BOOL bMulti
CODE:
	RETVAL = SelLVItemText(hWnd, lpItem, bMulti);
OUTPUT:
	RETVAL

BOOL
IsListViewItemSel(hWnd, lpItem)
	HWND hWnd
	char *lpItem
CODE:
	RETVAL = IsLVItemSel(hWnd, lpItem);
OUTPUT:
	RETVAL

void
GetTabItems(hWnd)
	HWND hWnd
PPCODE:
	char szItem[MAX_DATA_BUF+1] = "";
	int iCount = GetTCItemCount(hWnd);
	for (int i = 0; i < iCount; i++) {
		GetTCItemText(hWnd, i, szItem);
	        XPUSHs(sv_2mortal(newSVpv(szItem, 0)));
	}

BOOL
SelTabItem(hWnd, iItem)
	HWND hWnd
	int iItem
CODE:
	RETVAL = SelTCItem(hWnd, iItem);
OUTPUT:
	RETVAL

BOOL
SelTabItemText(hWnd, lpItem)
	HWND hWnd
	char *lpItem
CODE:
	RETVAL = SelTCItemText(hWnd, lpItem);
OUTPUT:
	RETVAL

BOOL
IsTabItemSel(hWnd, lpItem)
	HWND hWnd
	char *lpItem
CODE:
	RETVAL = IsTCItemSel(hWnd, lpItem);
OUTPUT:
	RETVAL

BOOL
SelTreeViewItemPath(hWnd, lpPath)
	HWND hWnd
	char *lpPath
CODE:
	RETVAL = SelTVItemPath(hWnd, lpPath);
OUTPUT:
	RETVAL

SV*
GetTreeViewSelPath(hWnd)
	HWND hWnd
CODE:
	char szPath[MAX_DATA_BUF+1] = "";
	int len = GetTVSelPath(hWnd, szPath);
	RETVAL = newSVpv(szPath, len);
OUTPUT:
	RETVAL

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


#ifndef WHEEL_DELTA
#define WHEEL_DELTA 120
#endif
void
MouseMoveWheel(dwChange)
    DWORD dwChange
CODE:
    mouse_event(MOUSEEVENTF_WHEEL, 0, 0, (dwChange*WHEEL_DELTA), 0);

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
//        SV* sv;
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
//        SV* sv;
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
  		AttachWin(hWnd, TRUE);
        RETVAL = SetFocus(hWnd);
		AttachWin(hWnd, FALSE);
    OUTPUT:
        RETVAL

void
GetChildWindows(hWnd)
    HWND hWnd;
    PREINIT:
        windowtable children;
        int i;
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
//        SV* sv;
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
        name[3]=NUL;
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

# experimental code by SZABGAB

void
GetMenuItemInfo(hMenu, uItem)
    HMENU hMenu;
    UINT uItem;
INIT:
    MENUITEMINFO minfo;
    char buff[256] = "";   /* Menu Data Buffer */
PPCODE:
    memset(buff, 0, sizeof(buff));
    minfo.cbSize = sizeof(MENUITEMINFO);
    minfo.fMask = MIIM_CHECKMARKS | MIIM_DATA | MIIM_TYPE | MIIM_STATE;
    minfo.dwTypeData = buff;
    minfo.cch = sizeof(buff);

    if (GetMenuItemInfo(hMenu, uItem, TRUE, &minfo)) {
        XPUSHs(sv_2mortal(newSVpv("type", 4)));
       	if (minfo.fType == MFT_STRING) { 
            XPUSHs(sv_2mortal(newSVpv("string", 6)));
    	    int r;
    	    r = strlen(minfo.dwTypeData);
            XPUSHs(sv_2mortal(newSVpv("text", 4)));
            XPUSHs(sv_2mortal(newSVpv(minfo.dwTypeData, r)));
	} else if (minfo.fType == MFT_SEPARATOR) { 
            XPUSHs(sv_2mortal(newSVpv("separator", 9)));
	} else {
            XPUSHs(sv_2mortal(newSVpv("unknown", 7)));
	}
        XPUSHs(sv_2mortal(newSVpv("fstate", 6)));
        XPUSHs(sv_2mortal(newSViv(minfo.fState)));
        XPUSHs(sv_2mortal(newSVpv("ftype", 5)));
        XPUSHs(sv_2mortal(newSViv(minfo.fType)));
    }

#void
#getLW(hWnd)
#    HWND hWnd;
#INIT:
#   CWnd myWnd;
#PPCODE:
#    myWnd = CWnd::FromHandle(hWnd);
#    XPUSHs(sv_2mortal(newSVpv("type", 4)));


int 
GetMenuItemCount(hMenu)
    HMENU hMenu;
CODE:
    RETVAL = GetMenuItemCount(hMenu);
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

HWND
WindowFromPoint(x, y)
    int x;
    int y;
PREINIT:
    POINT pt;
CODE:
    pt.x = x;
    pt.y = y;
    RETVAL = WindowFromPoint(pt);
OUTPUT:
    RETVAL


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
