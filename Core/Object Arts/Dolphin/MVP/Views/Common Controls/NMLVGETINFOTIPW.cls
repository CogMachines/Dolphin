﻿"Filed out from Dolphin Smalltalk 7"!

NMGETINFOTIP subclass: #NMLVGETINFOTIPW
	instanceVariableNames: ''
	classVariableNames: '_OffsetOf_cchTextMax _OffsetOf_dwFlags _OffsetOf_iItem _OffsetOf_iSubItem _OffsetOf_lParam _OffsetOf_pszText'
	poolDictionaries: ''
	classInstanceVariableNames: ''!
NMLVGETINFOTIPW guid: (GUID fromString: '{cfd19e11-86a3-4b65-ae78-55b3c8c34b0c}')!
NMLVGETINFOTIPW addClassConstant: '_OffsetOf_cchTextMax' value: 16r14!
NMLVGETINFOTIPW addClassConstant: '_OffsetOf_dwFlags' value: 16rC!
NMLVGETINFOTIPW addClassConstant: '_OffsetOf_iItem' value: 16r18!
NMLVGETINFOTIPW addClassConstant: '_OffsetOf_iSubItem' value: 16r1C!
NMLVGETINFOTIPW addClassConstant: '_OffsetOf_lParam' value: 16r20!
NMLVGETINFOTIPW addClassConstant: '_OffsetOf_pszText' value: 16r10!
NMLVGETINFOTIPW comment: ''!
!NMLVGETINFOTIPW categoriesForClass!External-Data-Structured-Win32! !
!NMLVGETINFOTIPW methodsFor!

cchTextMax
	"Answer the <Integer> value of the receiver's 'cchTextMax' field."

	^bytes sdwordAtOffset: _OffsetOf_cchTextMax!

dwFlags
	"Answer the <Integer> value of the receiver's 'dwFlags' field."

	^bytes dwordAtOffset: _OffsetOf_dwFlags!

iItem
	"Answer the <Integer> value of the receiver's 'iItem' field."

	^bytes sdwordAtOffset: _OffsetOf_iItem!

iSubItem
	"Answer the <Integer> value of the receiver's 'iSubItem' field."

	^bytes sdwordAtOffset: _OffsetOf_iSubItem!

itemHandle
	"Answer the 'handle' of the receiver's item."

	^self iItem + 1!

pszText
	"Answer the <ExternalAddress> value of the receiver's 'pszText' field."

	^(bytes uintPtrAtOffset: _OffsetOf_pszText) asExternalAddress! !
!NMLVGETINFOTIPW categoriesFor: #cchTextMax!**compiled accessors**!public! !
!NMLVGETINFOTIPW categoriesFor: #dwFlags!**compiled accessors**!public! !
!NMLVGETINFOTIPW categoriesFor: #iItem!**compiled accessors**!public! !
!NMLVGETINFOTIPW categoriesFor: #iSubItem!**compiled accessors**!public! !
!NMLVGETINFOTIPW categoriesFor: #itemHandle!accessing!public! !
!NMLVGETINFOTIPW categoriesFor: #pszText!**compiled accessors**!public! !

!NMLVGETINFOTIPW class methodsFor!

defineFields
	"Define the structure template for Win32 NMLVGETINFOTIPW structure.
	Implementation Note: We define the text field as an address because we
	need to write back to the buffer pointed at by that field rather than overwrite
	it.

		self compileDefinition

		typedef struct tagNMLVGETINFOTIPW
		{
			NMHDR hdr;
			DWORD dwFlags;
			LPWSTR pszText;
			int cchTextMax;
			int iItem;
			int iSubItem;
			LPARAM lParam;
		} NMLVGETINFOTIPW, *LPNMLVGETINFOTIPW;"

	super defineFields.
	self
		defineField: #dwFlags type: DWORDField readOnly;
		defineField: #pszText type: LPVOIDField readOnly;
		defineField: #cchTextMax type: SDWORDField readOnly;
		defineField: #iItem type: SDWORDField readOnly;
		defineField: #iSubItem type: SDWORDField readOnly;
		defineField: #lParam type: INT_PTRField filler!

getFieldNames
	^#(#hwndFrom #idFrom #code #dwFlags #pszText #cchTextMax #iItem #iSubItem)! !
!NMLVGETINFOTIPW class categoriesFor: #defineFields!initializing!public! !
!NMLVGETINFOTIPW class categoriesFor: #getFieldNames!**compiled accessors**!constants!private! !

