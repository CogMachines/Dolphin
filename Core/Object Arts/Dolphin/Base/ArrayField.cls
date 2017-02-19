"Filed out from Dolphin Smalltalk 7"!

EmbeddedField subclass: #ArrayField
	instanceVariableNames: 'arrayLength'
	classVariableNames: ''
	poolDictionaries: ''
	classInstanceVariableNames: ''!
ArrayField guid: (GUID fromString: '{87b4c4de-026e-11d3-9fd7-00a0cc3e4a32}')!
ArrayField comment: 'ArrayField is an <ExternalField> type to represent <ExternalStructure> fields which are fixed arrays whose contents are actually embedded in the structure, as opposed to being merely pointed at from the structure.

Instance Variables:
	length		<SmallInteger> or <Symbol>. Either the integer length of fixed arrays, or the symbolic name of the length field for conformant arrays.

'!
!ArrayField categoriesForClass!External-Data-Types! !
!ArrayField methodsFor!

alignment
	"Answer the alignment requirements for the receiver.
	This is the default alignment required for a field of the receiver's type
	when embedded in an array or structure, generally speaking this is the
	same as the byte size."

	^self elementSize!

allocationLength
	^arrayLength allocationLength!

arrayClass
	"Private - Answer the class of <ExternalArray> that this field type describes."

	^fieldClass!

arrayLength: anArrayFieldLength
	arrayLength := anArrayFieldLength!

byteSize
	"Private - Answer the byte size of the embedded array the receiver represents.
	By default we assume that the length of the receiver is specified in bytes."

	"N.B. We use the length variable directly, rather than sending the length message as we need
	the allocation length, not the element count (the latter excludes null-terminators)"

	^arrayLength allocationLength * self elementSize!

elementClass
	"Private - Answer the byte size of the structures/values that constitute
	the elements of the embedded array the receiver represents."

	^self arrayClass elementClass!

elementSize
	"Private - Answer the byte size of the structures/values that constitute
	the elements of the embedded array the receiver represents."

	^self arrayClass elementSize!

elementSizeSelector
	^#elementSize!

isFixedSize
	^arrayLength isFixedSize!

length
	"Private - Answer the length of the embedded array represented by the receiver."

	#deprecated.
	^self allocationLength!

printAccessorExpressionSuffixOn: aWriteStream
	"Private - Print any extra messages/statements onto the <puttableStream> argument that are required to
	configure the object being read from the structure instance."

	"We need to set the length of the array"

	aWriteStream
		space;
		display: #length:;
		space.
	arrayLength printElementCountExpressionFor: self on: aWriteStream!

printElementSizeExpressionBodyOn: stream 
	stream
		display: self arrayClass;
		space;
		display: #elementSize!

printFieldSizeExpressionBodyOn: aWriteStream
	arrayLength printElementCountExpressionFor: self on: aWriteStream.
	aWriteStream nextPutAll: ' * '.
	self isFixedSize
		ifTrue: [self printElementSizeExpressionBodyOn: aWriteStream]
		ifFalse: [self printStaticElementSizeExpressionOn: aWriteStream]!

printFieldSizeExpressionOn: aWriteStream 
	self isFixedSize 
		ifTrue: 
			[self emitStaticExpression: [:stream | self printFieldSizeExpressionBodyOn: stream] on: aWriteStream]
		ifFalse: [self printFieldSizeExpressionBodyOn: aWriteStream]!

printMutatorBody: aSymbol on: aWriteStream
	"Private - Print a suitable statement or statement onto the specified <puttableStream> which
	will write the value of this field into an isntance of the structure. The field in question
	is after the fields in the <sequencedReadableCollection> that is the 2nd argument."

	| keywords valueParam |
	valueParam := self valueParameterName.
	aWriteStream
		nextPutAll: '| size |';
		crtab;
		nextPutAll: 'size := (';
		nextPutAll: valueParam;
		space;
		display: #byteSize.
	"Null terminator is included in the reported byteSize, but not the size/basicSize"
	self arrayClass isNullTerminated
		ifTrue: 
			[aWriteStream nextPutAll: ' - '.
			self printStaticElementSizeExpressionOn: aWriteStream].
	self isFixedSize
		ifTrue: 
			[aWriteStream
				nextPutAll: ') ';
				display: #min:;
				nextPutAll: ' ('.
			self printFieldSizeExpressionOn: aWriteStream].
	keywords := #replaceBytesOf:from:to:startingAt: keywords.
	aWriteStream
		nextPutAll: ').';
		crtab;
		nextPutAll: valueParam;
		space;
		display: keywords first;
		nextPutAll: ' bytes ';
		display: keywords second;
		space.
	self
		printOffsetExpression: aSymbol
		on: aWriteStream
		extra: 1.
	aWriteStream
		space;
		display: keywords third;
		space.
	self offset = 0
		ifFalse: 
			[self printOffsetExpression: aSymbol on: aWriteStream.
			aWriteStream nextPutAll: ' + '].
	aWriteStream
		nextPutAll: 'size ';
		display: keywords fourth;
		nextPutAll: ' 1.';
		crtab.
	arrayLength printSetSizeFor: self on: aWriteStream!

printStaticElementSizeExpressionOn: aWriteStream
	self emitStaticExpression: [:stream | self printElementSizeExpressionBodyOn: stream]
		on: aWriteStream!

readFrom: anExternalStructure
	"Private - Answer an byte-object array of the type described by the receiver, and of the
	size described by the receiver, which is either an <ExternalArray> reference to the data in
	the <ExternalStructure> argument at the receiver's offset, or a <ByteArray> copy of the data
	at that offset."

	^self arrayClass fromAddress: anExternalStructure yourAddress + offset
		length: (arrayLength getElementCountOf: ExternalField new in: anExternalStructure)!

writeInto: anExternalStructure value: anObject
	"Private - Write the bytes of anObject into anExternal."

	| byteSize |
	byteSize := self isFixedSize
				ifTrue: 
					[anObject byteSize
						min: (arrayLength getElementCountOf: ExternalField new in: anExternalStructure) * self elementSize]
				ifFalse: [anObject byteSize].
	anExternalStructure bytes
		replaceFrom: offset + 1
		to: offset + byteSize
		with: anObject
		startingAt: 1.
	arrayLength
		setElementCount: anObject
		of: self
		in: anExternalStructure! !
!ArrayField categoriesFor: #alignment!constants!public! !
!ArrayField categoriesFor: #allocationLength!accessing!private! !
!ArrayField categoriesFor: #arrayClass!constants!private! !
!ArrayField categoriesFor: #arrayLength:!accessing!private! !
!ArrayField categoriesFor: #byteSize!accessing!private! !
!ArrayField categoriesFor: #elementClass!accessing!private! !
!ArrayField categoriesFor: #elementSize!accessing!private! !
!ArrayField categoriesFor: #elementSizeSelector!automatic generation!constants!private! !
!ArrayField categoriesFor: #isFixedSize!private!testing! !
!ArrayField categoriesFor: #length!accessing!private! !
!ArrayField categoriesFor: #printAccessorExpressionSuffixOn:!automatic generation!development!private! !
!ArrayField categoriesFor: #printElementSizeExpressionBodyOn:!automatic generation!private! !
!ArrayField categoriesFor: #printFieldSizeExpressionBodyOn:!automatic generation!private! !
!ArrayField categoriesFor: #printFieldSizeExpressionOn:!automatic generation!private! !
!ArrayField categoriesFor: #printMutatorBody:on:!automatic generation!development!private! !
!ArrayField categoriesFor: #printStaticElementSizeExpressionOn:!automatic generation!private! !
!ArrayField categoriesFor: #readFrom:!indirect accessing!private! !
!ArrayField categoriesFor: #writeInto:value:!indirect accessing!private! !

!ArrayField class methodsFor!

type: aClass arrayLength: anArrayFieldLength
	"Answer a new instance of the receiver which is used for describing embedded array objects
	of type, aClass, where the length is described by the <ArrayFieldLength> argument. The field
	could be fixed in length, or varying (conformant)."

	^(self basicNew)
		initialize;
		fieldClass: aClass;
		arrayLength: anArrayFieldLength;
		yourself!

type: aClass length: anInteger
	"Answer a new instance of the receiver which is used for describing
	embedded arrays of type aClass, with anInteger elements."

	^self type: aClass arrayLength: (FixedArrayFieldLength elementCount: anInteger)!

type: aClass lengthField: aSymbol
	"Answer a new instance of the receiver which is used for describing embedded conformant
	array objects of type, aClass, where the length is specified by the another field of the
	structure being described with the specified <Symbol> name."

	^self type: aClass arrayLength: (ConformantArrayFieldLength lengthField: aSymbol)! !
!ArrayField class categoriesFor: #type:arrayLength:!instance creation!public! !
!ArrayField class categoriesFor: #type:length:!instance creation!public! !
!ArrayField class categoriesFor: #type:lengthField:!instance creation!public! !
