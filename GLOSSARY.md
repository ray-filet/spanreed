# Spanreed

A minimal macOS plain-text editor for jotting quick notes throughout the day.

## Language

**Note**:
The plain text shown in one Spanreed window, together with the file it is stored in.
_Avoid_: Document, file, buffer

**Home Note**:
The one Note Spanreed creates on first launch and reopens, with its text, on every launch. It is saved automatically as you type.
_Avoid_: Scratchpad, default document, main note

**Config**:
The plain-text settings file the user edits by hand. It is Spanreed's source of truth for its settings.
_Avoid_: Settings, preferences, prefs

**Selected Fonts**:
The fonts listed in the Config that the user can switch between in Spanreed.
_Avoid_: Font list, available fonts, font families

**Active Font**:
The one font from the Selected Fonts that every Note is currently displayed in.
_Avoid_: Current font, chosen font

**Untitled Note**:
A Note that has never been saved to a file. Closing it asks whether to save it.
_Avoid_: New document, draft, blank note
