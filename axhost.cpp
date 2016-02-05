#include "Ist.h"
#include "axhost.h"
#include "rc_vm.h"

#pragma code_seg(ATL_SEG)

// We derive our own control site window so that:
// 1) We can fix some bugs
// 2) We can improve on the handling of failure to create embedded controls by displaying an HTML message
// 3) We can use our own window class name and interface to avoid clashing with the ATL versions
class CDolphinAxHost : public /*virtual*/ CAxHostWindow
	, public IDolphinAxHost
{
protected:
	enum NormalizedObjectType { otOther, otMSHTML, otWebBrowser };

	static HRESULT CreateHost(HWND hWnd, IUnknown** ppUnkContainer);
	static HRESULT CreateNormalizedObject(LPCOLESTR lpszTricsData, REFIID riid, void** ppvObj, 
			NormalizedObjectType& otCreated, LPCOLESTR& lpszHTMLText, BSTR bstrLicKey);

public:
	DECLARE_NO_REGISTRY()
	DECLARE_POLY_AGGREGATABLE(CDolphinAxHost)
	DECLARE_GET_CONTROLLING_UNKNOWN()

	BEGIN_COM_MAP(CDolphinAxHost)
		COM_INTERFACE_ENTRY(IDolphinAxHost)
		COM_INTERFACE_ENTRY_CHAIN(CAxHostWindow)
	END_COM_MAP()

public:
	static LRESULT CALLBACK WindowProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
	static LPCTSTR GetWndClassName()
	{
		return _T("AtlAxWin71"/*ATLAXWIN_CLASS*/);
	}

	///////////////////////////////////////////////////////////////////////////
	// Message Handlers

	BEGIN_MSG_MAP(CDolphinAxHost)
		MESSAGE_HANDLER(WM_PAINT, OnPaint)
		CHAIN_MSG_MAP(CAxHostWindow)
	END_MSG_MAP()

	LRESULT OnPaint(UINT uMsg, WPARAM wParam, LPARAM lParam, BOOL& bHandled);

	///////////////////////////////////////////////////////////////////////////
	// COM Interfaces

	// IDolphinAxHost (additional interface)
	STDMETHOD(get_IsWindowless)(VARIANT_BOOL* pbIsWindowless)
	{
		*pbIsWindowless = m_bWindowless ? ATL_VARIANT_TRUE : ATL_VARIANT_FALSE;
		return S_OK;
	}

	STDMETHOD(CreateControlLicEx)(LPCOLESTR lpszTricsData, HWND hWnd, IStream* pStream, IUnknown** ppUnk, IPropertyNotifySink* piSink, BSTR bstrLic)
	{
		return static_cast<IAxWinHostWindowLic*>(this)->CreateControlLicEx(lpszTricsData, hWnd, 
			pStream, ppUnk, 
			piSink?__uuidof(IPropertyNotifySink):IID_NULL, piSink, 
			bstrLic);
	}

	STDMETHOD(CreateControlLicEx)(LPCOLESTR lpszTricsData, HWND hWnd, IStream* pStream, IUnknown** ppUnk, REFIID iidAdvise, IUnknown* punkSink, BSTR bstrLic);

	// The following 3 methods are duplicates of those in the superclass, however since they are defined again in
	// the IDolphinAxHost interface, C++ treats them as different functions to those in IAxWinHostWindow
	// because the latter is a base class of the superclass
	STDMETHOD(SetExternalDispatch)(IDispatch* pDisp)
	{
		m_spExternalDispatch = pDisp;
		return S_OK;
	}
	STDMETHOD(SetExternalUIHandler)(IDocHostUIHandlerDispatch* pUIHandler)
	{
#ifndef _ATL_NO_DOCHOSTUIHANDLER
		m_spIDocHostUIHandlerDispatch = pUIHandler;
#endif
		return S_OK;
	}

	STDMETHOD(QueryControl)(REFIID riid, IUnknown** ppiObject)
	{
		return static_cast<IAxWinHostWindow*>(this)->QueryControl(riid, (void**)ppiObject);
	}

// IOleControlSite - overrides for bug fixes, etc
	STDMETHOD(TransformCoords)(POINTL* /*pPtlHimetric*/, POINTF* /*pPtfContainer*/, DWORD /*dwFlags*/)
	{
		// BSM bug fix - see MSDN Q244817
		return E_NOTIMPL;
	}

// IOleClientSite
	STDMETHOD(ShowObject)();

// IOleInPlaceSite (bug fix overrides)
	STDMETHOD(OnPosRectChange)(LPCRECT lprcPosRect);
};

#ifndef IS_INTRESOURCE
	#define IS_INTRESOURCE(_r) (((DWORD)(_r) >> 16) == 0)
#endif

HRESULT CDolphinAxHost::CreateNormalizedObject(LPCOLESTR lpszTricsData, REFIID riid, void** ppvObj, NormalizedObjectType& otCreated, LPCOLESTR& lpszHTMLText, BSTR bstrLicKey)
{
	ATLASSERT(ppvObj);
	if (ppvObj == NULL)
		return E_POINTER;
	*ppvObj = NULL;

	CLSID clsid;
	HRESULT hr = E_FAIL;

	otCreated = otOther;
	lpszHTMLText = NULL;

	if (lpszTricsData == NULL || lpszTricsData[0] == 0)
		return S_OK;

	// Is it HTML ?
	USES_CONVERSION;
	if ((lpszTricsData[0] == OLECHAR('M') || lpszTricsData[0] == OLECHAR('m')) &&
		(lpszTricsData[1] == OLECHAR('S') || lpszTricsData[1] == OLECHAR('s')) &&
		(lpszTricsData[2] == OLECHAR('H') || lpszTricsData[2] == OLECHAR('h')) &&
		(lpszTricsData[3] == OLECHAR('T') || lpszTricsData[3] == OLECHAR('t')) &&
		(lpszTricsData[4] == OLECHAR('M') || lpszTricsData[4] == OLECHAR('m')) &&
		(lpszTricsData[5] == OLECHAR('L') || lpszTricsData[5] == OLECHAR('l')) &&
		(lpszTricsData[6] == OLECHAR(':')))
	{
		// It's HTML, so let's create mshtml
		hr = CoCreateInstance(__uuidof(HTMLDocument), NULL, CLSCTX_INPROC_SERVER, riid, ppvObj);
		otCreated = otMSHTML;
		lpszHTMLText = lpszTricsData + 7;
		return hr;
	}

	// Can't be clsid, or progid if length is greater than 255
	if (ocslen(lpszTricsData) > 255 || PathIsURLW(lpszTricsData))
	{
		// Treat as URL, pass to instance of web browser
		hr = CoCreateInstance(__uuidof(WebBrowser), NULL, CLSCTX_INPROC_SERVER, riid, ppvObj);
		if (FAILED(hr))
			lpszHTMLText = MAKEINTRESOURCEW(IDS_CANTCREATEIE);
		else
			otCreated = otWebBrowser;

		return hr;
	}
	else
	{
		if (lpszTricsData[0] == '{') // Is it a CLSID?
			hr = CLSIDFromString((LPOLESTR)lpszTricsData, &clsid);
		else
			hr = CLSIDFromProgID((LPOLESTR)lpszTricsData, &clsid); // How about a ProgID?

		if (FAILED(hr))
		{
			lpszHTMLText = MAKEINTRESOURCEW(IDS_INVALIDPROGID);
			return hr;
		}
	}

	// Its a valid CLSID/ProgId at least, so lets see if we can find a class factory
	CComPtr<IClassFactory> piFactory;
	hr = ::CoGetClassObject(clsid, (CLSCTX_INPROC_SERVER|CLSCTX_LOCAL_SERVER), NULL, IID_IClassFactory, (void**)&piFactory);
	if (FAILED(hr))
	{
		// Unable to access the class factory of the control
		lpszHTMLText = MAKEINTRESOURCEW(IDS_CANTGETCLASSOBJECT);
		return hr;
	}

	lpszHTMLText = MAKEINTRESOURCEW(IDS_CANTCREATECONTROL);

	// License key supplied?
	if (bstrLicKey != NULL)
	{
		// Licensed create request, so try using IClassFactory2
		CComQIPtr<IClassFactory2> piFactory2 = piFactory;
		if (piFactory2)
		{
			// Supports IClassFactory2, so try licensed create...
			if (bstrLicKey != NULL)
			{
				// License supplied
				hr = piFactory2->CreateInstanceLic(NULL, NULL, riid, bstrLicKey, ppvObj);
				if (SUCCEEDED(hr))
					return hr;	// Successfully created licensed control
				// else: License create failed, drop thru and try normal unlicensed create thru IClassFactory
			}
		}
		// else: IClassFactory2 not supported,so ignore the license (drop thru)
	}

	// Got the class factory, try CreateInstance
	hr = piFactory->CreateInstance(NULL, riid, ppvObj);
	if (FAILED(hr))
	{
		if (hr == CLASS_E_NOTLICENSED)
		{
			// OK, so try using IClassFactory2
			CComQIPtr<IClassFactory2> piFactory2 = piFactory;
			if (piFactory2)
			{
				_ASSERTE(bstrLicKey == NULL);
				// License not supplied (or we would not be here), so try requesting a runtime one
				CComBSTR bstrRuntimeKey;
				HRESULT hr2 = piFactory2->RequestLicKey(0, &bstrRuntimeKey);
				if (SUCCEEDED(hr2))
				{
					hr = piFactory2->CreateInstanceLic(NULL, NULL, riid, bstrRuntimeKey, ppvObj);
				}
			}
		}
	}

	return hr;
}

LRESULT CDolphinAxHost::OnPaint(UINT uMsg, WPARAM wParam, LPARAM lParam, BOOL& bHandled)
{
	if (m_spViewObject == NULL)
		return CAxHostWindow::OnPaint(uMsg, wParam, lParam, bHandled);

	if (m_spViewObject && m_bWindowless)
	{
		PAINTSTRUCT ps;
		HDC hdc = ::BeginPaint(m_hWnd, &ps);

		if (hdc == NULL)
			return 0;

		RECT rcClient;
		GetClientRect(&rcClient);

		HBITMAP hBitmap = CreateCompatibleBitmap(hdc, rcClient.right - rcClient.left, rcClient.bottom - rcClient.top);
		if (hBitmap != NULL)
		{
			HDC hdcCompatible = ::CreateCompatibleDC(hdc);
			if (hdcCompatible != NULL)
			{
				HBITMAP hBitmapOld = (HBITMAP)SelectObject(hdcCompatible, hBitmap); 
				if (hBitmapOld != NULL)
				{
					HBRUSH hbrBack = CreateSolidBrush(m_clrBackground);
					if (hbrBack != NULL)
					{
						FillRect(hdcCompatible, &rcClient, hbrBack);
						DeleteObject(hbrBack);

						// BSM attempts to avoid crash in Draw which some objects experience by adding DVASPECTINFO struct instead of passing NULL
						// also because we are drawing into a bitmap DC specially created for the purpose, optimized drawing is OK
						// but probably not worth doing since we would then have to reselect original items and delete
						// those left by the control.

						DVASPECTINFO dvaInfo;
						dvaInfo.cb = sizeof(dvaInfo);
						dvaInfo.dwFlags = 0; //DVASPECTINFOFLAG_CANOPTIMIZE;

						// BSM bug fix - pass null for lprcWBounds since we are not drawing to a metafile
						m_spViewObject->Draw(DVASPECT_CONTENT, -1, &dvaInfo, NULL, NULL, hdcCompatible, (RECTL*)&m_rcPos, (RECTL*)&m_rcPos, NULL, NULL); 

						// End of BSM bug fixes
						// Original code
						//m_spViewObject->Draw(DVASPECT_CONTENT, -1, NULL, NULL, NULL, hdcCompatible, (RECTL*)&m_rcPos, (RECTL*)&m_rcPos, NULL, NULL); 

						::BitBlt(hdc, 0, 0, rcClient.right, rcClient.bottom,  hdcCompatible, 0, 0, SRCCOPY);
					}
					::SelectObject(hdcCompatible, hBitmapOld); 
				}
				::DeleteDC(hdcCompatible);
			}
			::DeleteObject(hBitmap);
		}
		::EndPaint(m_hWnd, &ps);
	}
	else
	{
		bHandled = FALSE;
		return 0;
	}
	return 1;
}

/////////////////////////////////////////////////////////////////
// *** BSM BUG FIX (see MSDN article Q242994
//
STDMETHODIMP CDolphinAxHost::OnPosRectChange(LPCRECT /*lprcPosRect*/)
{
	ATLTRACE2(atlTraceHosting, 0, 	_T("IOleInPlaceSite::OnPosRectChange"));

/*
	// Hmmmm, if we do this we get an infinite loop in layout manager

	// Use MoveWindow() to resize the CAxHostWindow.
	// The CAxHostWindow handler for OnSize() will
	// take care of calling IOleInPlaceObject::SetObjectRects().

	// Convert to parent window coordinates for MoveWindow().
	RECT rect = *lprcPosRect;
	ClientToScreen( &rect );
	HWND hWnd = GetParent();

	// Check to make sure it's a non-top-level window.
	if(hWnd != NULL)
	{
		CWindow wndParent(hWnd);
		wndParent.ScreenToClient(&rect);
		wndParent.Detach ();
	}

	MoveWindow( &rect);
*/

	GetClientRect(&m_rcPos);
	m_pxSize.cx = m_rcPos.right - m_rcPos.left;
	m_pxSize.cy = m_rcPos.bottom - m_rcPos.top;

	AtlPixelToHiMetric(&m_pxSize, &m_hmSize);

	if (m_spInPlaceObjectWindowless)
		m_spInPlaceObjectWindowless->SetObjectRects(&m_rcPos, &m_rcPos);
	if (m_bWindowless)
		InvalidateRect(NULL, TRUE);

	return S_OK;	
} 

// Copied from AtlAxWindowProc(2). Only the WM_CREATE is different (simplified to remove control
// creation from the window title)
LRESULT CALLBACK CDolphinAxHost::WindowProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	switch(uMsg)
	{
	case WM_CREATE:
		{
			// This is to make sure drag drop works
			::OleInitialize(NULL);

			IAxWinHostWindowLic* pAxWindow = NULL;

			USES_CONVERSION;
			CComPtr<IUnknown> spUnk;
			HRESULT hRet = CreateHost(hWnd, &spUnk);
			if(FAILED(hRet))
			{
#ifdef _DEBUG
				LPTSTR pszMsg = NULL;
				::FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER|FORMAT_MESSAGE_FROM_SYSTEM, NULL, hRet, 0, (LPTSTR)&pszMsg, 0, NULL);
				ATLTRACE(atlTraceControls, 0, _T("Control host creation failed\n.Error code: 0x%x - %s"), hRet, pszMsg);
				::LocalFree(pszMsg);
#endif
				return -1;	// abort window creation
			}
			hRet = spUnk->QueryInterface(__uuidof(IAxWinHostWindowLic), (void**)&pAxWindow);
			if(FAILED(hRet))
				return -1;	// abort window creation

			::SetWindowLongPtr(hWnd, GWLP_USERDATA, (DWORD_PTR)pAxWindow);
		// continue with DefWindowProc
		}
		break;
	case WM_NCDESTROY:
		{
			IAxWinHostWindow* pAxWindow = (IAxWinHostWindowLic*)::GetWindowLongPtr(hWnd, GWLP_USERDATA);
			if(pAxWindow != NULL)
				pAxWindow->Release();
			OleUninitialize();
		}
		break;

	case WM_PARENTNOTIFY:
		{
			if((UINT)wParam == WM_CREATE)
			{
				ATLASSERT(lParam);
				// Set the control parent style for the AxWindow
				DWORD dwExStyle = ::GetWindowLong((HWND)lParam, GWL_EXSTYLE);
				if(dwExStyle & WS_EX_CONTROLPARENT)
				{
					dwExStyle = ::GetWindowLong(hWnd, GWL_EXSTYLE);
					dwExStyle |= WS_EX_CONTROLPARENT;
					::SetWindowLong(hWnd, GWL_EXSTYLE, dwExStyle);
				}
			}
		}
		break;

	default:
		break;
	}

	return ::DefWindowProc(hWnd, uMsg, wParam, lParam);
}

HRESULT CDolphinAxHost::CreateHost(HWND hWnd, IUnknown** ppUnkContainer)
{
	*ppUnkContainer = NULL;

	HRESULT hr;
	CComPtr<IUnknown> spUnkContainer;
	CComPtr<IUnknown> spUnkControl;

	hr = CDolphinAxHost::_CreatorClass::CreateInstance(NULL, __uuidof(IUnknown), (void**)&spUnkContainer);
	if (FAILED(hr))
		return hr;

	// Bit of a waste of time calling this just to subclass the window handle, but there doesn't
	// seem to be any other way to do it short of adding another interface, or instantiating the object
	// differently.
	CComPtr<IAxWinHostWindowLic> pAxWindow;
	spUnkContainer->QueryInterface(__uuidof(IAxWinHostWindowLic), (void**)&pAxWindow);
	hr = pAxWindow->CreateControlLicEx(L"", hWnd, NULL, &spUnkControl, IID_NULL, NULL, NULL);
	if (FAILED(hr))
		return hr;
	ASSERT(spUnkControl == NULL);

	*ppUnkContainer = spUnkContainer.Detach();

	return hr;
}

STDMETHODIMP CDolphinAxHost::CreateControlLicEx(LPCOLESTR lpszTricsData, HWND hWnd, IStream* pStream, IUnknown** ppUnk, REFIID iidAdvise, IUnknown* punkSink, BSTR bstrLic)
{
	ATLASSERT(ppUnk != NULL);
	if (ppUnk == NULL)
		return E_POINTER;
	*ppUnk = NULL;
	HRESULT hr = S_FALSE;
	bool bReleaseWindowOnFailure = false; // Used to keep track of whether we subclass the window

	ReleaseAll();

	if ((m_hWnd != NULL) && (m_hWnd != hWnd)) // Don't release the window if it's the same as the one we already subclass/own
	{
		RedrawWindow(NULL, NULL, RDW_INVALIDATE | RDW_UPDATENOW | RDW_ERASE | RDW_INTERNALPAINT | RDW_FRAME);
		ReleaseWindow();
	}

	if (::IsWindow(hWnd))
	{
		USES_CONVERSION;
		if (m_hWnd != hWnd) // Don't need to subclass the window if we already own it
		{
			SubclassWindow(hWnd);
			bReleaseWindowOnFailure = true;
		}
		if (m_clrBackground == NULL)
		{
			if (IsParentDialog())
				m_clrBackground = GetSysColor(COLOR_BTNFACE);
			else
				m_clrBackground = GetSysColor(COLOR_WINDOW);
		}

		// BSM change begins - neater handling of errors, returns an error code in 
		// the HTML text which can be loaded as a string and reported in MSHTML control
		// also can create licensed controls
		NormalizedObjectType otCreated;
		LPCOLESTR lpszHTMLText;
		HRESULT hrCreate = hr = CreateNormalizedObject(lpszTricsData, __uuidof(IUnknown), (void**)ppUnk, otCreated, lpszHTMLText, bstrLic);
		if (FAILED(hr))
		{
			// Failed for some reason, probably available in the HTML text
			// Try and create an MSHTML instance to display the error.
			otCreated = otMSHTML;
			hr = CoCreateInstance(__uuidof(HTMLDocument), NULL, CLSCTX_INPROC_SERVER, __uuidof(IUnknown), (void**)ppUnk);
		}

		if (SUCCEEDED(hr))
			hr = ActivateAx(*ppUnk, hr == S_FALSE, pStream);

		//Try to hook up any sink the user might have given us.
		m_iidSink = iidAdvise;
		if(SUCCEEDED(hr) && *ppUnk && punkSink)
			AtlAdvise(*ppUnk, punkSink, m_iidSink, &m_dwAdviseSink);

		if (SUCCEEDED(hr) && (otCreated != otOther) && *ppUnk != NULL)
		{
			if ((GetStyle() & (WS_VSCROLL | WS_HSCROLL)) == 0)
				m_dwDocHostFlags |= DOCHOSTUIFLAG_SCROLL_NO;
			else
			{
				DWORD dwStyle = GetStyle();
				SetWindowLong(GWL_STYLE, dwStyle & ~(WS_VSCROLL | WS_HSCROLL));
				SetWindowPos(NULL, 0, 0, 0, 0, SWP_NOACTIVATE | SWP_NOMOVE | SWP_NOZORDER | SWP_NOSIZE | SWP_FRAMECHANGED | SWP_DRAWFRAME);
			}

			CComPtr<IUnknown> spUnk(*ppUnk);
			// Is it just plain HTML?
			USES_CONVERSION;
			if (otCreated == otMSHTML)
			{
				// Just HTML: load the HTML data into the document

				if (IS_INTRESOURCE(lpszHTMLText))
				{
					// Build error report HTML text
					char szErrorMsg[128];
					::LoadString(GetResLibHandle(), LOWORD(lpszHTMLText), szErrorMsg, sizeof(szErrorMsg)-1);
					char szErrorFormat[128];
					::LoadString(GetResLibHandle(), IDS_AXSITEERRORFMT, szErrorFormat, sizeof(szErrorFormat)-1);
					char szOsErrMsg[256] = "";
					::FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM|
									FORMAT_MESSAGE_IGNORE_INSERTS,
									NULL, hrCreate, 0, 
									szOsErrMsg, (sizeof(szOsErrMsg)/sizeof(char))-1, 
									NULL);
					LPSTR buf;
					DWORD args[4];
					args[0] = DWORD(W2A(lpszTricsData));
					args[1] = hrCreate;
					args[2] = DWORD(szErrorMsg);
					args[3] = DWORD(szOsErrMsg);
					::FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER | 
									FORMAT_MESSAGE_FROM_STRING |
									FORMAT_MESSAGE_ARGUMENT_ARRAY,
									szErrorFormat, 0, 0, LPSTR(&buf), 0, 
									(va_list*)args);
					lpszHTMLText = A2W(buf);
					::LocalFree(buf);
				}

				UINT nCreateSize = ocslen(lpszHTMLText) * sizeof(OLECHAR);
				HGLOBAL hGlobal = GlobalAlloc(GHND, nCreateSize);
				if (hGlobal)
				{
					CComPtr<IStream> spStream;
					BYTE* pBytes = (BYTE*) GlobalLock(hGlobal);
					memcpy(pBytes, lpszHTMLText, nCreateSize);
					GlobalUnlock(hGlobal);
					hr = CreateStreamOnHGlobal(hGlobal, TRUE, &spStream);
					if (SUCCEEDED(hr))
					{
						CComPtr<IPersistStreamInit> spPSI;
						hr = spUnk->QueryInterface(__uuidof(IPersistStreamInit), (void**)&spPSI);
						if (SUCCEEDED(hr))
							hr = spPSI->Load(spStream);
					}
				}
				else
					hr = E_OUTOFMEMORY;
			}
			else
			{
				CComPtr<IWebBrowser2> spBrowser;
				spUnk->QueryInterface(__uuidof(IWebBrowser2), (void**)&spBrowser);
				if (spBrowser)
				{
					CComVariant ve;
					CComVariant vurl(lpszTricsData);
					spBrowser->put_Visible(ATL_VARIANT_TRUE);
					spBrowser->Navigate2(&vurl, &ve, &ve, &ve, &ve);
				}
			}

		}
		if (FAILED(hr) || m_spUnknown == NULL)
		{
			// We don't have a control or something failed so release
			ReleaseAll();

			if (m_hWnd != NULL)
			{
				RedrawWindow(NULL, NULL, RDW_INVALIDATE | RDW_UPDATENOW | RDW_ERASE | RDW_INTERNALPAINT | RDW_FRAME);
				if (FAILED(hr) && bReleaseWindowOnFailure) // We subclassed the window in an attempt to create this control, so we unsubclass on failure
					ReleaseWindow();
			}
		}
	}
	return hr;
}

STDMETHODIMP CDolphinAxHost::ShowObject()
{
	ATLTRACE2(atlTraceHosting, 2, _T("IOleClientSite::ShowObject\r\n"));

	HDC hdc = CWindowImpl<CAxHostWindow>::GetDC();
	if (hdc == NULL)
		return E_FAIL;
	if (m_spViewObject)
	{
		// BSM attempts to avoid crash in Draw which some objects experience by adding DVASPECTINFO struct instead of passing NULL
		DVASPECTINFO dvaInfo;
		dvaInfo.cb = sizeof(dvaInfo);
		dvaInfo.dwFlags = 0;

		// BSM bug fix - pass null for lprcWBounds since we are not drawing to a metafile
		m_spViewObject->Draw(DVASPECT_CONTENT, -1, &dvaInfo, NULL, NULL, hdc, (RECTL*)&m_rcPos, NULL/*(RECTL*)&m_rcPos*/, NULL, NULL); 
	}

	CWindowImpl<CAxHostWindow>::ReleaseDC(hdc);
	return S_OK;
}

// N.B. This replaces the call to AtlAxWinInit. If MS changes that function in later versions of the ATL
// library, this may need to be modified to reflect the changes too
BOOL __stdcall AxWinInit()
{
	WM_ATLGETHOST = RegisterWindowMessage(_T("WM_ATLGETHOST"));
	WM_ATLGETCONTROL = RegisterWindowMessage(_T("WM_ATLGETCONTROL"));

	WNDCLASSEX wc;
// first check if the class is already registered
	memset(&wc, 0, sizeof(WNDCLASSEX));
	wc.cbSize = sizeof(WNDCLASSEX);
	BOOL bRet = ::GetClassInfoEx(_AtlBaseModule.GetModuleInstance(), CDolphinAxHost::GetWndClassName(), &wc);

// register class if not

	if(!bRet)
	{
		wc.cbSize = sizeof(WNDCLASSEX);

		wc.style = CS_GLOBALCLASS | CS_DBLCLKS;

		wc.lpfnWndProc = CDolphinAxHost::WindowProc;
		wc.cbClsExtra = 0;
		wc.cbWndExtra = 0;
		wc.hInstance = _AtlBaseModule.GetModuleInstance();
		wc.hIcon = NULL;
		wc.hCursor = ::LoadCursor(NULL, IDC_ARROW);
		wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
		wc.lpszMenuName = NULL;
		wc.lpszClassName = CDolphinAxHost::GetWndClassName();
		wc.hIconSm = NULL;

		bRet = (BOOL)::RegisterClassEx(&wc);
	}

	return bRet;
}

BOOL __stdcall AxWinTerm()
{
	UnregisterClass(CDolphinAxHost::GetWndClassName(), _AtlBaseModule.GetModuleInstance());
	return TRUE;
}

