"Filed out from Dolphin Smalltalk X6.2"!

AbstractDelegatingView subclass: #ReferenceView
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	classInstanceVariableNames: ''!
ReferenceView guid: (GUID fromString: '{87B4C713-026E-11D3-9FD7-00A0CC3E4A32}')!
ReferenceView comment: 'ReferenceView represents a dummy <view> that is capable of loading another view to take its place. This "referee" view is  identified by its resource identifier. The reference view then steps aside and forwards all pertinent messages to the referee. In general, from this point on, the reference view can be assumed to take a minimal part in the view hierarchy.

Typically, ReferenceViews are used to allow existing views held by the ResourceManager to be loaded, as is, into other views. In this way, if the referee view definition is changed then, when the referer is re-loaded, it will automatically get the latest referee definition.

Instance Variables (inherited)
	resourceIdentifier	<ResourceIdentifier> identifying the view to load as a referee.
	referee			<view> which is the delegated view.

'!
!ReferenceView categoriesForClass!MVP-Views! !
!ReferenceView methodsFor!

clearReferee
	referee := nil!

configureReferee
	referee
		position: Point zero;
		extent: self extent;
		isManaged: false;
		isTabStop: self isTabStop;
		isGroupStop: self isGroupStop;
		isDragSource: self isDragSource;
		isDropTarget: self isDropTarget.
	self contextMenu 
		ifNotNil: 
			[referee
				contextMenu: nil;
				inheritContextMenu: true]!

createDelegate
	"Force load of referred resource"
	self referee!

filerProxy
	"Private - Answer a filer proxy that represents the receiver."

	"Implementation Note: We must not save the referee, as the whole point is that this must be
	restored from the referenced resource in its latest state."

	| temp proxy |
	temp := referee.
	referee := nil.
	proxy := super filerProxy.
	proxy clearSubViews.
	referee := temp.
	^proxy!

loadReferee
	referee := resourceIdentifier loadWithContext: self.
	referee isNil 
		ifTrue: 
			["Referee resource not found so substitute a dummy static text."
			referee := StaticText new.
			Notification 
				signal: ('<1p> can''t load ''<2d>''' expandMacrosWith: self class with: resourceIdentifier).
			(self addSubView: referee) text: resourceIdentifier displayString].
	self configureReferee.
	referee show.
	^referee!

presenterConnectionPoint
	"Answer the view within the receiver to which a same named presenter should connect.
	For reference views this is the referee."

	^self referee!

printOn: aStream
	"Append a short description of the receiver to aStream."

	aStream
		basicPrint: self;
		nextPut: $(;
		display: (handle isNil ifTrue: ['NULL'] ifFalse: [handle asInteger printStringRadix: 16]);
		nextPutAll: ', ';
		print: self displayString;
		nextPutAll: ', ';
		display: resourceIdentifier;
		nextPut: $)!

referee
	"Answers the view which is referenced by the receiver."

	^referee ifNil: [self loadReferee]!

resource
	"Answers the resource which the receiver represents."

	"In Dolphin 3.0 several of the view names were changed to 'Default view'.
	If the first attempt at locating the resource fails then try a second time
	for a 'Default view' resource in the same owning class."

	| resource |
	(resource := resourceIdentifier resourceOrNil) isNil 
		ifTrue: 
			[| rid |
"self halt."
			rid := resourceIdentifier copy.
			rid name: 'Default view'.
			Notification 
				signal: 'Warning: ''' , resourceIdentifier printString , ''' not found. Trying: ''' 
						, rid printString , ''' instead.'.
			resource := rid resourceOrNil.
			resource notNil ifTrue: [resourceIdentifier := rid]].
	^resource!

resourceIdentifier
	"Private - Answer the <ResourceIdentifier> which uniquely identifies the <ViewResource> to which	
	the user is a reference."

	^resourceIdentifier!

resourceIdentifier: aResourceIdentifier
	"Private - Store the identifier of the ViewResource to which the receiver is a reference.
	When the receiver is created this will be resolved to form the receiver's sub-view."

	referee notNil ifTrue: [
		referee destroy.
		referee := nil ].
	resourceIdentifier := aResourceIdentifier!

validateUserInterface
	"Validates the user interface for the receiver. Usually performed at idle time
	when the UI has been flagged as being invalid"

	self referee presenter validateUserInterface! !
!ReferenceView categoriesFor: #clearReferee!event handling!private! !
!ReferenceView categoriesFor: #configureReferee!helpers!private! !
!ReferenceView categoriesFor: #createDelegate!event handling!private! !
!ReferenceView categoriesFor: #filerProxy!binary filing!private! !
!ReferenceView categoriesFor: #loadReferee!helpers!private! !
!ReferenceView categoriesFor: #presenterConnectionPoint!public! !
!ReferenceView categoriesFor: #printOn:!development!printing!public! !
!ReferenceView categoriesFor: #referee!accessing!public! !
!ReferenceView categoriesFor: #resource!operations!public! !
!ReferenceView categoriesFor: #resourceIdentifier!accessing!private! !
!ReferenceView categoriesFor: #resourceIdentifier:!accessing!private! !
!ReferenceView categoriesFor: #validateUserInterface!operations!public! !

!ReferenceView class methodsFor!

icon
	"Answers an Icon that can be used to represent this class"

	^##(self) defaultIcon!

new
	"The receiver should be created using #resourceIdentifier:.
	Note that this is only required at development time to implement View mutation in the 
	View Composer. To create ReferenceViews dynamically (though the reason for doing that
	is unclear) one should use #resourceIdentifier."

	^self resourceIdentifier: (ResourceIdentifier class: Presenter name: 'Container view')!

resourceIdentifier: aResourceIdentifier
	"Answer a new instance of the receiver with the specified details."

	^super new
		resourceIdentifier: aResourceIdentifier;
		yourself!

stbConvertFromVersion12: anArray 
	"Private - Perform an STB conversion from a version 12 <ReferenceView> to version 13."

	"Deliberately override superclass implementation in order to inherit background colour by default."

	anArray at: 6 put: nil.
	^anArray!

stbConvertFromVersion9: anArray 
	"Private - Perform an STB conversion from a version 9 (or earlier) <ReferenceView> to version 10,
	Fixes problem under Windows XP where toolbars need a parent reference view to have a backcolor
	of #face3d."

	| rid array |
	array := super stbConvertFromVersion9: anArray.
	rid := array at: 13.
	rid owningClass == (Smalltalk at: #Toolbar ifAbsent: []) ifTrue: [array at: 6 put: Color face3d].
	^array! !
!ReferenceView class categoriesFor: #icon!constants!public! !
!ReferenceView class categoriesFor: #new!development!instance creation!public! !
!ReferenceView class categoriesFor: #resourceIdentifier:!instance creation!public! !
!ReferenceView class categoriesFor: #stbConvertFromVersion12:!binary filing!private! !
!ReferenceView class categoriesFor: #stbConvertFromVersion9:!binary filing!private! !
