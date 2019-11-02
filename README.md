# cfc_notifications
CFC's Notification Library

## Planned structure/features (rough draft / to be rewritten)
### What it needs to support
 - Notifications must have an id (for blocking)
 - Recurring notifications exist (specific num of repeats, and delay)
 - trigger notification from shared
 - all notifications can be sent to a player or have a filter function (or default to GetAll())
 - notifications have lifetime (delay before hiding self)

### Technical details
 - need someway to click on notification (escape mouse with key?)
 - Message can be string or function
   - func takes id, ply
 - support buttons with callback
   - some sort of button class which has text, callback, maybe position and colour?
   - sent to client with some kind of id to call the callback on server on click
   - button callback takes ply
   - Button auto shows a number next to them for easy clicking

 - Some id's cannot be blocked, for very important messages
   - perhaps a "makeUnblockable(ID)"

 - Default notification presets
   - Generate their own id? or have some presets like "MinorNotif", "MajorNotif", "MajorQuestion"
   - Simple message (with/without "Okay")
   - Simple question (Yes or No)
   - Simple survey (Give it options and question and expiration, it'll ask random players it hasnt yet asked after some time, and accumulate the result)
     - Will probably need to store in file? as JSON, could layer change to SQL once it starts being used

- Way to disable all messages or hide current message
  - Hiding current adds id of current message to blacklist
    - keep track of blacklist client side, as json prolly
  - Disable all asks you to confirm, cuz could be important info

- Support multiple messages at once by bubbling them up
  - Client must keep track of which notifs are currently shown

### Implementation
- registerNotification()
- triggerNotification()
- makeUnblockable()
- repeatNotification()
- etc.
