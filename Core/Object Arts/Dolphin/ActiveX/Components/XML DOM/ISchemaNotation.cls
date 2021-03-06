﻿"Filed out from Dolphin Smalltalk 7"!

ISchemaItem subclass: #ISchemaNotation
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: 'MSXMLConstants'
	classInstanceVariableNames: ''!
ISchemaNotation guid: (IID fromString: '{50EA08BE-DD1B-4664-9A50-C2F40F4BD79A}')!
ISchemaNotation comment: '<ISchemaNotation> is a wrapper class for the COM interface ''MSXML2.ISchemaNotation'' generated from type information in the ''Microsoft XML, v4.0'' library. It contains methods to invoke the member functions exposed by that interface.

The type library contains the following helpstring for this interface
	"XML Schema Notation"

Warning: This comment was automatically generated from the interface''s type information, but any changes made here will not be overwritten if the wrapper class is regenerated.

IDL definition follows:

[
	object, 
	uuid(50EA08BE-DD1B-4664-9A50-C2F40F4BD79A), 
	helpstring("XML Schema Notation"), 
	dual, 
	nonextensible
]
interface ISchemaNotation : ISchemaItem
 {
	[id(0x000005c1), propget]
	HRESULT __stdcall systemIdentifier(
		[out, retval]BSTR* uri);
	[id(0x000005b9), propget]
	HRESULT __stdcall publicIdentifier(
		[out, retval]BSTR* uri);
};
'!
!ISchemaNotation categoriesForClass!COM-Interfaces!MSXML2-Interfaces! !
!ISchemaNotation methodsFor!

get_publicIdentifier: uri
	"Private - Get the value of the 'publicIdentifier' property of the receiver.

		HRESULT __stdcall publicIdentifier(
			[out, retval]BSTR* uri);"

	<virtual stdcall: hresult 16 bstr*>
	^self invalidCall!

get_systemIdentifier: uri
	"Private - Get the value of the 'systemIdentifier' property of the receiver.

		HRESULT __stdcall systemIdentifier(
			[out, retval]BSTR* uri);"

	<virtual stdcall: hresult 15 bstr*>
	^self invalidCall!

publicIdentifier
	"Answer the <bstr> value of the 'publicIdentifier' property of the receiver."

	| answer |
	answer := BSTR new.
	self get_publicIdentifier: answer.
	^answer asObject
!

systemIdentifier
	"Answer the <bstr> value of the 'systemIdentifier' property of the receiver."

	| answer |
	answer := BSTR new.
	self get_systemIdentifier: answer.
	^answer asObject
! !
!ISchemaNotation categoriesFor: #get_publicIdentifier:!**auto generated**!COM Interfaces-ISchemaNotation!private! !
!ISchemaNotation categoriesFor: #get_systemIdentifier:!**auto generated**!COM Interfaces-ISchemaNotation!private! !
!ISchemaNotation categoriesFor: #publicIdentifier!**auto generated**!properties!public! !
!ISchemaNotation categoriesFor: #systemIdentifier!**auto generated**!properties!public! !

!ISchemaNotation class methodsFor!

defineFunctions
	"Declare the virtual function table for the COM interface 'MSXML2.ISchemaNotation'
		ISchemaNotation defineTemplate"

	self
		defineFunction: #get_systemIdentifier:
			argumentTypes: 'bstr*';
		defineFunction: #get_publicIdentifier:
			argumentTypes: 'bstr*'
! !
!ISchemaNotation class categoriesFor: #defineFunctions!**auto generated**!initializing!public! !

