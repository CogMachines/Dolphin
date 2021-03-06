﻿"Filed out from Dolphin Smalltalk 7"!

SequenceableCollection subclass: #Interval
	instanceVariableNames: 'start stop step'
	classVariableNames: ''
	poolDictionaries: ''
	classInstanceVariableNames: ''!
Interval guid: (GUID fromString: '{87b4c50d-026e-11d3-9fd7-00a0cc3e4a32}')!
Interval comment: '<Interval>s represent a finite arithmetic progressions, that is a <sequencedReadableCollection> of numbers across a specified range and with a specified step between each element.

Instance Variables:
	start	<number>. First element in the collection.
	stop	<number>. Last element in the collection.
	step	<number>. Difference between elements of the collection (approximate where the elements are Floats)
'!
!Interval categoriesForClass!Collections-Sequenceable! !
!Interval methodsFor!

- delta
	"Answer a new Interval the same as the receiver, but negatively offset by the specified delta."

	^self class from: start - delta to: stop - delta by: step!

+ delta
	"Answer a new Interval the same as the receiver, but positively offset by the specified delta."

	^self class from: start + delta to: stop + delta by: step!

= anObject 
	"Answer whether the receiver and the <Object>, comparand, 
	are considered equivalent (that is they contain the same number
	of equivalent objects in the same order, and are of like class).
	The supersend ensures that expressions such as '(1 to: 5) = #(1 2 3 4 5)' are true"

	^(anObject isKindOf: self class) 
		ifTrue: [start = anObject start and: [step = anObject step and: [self size = anObject size]]]
		ifFalse: [super = anObject]!

add: newElement
	"Intervals are not extensible."

	^self shouldNotImplement!

at: index
	"Answer the <number> at index position anInteger in the receiver.

	This should probably be refined into the Interval protocol, because the 
	return value is restricted to <number>."

	^(index >= 1 and: [index <= self size])
		ifTrue: [start + (step * (index - 1))]
		ifFalse: [self errorSubscriptBounds: index]!

at: anInteger put: anObject
	"Replace the element at index anInteger of the receiver with anObject.
	Intervals are immutable."

	^self shouldNotImplement!

collect: transformer 
	"Evaluate the <monadicValuable> argument, transformer, for each of the receiver's elements.
	Answer a new <sequencedReadableCollection> 'like' the receiver containing the values returned 
	by the transformer on each evaluation."

	"Implementation Note: Superclass implmementation works, so this override for efficiency only."

	| answer size |
	size := self size.
	answer := self copyLike: size.
	1 to: size
		do: [:each | answer at: each put: (transformer value: start + (step * (each - 1)))].
	^answer!

displayOn: target 
	"Append, to the <puttableStream> argument, target, a string whose characters 
	are a description of the receiver as an end user would want to see it."

	target
		display: self start;
		nextPutAll: ' .. ';
		display: self stop!

first
	"Answer the first element of the receiver."

	self isEmpty ifTrue: [self errorSubscriptBounds: 1].
	^start
!

hash
	"Answer the <integer> hash value for the receiver."

	^(((start hash bitShift: 2) bitXor: stop hash) bitShift: 1) bitXor: step hash!

includes: anObject
	"Answer whether the <Object> argument, target, is one of the elements of the receiver.
	Implementation Note: This is based on John Brant's suggestion posted to comp.lang.smalltalk.dolphin,
	though it has been modified slightly to reduce the number of comparisons at the expense of some
	code clarity."

	anObject understandsArithmetic ifFalse: [^false].
	(step < 0 
		ifTrue: [anObject >= stop and: [anObject <= start]]
		ifFalse: [anObject >= start and: [anObject <= stop]]) ifFalse: [^false].
	^step isInteger 
		ifTrue: [(anObject - start) \\ step = 0]
		ifFalse: [start + (step * ((anObject - start) / step) rounded) = anObject]!

isEmpty
	"Answer whether the receiver contains any elements.
	Implementation note: Override superclass for improved performance."

	^step < 0 ifTrue: [start < stop] ifFalse: [stop < start]!

last
	"Answer the last <number> element of the receiver.
	This is not necessarily the same as the value of 'stop' 
	(e.g. if the step if non-integral)."

	self isEmpty ifTrue: [self errorSubscriptBounds: 1].
	^stop - (stop - start \\ step)!

printOn: target
	"Append, to the <puttableStream> argument, target, a string whose characters 
	are a description of the receiver as a developer would want to see it."

	target
		nextPut: $(;
		print: self start;
		nextPutAll: ' to: ';
		print: self stop.
	self step = 1 ifFalse: [
		target
			nextPutAll: ' by: ';
			print: self step].
	target nextPut: $)!

setFrom: startInteger to: stopInteger by: stepInteger
	"Private - Initialize the receiver's instance variables."

	start := startInteger.
	stop := stopInteger.
	step := stepInteger
!

size
	"Answer the inclusive size of the receiver."

	^self isEmpty 
		ifTrue: [0]
		ifFalse: [stop - start // step + 1]!

species
	"Answer the kind of <sequencedReadableCollection> that should result 
	from enumerations such as #collect: and #select: when applied against 
	the receiver.
	Note that this message helps to support the ANSI protocol refinements
	of the sequencedReadableCollection copying messages (e.g. #copyFrom:to:) 
	in the Interval protocol, without actually having to reimplement those 
	messages in the Interval class."

	^Array!

start
	"Answer the first element of the receiver."

	^start!

start: anInteger
	"Sets the first element of the receiver to anInteger"

	start := anInteger!

step
	"Answer the receiver's step."

	^step
!

step: anInteger
	"Sets the step element of the receiver to anInteger"

	step := anInteger!

stop
	"Answer the end of the receiver's interval. Depending on the step, this is not necessarily
	the last element of the receiver."

	^stop
!

stop: anInteger
	"Sets the last element of the receiver to anInteger"

	stop := anInteger!

storeOn: aStream 
	"Append to the <puttableStream> argument, target, an expression which when 
	evaluated will answer a collection similar to the receiver."

	self printOn: aStream!

uncheckedFrom: startInteger to: stopInteger keysAndValuesDo: aDyadicValuable 
	"Private - Evaluate the <dyadicValuable> argument for each element of the receiver
	between the specified <integer> indices, inclusive, with the element and its index as
	respectively the second and first arguments. No bounds checks are performed."

	"Implementation Note: Override because #at: is relative slow on Intervals. By overriding
	this one method we effectively replace the implementation of all the #do: family of
	enumerators."

	startInteger to: stopInteger do: [:i | aDyadicValuable value: i value: start + (step * (i - 1))]! !
!Interval categoriesFor: #-!arithmetic!public! !
!Interval categoriesFor: #+!arithmetic!public! !
!Interval categoriesFor: #=!comparing!public! !
!Interval categoriesFor: #add:!adding!public! !
!Interval categoriesFor: #at:!accessing!public! !
!Interval categoriesFor: #at:put:!accessing!public! !
!Interval categoriesFor: #collect:!enumerating!public! !
!Interval categoriesFor: #displayOn:!printing!public! !
!Interval categoriesFor: #first!accessing!public! !
!Interval categoriesFor: #hash!comparing!public! !
!Interval categoriesFor: #includes:!public!testing! !
!Interval categoriesFor: #isEmpty!public!testing! !
!Interval categoriesFor: #last!accessing!public! !
!Interval categoriesFor: #printOn:!printing!public! !
!Interval categoriesFor: #setFrom:to:by:!accessing!private! !
!Interval categoriesFor: #size!accessing!public! !
!Interval categoriesFor: #species!accessing!public! !
!Interval categoriesFor: #start!accessing!public! !
!Interval categoriesFor: #start:!accessing!public! !
!Interval categoriesFor: #step!accessing!public! !
!Interval categoriesFor: #step:!accessing!public! !
!Interval categoriesFor: #stop!accessing!public! !
!Interval categoriesFor: #stop:!accessing!public! !
!Interval categoriesFor: #storeOn:!printing!public! !
!Interval categoriesFor: #uncheckedFrom:to:keysAndValuesDo:!debugger-step through!enumerating!private! !

Interval methodProtocol: #Interval attributes: #(#ansi #readOnly) selectors: #(#, #after: #allSatisfy: #anySatisfy: #asArray #asBag #asByteArray #asOrderedCollection #asSet #asSortedCollection #asSortedCollection: #at: #at:ifAbsent: #before: #collect: #copyFrom:to: #copyReplaceAll:with: #copyReplaceFrom:to:with: #copyReplaceFrom:to:withObject: #copyReplacing:withObject: #copyWith: #copyWithout: #detect: #detect:ifNone: #do: #do:separatedBy: #findFirst: #findLast: #first #from:to:do: #from:to:keysAndValuesDo: #includes: #indexOf: #indexOf:ifAbsent: #indexOfSubCollection:startingAt: #indexOfSubCollection:startingAt:ifAbsent: #inject:into: #isEmpty #keysAndValuesDo: #last #notEmpty #occurrencesOf: #rehash #reject: #reverse #reverseDo: #select: #size #with:do:)!

!Interval class methodsFor!

from: fromNumber to: toNumber 
	"Answer a new instance of the receiver representing the interval 
	between the <number> arguments from and to inclusive in increments
	of the <integer> one."

	^self 
		from: fromNumber
		to: toNumber
		by: 1!

from: fromNumber to: toNumber by: byNumber 
	"Answer a new instance of the receiver representing the interval between the <number>
	arguments from and to inclusive in increments of the <number> by."

	<primitive: 157>
	^self basicNew 
		setFrom: fromNumber
		to: toNumber
		by: byNumber!

new
	"Use #from:to:[by:]"

	^self shouldNotImplement! !
!Interval class categoriesFor: #from:to:!instance creation!public! !
!Interval class categoriesFor: #from:to:by:!instance creation!public! !
!Interval class categoriesFor: #new!instance creation!private! !

Interval class methodProtocol: #'Interval factory' attributes: #(#ansi #readOnly) selectors: #(#from:to: #from:to:by:)!

