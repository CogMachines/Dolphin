﻿"Filed out from Dolphin Smalltalk 7"!

MultilineTextEdit subclass: #RichTextEdit
	instanceVariableNames: 'streamIn winStruct'
	classVariableNames: 'AutoUrlDetectionMask Library ParagraphAlignmentMap StreamingDescriptor StreamInIndex'
	poolDictionaries: 'CommonDialogConstants RichEditConstants'
	classInstanceVariableNames: ''!
RichTextEdit guid: (GUID fromString: '{87b4c744-026e-11d3-9fd7-00a0cc3e4a32}')!
RichTextEdit addClassConstant: 'AutoUrlDetectionMask' value: 16r1000000!
RichTextEdit comment: 'RichTextEdit is a <valueView> class that implements the Windows "RichEdit" control for the displaying and editing of multi-line rich text. The <valueModel> associated with a RichTextEdit  must always yield a <richString> value when mapped through the installed type converter. A RichTextEdit will normally be used in conjunction with a <RichTextPresenter>. 

Note that the <richString> protocol relies on double dispatch (using #setTextInto:) to set either plain text or rich text into a destination <view> depending on it''s capabilities.

Instance Variables:
	streamIn		<BlockCallback> for streaming in text to the editor.
	winStruct		<EDITSTREAM> streaming information block.

Class Variables:
	StreamingDescriptor	<ExternalDescriptor> for stream-in callback parameters.

'!
!RichTextEdit categoriesForClass!MVP-Views! !
!RichTextEdit methodsFor!

basicLineFromPosition: anInteger 
	"Private - Answers the zero-based line index from the zero-based character position,
	anInteger. If anInteger is greater than the length of the text in the receiver, then the
	zero-based index of the last line is answered."

	^self 
		sendMessage: EM_EXLINEFROMCHAR
		wParam: 0
		lParam: anInteger!

basicSelectionRange
	"Private - Answer an interval identifying the selected range of text/ OLE objects, as
	reported by the underlying Windows control. Note that this range includes the starting
	character, but the end of the range is the first unselected character. Note further that
	this characteristic means that the range should NEVER be empty."

	| charRange |
	charRange := POINTL new.
	self sendMessage: EM_EXGETSEL wParam: 0 lpParam: charRange.
	^charRange x to: charRange y!

basicSelectionStart: start end: end
	"Private - Sets the selected range of text to the range defined by start and end 
	(0 based, end-exclusive)."

	| charRange |
	charRange := POINTL x: start y: end.
	self sendMessage: EM_EXSETSEL wParam: 0 lpParam: charRange!

beBold
	"Set the receiver to bold text mode."

	self isBold: true!

beItalic
	"Set the receiver to italic text mode."

	self isItalic: true!

beNonBold
	"Set the receiver to non-bold text mode."

	self isBold: false!

beNonItalic
	"Set the receiver to non-italic text mode."

	self isItalic: false!

beNonUnderlined
	"Set the receiver to non-underline text mode."

	self isUnderlined: false!

bePlain
	"Set the receiver to plain text mode."

	self selectionCharFormat: (CHARFORMAT2W new
				bePlain;
				yourself)!

beUnderlined
	"Set the receiver to underline text mode."

	self isUnderlined: true!

calculateExtent: aLayoutContext 
	"Private - Answer a calculated preferred extent for the receiver. It's not so easy to
	predict the formatting rectangle of rich text so we don't attempt it."

	^aLayoutContext extentOf: self!

canPaste
	"Answer whether the window can paste from the current contents of the clipboard."

	^(self sendMessage: EM_CANPASTE) ~= 0
		ifTrue: [true]
		ifFalse: [super canPaste]
!

canRedo
	"Answer whether the window can redo the last undone operation."

	^(self sendMessage: EM_CANREDO) ~=  0
!

charNearestPosition: aPoint 
	"Answer the one based index of the character nearest aPoint within the receiver. Note the
	differences in the parameter and return types from a normal Edit control in order to
	accomodate the larger potential size of a RichEdit (or course a multiline Edit control could
	be just as large on NT as well....)."

	^(self 
		sendMessage: EM_CHARFROMPOS
		wParam: 0
		lpParam: aPoint asParameter) + 1!

clear
	"Clears the contents of the receiver.
	Override to ensure the receiver has the correct character formatting."

	super clear.
	self resetCharFormat!

color: aColor
	"Private - Set the colour of the selection in the receiver to aColor."

	| cf |
	cf := CHARFORMAT2W new.
	cf color: aColor.
	self selectionCharFormat: cf!

defaultCharFormat
	"Private - Gets the default character attributes for the receiver."

	^self getCharFormat: 0!

defaultCharFormat: aCHARFORMAT
	"Private - Apply the specified character formatting options as the receiver's
	default format (i.e. that in use unless a selection overrides it)."

	self setCharFormat: aCHARFORMAT flags: 0!

defaultNotificationMask
	"Private - Answer the mask for the notifications we want to receiver.
	The default is to only ask for EN_SELCHANGE"

	^ENM_SELCHANGE bitOr: 1 "ENM_CHANGE"!

defaultWindowStyle
	"Private - Answer the default style to use when creating a rich edit control."

	^super defaultWindowStyle bitOr: 	##(
			"ES_SELECTIONBAR |"	"Not entirely sure what this does, but MFC sets by default"
			ES_AUTOVSCROLL 		"Scrolls vertically when caret would otherwise go out of window"
		)!

displayValue
	"Private - Answer the displayed contents, the rich text, of the receiver."

	"Implementation Note: The reason we don't use the #richText accessor
	is to assist image stripping. If we do then we create a reference to the 
	#richText selector which keeps the entire TextEdit/Presenter group
	in the image."

	^self privGetRichText!

displayValue: aRichString
	"Private - Set the displayed contents or the receiver to the text argument,
	(either a RichText, or a String, or nil)."

	| newValue |
	newValue := aRichString ?? ''.
	self displayValue = newValue ifFalse: [self text: newValue]!

enLink: anExternalAddress 
	| struct |
	struct := ENLINK fromAddress: anExternalAddress.
	struct msg = WM_LBUTTONUP 
		ifTrue: 
			[| range text |
			range := struct chrg.
			text := self plainTextRange: (range cpMin + 1 to: range cpMax).
			self presenter trigger: #linkClicked: with: text].
	^nil!

enSelChange: anNMHDR
	self invalidateUserInterface!

eventMask
	^self sendMessage: EM_GETEVENTMASK!

eventMask: anInteger 
	self 
		sendMessage: EM_SETEVENTMASK
		wParam: 0
		lParam: anInteger!

eventMask: anInteger set: aBoolean 
	self eventMask: (self eventMask mask: anInteger set: aBoolean)!

filerProxy
	"Private - Answer a filer proxy that represents the receiver."

	| answer |
	answer := super filerProxy.
	answer instVars at: StreamInIndex put: nil.
	^answer!

find: aFindDetails range: anInterval 
	"Private - Find the first occurrence of aString in the text of the receiver within the range rangeInterval."

	"For simple searches we can use the RichEdit search facility, anything else we have to implement ourselves"

	| frFlags |
	(aFindDetails isForwards not or: [aFindDetails isRegularExpression]) 
		ifTrue: [^super find: aFindDetails range: anInterval].
	frFlags := 0.
	aFindDetails isForwards ifTrue: [frFlags := frFlags maskSet: FR_DOWN].
	aFindDetails isWholeWord ifTrue: [frFlags := frFlags maskSet: FR_WHOLEWORD].
	aFindDetails isCaseSensitive ifTrue: [frFlags := frFlags maskSet: FR_MATCHCASE].
	^self 
		find: aFindDetails pattern
		range: anInterval
		flags: frFlags!

find: findString range: findRange flags: frFlags
	"Attempt to find the text findString in the receivers text within findRange. flags are from
	FINDREPLACE. Answer the (1-based) position of the found string, or 0 if nothing matched."

	| findText start stop range |
	findRange isNil
		ifTrue: 
			[start := 0.
			stop := self textLength]
		ifFalse: 
			[start := findRange start - 1.
			stop := findRange stop].
	findText := FINDTEXTEX
				from: start
				to: stop
				text: findString asUtf16String.
	self
		sendMessage: EM_FINDTEXTEXW
		wParam: frFlags
		lpParam: findText.
	range := findText chrgText.
	^range cpMin + 1 to: range cpMax!

forecolor: aColorOrNil
	"Sets the foreground colour of the receiver to aColorOrNil.
	If aColorOrNil is nil then use the default color"

	| cf |
	super forecolor: aColorOrNil.
	cf := CHARFORMAT2W new.
	cf color: (aColorOrNil notNil ifTrue: [aColorOrNil] ifFalse: [Color windowText]).
	self defaultCharFormat: cf!

getCharFormat: flagsMask
	"Private - Gets the receiver control's character attributes, according
	to flagsMask, as follows:
		0 -				- Answer the default attributes (i.e. those set by '\plain\pard\sectd')
		SCF_SELECTION	- Answer the common attributes of the selection
		SCF_ALL			- Answer the common attributes of all the text
	"

	| cf |
	cf := CHARFORMAT2W new.
	"We want all attributes"
	cf dwMask: 16rFFFFFFFF.
	self
		sendMessage: EM_GETCHARFORMAT
		wParam: flagsMask
		lpParam: cf asParameter.
	^cf!

getWindowText: flagsInteger length: lengthInteger
	| buf struct |
	buf := Utf16String newFixed: lengthInteger.
	struct := GETTEXTEX newBuffer
				cb: lengthInteger + 1 << 1;
				flags: GT_USECRLF | flagsInteger;
				codepage: CP_UNICODE;
				yourself.
	"The docs say the return value is the number of chars (not byte) copied including the null, but actually it is
	the number of chars excluding the null. We ignore it anyway."
	self
		sendMessage: EM_GETTEXTEX
		wParam: struct yourAddress
		lpParam: buf.
	^buf asUtf8String!

initialize
	"Private - Allocate Win32 EDITSTREAM structure for communicating with control
	and perform superclass initialization."

	super initialize.
	self setMaxTextLimit.
	winStruct := EDITSTREAM new!

isBold
	"Answer true if receiver's current selection is bold."

	^self selectionCharFormat isBold!

isBold: set
	"Private - Turn on/off emboldening for the receiver's current selection."

	self selectionCharFormat: (CHARFORMAT2W new
				isBold: set;
				yourself)!

isItalic
	"Answer true if receiver's current selection is italic."

	^self selectionCharFormat isItalic!

isItalic: set
	"Private - Turn on/off italics for the receiver's current selection."

	self selectionCharFormat: (CHARFORMAT2W new
				isItalic: set;
				yourself)!

isSelectionKept
	"Answer true if the receiver is set to maintain selection after losing focus.
	This is a manifestation of the ECO_NOHIDESEL style"

	^self baseStyleAllMask: ECO_NOHIDESEL!

isSelectionKept: aBoolean 
	"Sets the receiver to maintain selection after losing focus according to aBoolean.
	This is a manifestation of the ECO_NOHIDESEL style"

	self 
		baseStyleMask: ECO_NOHIDESEL
		set: aBoolean
		recreateIfChanged: true	"Recreate required for this change to take effect"!

isUnderlined
	"Answer true if receiver's current selection is underlined."

	^self selectionCharFormat isUnderlined!

isUnderlined: set
	"Turn on/off underlining for the receiver's current selection."

	self selectionCharFormat: (CHARFORMAT2W new
				isUnderlined: set;
				yourself)!

isUrlDetectionEnabled
	^teFlags allMask: AutoUrlDetectionMask!

isUrlDetectionEnabled: aBoolean 
	aBoolean = self isUrlDetectionEnabled ifTrue: [^self].
	teFlags := teFlags mask: AutoUrlDetectionMask set: aBoolean.
	self isOpen ifTrue: [self setAutoUrlDetection: aBoolean]!

nmNotify: pNMHDR
	^(##((Array new: EN_DRAGDROPDONE - EN_MSGFILTER + 1 withAll: #nmDummy:)
		at: EN_SELCHANGE - EN_MSGFILTER + 1 put: #enSelChange:;
		at: EN_LINK - EN_MSGFILTER + 1 put: #enLink:;
		yourself) lookup: (pNMHDR sdwordAtOffset: 8) - ##(EN_MSGFILTER - 1))
		ifNil: [super nmNotify: pNMHDR]
		ifNotNil: [:action | self perform: action with: pNMHDR]!

onRightButtonReleased: aMouseEvent
	"Default handler for a Right button up mouse event.
	Accept the default window processing."

	self presenter trigger: #rightButtonReleased: with: aMouseEvent.

	"#228: There is a bug in the version 1.0 RichEdit control such that it doesn't pop its
	context menu (presumably doesn't forward WM_RBUTTONUP to the DefWindowProc.
	Therefore we need to send WM_CONTEXTMENU explicitly. The bug was fixed in the
	v3.0 control emulating 1.0, but as it is very difficult to determine if the original control
	or the emulation is in place, we take total control of this and suppress the controls
	own WM_RBUTTONUP handling by return zero."
	self
		sendMessage: WM_CONTEXTMENU
		wParam: handle
		lParam: aMouseEvent screenPosition asUIntPtr.
	^0!

onViewCreated
	"The receiver window has just been created. Inform it of the
	required background and foreground colours, and ensure it picks
	up the default character format."

	super onViewCreated.
	self backcolor ifNotNil: [:color | self backcolor: color].
	self forecolor ifNotNil: [:color | self forecolor: color].

	"Also ask to receive notifications"
	self 
		sendMessage: WM_SETEVENTMASK
		wParam: 0
		lParam: self defaultNotificationMask.

	"3.05 BUG Fix: Text will be truncated to 32Kb on image restart if don't increase limit"
	self setMaxTextLimit.
	self isUrlDetectionEnabled ifTrue: [self setAutoUrlDetection: true]!

onViewOpened
	"Handler for view opened"

	super onViewOpened.
	"Win2k bug fix: RTEs keep reverting to Times Roman"
	self font isNil ifTrue: [self setFont: self actualFont]!

paragraphAlignment
	"Answer a symbolic alignment for the receiver's current paragraph"

	^ParagraphAlignmentMap keyAtValue: self selectionParaFormat alignment!

paragraphAlignment: aSymbol
	"Sets the paragraph alignment to the symbolic aligment name, aSymbol."

	| pf |
	pf := PARAFORMAT new.
	pf alignment: (ParagraphAlignmentMap at: aSymbol).
	self selectionParaFormat: pf.
	self updatePerChar ifTrue: [self updateModel].


	!

paragraphIndent
	"Answer an <Integer> indent for the receiver's current paragraph"

	^self selectionParaFormat startIndent!

paragraphIndent: anInteger
	"Sets the paragraph indent to anInteger"

	| pf |
	pf := PARAFORMAT new.
	pf startIndent: anInteger.
	self selectionParaFormat: pf.

	!

paragraphOffset
	"Answer an <Integer> offset for the receiver's current paragraph"

	^self selectionParaFormat offset!

paragraphOffset: anInteger
	"Sets the paragraph offset to anInteger"

	| pf |
	pf := PARAFORMAT new.
	pf offset: anInteger.
	self selectionParaFormat: pf.

	!

pastePlainText
	"Paste the clipboard text into the receiver's window."

	self replaceSelection: Clipboard current getText!

plainText
	"Answer a <Utf16String> containing the plain text contents of the receiver."

	^self getWindowText: 0 length: self textLength!

plainTextFrom: start to: stop
	"Answer a string containing the plain text contents of the receiver
	in the specified 1-based, end-inclusive, range."

	| range num text |
	start < 1 ifTrue: [^self errorSubscriptBounds: start].
	stop < start ifTrue: [^String new].
	range := TEXTRANGE
				from: start - 1
				to: stop
				type: Utf16String.
	num := self
				sendMessage: EM_GETTEXTRANGE
				wParam: 0
				lpParam: range.
	text := range text.
	^num = text size ifTrue: [text] ifFalse: [self errorSubscriptBounds: stop]!

pointSize: anInteger
	"Private - Set the point size of the currently selected text to, anInteger."

	| cf |
	cf := CHARFORMAT2W new.
	cf pointSize: anInteger.
	self selectionCharFormat: cf!

positionAtLine: lineNumber
	"Answer the index of the first character in the specified line (if 0 then
	the line containing the caret). Raise a BoundsError if the lineNumber is 
	<= 0 or > number of lines.
	This is only overridden due to a bug in the RichEdit control whereby it may
	report an error where a line is in range, but has not yet been streamed.
	We force the whole text to be streamed by asking for the line length."

	self lineCount.
	^super positionAtLine: lineNumber
!

positionOfChar: anInteger 
	"Map the one-based index of a character in the receiver to its client co-ordinates
	within the receiver."

	| pt |
	pt := POINTL new.
	self 
		sendMessage: EM_POSFROMCHAR
		wParam: pt yourAddress
		lParam: anInteger - 1.
	^pt asPoint!

printRtfOn: puttableStream
	"Append the receiver control's RTF contents to the argument,
	puttableStream, i.e. this method is used to GET RTF from the receiver."

	^self printRtfOn: puttableStream format: ##(CP_UTF8 << 16 | SF_USECODEPAGE)!

printRtfOn: puttableStream format: formatMask
	"Private - Stream the RTF contents of the receiver to the stream aStream. i.e. this method
	is used to GET text from the receiver. The RTF is always streamed in UTF-8, so the stream
	needs to be over a string that supports unicode encodings or there will be data loss."

	| stringClass |
	stringClass := formatMask >> 16 == CP_UTF8 ifTrue: [Utf8String] ifFalse: [AnsiString].
	^self streamOut: formatMask | SF_RTF
		format: (ExternalCallback block: 
					[:dwCookie :pbBuff :cb :pcb |
					| str |
					str := stringClass fromAddress: pbBuff length: cb.
					"We don't want the null terminator, if present"
					(str basicAt: cb) = 0 ifTrue: [str := str resize: cb - 1].
					puttableStream nextPutAll: str.
					pcb value: cb.
					0	"Continue streaming"]
				descriptor: StreamingDescriptor)!

printTextOn: aStream
	"Private - Stream the plain text contents of the receiver to the <puttableStream>, aStream."

	^self printTextOn: aStream format: SF_TEXT!

printTextOn: aStream format: anInteger
	^self streamOut: anInteger | SF_UNICODE
		format: (ExternalCallback block: 
					[:dwCookie :pbBuff :cb :pcb |
					| str cch |
					"Control sends block size in bytes, not chars"
					cch := cb bitShift: -1.
					str := Utf16String fromAddress: pbBuff length: cch.
					"Ignore any null terminator"
					(str basicAt: cch) = 0 ifTrue: [str := str allButLast].
					aStream nextPutAll: str.
					pcb value: cb.
					"Continue streaming"
					0]
				descriptor: StreamingDescriptor)!

privGetRichText
	"Private - Answer the <RichText> contents of the receiver."

	"Implementation Note: The reason we have this separate method, rather
	than just implementing directly in #richText, is so that we don't have
	to send #richText from this class. If we do then we create a reference to the 
	#richText selector which keeps the entire TextEdit/Presenter group
	in the image when stripping because #richText is implemented on View."

	^self richTextClass fromRtf: self rtfText!

queryCommand: aCommandQuery 
	"Private - Enters details about a potential command for the receiver into the 
	<CommandQuery> argument."

	| command |
	command := aCommandQuery commandSymbol.
	(#(#pastePlainText) identityIncludes: command) 
		ifTrue: 
			[aCommandQuery isEnabled: self canPaste.
			^true].
	^super queryCommand: aCommandQuery!

readRtfFrom: aPositionableStream
	"Replace the receiver control's contents with the RTF data read from the argument,
	gettableStream."

	^self
		streamIn: (ExternalCallback block: 
					[:dwCookie :pbBuff :cb :pcb |
					| text size |
					text := aPositionableStream nextAvailable: cb.
					size := text size.
					pbBuff
						replaceFrom: 1
						to: size
						with: text
						startingAt: 1.
					pcb value: size.
					0]
				descriptor: StreamingDescriptor)
		format: SF_RTF!

readTextFrom: gettableStream
	"Replace the receiver control's contents with the plain text 
	read from the argument, gettableStream."

	^self readTextFrom: gettableStream format: ##(SF_TEXT | SF_UNICODE).
!

readTextFrom: gettableStream format: formatMask
	"Private - Stream text from the stream, gettableStream, into the RichEdit control. The
	receiver holds on the to the stream it is reading, because the RichEdit control appears to
	read from it asynchronously. Answer the number of characters read from aStream.
	Implementation Note: Extend the life of the old 'stream' to the end of the method in case
	control still using it - BUT we must be very careful not to cause a reference to the old
	callback to be kept in this method context, otherwise we'll build a huge linked list of
	callbacks, blocks, and method contexts, etc."

	^self
		streamIn: (ExternalCallback block: 
					[:dwCookie :pbBuff :cb :pcb |
					| text size |
					text := (gettableStream nextAvailable: cb) asUtf16String.
					size := text size bitShift: 1.
					pbBuff
						replaceFrom: 1
						to: size
						with: text
						startingAt: 1.
					pcb value: size.
					"Continue streaming"
					0]
				descriptor: StreamingDescriptor)
		format: formatMask!

resetCharFormat
	"Resets the formatting attributes of the selection to the default mode."

	| cf |
	cf := self defaultCharFormat.		"Get the overall attributes, not those of the selection"
	self selectionCharFormat: cf.!

richText
	"Answer a RichText containing the RTF contents of the receiver."

	^self privGetRichText!

richText: aRichText
	"Private - Set the text contents of the receiver to the RTF text, aRichText.
	Part of the RichText double dispatching protocol"

	self rtfText: aRichText rtf!

rtfText
	"Private - Answer a String containing the RTF contents of the receiver."

	| aStream |
	aStream := Utf8String writeStream: 1024.
	self printRtfOn: aStream.
	^aStream contents!

rtfText: aString
	"Private - Set the text contents of the receiver to the raw 
	RTF in aString.
	Part of the RichText double dispatching protocol"

	self readRtfFrom: aString readStream
!

selection
	"Answer a string containing the plain text of the selection in the receiver."

	| selection cch |
	cch := self basicSelectionRange size - 1.
	cch == 0 ifTrue: [^''].
	selection := self getWindowText: GT_SELECTION length: cch.
	"Strip off the final null if present"
	(selection basicAt: cch) == 0 ifTrue: [selection resize: cch - 1].
	^selection!

selectionCharFormat
	"Private - Gets the attributes of the selection in the receiver."

	^self getCharFormat: SCF_SELECTION!

selectionCharFormat: aCHARFORMAT 
	"Private - Apply the specified character formatting options to the receiver's
	current selection (or from the insertion point if no selection."

	self setCharFormat: aCHARFORMAT flags: SCF_SELECTION.
	self updatePerChar ifTrue: [self updateModel]!

selectionColor
	"Answer the colour of the selection in the receiver "

	^self selectionCharFormat color!

selectionColor: aColorOrNil
	"Set the colour of the selection in the receiver to aColorOrNil. If nil then
	set the colour to the default window text"

	self selectionCharFormat: (CHARFORMAT2W new
				color: aColorOrNil;
				yourself)!

selectionFont
	"Answer the font of the selection in the receiver "

	^self selectionCharFormat font!

selectionFont: aFont
	"Set the font of the selection in the receiver to aFont"

	| cf |
	cf := CHARFORMAT2W new.
	cf font: aFont.
	self selectionCharFormat: cf!

selectionParaFormat
	"Private - Answer a <PARAFORMAT> detailing the paragraph format options
	for the current selection."

	| pf |
	pf := PARAFORMAT new.
	"We want all attributes"
	pf dwMask: 16rFFFFFFFF.
	self sendMessage: EM_GETPARAFORMAT wParam: 0 lpParam: pf asParameter.
	^pf!

selectionParaFormat: options
	"Private - Set paragraph formatting options for the current selection
	in the receiver to those specified in the <PARAFORMAT>, options."

	self sendMessage: EM_SETPARAFORMAT wParam: 0 lpParam: options asParameter!

selectionPlainText: aString
	| stex |
	stex := ByteArray newFixed: 8.
	stex
		dwordAtOffset: 0 put: ST_SELECTION | ST_UNICODE;
		dwordAtOffset: 4 put: aString codePage.
	self
		sendMessage: EM_SETTEXTEX
		wParam: stex yourAddress
		lpParam: aString!

selectionRichText
	"Private - Answer the selected RichText in the receiver."

	^self richTextClass fromRtf: self selectionRtf!

selectionRichText: aRichText
	"Private - Replace the selected text in the receiver with the RTF 
	string, aRichText.
	This is the backend of a double-dispatch protocol between TextEdits and 
	RichText/Strings."

	^self readTextFrom: aRichText rtf readStream
		format: ##(SFF_SELECTION | (CP_UTF8 << 16) | SF_USECODEPAGE | SF_RTF)!

selectionRtf
	"Private - Answer the selected text in the receiver as an RTF <Utf8String>."

	| s |
	s := Utf8String writeStream: 512.
	self printRtfOn: s format: ##(CP_UTF8 << 16 | SF_USECODEPAGE | SFF_SELECTION).
	^s contents!

setAutoUrlDetection: aBoolean 
	self sendMessage: EM_AUTOURLDETECT wParam: aBoolean asParameter.
	self eventMask: ENM_LINK set: aBoolean!

setCharFormat: aCHARFORMAT flags: maskInteger
	"Private - Set the receiver control's default/selection character attributes
	(depending on the flags mask). Answer whether the call succeeded."

	^(self sendMessage: EM_SETCHARFORMAT wParam: maskInteger lpParam: aCHARFORMAT) ~= 0!

setControlBackcolor: aColor 
	self 
		sendMessage: EM_SETBKGNDCOLOR
		wParam: 0
		lParam: aColor asColorRef asParameter!

setFont: aFont
	"Private - Sets the font for the entire receiver text to be aFont. Overridden here because
	the Windows RichEdit control does not correctly redraw on font change"

	| modified |
	modified := self isTextModified.
	super setFont: aFont.
	aFont isNil
		ifFalse: 
			[| cf |
			cf := CHARFORMAT2W new.
			cf font: aFont.
			self setCharFormat: cf flags: SCF_ALL].
	self isTextModified: modified!

setMaxTextLimit
	"Private - Increase the maximum text limit. The default is 32K."

	self textLimit: self maxTextLimit!

setWindowText: aString
	"Private - Set the contents of the receiver to aString, interpreting as plain text or RTF depending on the content."

	"Unusually the RichEdit control will accept different string encodings through EM_SETTEXTEX,
	so we don't need to first translate to UTF-16, but just pass along whatever we get."

	| stex |
	stex := ByteArray newFixed: 8.
	stex dwordAtOffset: 4 put: aString codePage.
	self
		sendMessage: EM_SETTEXTEX
		wParam: stex yourAddress
		lpParam: aString!

state
	"Private - Answer a MessageSequence which, when replayed, will restore the receiver 
	to its current state.
	Implementation Note: We must send resetCharFormat as the last thing we do 
	to pick up the actual default settings which may have been overridden by the RTF
	text loaded in after the default font was set. However we only want to do this if
	the selection is empty as otherwise we'll (a) set the modification flag as a side
	effect and (b) modify the formatting of the selection back to the default."

	| sequence |
	sequence := super state.
	self hasSelection ifFalse: [sequence add: (MessageSend receiver: self selector: #resetCharFormat)].

	"NOTE: If adding anything to the sequence bear in mind that it may affect the control's
	 modification flag, the value of which is preserved by the last message in the inherited
	 state and which will therefore be overridden if the text is modified in any way
	 by messages added to the end of the sequence here."
	^sequence!

streamIn: callback format: anInteger
	| answer |
	winStruct pfnCallback: callback asParameter.
	answer := self
				sendMessage: EM_STREAMIN
				wParam: anInteger
				lpParam: winStruct.
	self isTextModified: false.
	"It seems we have to increase the limit again after streaming in."
	self setMaxTextLimit.
	streamIn isNil ifFalse: [streamIn free].
	streamIn := callback.
	^answer!

streamOut: formatMask format: callback
	| result |
	winStruct pfnCallback: callback asParameter.
	result := self
				sendMessage: EM_STREAMOUT
				wParam: formatMask
				lpParam: winStruct.
	callback free.
	^result!

text
	"Answer the text contents of the receiver (N.B. this will be RichText)."

	^self privGetRichText!

textLength
	"Private - Answers the length of text for the receiver. This is the number of 16-bit code
	units required to represent the content in UTF-16, and therefore the size of Utf16String
	required to hold that content."

	| gtlex |
	gtlex := ByteArray newFixed: 8.
	gtlex
		dwordAtOffset: 0 put: ##(GTL_USECRLF | GTL_PRECISE | GTL_NUMCHARS);
		dwordAtOffset: 4 put: CP_UNICODE.
	^self sendMessage: EM_GETTEXTLENGTHEX wParam: gtlex yourAddress!

textLimit: anInteger
	"Set the maximum text limit for the receiver. 
	N.B. The actual limit is not documented, but it seems to be less than 16rFFFFFFFF (the claimed
	limit for a multiline edit control)."

	(anInteger between: 1 and: self maxTextLimit) ifFalse: [self errorSubscriptBounds: anInteger].
	^self sendMessage: EM_EXLIMITTEXT wParam: 0 lParam: anInteger!

winFinalize
	"Private - Perform finalization actions for this View on destruction."

	streamIn isNil ifFalse: [streamIn free. streamIn := nil].
	^super winFinalize!

wmInitMenu: message wParam: wParam lParam: lParam
	"Private - A top-level menu is about to be popped.
	Implementation Note: RichEdit control sets the I-beam cursor (if there is 
	no selection) at some point after TrackPopupMenu() is called, so we
	override back to the (correct) arrow cursor."

	Cursor arrow setCursor.
	^super wmInitMenu: message wParam: wParam lParam: lParam! !
!RichTextEdit categoriesFor: #basicLineFromPosition:!accessing!private! !
!RichTextEdit categoriesFor: #basicSelectionRange!helpers!private! !
!RichTextEdit categoriesFor: #basicSelectionStart:end:!helpers!private! !
!RichTextEdit categoriesFor: #beBold!modes!public! !
!RichTextEdit categoriesFor: #beItalic!modes!public! !
!RichTextEdit categoriesFor: #beNonBold!modes!public! !
!RichTextEdit categoriesFor: #beNonItalic!modes!public! !
!RichTextEdit categoriesFor: #beNonUnderlined!modes!public! !
!RichTextEdit categoriesFor: #bePlain!modes!public! !
!RichTextEdit categoriesFor: #beUnderlined!modes!public! !
!RichTextEdit categoriesFor: #calculateExtent:!geometry!private! !
!RichTextEdit categoriesFor: #canPaste!public!testing! !
!RichTextEdit categoriesFor: #canRedo!public!testing!undo & redo! !
!RichTextEdit categoriesFor: #charNearestPosition:!accessing!public! !
!RichTextEdit categoriesFor: #clear!operations!public! !
!RichTextEdit categoriesFor: #color:!helpers!private! !
!RichTextEdit categoriesFor: #defaultCharFormat!accessing!private! !
!RichTextEdit categoriesFor: #defaultCharFormat:!accessing!private! !
!RichTextEdit categoriesFor: #defaultNotificationMask!constants!private! !
!RichTextEdit categoriesFor: #defaultWindowStyle!constants!private! !
!RichTextEdit categoriesFor: #displayValue!private!updating! !
!RichTextEdit categoriesFor: #displayValue:!private!updating! !
!RichTextEdit categoriesFor: #enLink:!event handling-win32!private! !
!RichTextEdit categoriesFor: #enSelChange:!event handling-win32!private! !
!RichTextEdit categoriesFor: #eventMask!accessing!private! !
!RichTextEdit categoriesFor: #eventMask:!accessing!private! !
!RichTextEdit categoriesFor: #eventMask:set:!accessing!private! !
!RichTextEdit categoriesFor: #filerProxy!binary filing!private! !
!RichTextEdit categoriesFor: #find:range:!private!searching and replacing! !
!RichTextEdit categoriesFor: #find:range:flags:!public!searching and replacing! !
!RichTextEdit categoriesFor: #forecolor:!accessing!public! !
!RichTextEdit categoriesFor: #getCharFormat:!helpers!private! !
!RichTextEdit categoriesFor: #getWindowText:length:!accessing!private! !
!RichTextEdit categoriesFor: #initialize!initializing!private! !
!RichTextEdit categoriesFor: #isBold!helpers!public! !
!RichTextEdit categoriesFor: #isBold:!helpers!private! !
!RichTextEdit categoriesFor: #isItalic!helpers!public! !
!RichTextEdit categoriesFor: #isItalic:!helpers!private! !
!RichTextEdit categoriesFor: #isSelectionKept!accessing!public! !
!RichTextEdit categoriesFor: #isSelectionKept:!accessing!public! !
!RichTextEdit categoriesFor: #isUnderlined!helpers!public! !
!RichTextEdit categoriesFor: #isUnderlined:!helpers!public! !
!RichTextEdit categoriesFor: #isUrlDetectionEnabled!public!testing! !
!RichTextEdit categoriesFor: #isUrlDetectionEnabled:!accessing!public! !
!RichTextEdit categoriesFor: #nmNotify:!event handling-win32!private! !
!RichTextEdit categoriesFor: #onRightButtonReleased:!event handling!public! !
!RichTextEdit categoriesFor: #onViewCreated!event handling!public! !
!RichTextEdit categoriesFor: #onViewOpened!event handling!public! !
!RichTextEdit categoriesFor: #paragraphAlignment!accessing!public! !
!RichTextEdit categoriesFor: #paragraphAlignment:!accessing!public! !
!RichTextEdit categoriesFor: #paragraphIndent!accessing!public! !
!RichTextEdit categoriesFor: #paragraphIndent:!accessing!public! !
!RichTextEdit categoriesFor: #paragraphOffset!accessing!public! !
!RichTextEdit categoriesFor: #paragraphOffset:!accessing!public! !
!RichTextEdit categoriesFor: #pastePlainText!commands!public! !
!RichTextEdit categoriesFor: #plainText!accessing!public! !
!RichTextEdit categoriesFor: #plainTextFrom:to:!accessing!public! !
!RichTextEdit categoriesFor: #pointSize:!accessing!private! !
!RichTextEdit categoriesFor: #positionAtLine:!accessing!public! !
!RichTextEdit categoriesFor: #positionOfChar:!accessing!public! !
!RichTextEdit categoriesFor: #printRtfOn:!public!streaming! !
!RichTextEdit categoriesFor: #printRtfOn:format:!private!streaming! !
!RichTextEdit categoriesFor: #printTextOn:!public!streaming! !
!RichTextEdit categoriesFor: #printTextOn:format:!private!streaming! !
!RichTextEdit categoriesFor: #privGetRichText!private!updating! !
!RichTextEdit categoriesFor: #queryCommand:!commands!private! !
!RichTextEdit categoriesFor: #readRtfFrom:!public!streaming! !
!RichTextEdit categoriesFor: #readTextFrom:!public!streaming! !
!RichTextEdit categoriesFor: #readTextFrom:format:!private!streaming! !
!RichTextEdit categoriesFor: #resetCharFormat!operations!public! !
!RichTextEdit categoriesFor: #richText!accessing!public! !
!RichTextEdit categoriesFor: #richText:!accessing!private! !
!RichTextEdit categoriesFor: #rtfText!accessing!private! !
!RichTextEdit categoriesFor: #rtfText:!accessing!private! !
!RichTextEdit categoriesFor: #selection!accessing!public! !
!RichTextEdit categoriesFor: #selectionCharFormat!accessing!private! !
!RichTextEdit categoriesFor: #selectionCharFormat:!accessing!private! !
!RichTextEdit categoriesFor: #selectionColor!accessing!public! !
!RichTextEdit categoriesFor: #selectionColor:!operations!public! !
!RichTextEdit categoriesFor: #selectionFont!accessing!public! !
!RichTextEdit categoriesFor: #selectionFont:!operations!public! !
!RichTextEdit categoriesFor: #selectionParaFormat!accessing!private! !
!RichTextEdit categoriesFor: #selectionParaFormat:!accessing!private! !
!RichTextEdit categoriesFor: #selectionPlainText:!private!selection! !
!RichTextEdit categoriesFor: #selectionRichText!private!selection! !
!RichTextEdit categoriesFor: #selectionRichText:!private!selection! !
!RichTextEdit categoriesFor: #selectionRtf!private!selection! !
!RichTextEdit categoriesFor: #setAutoUrlDetection:!helpers!private! !
!RichTextEdit categoriesFor: #setCharFormat:flags:!helpers!private! !
!RichTextEdit categoriesFor: #setControlBackcolor:!helpers!private! !
!RichTextEdit categoriesFor: #setFont:!helpers!private! !
!RichTextEdit categoriesFor: #setMaxTextLimit!operations!private! !
!RichTextEdit categoriesFor: #setWindowText:!accessing!private! !
!RichTextEdit categoriesFor: #state!accessing!private! !
!RichTextEdit categoriesFor: #streamIn:format:!private!streaming! !
!RichTextEdit categoriesFor: #streamOut:format:!private!streaming! !
!RichTextEdit categoriesFor: #text!accessing!public! !
!RichTextEdit categoriesFor: #textLength!accessing!private! !
!RichTextEdit categoriesFor: #textLimit:!operations!public! !
!RichTextEdit categoriesFor: #winFinalize!event handling!private! !
!RichTextEdit categoriesFor: #wmInitMenu:wParam:lParam:!event handling-win32!private! !

!RichTextEdit class methodsFor!

initialize
	"Private - Initialize the receiver's class variables.
		RichTextEdit initialize
	"

	self registerClass.
	StreamInIndex := self indexOfInstVar: 'streamIn'.

	"Descriptor for stream out callback"
	StreamingDescriptor := ExternalDescriptor argumentTypes: 'dword lpvoid sdword DWORD*'.
	ParagraphAlignmentMap := (IdentityDictionary new)
				at: #left put: PFA_LEFT;
				at: #right put: PFA_RIGHT;
				at: #center put: PFA_CENTER;
				shrink;
				isImmutable: true;
				yourself.
	self addClassConstant: 'AutoUrlDetectionMask' value: 16r1000000.!

maxTextLimit
	"Private - Answer the absolute maximum amount of text that the receiver can ever hold."

	^SmallInteger maximum!

registerClass
	"Private - Ensure the the rich edit window class is registered by loading the relevant library."

	(Library isNil or: [Library isOpen not])
		ifTrue: [Library := ExternalLibrary open: self richEditDllName]!

richEditDllName
	^'riched20.dll'
	"^'msftedit.dll'"!

winClassName
	"Private - Answer the name of the Windows window class to use when realizing the receiver."

	self registerClass.
	^'RichEdit20W'! !
!RichTextEdit class categoriesFor: #initialize!development!initializing!private! !
!RichTextEdit class categoriesFor: #maxTextLimit!constants!private! !
!RichTextEdit class categoriesFor: #registerClass!initializing!private! !
!RichTextEdit class categoriesFor: #richEditDllName!constants!private! !
!RichTextEdit class categoriesFor: #winClassName!constants!private! !

