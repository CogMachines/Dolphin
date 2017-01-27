"Filed out from Dolphin Smalltalk X6.1"!

ENHMETARECORD subclass: #EMRSETARCDIRECTION
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	classInstanceVariableNames: ''!
EMRSETARCDIRECTION guid: (GUID fromString: '{41D545C1-ED58-46F1-9B90-34EF56BD4213}')!
EMRSETARCDIRECTION comment: '<EMRSETARCDIRECTION> is an <ExternalStructure> class to wrap the struct ''Win32.EMRSETARCDIRECTION'' from type information in the ''Win32 API (ANSI). Derived from Bruce McKinney�s Hardcore Visual Basic Type Library'' library.

The type library contains no documentation for this struct

Warning: This comment was automatically generated from the struct''s type information, but any changes made here will not be overwritten if the wrapper class is regenerated.

IDL definition follows:

typedef [uuid(41D545C1-ED58-46F1-9B90-34EF56BD4213)]
struct tagEMRSETARCDIRECTION {
	EMR EMR;
	[helpstring("Specifies the arc direction in the advanced graphics mode.")] DWORD iArcDirection;
} EMRSETARCDIRECTION;
'!
!EMRSETARCDIRECTION categoriesForClass!Win32-Structs! !
!EMRSETARCDIRECTION methodsFor!

iArcDirection
	"Answer the receiver's iArcDirection field as a Smalltalk object."

	^bytes dwordAtOffset: ##(self offsetOf: #iArcDirection)!

iArcDirection: anObject 
	"Set the receiver's iArcDirection field to the value of anObject."

	bytes dwordAtOffset: ##(self offsetOf: #iArcDirection) put: anObject! !
!EMRSETARCDIRECTION categoriesFor: #iArcDirection!**compiled accessors**!public! !
!EMRSETARCDIRECTION categoriesFor: #iArcDirection:!**compiled accessors**!public! !

!EMRSETARCDIRECTION class methodsFor!

defineFields
	"Define the fields of the EMRSETARCDIRECTION structure.

	EMRSETARCDIRECTION  compileDefinition

		typedef [uuid(41D545C1-ED58-46F1-9B90-34EF56BD4213)]
		struct tagEMRSETARCDIRECTION {
			EMR EMR;
			[helpstring('Specifies the arc direction in the advanced graphics mode.')] DWORD iArcDirection;
		} EMRSETARCDIRECTION;
"

	super defineFields.
	self
		defineField: #iArcDirection
			type: DWORDField new
			offset: 8.
	self byteSize: 12!

iTypes
	"Answer the integer enhanced metafile record type id for this record class."

	^Array with: EMR_SETARCDIRECTION! !
!EMRSETARCDIRECTION class categoriesFor: #defineFields!**auto generated**!initializing!public! !
!EMRSETARCDIRECTION class categoriesFor: #iTypes!constants!public! !
