﻿"Filed out from Dolphin Smalltalk 7"!

DolphinTest subclass: #ExternalArrayTest
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	classInstanceVariableNames: ''!
ExternalArrayTest guid: (GUID fromString: '{356dac42-9b9c-4970-87d2-bfd4846fafa4}')!
ExternalArrayTest isAbstract: true!
ExternalArrayTest comment: ''!
!ExternalArrayTest categoriesForClass!Unclassified! !
!ExternalArrayTest methodsFor!

arrayClass
	^self subclassResponsibility!

arrayValueString: eachValue
	^eachValue printString!

canonicalizeValue: anObject 
	^self elementToValue: (self elementFromValue: anObject)!

elementFromValue: anObject 
	^anObject!

elementToValue: element 
	^element!

newArrayOfIntegers: anArray 
	^self arrayClass withAll: anArray!

newNumericArray: anInteger 
	^self newArrayOfIntegers: (1 to: anInteger)!

testAtAndAtPut
	| array |
	array := self newNumericArray: 0.
	#(-1 0 1 2) do: 
			[:each |
			self should: [array at: each] raise: BoundsError.
			self should: [array at: each put: (self elementFromValue: each)] raise: BoundsError].
	array := self newNumericArray: 1.
	#(-1 0 2 3) do: 
			[:each |
			self should: [array at: each] raise: BoundsError.
			self should: [array at: each put: (self elementFromValue: each)] raise: BoundsError].
	#(1) do: 
			[:each |
			| elem |
			elem := self elementFromValue: each.
			self assert: (array at: each put: elem) equals: elem.
			self assert: (self elementToValue: (array at: each)) equals: each].
	array := self newNumericArray: 2.
	#(-1 0 3) do: 
			[:each |
			self should: [array at: each] raise: BoundsError.
			self should: [array at: each put: (self elementFromValue: each)] raise: BoundsError].
	#(1 2) do: 
			[:each |
			| elem |
			elem := self elementFromValue: each.
			self assert: (array at: each put: elem) equals: elem.
			self assert: (self elementToValue: (array at: each)) equals: each].
	array := self newNumericArray: 3.
	#(-1 0 4) do: 
			[:each |
			self should: [array at: each] raise: BoundsError.
			self should: [array at: each put: (self elementFromValue: each)] raise: BoundsError].
	#(1 2 3) do: 
			[:each |
			| elem |
			elem := self elementFromValue: each.
			self assert: (array at: each put: elem) equals: elem.
			self assert: (self elementToValue: (array at: each)) equals: each]!

testFromToKeysAndValuesDo
	"Empty array"

	| array pairs |
	array := self newNumericArray: 0.
	pairs := OrderedCollection new.
	#(#(1 0)) do: 
			[:each |
			array
				from: each first
				to: each last
				keysAndValuesDo: [:eachKey :eachValue | pairs addLast: eachKey -> eachValue].
			self assert: pairs isEmpty].
	#(#(0 -1) #(-1 0) #(0 1) #(1 1) #(2 2) #(2 1) #(3 2)) do: 
			[:each |
			self should: 
					[array
						from: each first
						to: each last
						keysAndValuesDo: [:eachKey :eachValue | pairs addLast: eachKey -> eachValue]]
				raise: BoundsError.
			self assert: pairs isEmpty].
	"Array of 1 element"
	array := self newNumericArray: 1.
	#(#(1 0) #(2 1)) do: 
			[:each |
			array
				from: each first
				to: each last
				keysAndValuesDo: [:eachKey :eachValue | pairs addLast: eachKey -> eachValue].
			self assert: pairs isEmpty].
	#(#(1 1)) do: 
			[:each |
			| expected |
			pairs := OrderedCollection new.
			array
				from: 1
				to: 1
				keysAndValuesDo: [:eachKey :eachValue | pairs addLast: eachKey -> (self arrayValueString: eachValue)].
			expected := (each first to: each last) collect: [:i | i -> (self canonicalizeValue: i) printString].
			self assert: pairs asArray equals: expected].
	#(#(1 2) #(2 2) #(3 2)) do: 
			[:each |
			self should: 
					[array
						from: each first
						to: each last
						keysAndValuesDo: [:eachKey :eachValue | pairs addLast: eachKey -> (self arrayValueString: eachValue)]]
				raise: BoundsError].
	pairs := OrderedCollection new.
	"Array of two elements"
	array := self newNumericArray: 2.
	#(#(1 0) #(2 1) #(3 2)) do: 
			[:each |
			array
				from: each first
				to: each last
				keysAndValuesDo: [:eachKey :eachValue | pairs addLast: eachKey -> (self arrayValueString: eachValue)].
			self assert: pairs isEmpty].
	#(#(1 1) #(1 2) #(2 2)) do: 
			[:each |
			| expected |
			pairs := OrderedCollection new.
			array
				from: each first
				to: each last
				keysAndValuesDo: [:eachKey :eachValue | pairs addLast: eachKey -> (self arrayValueString: eachValue)].
			expected := (each first to: each last) collect: [:i | i -> (self canonicalizeValue: i) printString].
			self assert: pairs asArray equals: expected].
	#(#(1 3) #(2 3) #(3 3)) do: 
			[:each |
			self should: 
					[array
						from: each first
						to: each last
						keysAndValuesDo: [:eachKey :eachValue | pairs addLast: eachKey -> (self arrayValueString: eachValue)]]
				raise: BoundsError].
	"Array of three elements"
	pairs := OrderedCollection new.
	array := self newNumericArray: 3.
	#(#(1 0) #(2 1) #(3 2) #(4 3)) do: 
			[:each |
			array
				from: each first
				to: each last
				keysAndValuesDo: [:eachKey :eachValue | pairs addLast: eachKey -> (self arrayValueString: eachValue)].
			self assert: pairs isEmpty].
	#(#(1 1) #(1 2) #(2 2) #(1 3) #(2 3) #(3 3)) do: 
			[:each |
			| expected |
			pairs := OrderedCollection new.
			array
				from: each first
				to: each last
				keysAndValuesDo: [:eachKey :eachValue | pairs addLast: eachKey -> (self arrayValueString: eachValue)].
			expected := (each first to: each last) collect: [:i | i -> (self canonicalizeValue: i) printString].
			self assert: pairs asArray equals: expected].
	#(#(1 4) #(2 4) #(3 4) #(4 4)) do: 
			[:each |
			self should: 
					[array
						from: each first
						to: each last
						keysAndValuesDo: [:eachKey :eachValue | ]]
				raise: BoundsError]! !
!ExternalArrayTest categoriesFor: #arrayClass!constants!private! !
!ExternalArrayTest categoriesFor: #arrayValueString:!private!unit tests! !
!ExternalArrayTest categoriesFor: #canonicalizeValue:!private!unit tests! !
!ExternalArrayTest categoriesFor: #elementFromValue:!private!unit tests! !
!ExternalArrayTest categoriesFor: #elementToValue:!private!unit tests! !
!ExternalArrayTest categoriesFor: #newArrayOfIntegers:!helpers!private! !
!ExternalArrayTest categoriesFor: #newNumericArray:!helpers!private! !
!ExternalArrayTest categoriesFor: #testAtAndAtPut!public!unit tests! !
!ExternalArrayTest categoriesFor: #testFromToKeysAndValuesDo!public!unit tests! !

