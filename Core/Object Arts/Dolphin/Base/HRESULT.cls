﻿"Filed out from Dolphin Smalltalk 7"!

ExternalInteger subclass: #HRESULT
	instanceVariableNames: ''
	classVariableNames: 'Facilities Fail'
	poolDictionaries: 'FacilityCodes Win32Constants Win32Errors'
	classInstanceVariableNames: ''!
HRESULT guid: (GUID fromString: '{87b4c5ae-026e-11d3-9fd7-00a0cc3e4a32}')!
HRESULT comment: ''!
!HRESULT categoriesForClass!External-Data-Unstructured! !
!HRESULT methodsFor!

asSignedInteger
	"Answer the signed 32-bit <Integer> value of the receiver."

	^bytes sdwordAtOffset: 0!

asUnsignedInteger
	"Answer the unsigned 32-bit <Integer> value of the receiver."

	^bytes dwordAtOffset: 0!

displayOn: aStream
	"Append a textual representation of the receiver to aStream.
		(HRESULT fromInteger: Win32Errors.E_ABORT) displayString.
	"

	| buf len |
	buf := Utf16String newFixed: 255.
	len := KernelLibrary default
				formatMessage: ##(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS)
				lpSource: 0
				dwMessageId: self asInteger
				dwLanguageId: 0
				lpBuffer: buf
				nSize: buf size + 1
				arguments: 0.
	len == 0
		ifTrue: 
			[aStream
				nextPutAll: 'Unrecognised HRESULT - ';
				nextPutAll: (self asUnsignedInteger printStringRadix: 16)]
		ifFalse: 
			["Windows appends trailing line delimiter, and breaks up the text into lines too, 
			so we remove them."
			(buf resize: len) lines do: [:each | aStream nextPutAll: each] separatedBy: [aStream space]]!

errorCode
	"Answer the Win32 status code extracted from the receiver's code."

	^self asUnsignedInteger maskClear: ##(8191 bitShift: 16)!

facility
	"Answer a string describing the facility of the receiver's HRESULT code."

	^Facilities at: self facilityCode ifAbsent: ['Unknown facility']!

facilityCode
	"Answer the Win32 facility code extracted from the receiver's code.

		#define HRESULT_FACILITY(hr)  (((hr) >> 16) & 0x1fff)"

	^(self asUnsignedInteger bitShift: -16) bitAnd: 16r1FFF!

failed
	"Answer whether the receiver represents the result of a failed operation
	(named for compatibility with the C/C++ FAILED macro)."

	^self asUnsignedInteger anyMask: 16r80000000!

isSeverityError
	"Answer whether the receiver is a SEVERITY_ERROR code."

	^self severity == SEVERITY_ERROR!

printOn: aStream
	"Append a debug textual representation of the receiver to aStream."

	aStream
		basicPrint: self;
		nextPutAll: '(0x'.
	self asUnsignedInteger printOn: aStream base: 16 showRadix: false.
	aStream
		nextPutAll: ' - ';
		display: self;
		nextPut: $)!

severity
	"Answer the severity of the HRESULT (1 for errors, otherwise 0)."

	^(self asInteger bitShift: -31) bitAnd: 16r1!

statusCode
	"Answer the Win32 status code extracted from the receiver.

		#define HRESULT_CODE(hr)	((hr) & 0xFFFF)"

	^self asUnsignedInteger bitAnd: 16rFFFF!

succeeded
	"Answer whether the receiver represents the result of a successful operation
	(named for compatibility with the C/C++ SUCCEEDED macro)."

	^self failed not!

unsignedValue: anUnsigned
	"Set the receiver's value field to the value of the unsigned positive
	integer, anUnsigned."

	bytes dwordAtOffset: 0 put: anUnsigned!

value
	"Answer the <Integer> value of the receiver's 'value' field."

	^bytes sdwordAtOffset: _OffsetOf_value!

value: anInteger
	"Set the receiver's 'value' field to the value of the argument, anInteger"

	bytes sdwordAtOffset: _OffsetOf_value put: anInteger! !
!HRESULT categoriesFor: #asSignedInteger!converting!public! !
!HRESULT categoriesFor: #asUnsignedInteger!converting!public! !
!HRESULT categoriesFor: #displayOn:!displaying!public! !
!HRESULT categoriesFor: #errorCode!accessing!public! !
!HRESULT categoriesFor: #facility!accessing!public! !
!HRESULT categoriesFor: #facilityCode!accessing!public! !
!HRESULT categoriesFor: #failed!public!testing! !
!HRESULT categoriesFor: #isSeverityError!public!testing! !
!HRESULT categoriesFor: #printOn:!displaying!public! !
!HRESULT categoriesFor: #severity!accessing!public! !
!HRESULT categoriesFor: #statusCode!accessing!public! !
!HRESULT categoriesFor: #succeeded!public!testing! !
!HRESULT categoriesFor: #unsignedValue:!accessing!public! !
!HRESULT categoriesFor: #value!**compiled accessors**!public! !
!HRESULT categoriesFor: #value:!**compiled accessors**!public! !

!HRESULT class methodsFor!

defineFields
	"Define the fields of the ExternalInteger 'structure'. ExternalInteger subclasses
	have a single value."

	self defineField: #value type: SDWORDField new beOverride!

fail
	"Answer the generic failure HRESULT."

	^Fail!

fromUnsignedInteger: anUnsignedInteger
	"Answer a new instance of the receiver with contents copied from anInteger"

	^self new unsignedValue: anUnsignedInteger!

initialize
	"Private - Initialize the receiver's class variables.
		self initialize
	"

	Fail := self fromInteger: E_FAIL.
	Facilities := LookupTable new.
	FacilityCodes keysAndValuesDo: [:eachKey :eachValue | Facilities at: eachValue put: eachKey]!

notImplemented
	"Answer the 'not implemented' HRESULT."

	^self fromInteger: E_NOTIMPL!

ntStatusCode: anInteger
	"Make and answer an HRESULT from the NT status code, anInteger."

	^self fromUnsignedInteger: (anInteger bitOr: FACILITY_NT_BIT)!

ok
	"Answer the 'OK' HRESULT."

	^self fromInteger: S_OK!

registerFacility: anInteger name: aString 
	"Register the specified facility code name for the specified facility code"

	Facilities at: anInteger put: aString!

severity: sev facility: fac code: code
	"Private - Make and answer an HRESULT from the arguments."

	^self fromUnsignedInteger: (
		((sev bitAnd: 1) bitShift: 31) bitOr:
			(((fac bitAnd: 16r1FFF) bitShift: 16) bitOr: (code bitAnd: 16rFFFF)))
!

status: code facility: fac
	"Private - Make and answer an HRESULT from the arguments."

	^self severity: SEVERITY_ERROR facility: fac code: code!

unregisterFacility: anInteger 
	"Unregister the specified facility code name for the specified facility code"

	Facilities removeKey: anInteger ifAbsent: []!

win32Error: anInteger 
	^self 
		severity: SEVERITY_ERROR
		facility: FACILITY_WIN32
		code: anInteger! !
!HRESULT class categoriesFor: #defineFields!initializing!public! !
!HRESULT class categoriesFor: #fail!constants!instance creation!public! !
!HRESULT class categoriesFor: #fromUnsignedInteger:!instance creation!public! !
!HRESULT class categoriesFor: #initialize!development!initializing!private! !
!HRESULT class categoriesFor: #notImplemented!constants!instance creation!public! !
!HRESULT class categoriesFor: #ntStatusCode:!instance creation!public! !
!HRESULT class categoriesFor: #ok!constants!instance creation!public! !
!HRESULT class categoriesFor: #registerFacility:name:!public! !
!HRESULT class categoriesFor: #severity:facility:code:!instance creation!private! !
!HRESULT class categoriesFor: #status:facility:!instance creation!private! !
!HRESULT class categoriesFor: #unregisterFacility:!public! !
!HRESULT class categoriesFor: #win32Error:!instance creation!public! !

