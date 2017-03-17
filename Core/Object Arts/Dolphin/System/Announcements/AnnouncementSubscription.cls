"Filed out from Dolphin Smalltalk 7"!

Object subclass: #AnnouncementSubscription
	instanceVariableNames: 'announcer announcementClass subscriber action'
	classVariableNames: ''
	poolDictionaries: ''
	classInstanceVariableNames: ''!
AnnouncementSubscription guid: (GUID fromString: '{4a8f9aba-3fcf-4905-9d19-124f99040d7a}')!
AnnouncementSubscription comment: 'The subscription is a single entry in a SubscriptionRegistry.
!AnnouncementSubscription categoriesForClass!Announcements-Core! !
!AnnouncementSubscription methodsFor!

action

action: anObject

announcementClass

announcementClass: anObject

announcer

announcer: anAnnouncer

deliver: anAnnouncement 
	" deliver an announcement to receiver."

	^(self handlesAnnouncement: anAnnouncement) ifTrue: [action cull: anAnnouncement cull: announcer]!

handlesAnnouncement: anAnnouncement

makeStrong

makeWeak
	^announcer replace: self
		with: ((WeakAnnouncementSubscription new)
				announcer: announcer;
				action: action asWeakMessageSend;
				subscriber: subscriber;
				announcementClass: announcementClass)!

subscriber

subscriber: aSubscriber

valuable: aValuable
!AnnouncementSubscription categoriesFor: #action!accessing!public! !
!AnnouncementSubscription categoriesFor: #action:!accessing!public! !
!AnnouncementSubscription categoriesFor: #announcementClass!accessing!public! !
!AnnouncementSubscription categoriesFor: #announcementClass:!accessing!public! !
!AnnouncementSubscription categoriesFor: #announcer!accessing!public! !
!AnnouncementSubscription categoriesFor: #announcer:!accessing!public! !
!AnnouncementSubscription categoriesFor: #deliver:!announcing!public! !
!AnnouncementSubscription categoriesFor: #handlesAnnouncement:!public!testing! !
!AnnouncementSubscription categoriesFor: #makeStrong!converting!public! !
!AnnouncementSubscription categoriesFor: #makeWeak!converting!public! !
!AnnouncementSubscription categoriesFor: #subscriber!accessing!public! !
!AnnouncementSubscription categoriesFor: #subscriber:!accessing!public! !
!AnnouncementSubscription categoriesFor: #valuable:!accessing!public! !
