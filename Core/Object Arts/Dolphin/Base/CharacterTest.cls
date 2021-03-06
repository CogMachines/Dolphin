﻿"Filed out from Dolphin Smalltalk 7"!

DolphinTest subclass: #CharacterTest
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	classInstanceVariableNames: ''!
CharacterTest guid: (GUID fromString: '{b5b1b518-3a55-4441-9aa3-32c87f1aedba}')!
CharacterTest comment: ''!
!CharacterTest categoriesForClass!Tests-Magnitude-General! !
!CharacterTest methodsFor!

testAnsiValue
	1 to: 256
		do: [:each | self assert: (Character byteCharacterSet at: each) ansiValue equals: each - 1].
	self should: [Character dolphin ansiValue] raise: Error!

testAsciiValue
	1 to: 128
		do: [:each | self assert: (Character byteCharacterSet at: each) asciiValue equals: each - 1].
	self should: [(Character ansiValue: 128) asciiValue] raise: Error.
	self should: [(Character value: 16r20AC) asciiValue] raise: Error.
	self should: [$£ asciiValue] raise: Error.
	self should: [Character dolphin asciiValue] raise: Error!

testAsLowercase
	self assert: $a asLowercase identicalTo: $a.
	self assert: $A asLowercase identicalTo: $a.
	self assert: $\0 asLowercase identicalTo: $\0.
	"Euro symbol - still a unique ANSI encoded char"
	self assert: (Character ansiValue: 128) asLowercase identicalTo: (Character ansiValue: 128).
	"Turkish, but 8-bit"
	self assert: (Character codePoint: 16rC7) asLowercase equals: (Character codePoint: 16rE7).
	"Cyrillic, 16-bit"
	self assert: (Character codePoint: 16r0400) asLowercase equals: (Character codePoint: 16r450).
	"Greek delta"
	self assert: (Character codePoint: 16r394) asLowercase equals: (Character codePoint: 16r3B4).
	"Thai 7 - not a letter"
	self assert: (Character codePoint: 16rE57) asLowercase equals: (Character codePoint: 16rE57).
	"Symbol outside BMP"
	self assert: Character dolphin asLowercase equals: Character dolphin!

testAsUppercase
	"Ascii chars have unique instances in the ANSI set"

	self assert: $A asUppercase identicalTo: $A.
	self assert: $a asUppercase identicalTo: $A.
	self assert: $\0 asUppercase identicalTo: $\0.
	"Euro symbol - still a unique ANSI encoded char"
	self assert: (Character ansiValue: 128) asUppercase identicalTo: (Character ansiValue: 128).
	"Turkish, but 8-bit"
	self assert: (Character codePoint: 16rE7) asUppercase equals: (Character codePoint: 16rC7).
	"Cyrillic, 16-bit"
	self assert: (Character codePoint: 16r0450) asUppercase equals: (Character codePoint: 16r400).
	"Greek delta"
	self assert: (Character codePoint: 16r3B4) asUppercase equals: (Character codePoint: 16r394).
	"Thai 7 - not a letter"
	self assert: (Character codePoint: 16rE57) asUppercase equals: (Character codePoint: 16rE57).
	"Symbol outside BMP"
	self assert: Character dolphin asUppercase equals: Character dolphin!

testAsUtf16String
	#(#($A #[65 0]) #($\x7F #[16r7F 0]) #($\x20AC #[16rAC 16r20]) #($\x7FF #[16rFF 16r07]) #($\x800 #[16r00 16r08]) #($\x10000 #[16r00 16rD8 16r00 16rDC]) #($\x1F42C #[16r3D 16rD8 16r2C 16rDC]))
		do: 
			[:each |
			| actual subject expected |
			subject := each first.
			expected := each last.
			actual := subject asUtf16String asByteArray.
			self assert: actual equals: expected]!

testAsUtf8String
	#(#($A #[65]) #($\x7F #[16r7F]) #($\xA3 #[16rC2 16rA3]) #($\x7FF #[16rDF 16rBF]) #($\x800 #[16rE0 16rA0 16r80]) #($\x10000 #[16rF0 16r90 16r80 16r80]) #($\x1F42C #[16rF0 16r9F 16r90 16rAC]))
		do: 
			[:each |
			| actual subject expected |
			subject := each first.
			expected := each last.
			actual := subject asUtf8String asByteArray.
			self assert: actual equals: expected]!

testClassCodePoint
	| ch |
	ch := Character codePoint: 0.
	self assert: ch identicalTo: $\0.
	ch := Character codePoint: 127.
	self assert: ch identicalTo: $\x7F.
	ch := Character codePoint: 128.
	self assert: ch encoding equals: #utf32.
	"Euro symbol"
	ch := Character codePoint: 16r20AC.
	self assert: ch codePoint equals: 16r20AC.
	self assert: ch encoding equals: #ansi.
	self assert: ch identicalTo: ((AnsiString fromByteArray: #[128]) at: 1).
	ch := Character codePoint: 16r1F42C.
	self assert: ch codePoint equals: 16r1F42C.
	self assert: ch encoding equals: #utf32.
	"The replacement character"
	ch := Character codePoint: 16rFFFD.
	self assert: ch codePoint equals: 16rFFFD.
	self assert: ch encoding equals: #utf32.
	"Utf-16 surrogates, not code points"
	#(16rD800 16rDB7F 16rDB80 16rDBFF 16rDC00 16rDCFF 16rDF80 16rDFFF) do: [:i | self should: [Character codePoint: (i << 16) + 16rFFFE] raise: Error].
	"Valid code points but not valid characters"
	16rFDD0 to: 16rFDEF do: [:i | self should: [Character codePoint: (i << 16) + 16rFFFE] raise: Error].
	(0 to: 16) do: 
			[:i |
			self should: [Character codePoint: (i << 16) + 16rFFFE] raise: Error.
			self should: [Character codePoint: (i << 16) + 16rFFFF] raise: Error]!

testCodePoint
	| euro utf8 utf16 |
	euro := (AnsiString fromByteArray: #[128]) at: 1.
	self assert: euro codePoint equals: 16r20AC.
	self assert: Character dolphin codePoint equals: 16r1F42C.
	"Surrogates  - not real code points"
	utf8 := Utf8String with: Character dolphin.
	#[16rF0 16r9F 16r90 16rAC] keysAndValuesDo: 
			[:i :each |
			| ch |
			ch := utf8 at: i.
			self assert: ch isSurrogate.
			self assert: ch codePoint equals: each].
	utf16 := utf8 asUtf16String.
	#(16rD83D 16rDC2C) keysAndValuesDo: 
			[:i :each |
			| ch |
			ch := utf16 at: i.
			self assert: ch isSurrogate.
			self assert: ch codePoint equals: each]!

testDigitValue
	self assert: Character null digitValue equals: -1!

testEquals
	self assert: $a equals: (Character codePoint: 97).
	self deny: $a equals: $A.
	self assert: $\0 equals: (Character codePoint: 0).
	self assert: (Character codePoint: 255) equals: (Character codePoint: 255).
	self should: [Character codePoint: 16rFFFF] raise: Error.
	self deny: (Character codePoint: 16rFFFC) equals: (Character codePoint: 16rFFFD).
	self deny: (Character codePoint: 16r200E) equals: 16r200E.
	self deny: (Character utf8Value: 240) equals: (Character codePoint: 240).
	self deny: (Character utf8Value: 16r80) equals: (Character codePoint: 16r80)!

testIdentity
	self assert: $a identicalTo: (Character codePoint: 97).
	self assert: (Character codePoint: 255) identicalTo: (Character codePoint: 255).
	self deny: (Character codePoint: 256) identicalTo: (Character codePoint: 256)!

testIsAlphaNumeric
	self assert: $a isAlphaNumeric.
	self assert: $A isAlphaNumeric.
	self assert: $0 isAlphaNumeric.
	"Punctuation"
	self deny: $" isAlphaNumeric.
	"Control char"
	self deny: $\0 isAlphaNumeric.
	"Left-to-right mark"
	self deny: (Character codePoint: 16r200E) isLowerCase.
	"Turkish, but 8-bit"
	self assert: (Character codePoint: 16rC7) isAlphaNumeric.
	self assert: (Character codePoint: 16rE7) isAlphaNumeric.
	" Cyrillic ie with grave, 16-bit"
	self assert: (Character codePoint: 16r400) isAlphaNumeric.
	self assert: (Character codePoint: 16r450) isAlphaNumeric.
	"Arabic indic digit zero"
	self assert: (Character codePoint: 16r660) isAlphaNumeric.
	"Arabic percent sign"
	self deny: (Character codePoint: 16r066A) isAlphaNumeric.
	"Thai digit for 7"
	self assert: (Character codePoint: 16rE57) isAlphaNumeric!

testIsControl
	"Tests Character>>isControl"

	"C0 and C1 control codes"

	(0 to: 31) , (127 to: 15) do: [:i | self assert: (Character codePoint: i) isControl].
	"All other ASCII chars are not control codes"
	32 to: 126 do: [:i | self deny: (Character codePoint: i) isControl].
	"Left to right mark"
	self assert: (Character codePoint: 16r200E) isControl.
	"Turkish, but ANSI"
	self deny: (Character codePoint: 16rC7) isControl.
	"Cyrillic letter ie with grave"
	self deny: (Character codePoint: 16r0400) isControl.
	"Thai 7"
	self deny: (Character codePoint: 16rE57) isControl!

testIsDigit
	#($0 $1 $2 $3 $4 $5 $6 $7 $8 $9) do: [:each | self assert: each isDigit].
	self deny: $a isDigit.
	self deny: Character null isDigit.
	self deny: (Character codePoint: 16r1F37B) isDigit!

testIsHexDigit
	| dolphin |
	#($0 $1 $2 $3 $4 $5 $6 $7 $8 $9 $A $B $C $D $E $F) do: [:each | self assert: each isHexDigit].
	self deny: $a isHexDigit.
	self deny: $G isHexDigit.
	self deny: Character null isHexDigit.
	dolphin := Character dolphin.
	self deny: dolphin isHexDigit.
	"Test surrogates"
	dolphin := dolphin asUtf8String.
	1 to: 4 do: [:each | self deny: (dolphin at: each) isHexDigit].
	dolphin := dolphin asUtf16String.
	1 to: 2 do: [:each | self deny: (dolphin at: each) isHexDigit]!

testIsLowercase
	self assert: $a isLowerCase.
	self deny: $A isLowerCase.
	self deny: $0 isLowerCase.
	self deny: $\0 isLowerCase.
	"Left-to-right mark"
	self deny: (Character codePoint: 16r200E) isLowerCase.
	"Turkish, but 8-bit"
	self deny: (Character codePoint: 16rC7) isLowercase.
	self assert: (Character codePoint: 16rE7) isLowerCase.
	"Cyrillic, 16-bit"
	self deny: (Character codePoint: 16r0400) isLowercase.
	self assert: (Character codePoint: 16r450) isLowerCase.
	"Greek delta"
	self assert: (Character codePoint: 16r3B4) isLowercase.
	self deny: (Character codePoint: 16r394) isLowercase.
	"Thai 7"
	self deny: (Character codePoint: 16rE57) isLowercase.
	"Outside BMP"
	self deny: Character dolphin isLowercase!

testIsPunctuation
	self deny: $a isPunctuation.
	self deny: $0 isPunctuation.
	self assert: $. isPunctuation.
	"Solidus"
	self assert: $/ isPunctuation.
	"Left-to-right mark"
	self deny: (Character codePoint: 16r200E) isLowerCase.
	"Greek"
	self deny: (Character codePoint: 16r3B4) isPunctuation.
	self assert: (Character codePoint: 16r37E) isPunctuation.
	"Arabic indic digit zero"
	self deny: (Character codePoint: 16r660) isPunctuation.
	"Arabic percent sign"
	self assert: (Character codePoint: 16r066A) isPunctuation!

testIsUppercase
	self deny: $a isUppercase.
	self assert: $A isUppercase.
	self deny: $0 isUppercase.
	self deny: $\0 isUppercase.
	"Left-to-right mark"
	self deny: (Character codePoint: 16r200E) isLowerCase.
	"Turkish, but 8-bit"
	self assert: (Character codePoint: 16rC7) isUppercase.
	self deny: (Character codePoint: 16rE7) isUppercase.
	"Cyrillic, 16-bit"
	self assert: (Character codePoint: 16r0400) isUppercase.
	self deny: (Character codePoint: 16r450) isUppercase.
	"Greek delta"
	self deny: (Character codePoint: 16r3B4) isUppercase.
	self assert: (Character codePoint: 16r394) isUppercase.
	"Thai 7"
	self deny: (Character codePoint: 16rE57) isUpperCase.
	"Outside BMP"
	self deny: Character dolphin isUppercase!

testISurrogate
	| utf |
	Character byteCharacterSet do: [:each | self deny: each isSurrogate].
	self deny: Character dolphin isSurrogate.
	utf := Character dolphin asUtf8String.
	self assert: utf size equals: 4.
	1 to: utf size do: [:i | self assert: (utf at: i) isSurrogate].
	utf := utf asUtf16String.
	self assert: utf size equals: 2.
	1 to: utf size do: [:i | self assert: (utf at: i) isSurrogate].
	self deny: (Character codePoint: 16r80) isSurrogate!

testIsUtf8Lead
	| str |
	self deny: $a isUtf8Lead.
	self deny: (Character ansiValue: 127) isUtf8Lead.
	self deny: (Character value: 128) isUtf8Lead.
	self deny: (Character ansiValue: 128) isUtf8Lead.
	self deny: (Character value: 2r11000000) isUtf8Lead.
	str := Character dolphin asUtf8String.
	self assert: str first isUtf8Lead.
	self deny: str second isUtf8Lead.
	self deny: str third isUtf8Lead.
	self deny: str fourth isUtf8Lead.
	str := Character dolphin asUtf16String.
	self deny: str first isUtf8Lead.
	self deny: str second isUtf8Lead!

testIsUtf8Surrogate
	| str |
	self deny: $\0 isUtf8Surrogate.
	self deny: $a isUtf8Surrogate.
	self deny: (Character ansiValue: 127) isUtf8Surrogate.
	self deny: (Character value: 128) isUtf8Surrogate.
	self deny: (Character value: 255) isUtf8Surrogate.
	self deny: (Character ansiValue: 128) isUtf8Surrogate.
	self deny: (Character ansiValue: 255) isUtf8Surrogate.
	self deny: (Character value: 2r11000000) isUtf8Surrogate.
	self deny: (Character value: 16rFFFD) isUtf8Surrogate.
	self deny: Character dolphin isUtf8Surrogate.
	self deny: (Character value: 16r1FFFD) isUtf8Surrogate.
	str := Character dolphin asUtf8String.
	self assert: str size equals: 4.
	1 to: 4
		do: 
			[:i |
			| ch b |
			b := #[240 159 144 172] at: i.
			ch := str at: i.
			self assert: ch isSurrogate.
			self assert: ch isUtf8Surrogate.
			i = 1
				ifTrue: 
					[self assert: ch isUtf8Lead.
					self deny: ch isUtf8Trail]
				ifFalse: 
					[self deny: ch isUtf8Lead.
					self assert: ch isUtf8Trail].
			self assert: ch codeUnit equals: b.
			self deny: ch equals: (Character codePoint: b)].
	str := Character dolphin asUtf16String.
	str with: #(16rD83D 16rDC2C)
		do: 
			[:ch :c |
			self assert: ch codeUnit equals: c.
			self assert: ch isUtf16Surrogate.
			self deny: ch isUtf8Surrogate.
			self deny: ch equals: (Character newCode: (Character.Utf32Mask bitOr: c))]!

testPrintString
	self assert: $a printString equals: '$a'.
	self assert: $a printString equals: '$a'.
	(1 to: 6) , (14 to: 32) do: 
			[:i |
			self assert: (Character codePoint: i) printString
				equals: '$\x' , (i printStringBase: 16)].
	(33 to: 126) do: [:i | self deny: ((Character codePoint: i) printString beginsWith: '$\x')].
	self assert: (Character codePoint: 0) printString equals: '$\0'.
	self assert: (Character codePoint: 7) printString equals: '$\a'.
	self assert: (Character codePoint: 8) printString equals: '$\b'.
	self assert: (Character codePoint: 9) printString equals: '$\t'.
	self assert: (Character codePoint: 10) printString equals: '$\n'.
	self assert: (Character codePoint: 11) printString equals: '$\v'.
	self assert: (Character codePoint: 12) printString equals: '$\f'.
	self assert: (Character codePoint: 13) printString equals: '$\r'.
	self assert: (Character codePoint: 127) printString equals: '$\x7F'.
	self assert: (Character codePoint: 16r394) printString equals: '$\x394'.
	"Left-to-right mark"
	self assert: (Character codePoint: 16r200E) printString equals: '$\x200E'!

testSize
	self assert: $a size equals: 0.
	self assert: Character dolphin size equals: 0! !
!CharacterTest categoriesFor: #testAnsiValue!public! !
!CharacterTest categoriesFor: #testAsciiValue!public! !
!CharacterTest categoriesFor: #testAsLowercase!public! !
!CharacterTest categoriesFor: #testAsUppercase!public! !
!CharacterTest categoriesFor: #testAsUtf16String!public! !
!CharacterTest categoriesFor: #testAsUtf8String!public! !
!CharacterTest categoriesFor: #testClassCodePoint!public! !
!CharacterTest categoriesFor: #testCodePoint!public! !
!CharacterTest categoriesFor: #testDigitValue!public! !
!CharacterTest categoriesFor: #testEquals!public! !
!CharacterTest categoriesFor: #testIdentity!public! !
!CharacterTest categoriesFor: #testIsAlphaNumeric!public! !
!CharacterTest categoriesFor: #testIsControl!public! !
!CharacterTest categoriesFor: #testIsDigit!public! !
!CharacterTest categoriesFor: #testIsHexDigit!public! !
!CharacterTest categoriesFor: #testIsLowercase!public! !
!CharacterTest categoriesFor: #testIsPunctuation!public! !
!CharacterTest categoriesFor: #testIsUppercase!public! !
!CharacterTest categoriesFor: #testISurrogate!public! !
!CharacterTest categoriesFor: #testIsUtf8Lead!public! !
!CharacterTest categoriesFor: #testIsUtf8Surrogate!public! !
!CharacterTest categoriesFor: #testPrintString!public! !
!CharacterTest categoriesFor: #testSize!public! !

