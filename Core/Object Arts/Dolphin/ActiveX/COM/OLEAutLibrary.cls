﻿"Filed out from Dolphin Smalltalk 7"!

ExternalLibrary subclass: #OLEAutLibrary
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	classInstanceVariableNames: ''!
OLEAutLibrary guid: (GUID fromString: '{6467404a-3a82-101b-8181-00aa003743d3}')!
OLEAutLibrary comment: 'OLEAutLibrary is the <ExternalLibrary> class to represent the Win32 System DLL, OLEAUT32.DLL.
This library contains functions pertaining to the use of Active-X Automation.'!
!OLEAutLibrary categoriesForClass!ActiveX Automation!External-Libraries-ActiveX! !
!OLEAutLibrary methodsFor!

getErrorInfo: dwReserved pperrinfo: pperrinfo
	"Loads _and registers_ a type library from the specified path.

		HRESULT GetErrorInfo(
			ULONG			dwReserved,
			IErrorInfo**		pperrinfo
		)"

	<stdcall: hresult GetErrorInfo dword lppvoid>
	^self invalidCall
!

sysAllocString: aUtf16String
	"Allocates and answer a new Basic string which is a copy of the 
	argument, aUtf16String. Answers NULL if there is insufficient memory.

		BSTR SysAllocString(OLECHAR FAR* sz);
	"

	<stdcall: bstr SysAllocString lpvoid>
	#todo "Relax lpwstr to accept int args".
	^self invalidCall!

sysFreeString: aBSTR
	"Free a Basic string previously allocated with 
	SysAllocString, etc.

		void SysFreeString(BSTR bstr)
	"

	<stdcall: void SysFreeString BSTR>
	^self invalidCall!

sysStringByteLen: aBSTR
	"Answer the length (in bytes) of a Basic string previously allocated with 
	SysAllocString, etc, including any null characters except the terminating null.

		HRESULT SysStringByteLen(BSTR bstr); 
	"

	<stdcall: hresult SysStringByteLen BSTR>
	^self invalidCall!

sysStringLen: aBSTR
	"Answer the length (in characters) of a Basic string previously allocated with 
	SysAllocString, etc, including any null characters except the terminating null.

		HRESULT SysStringLen(BSTR bstr); 
	"

	<stdcall: hresult SysStringLen BSTR>
	^self invalidCall! !
!OLEAutLibrary categoriesFor: #getErrorInfo:pperrinfo:!Automation Functions-Error Handling API!primitives!public! !
!OLEAutLibrary categoriesFor: #sysAllocString:!Automation Functions-String Manipulation!primitives!public! !
!OLEAutLibrary categoriesFor: #sysFreeString:!Automation Functions-String Manipulation!primitives!public! !
!OLEAutLibrary categoriesFor: #sysStringByteLen:!Automation Functions-String Manipulation!primitives!public! !
!OLEAutLibrary categoriesFor: #sysStringLen:!Automation Functions-String Manipulation!primitives!public! !

!OLEAutLibrary class methodsFor!

fileName
	"Answer the host system file name of the external library which
	the receiver represents."

	^'OLEAUT32'! !
!OLEAutLibrary class categoriesFor: #fileName!constants!public! !

