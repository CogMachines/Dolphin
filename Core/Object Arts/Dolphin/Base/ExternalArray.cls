﻿"Filed out from Dolphin Smalltalk 7"!

ExternalStructure subclass: #ExternalArray
	instanceVariableNames: 'length'
	classVariableNames: ''
	poolDictionaries: ''
	classInstanceVariableNames: ''!
ExternalArray guid: (GUID fromString: '{87b4c593-026e-11d3-9fd7-00a0cc3e4a32}')!
ExternalArray comment: 'ExternalArray is a specialized class of <ExternalStructure> to represent contiguous heterogeneous arrays of external types, be they scalar of structured. ExternalArray itself can be used to represent arrays of unsigned 8-bit integers (i.e. bytes). It and its various subclasses can be used for external interfacing tasks, such as where C arrays are expected.

StructureArray is the most general of the subclasses in that it supports arbitrary element types (represented by other ExternalStructures), and can in fact perform the task of the other subclasses such as DWORDArray. The more specialized subclasses do, however, offer much greater efficiency where they are applicable.

Specialized subclasses are provided for most standard intrinsic types; signed and unsigned integers of 16 and 32-bits, single and double precision floating point numbers, etc.

Instance Variables:
	length		<integer>. Number of elements in the instance.

'!
!ExternalArray categoriesForClass!External-Data-Structured! !
!ExternalArray methodsFor!

= comparand
	| size |
	self == comparand ifTrue: [^true].
	#todo "ANSI draft says must be same class, not just same species".
	(self species == comparand species) ifFalse: [^false].
	size := self size.
	size = comparand size ifFalse: [^false].
	1 to: size do: [ :i |
		(self at: i) = (comparand at: i)
			ifFalse: [^false]].
	^true!

appendToStream: puttableStream
	"Private - Append the receiver's elements to the argument, puttableStream.
	We can be able to do a fast block copy. Answer the receiver.
	Implementation note: Double dispatched from puttableStream>>nextPutAll:."

	puttableStream next: self byteSize putAll: bytes startingAt: 1!

asArray
	"Answer an <Array> containing the constituent elements of the receiver."

	^self collect: [:each | each]!

asOrderedCollection
	"Answer an <OrderedCollection> whose elements are those of the receiver
	The ordering is that of the #do: operation as implemented by the receiver,
	and the answer will normally be the same size as the receiver.
	Implementation Note: Although we might be able to perform this operation 
	faster for collections which keep a tally of their size (or can otherwise 
	access it without calculation) we must be careful NOT to provide a default 
	implementation which will cause a double enumeration for collections which must
	count their elements to determine their size, which may be very slow."

	| answer |
	answer := OrderedCollection new: self size.
	self do: [:elem | answer addLast: elem].
	^answer!

at: anInteger 
	"Answer the element of the receiver at the specified index.
	Raise an error if the index if out of bounds."

	(anInteger < 1 or: [anInteger > self size]) 
		ifTrue: [^self errorSubscriptBounds: anInteger].
	^self uncheckedAt: anInteger!

at: index ifAbsent: exceptionBlock 
	"Answer an <Object> which is the element of the receiver 
	at the specified index. If the index is out of bounds answer
	the result of evaluating the <niladicValuable> exceptionBlock."

	^(index > 0 and: [index <= self size]) 
		ifTrue: [self uncheckedAt: index]
		ifFalse: [exceptionBlock value]!

at: anInteger put: newValue 
	"Set the element of the receiver at the specified index.
	Raise an error if the index is out of bounds."

	(anInteger < 1 or: [anInteger > self size]) 
		ifTrue: [self errorSubscriptBounds: anInteger].
	^self uncheckedAt: anInteger put: newValue!

basicLength: anInteger
	"Private - Set the length (in elements, not bytes) of the receiver."
	
	length := anInteger!

binarySearchFor: anObject using: searchBlock 
	"Private - Answer the index at which anObject is located using a binary chop search based on searchBlock"

	^SequenceableCollection 
		binarySearch: self
		for: anObject
		using: searchBlock!

byteSize
	"Answer the total size in bytes of this array."

	^self elementSize * self length!

collect: transformer
	"Evaluate the <monadicValuable> argument, transformer, for each of the receiver's elements
	in the order defined by the receiver's implementation of #do:. Answer a new collection like
	the receiver containing the values returned by transformer on each evaluation."

	"Implementation Note: We use the special instance creation method #copyLikeOfSize: because
	the transformation block may evaluate to objects which cannot be stored as elements of this
	type of array and therefore we must store them in an <Array>."

	| answer size |
	size := self size.
	answer := self species new: size.
	self
		uncheckedFrom: 1
		to: size
		keysAndValuesDo: [:i :each | answer at: i put: (transformer value: each)].
	^answer!

copyFrom: start to: stop
	"Answer an object of the same species as the receiver
	containing a copy of the elements of the receiver starting at index start, 
	until index stop, inclusive."

	| len |
	len := stop - start + 1.
	^(self species new: len)
		replaceFrom: 1
		to: len
		with: self
		startingAt: start!

detect: discriminator
	"Evaluate the <monadicValuable> argument, discriminator, for each of the receiver's elements
	in the order defined by the receiver's implementation of #do:.
	Answer the first element for which discriminator evaluates to true. If none evaluates to true,
	report an error."

	^self detect: discriminator ifNone: [self errorNotFound: discriminator]!

detect: discriminator ifNone: exceptionHandler
	"Evaluate the <monadicValuable> argument, discriminator, for each of the receiver's 
	elements.  Answer the first element (in the #do: order) for which discriminator evaluates 
	to true. If none evaluates to true answer the result of evaluating the <niladicValuable> 
	argument, exceptionHandler.
	Implementation Note: It is important for Shared subclasses that the exceptionHandler is 
	not evaluated inside the enumeration in case it is a niladic block containing an explicit 
	return (we try to avoid explicit returns from critical sections, as these require an unwind)."

	self do: [:each | (discriminator value: each) ifTrue: [^each]].
	^exceptionHandler value!

displayOn: target
	"Append a textual representation of the receiver onto the <puttableStream> argument,
	target, in the format that an end-user might want to see it."

	target
		nextPut: $(.
	self isNull ifFalse: [
		self 
			do: [:element | target display: element]
			separatedBy: [target nextPut: $,; space]].
	target  nextPut: $).!

do: operation
	"Evaluate monadic value argument, operation, for each of the elements of the 
	receiver. Answers the receiver. The elements are evaluated in index order.
	Implementation Note: Implemented in terms of keysAndValuesDo: to reduce
	the burden of subclassing. Where performance is an issue subclasses may 
	want to override this."

	self keysAndValuesDo: [:i :elem | operation value: elem]!

do: operation separatedBy: separator
	"Evaluate the <monadicValuable> argument, operation, for each of the 
	receiver's elements, interspersed with evaluations of the <niladicValuable>
	argument, separator. The separator is first evaluated after the first
	element, and is not evaluated after the last element (i.e. it is not evaluated
	at all if there are less than two elements)."

	| sep |
	sep := [sep := separator].	"Switch to the real separator after first eval."
	self do: [:e |
		sep value.
		operation value: e]!

elementClass
	"Answer the class of <ExternalStructure> used to represent elements of the receiver."

	^self class elementClass!

elementSize
	"Private - Answer the size of the receiver's instances' constituent 
	elements in bytes."

	^self elementClass elementSize!

first
	^self at: 1!

from: start do: operation
	"Evaluate the <monadicValuable>, operation, for each element of the receiver
	from start, inclusive."

	self 
		from: start
		keysAndValuesDo: [:i :each | operation value: each]!

from: start keysAndValuesDo: operation 
	"Evaluate the <dyadicValuable>, operation, for each element of the receiver
	from the element with <integer> index, start, inclusive. A BoundsError will be
	raised if either start or stop is out of bounds."

	self 
		from: start
		to: self size
		keysAndValuesDo: operation!

from: startInteger to: stopInteger keysAndValuesDo: operation 
	"Evaluate the <dyadicValuable>, operation, for each element of the receiver
	between the <integer> indices, start and stop, inclusive with the element and its
	index as respectively the second and first arguments."

	"Implementation Note: Do the bounds check up front to avoid the need to check
	on each access."

	startInteger < 1 ifTrue: [self errorSubscriptBounds: startInteger].
	stopInteger > self size ifTrue: [self errorSubscriptBounds: stopInteger].
	self 
		uncheckedFrom: startInteger
		to: stopInteger
		keysAndValuesDo: operation!

includes: target
	"Answer whether the argument, target, is one of the elements of the receiver.
	Implementation Note: Override superclass to revert to element search."

	1 to: self size do: [:i | target = (self at: i) ifTrue: [^true]].
	^false!

includesKey: anInteger
	^anInteger between: 1 and: self size!

initializePointer
	length := 0!

inject: initialValue into: operation
	"Evaluate the <dyadicValuable> argument, operation, once for each element in the receiver, with
	that element as the second argument; and with the first argument as the value of the previous 
	evaluation, starting with the <Object> argument, initialValue. The operation must answer the value
	it wishes to have passed as its first argument the next time it is evaluated. The traversal is in the #do: 
	order. Answer the final value of the operation.
	This enumeration is particularly useful for performing summations and other statistical operations."

	| nextValue |
	nextValue := initialValue.
	self do: [:each | nextValue := operation value: nextValue value: each].
	^nextValue!

isEmpty
	"Answer whether the receiver contains no elements."

	^self size == 0
!

keys
	"Answer a <collection> containing the receiver's keys."

	^1 to: self size!

keysAndValuesDo: operation 
	"Evaluate the <dyadicValuable>, operation, for each element of the receiver
	with the index of that element and the element itself as the arguments.
	Implementation Note: Subclasses should override #from:to:keysAndValuesDo: rather 
	than this method, unless they have a slow implementation of #size."

	self 
		uncheckedFrom: 1
		to: self size
		keysAndValuesDo: operation!

last
	^self at: self size!

length
	"Answer the number of elements in the receiver."

	^length!

length: anInteger
	"Set the length (in elements, not bytes) of the receiver, resizing the
	bytes of the receiver to accomodate the new length.
	This is not private as it can be used to adjust the length of 
	pointer instances after creation."
	
	self basicLength: anInteger.
	self bytes resize: self byteSize!

lookup: keyInteger
	"Answer the value named by the <Integer> argument, keyInteger, or nil if there is no such key in the receiver."

	^(keyInteger > 0 and: [keyInteger <= self size]) ifTrue: [self uncheckedAt: keyInteger]!

notEmpty
	"Answer whether the receiver contains any elements."

	^self isEmpty not!

replaceBytesOf: aByteObject from: start to: stop startingAt: fromStart
	"Private - Standard method for transfering bytes from one variable
	byte object to another, normally double dispatched from #replaceFrom:to:with:startingAt:"

	^bytes replaceBytesOf: aByteObject from: start to: stop startingAt: fromStart-1*self elementSize+1!

replaceElementsOf: anIndexableObject from: startInteger to: stopInteger startingAt: startAtInteger
	"Private - Replace the indexable instance variables of the variable pointer object,
	anIndexableObject, between startInteger and stopInteger inclusive with values from the
	receiver starting from startAtInteger. Answers anIndexableObject."

	| offset |
	offset := startAtInteger - startInteger.
	startInteger to: stopInteger do: [:i | anIndexableObject basicAt: i put: (self at: offset + i)].
	^anIndexableObject!

replaceFrom: startInteger to: stopInteger with: aByteObject startingAt: startAtInteger 
	"Standard method for transfering bytes from one variable
	byte object to another. See String>>replaceFrom:to:with:startingAt:"

	| elemSize offset |
	elemSize := self elementSize.
	offset := (startInteger - 1) * elemSize.
	aByteObject 
		replaceBytesOf: self bytes
		from: 1 + offset
		to: stopInteger * elemSize
		startingAt: startAtInteger!

select: discriminator
	"Evaluate the <monadicValuable> argument, discriminator, for each of the receiver's elements.
	Answer a new <collection> like the receiver containing only those elements for which 
	the discriminator evaluates to true."

	| aStream |
	aStream := self species writeStream.
	self keysAndValuesDo: [:i :elem | 
		(discriminator value: elem) ifTrue: [aStream nextPut: elem]].
	^aStream contents!

size
	"Answer the number of elements in the receiver."
	
	^self length!

species
	"Answer the class of object to be used when copying the receiver."

	^Array!

uncheckedAt: anInteger 
	"Private - Answer an 16-bit unsigned <SmallInteger> representing the element of the 
	receiver at the specified <integer> index. No bounds checks are performed on the subscript."

	^bytes byteAtOffset: anInteger - 1!

uncheckedAt: indexInteger put: valueInteger 
	"Private - Replace the 16-bit unsigned integer value at the specified index in the receiver
	with the <integer> argument. No bounds checks are performed on the subscript."

	^bytes byteAtOffset: indexInteger - 1 put: valueInteger!

uncheckedFrom: startInteger to: stopInteger keysAndValuesDo: operation 
	"Private - Evaluate the <dyadicValuable>, operation, for each element of the receiver
	between the <integer> indices, start and stop, inclusive with the element and its
	index as respectively the second and first arguments. No bounds checking is
	performed. "

	"Subclasses should override this method in order to replace all #do: family enumerators 
	(#do:, #keysAndValuesDo:, #from:to:do:, and,	of course, #from:to:keysAndValuesDo:)."

	startInteger to: stopInteger do: [:i | operation value: i value: (self uncheckedAt: i)]! !
!ExternalArray categoriesFor: #=!public! !
!ExternalArray categoriesFor: #appendToStream:!double dispatch!private! !
!ExternalArray categoriesFor: #asArray!converting!public! !
!ExternalArray categoriesFor: #asOrderedCollection!converting!public! !
!ExternalArray categoriesFor: #at:!accessing!public! !
!ExternalArray categoriesFor: #at:ifAbsent:!accessing!public! !
!ExternalArray categoriesFor: #at:put:!accessing!public! !
!ExternalArray categoriesFor: #basicLength:!accessing!private! !
!ExternalArray categoriesFor: #binarySearchFor:using:!public!searching! !
!ExternalArray categoriesFor: #byteSize!accessing!public! !
!ExternalArray categoriesFor: #collect:!enumerating!public! !
!ExternalArray categoriesFor: #copyFrom:to:!copying!public! !
!ExternalArray categoriesFor: #detect:!public!searching! !
!ExternalArray categoriesFor: #detect:ifNone:!public!searching! !
!ExternalArray categoriesFor: #displayOn:!printing!private! !
!ExternalArray categoriesFor: #do:!enumerating!public! !
!ExternalArray categoriesFor: #do:separatedBy:!enumerating!public! !
!ExternalArray categoriesFor: #elementClass!constants!public! !
!ExternalArray categoriesFor: #elementSize!instance creation!private! !
!ExternalArray categoriesFor: #first!accessing!public! !
!ExternalArray categoriesFor: #from:do:!enumerating!public! !
!ExternalArray categoriesFor: #from:keysAndValuesDo:!enumerating!public! !
!ExternalArray categoriesFor: #from:to:keysAndValuesDo:!enumerating!public! !
!ExternalArray categoriesFor: #includes:!public!searching! !
!ExternalArray categoriesFor: #includesKey:!public!testing! !
!ExternalArray categoriesFor: #initializePointer!public! !
!ExternalArray categoriesFor: #inject:into:!enumerating!public! !
!ExternalArray categoriesFor: #isEmpty!public!testing! !
!ExternalArray categoriesFor: #keys!accessing!public! !
!ExternalArray categoriesFor: #keysAndValuesDo:!enumerating!public! !
!ExternalArray categoriesFor: #last!accessing!public! !
!ExternalArray categoriesFor: #length!accessing!public! !
!ExternalArray categoriesFor: #length:!accessing!public! !
!ExternalArray categoriesFor: #lookup:!accessing!public! !
!ExternalArray categoriesFor: #notEmpty!public!testing! !
!ExternalArray categoriesFor: #replaceBytesOf:from:to:startingAt:!double dispatch!private! !
!ExternalArray categoriesFor: #replaceElementsOf:from:to:startingAt:!private!replacing! !
!ExternalArray categoriesFor: #replaceFrom:to:with:startingAt:!public!replacing! !
!ExternalArray categoriesFor: #select:!enumerating!public! !
!ExternalArray categoriesFor: #size!accessing!public! !
!ExternalArray categoriesFor: #species!constants!public! !
!ExternalArray categoriesFor: #uncheckedAt:!accessing!private! !
!ExternalArray categoriesFor: #uncheckedAt:put:!accessing!private! !
!ExternalArray categoriesFor: #uncheckedFrom:to:keysAndValuesDo:!enumerating!private! !

!ExternalArray class methodsFor!

alignment
	"Answer the alignment required for instances of the receiver when embedded in arrays or
	other structures. This is the alignment of the elements of the array in most cases."

	^self elementSize!

elementClass
	"Answer the class of <ExternalStructure> used to represent elements of the receiver."

	^BYTE!

elementSize
	"Private - Answer the size of the receiver's instances' constituent 
	elements in bytes."

	^self elementClass elementSize!

fromAddress: anAddress
	"The receiver needs to know how long the array is to avoid
	reading or writing off its end."

	^self shouldNotImplement !

fromAddress: anAddress length: anInteger
	"Answer a new instance of the receiver that points at an
	array of anInteger elements of type elementClass at anAddress.
	Implementation Note: If the length is zero, then we ignore the address (even if invalid).
	If the length is non-zero then we answer nil if the address is the Null pointer."

	^anAddress isNull
		ifFalse: 
			[(self basicNew)
				initializeAtAddress: anAddress;
				basicLength: anInteger]!

getFieldNames
	^#()!

length: count elementSize: bytes
	"Private - Answer a new instance of the receiver allocated 
	with space for count elements of bytes size."

	^(super new: count*bytes)
		basicLength: count!

new: anInteger
	"Answer a new instance of the receiver allocated at an immovable location."

	^self length: anInteger elementSize: self elementSize!

with: element1
	"Answer a new instance of the receiver containing the single 
	<Object> element, element1."

	^(self new: 1)
		at: 1 put: element1;
		yourself!

withAll: newElements
	"Answer a new instance of the receiver containing all of the 
	elements of the <collection> newElements.
	An error will be raised if any of the elements of newElements
	cannot be stored in instances of the receiver."

	| answer |
	answer := self new: newElements size.
	newElements inject: 1 into: [:i :elem | answer at: i put: elem. i + 1].
	^answer! !
!ExternalArray class categoriesFor: #alignment!constants!public! !
!ExternalArray class categoriesFor: #elementClass!constants!public! !
!ExternalArray class categoriesFor: #elementSize!instance creation!private! !
!ExternalArray class categoriesFor: #fromAddress:!instance creation!public! !
!ExternalArray class categoriesFor: #fromAddress:length:!instance creation!public! !
!ExternalArray class categoriesFor: #getFieldNames!constants!private! !
!ExternalArray class categoriesFor: #length:elementSize:!instance creation!private! !
!ExternalArray class categoriesFor: #new:!instance creation!public! !
!ExternalArray class categoriesFor: #with:!instance creation!public! !
!ExternalArray class categoriesFor: #withAll:!instance creation!public! !

