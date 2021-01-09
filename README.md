# cfc_notifications
CFC's Notification Library!

## Overview
This library acts as a framework for notifications of any functionality to be created, managed and removed.  
Notifications are treated as objects with methods and fields, these objects have a type which defines how they look, behave, etc. and they can be created and displayed from server or client.  
One can also easily define their own notification types, similar to how you would create a vgui element.
Each notification object has an ID, simply a string.  
This allows the notification to be blocked (temporarily or permanently) by specific clients (if permitted) and for networking of notification events.
Notifications will automatically wrap text and grow taller to accomodate long messages.

## Client
Clients can press F3 (or open chat) to release their mouse and interact with notifications.
This library implements an options menu on the client, where they can configure:
- Maximum visible notifications.
- Notification width.
- Vertical position of first notification.
- Enable/disable the pop sound.
- Minimum priority required for the pop sound.
- Whether the mouse should default to near notifications when releasing it.

They can also fire a test notification, reload the addon, or reset it to factory settings.  
Lastly, they can see their permanently blocked, temporarily (per session) blocked and unblocked notifications, and move them between these 3 categories.

## Simple usage
There are several easy to use helper functions for sending out generic notifications.  
All notifications support a filter argument, this argument only functions on the server, and can be any of the following:
- `nil` - Sends to all players.
- `table` - Sends to all players in this table.
- `player` - Sends only to that player.
- `function` - Expected to return one of the above types, sends to those players.

Notifications also contain a priority, which can be any of the following enums (these are fields on `CFCNotifications`):
- `PRIORITY_MIN`
- `PRIORITY_LOW`
- `PRIORITY_NORMAL`
- `PRIORITY_HIGH`
- `PRIORITY_MAX`

The helper functions are as follows:
- `CFCNotifications.sendSimple( id, title, message, filter )`  
  This displays a simple text notification, defaulting with LOW priority, and can be closed and ignored.
  - `id` - String identifier for the notification.
  - `title` - Title text.
  - `message` - Contents of the notification.
  - `filter` - See above for filter usage.

- `CFCNotifications.sendImportantSimple( id, title, message, filter )`  
  Acts the same as above, but cannot be closed or ignored. This will disapear after 5 seconds, and defaults with `MAX` priority (thus showing a red titlebar).

- `CFCNotifications.sendHint( id, title, message, filter )`  
  Same fields as above, but shows a very clear "Okay" and "Never show again" button.
  This notification also fades to low opacity after a short delay, as to not distract the player.
  Intended to be used for usage hints, such as "You got [powerup], it allows you to [description]"
  Defaults to LOW priority.

- `CFCNotifications.startVote( id, question, time, options, cb )`  
This function is SERVER only.  
Starts a server wide vote, and calls `cb` with whatever the result is.
  - `id` - String identifier for the notification.
  - `title` - Title text.
  - `time` - Duration of the vote in seconds. (default: `30`)
  - `options` - List of string options. (default: `{"Yes", "No"}`)
  - `cb` - Callback function, this is called when everyone has voted, or the time runs out. If 1 winner, the function is called with the string that won (or `true`/`false` if no options given). If there is a draw, a table of winners is given.

## In-depth usage
As mentioned, notifications are object. (all helper functions create these objects internally). 
To create or get a notification object, you can use any of the following:
- `CFCNotifications.new( id, notificationType, forceCreate )`  
  - `id` - Unique string ID for the notification.
  - `notificationType` - Options below.
  - `forceCreate` - If a notification with given id already exists, it is deleted first. (an error is thrown if this is false and the id already exists)
- `CFCNotifications.get( id )`  
Simply gets the notification with the given id, `nil` if it doesn't exist.
- `CFCNotifications.getOrNew( id, notificationType )`  
  If the notification exists, this simply gets it, else this creates it.

### Notification Object
All notification types support the following by default:
- `notification:Remove()`  
- `notification:RemovePopup( id, ply )`  
  - `id` - Popup ID. **This is different to the notification ID.**  
  Popup ID's are automatically generated and can be obtained using `notification:GetCallingPopupID` in any notification event hook.
  - `ply` - Only required on server, player to remove the popup for.
- `notification:RemovePopups( ply )`  
  Removes all of this notifications popups from a player.
  - `ply` - Only required on server.
- `notification:Send( filter )`  
  - `filter` - Only required on server, see above Simple Usage for filter definition.
- `notification:SendDelayed( delay, filter )`  
  Same as send, but waits for `delay` seconds to pass before sending.
- `notification:SendRepeated( delay, reps, filter )`  
  Sends the notification `reps` times (or infinitely if `reps` == 0) with `delay` seconds between each send.
  `filter` is evaluated again for every send, so if it's a function, the recipients can be different for each interval.
- `notification:CancelDelay()` and `notification:CancelTimer()`  
  Stops any existing repeated or delayed notification sends.
- `notification:HasTimer()`  
  Returns if currently waiting on delay or repeated send.
- `notification:GetID()`
- `notification:GetType()`

The following fields all have getters and setters defined, e.g. `displayTime` -> `SetDisplayTime( t )` and `GetDisplayTime()`. Their default values are also provided.
- `displayTime` - Duration to show a notification for in seconds. (default: `5`)
- `timed` - Whether this notification has a timeout. (default: `true`)
- `priority` - Determines the position in the notification stack this notification will sit (high priority means bottom - always visible). Notifications with `HIGH` or `MAX` priotity have orange and red title backgrounds respectively. High priority notifications also make a pop sound, default to HIGH and above (though this can be changed on the client). (default: `CFCNotifications.PRIORITY_LOW`)
- `allowMultiple` - Determines if this notification can have >1 popup. (default: `false`)
- `title` - Title text for a notification. (default: `"Notification"`)
- `alwaysTiming` - When too many notifications are sent, some are hidden, if alwaysTiming is false, they will not decrease their time left while not visible. (default: `false`)
- `extraHeight` - Provides additional height to the notification, useful for notifications with non-text components.

### Hooks
Notifications support hooks for events. If the notification was created on the server, the first argument to every hook will be the player it came from.
Within any hook, `notification:GetCallingPopupID()` can be called to get the ID of the notification that fired the event.
Default hooks are as follows:
- `notification:OnClose( wasTimeout )` - Called when the notification closes, `wasTimeout` is true if the notification closed due to timeout.
- `notification:OnOpen( popupID )` - Called when a notification opens, useful when sending notifications from server to quickly get the popupID.

Whenever a hook is called, a client side version of that hook is also called, that version is called [hookname]_CLIENT.  e.g. `notification:OnClose_CLIENT()`
This can be useful when creating notification types, to ensure a hook is called on client.

### Notification Types
Below are the predefined notification types (you can define your own) with whatever they define.
- "Text" - Simple text notification
  - `notification:SetText( text )` - Sets the text for `notification`
  - `notification:SetTextColor( color )` - Sets the text color for `notification`
  - `notification:SetExtraHeight()` - Sets additional height for `notification`
- "Buttons" - Text notification with variable number of buttons
  - `notification:SetText( text )` - Sets the text for `notification`
  - `notification:SetTextColor( color )` - Sets the text color for `notification`
  - `notification:SetExtraHeight()` - Sets additional height for `notification`
    Defauts to 40 (plus 50 for each additional row) to give room for the buttons.
  - `notification:AddButton( text, buttonColor, data1, data2, ... )`  
    Adds a button with given text and color. The button text, underline and click animation will be `buttonColor`. `data1, data2, ...` will be passed to OnButtonPressed when the respective button is pressed. If not defined, `text` will be used instead.
    If this function is never called, the notification will default to a green "Yes" and red "No" button.
    There is enough vertical height in each button to fit at most two lines of text.
  - `notification:AddButtonAligned( text, buttonColor, alignment, data1, data2, ... )`
    Adds a button with horizontal text alignment, using the constants below.
    - `CFCNotifications.ALIGN_LEFT`
    - `CFCNotifications.ALIGN_CENTER`
    - `CFCNotifications.ALIGN_RIGHT`
  - `notification:NewButtonRow()`
    Any buttons created from here on will start on a new row.
  - Hooks:
    - `notification:OnButtonPressed( data )`  
      - Called when a button is pressed with the data used to create it.
      - **Remember:** The first argument to this will be the player if the notification was sent from the server.
- "TextAcknowledge" - Inherits from Buttons, creates an "Okay" and "Never show again" button, where the "Okay" button hides the notification, and "Never show again" permanently ignores it.  
  This type also fades itself automatically to not get in the way.

## Making your own notification type
This is done by calling `CFCNotifications.registerNotificationType( name, cb, inherit )`
- `name` - The name of the new notification type.
- `cb` - A function that is called with the CONTEXT to expand on, this is called immediately.
- `inherit` - Another notification type to inherit from. (optional)

**Notification types must be registered in a shared environment**

There are 2 functions you will probably want to override when defining a notification type:
 - `CONTEXT:PopulatePanel( canvas )` - This is called when the notification derma object is created, and allows you to set how it looks
 - `CONTEXT:OnAltNum( num )` - This is called when a player holds ALT and presses a number key. It is only called on the bottom notification.

This library also adds a couple helper functions for adding fields and calling hooks:
- `CFCNotifications.contextHelpers.addField( context, name, default, argType, onChange )`
  - `context` - The table to add the getter/setter to
  - `name` - The field name in lower camel-case (e.g. `displayTime`)
  - `default` - Default value for the field
  - `argType` - Type of the field (this function adds type checking for the setter it defines).
  - `onChange` - Optional function called when the field is set.
- `CONTEXT:_callHook( popupID, hookName, ... )`  
  This hook should only ever be called internally. It handles networking, the popupID, and checking existance of the hook.

### Example
This example is how the "Text" type is defined.
```lua
CFCNotifications.registerNotificationType( "Text", function( CONTEXT )
    CFCNotifications.contextHelpers.addField( CONTEXT, "text", "", "string" )
    CFCNotifications.contextHelpers.addField( CONTEXT, "textColor", Color( 255, 255, 255 ), "Color" )

    function CONTEXT:PopulatePanel( canvas )
        local label = Label( self:GetText(), canvas )
        label:SetFont( "CFC_Notifications_Big" )
        label:SizeToContents()
        label:SetTextColor( self:GetTextColor() )
    end
end )
```
