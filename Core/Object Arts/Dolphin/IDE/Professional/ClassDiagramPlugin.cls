﻿"Filed out from Dolphin Smalltalk 7"!

ClassBrowserPlugin subclass: #ClassDiagramPlugin
	instanceVariableNames: 'classesPresenter'
	classVariableNames: ''
	poolDictionaries: ''
	classInstanceVariableNames: ''!
ClassDiagramPlugin guid: (GUID fromString: '{2a2213bc-1639-42cf-a5b9-987d7fd36e9a}')!
ClassDiagramPlugin comment: 'ClassDiagramPlugin is a simple example of a <classBrowserPlugin> that renders the hierarchy below the browser''s currently selected class in a moen tree diagram. Although the time taken to perform this rendition is not significant, for illustrative purposes, we have chosen to defer the building of the class diagram until the plug-in''s card is selected in the browser.

Instance Variables:
	classesPresenter		<ClassHierarchySelector> used to show the class hierarchy diagram

'!
!ClassDiagramPlugin categoriesForClass!Browser-Plugins!MVP-Presenters! !
!ClassDiagramPlugin methodsFor!

buildClassDiagram
	"Private - Create the diagram for the browser's currently selected class"

	Cursor wait showWhile: 
			[| classModel instClass showAllClasses |
			instClass := self browser actualClass 
						ifNotNil: [:actualClass | actualClass instanceClass].
			classModel := ClassHierarchyModel withAllClasses.
			showAllClasses := instClass isNil or: [instClass == Object].
			showAllClasses 
				ifFalse: 
					[classModel filter: 
							[:x | 
							(instClass allSuperclasses includes: x) or: [instClass withAllSubclasses includes: x]]].
			classesPresenter model: classModel.
			classesPresenter selectionOrNil: instClass.

			"Don't expand Object since it just wastes times"
			showAllClasses ifFalse: [classesPresenter expandAll: nil]]!

createComponents
	"Create the presenters contained by the receiver"

	super createComponents.
	classesPresenter := self add: ClassHierarchySelector new name: 'classes'!

createSchematicWiring
	"Create the trigger wiring for the receiver"

	super createSchematicWiring.
	classesPresenter when: #selectionChanged send: #onClassSelected to: self.
	self model 
		when: #classSelected send: #onBrowserClassSelected to: self;
		when: #methodSelected send: #onBrowserMethodSelected to: self.

!

defaultHelpId
	^10748!

displayOn: aStream
	"Append, to aStream, a String whose characters are a representation of the receiver as a user
	would want to see it. This will be used as the label for the tab when the receiver is being displayed
	as a plugin within the Class Browser"

	aStream nextPutAll: 'Class Diagram'!

onBrowserClassSelected
	"Event handler for a class being selected within the receiver's associated browser. "

	"For efficiency we only build the diagram if we are the current card"

	self isCurrentCard ifTrue: [self buildClassDiagram]!

onBrowserMethodSelected
	"Event handler for a method being selected within the receiver's associated browser. "

	(self isCurrentCard and: [self browser hasMethodSelected]) 
		ifTrue: [self browser ensureSourceVisible]!

onClassSelected
	"Event handler for a class being selected within the receiver's diagram. 
	Pass the class selection on to the browser"

	| classRequired |
	classRequired := classesPresenter selectionOrNil.
	classRequired notNil 
		ifTrue: [self browser isInstanceMode ifFalse: [classRequired := classRequired class]].
	self browser actualClass: classRequired!

onShownInBrowser
	"Event handler indicating that the receiver has been displayed within it's browser. "

	super onShownInBrowser.
	"For efficiency we defer the creation of the diagram until the receiver becomes the current card"
	self buildClassDiagram! !
!ClassDiagramPlugin categoriesFor: #buildClassDiagram!operations!private! !
!ClassDiagramPlugin categoriesFor: #createComponents!initializing!public! !
!ClassDiagramPlugin categoriesFor: #createSchematicWiring!initializing!public! !
!ClassDiagramPlugin categoriesFor: #defaultHelpId!constants!public! !
!ClassDiagramPlugin categoriesFor: #displayOn:!displaying!public! !
!ClassDiagramPlugin categoriesFor: #onBrowserClassSelected!event handling!private! !
!ClassDiagramPlugin categoriesFor: #onBrowserMethodSelected!event handling!private! !
!ClassDiagramPlugin categoriesFor: #onClassSelected!event handling!private! !
!ClassDiagramPlugin categoriesFor: #onShownInBrowser!event handling!public! !

!ClassDiagramPlugin class methodsFor!

icon
	"Answers an Icon that can be used to represent this class"

	^ClassHierarchyDiagram icon!

resource_Default_view
	"Answer the literal data from which the 'Default view' resource can be reconstituted.
	DO NOT EDIT OR RECATEGORIZE THIS METHOD.

	If you wish to modify this resource evaluate:
	ViewComposer openOn: (ResourceIdentifier class: self selector: #resource_Default_view)
	"

	^#(#'!!STL' 4 788558 10 ##(Smalltalk.STBViewProxy) ##(Smalltalk.ContainerView) 34 15 nil nil 34 2 8 1409286144 131073 416 nil 786694 ##(Smalltalk.ColorDefault) 8 4278190080 nil 5 nil nil nil 416 788230 ##(Smalltalk.BorderLayout) 1 1 nil nil nil nil 410 ##(Smalltalk.ReferenceView) 34 14 nil 416 34 2 8 1140850688 131073 560 nil nil nil 5 265030 4 ##(Smalltalk.Menu) nil true 34 17 984134 2 ##(Smalltalk.CommandMenuItem) 2097153 1180998 4 ##(Smalltalk.CommandDescription) #findClass 8 'Find...' 1 1 263494 3 ##(Smalltalk.Icon) nil true 1572870 ##(Smalltalk.ImageRelativeFileLocator) 8 'FindClass.ico' 2032142 ##(Smalltalk.STBExternalResourceLibraryProxy) 8 'dolphindr7.dll' nil nil nil 626 nil true 34 10 674 1 706 #browseClassPackage 8 'Package <1d>' 1 1 754 nil true 800 8 'Package.ico' 848 nil nil 983366 1 ##(Smalltalk.DividerMenuItem) 4097 674 2097153 706 #browseClassReferences 8 '&Class References' 1 1 nil nil nil 626 nil true 8 #() 8 'Local Re&ferences To' #browseVariablesMenu 134217729 nil nil nil nil nil 994 4097 674 1 706 #browseChangedMethods 8 'Changed &Methods' 1 1 nil nil nil 674 1 706 #browseMethodHistoryForClass 8 'Method &History' 1 1 754 nil true 800 8 'MethodHistory.ico' 848 nil nil 994 4097 674 1 706 #browsePublishedEvents 8 'Published &events' 1 1 nil nil nil 674 1 706 #browsePublishedAspects 8 'Published &aspects' 1 1 nil nil nil 8 '&Browse' #browseMenu 134217729 nil nil nil nil nil 994 4097 674 1 706 #newClass 8 '&New...' 1 1 754 nil true 800 8 'NewClass.ico' 848 nil nil 674 1 706 #deleteClassHierarchy 8 '&Delete' 1 1 754 nil true 800 8 'EditClear.ico' 848 nil nil 626 nil true 34 19 674 1 706 #safeRemoveClass 8 '&Remove' 1 1 nil nil nil 674 2097153 706 #renameClass 8 'Re&name...' 1 1 754 nil true 800 8 'Rename.ico' 848 nil nil 674 1 706 #copyClass 8 'Cl&one...' 1 1 nil nil nil 994 4097 674 1 706 #addInstanceVariable 8 'Add <1s>&Instance Variable...' 1 1 nil nil nil 674 1 706 #addClassVariable 8 'Add &Class Variable...' 1 1 nil nil nil 626 nil true 8 #() 8 'Re&move Variable' #removeVariables 134217729 nil nil nil nil nil 626 nil true 8 #() 8 'Ren&ame Variable' #renameVariables 134217729 nil nil nil nil nil 994 4097 626 nil true 8 #() 8 'Push &Down' #pushDownVariables 134217729 nil nil nil nil nil 626 nil true 8 #() 8 'Pull &Up' #pullUpVariables 134217729 nil nil nil nil nil 994 4097 626 nil true 8 #() 8 'Cr&eate Accessors' #createVariableAccessors 134217729 nil nil nil nil nil 626 nil true 8 #() 8 'A&bstract' #abstractVariables 134217729 nil nil nil nil nil 626 nil true 8 #() 8 '&Protect/Concrete' #protectVariables 134217729 nil nil nil nil nil 994 4097 674 1 706 #convertToSibling 8 'Con&vert to Sibling...' 1 1 nil nil nil 994 4097 674 1 706 #removeDuplicateMethods 8 'Remove Dup&licate Methods' 1 1 nil nil nil 8 '&Refactorings' #classRefactoringsMenu 134217729 754 nil true 800 8 'Refactoring.ico' 848 nil nil nil nil 994 4097 674 1 706 #createInstanceVariableAccessors 8 'Create &Accessors...' 1 1 nil nil nil 674 1 706 #reformatAll 8 'Refor&mat All' 1 1 nil nil nil 994 4097 674 1 706 #fileInClass 8 'File &In...' 1 1 nil nil nil 674 1 706 #fileOutClass 8 'File &Out...' 1 1 nil nil nil 994 4097 674 1 706 #classPackage 8 '&Package...' 1 1 754 nil true 800 8 'Package.ico' 848 nil nil 674 1 706 #categorizeClass 8 '&Category...' 1 1 754 nil true 800 8 'Category.ico' 848 nil nil 994 4097 626 nil true 34 4 674 1 706 #newView 8 '&New...' 1 1 nil nil nil 994 4097 626 nil true 8 #() 8 '&Edit' #viewsEditMenu 1 754 nil true 800 8 'ViewComposer.ico' 848 nil nil nil nil 626 nil true 8 #() 8 '&Show' #viewsShowMenu 1 754 nil true 800 8 'TestView.ico' 848 nil nil nil nil 8 '&Views' #viewsMenu 134217729 754 nil true 800 8 'View.ico' 848 nil nil nil nil 8 '&Class' nil 134217729 nil nil nil nil nil nil nil 560 1180230 1 ##(Smalltalk.ResourceIdentifier) ##(Smalltalk.ClassHierarchySelector) #resource_Moen_view nil 983302 ##(Smalltalk.MessageSequence) 138 144 34 2 721670 ##(Smalltalk.MessageSend) #createAt:extent: 34 2 328198 ##(Smalltalk.Point) 1 1 3314 701 501 560 3266 #contextMenu: 34 1 640 560 983302 ##(Smalltalk.WINDOWPLACEMENT) 8 #[44 0 0 0 0 0 0 0 1 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 0 0 0 0 0 0 0 0 94 1 0 0 250 0 0 0] 8 #() 3314 193 193 nil 27 170 192 34 2 560 8 'classes' nil 3202 138 144 34 1 3266 #createAt:extent: 34 2 3314 3839 21 3314 701 501 416 3394 8 #[44 0 0 0 0 0 0 0 1 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 127 7 0 0 10 0 0 0 221 8 0 0 4 1 0 0] 34 1 560 3456 nil 27 )! !
!ClassDiagramPlugin class categoriesFor: #icon!constants!public! !
!ClassDiagramPlugin class categoriesFor: #resource_Default_view!public!resources-views! !

