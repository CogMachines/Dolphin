﻿"Filed out from Dolphin Smalltalk 7"!

KeyedAspect subclass: #AnonymousKeyedAspect
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	classInstanceVariableNames: ''!
AnonymousKeyedAspect guid: (GUID fromString: '{c64b85f4-37c0-4dd2-9f9d-7539c2f99594}')!
AnonymousKeyedAspect comment: 'Part of the PublishedAspectorInspector framework. AnonymouseKeyedAspect instances are used to describe the published aspects of a keyed collection where the key name is anonymous and should not be displayed. '!
!AnonymousKeyedAspect categoriesForClass!Attribute-Definition! !
!AnonymousKeyedAspect methodsFor!

displayAspectNameOf: anObject on: aStream 
	"Don't display the anonymouse key name"
!

displayAspectText: anObject on: aStream
	"Don't display the anonymouse key name"

	[(self readFrom: anObject) aspectDisplayOn: aStream] on: Error do: [:ex | ex displayOn: aStream]! !
!AnonymousKeyedAspect categoriesFor: #displayAspectNameOf:on:!displaying!private! !
!AnonymousKeyedAspect categoriesFor: #displayAspectText:on:!displaying!private! !

