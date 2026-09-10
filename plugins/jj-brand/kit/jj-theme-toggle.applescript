-- Jack & Jill: one click flips the terminal and Claude Code between the two
-- grounds, and advances the cursor to the next magic colour.
--
-- The file work lives in jj-toggle.sh, so this side owns Terminal only and
-- macOS asks for automation permission once, in this app's name. Two rules the
-- first version got wrong:
--   1. Terminal names an imported profile after the FILE, not the name inside
--      it, and the user may rename it afterwards, so the profile is found by
--      pattern rather than by one exact string.
--   2. Terminal cannot import a file while it is mid-Apple-event, so an import
--      is polled for rather than assumed to have landed after a fixed delay.

on run
	set home to POSIX path of (path to home folder)
	set toggler to home & ".claude/themes/terminal-app/jj-toggle.sh"
	set plan to do shell script "/bin/sh " & quoted form of toggler & " plan"

	set oldDelims to AppleScript's text item delimiters
	set AppleScript's text item delimiters to "|"
	set mode to text item 1 of plan
	set groundLabel to text item 2 of plan
	set cursorHex to text item 3 of plan
	set cursorIndex to text item 4 of plan
	set AppleScript's text item delimiters to oldDelims

	set cursorRGB to my hexToRGB(cursorHex)
	set profileFile to home & ".claude/themes/terminal-app/Jack-and-Jill-" & groundLabel & ".terminal"

	tell application "Terminal"
		set profileName to my findProfile(groundLabel)

		if profileName is missing value then
			-- Terminal's only import path is opening the file, and it needs to
			-- be free of an event to do it, so hand it over and then wait.
			do shell script "open " & quoted form of profileFile
			repeat 24 times
				delay 0.5
				set profileName to my findProfile(groundLabel)
				if profileName is not missing value then exit repeat
			end repeat
		end if

		if profileName is missing value then
			display alert "Jack & Jill: profile not installed" message "Terminal has no " & groundLabel & " profile yet. Import it once by opening:" & return & return & profileFile as warning
			return
		end if

		set targetSet to settings set profileName
		set default settings to targetSet
		set startup settings to targetSet

		-- Every open tab, not just the front one: a theme that lands on one
		-- window and leaves the rest behind is worse than no theme.
		repeat with w in windows
			try
				repeat with t in tabs of w
					set current settings of t to targetSet
					-- after the settings, or the profile's own cursor wins
					set cursor color of t to cursorRGB
				end repeat
			end try
		end repeat
	end tell

	-- Only now, with the terminal actually wearing it, does Claude Code flip.
	do shell script "/bin/sh " & quoted form of toggler & " commit " & quoted form of mode & " " & quoted form of cursorIndex

	set noteTitle to "Jack & Jill " & groundLabel
	set noteBody to "Cursor " & cursorHex & ", and Claude Code repaints live"
	display notification noteBody with title noteTitle subtitle profileName
end run

-- Any profile whose name carries both "Jack" and the ground, so renaming it in
-- Terminal's own settings cannot break the toggle.
on findProfile(groundLabel)
	tell application "Terminal"
		set names to name of every settings set
	end tell
	repeat with candidate in {"Jack & Jill " & groundLabel, "Jack-and-Jill-" & groundLabel}
		repeat with n in names
			if (n as text) is (candidate as text) then return (n as text)
		end repeat
	end repeat
	repeat with n in names
		set nt to n as text
		if nt contains "Jack" and nt contains groundLabel then return nt
	end repeat
	return missing value
end findProfile

-- AppleScript colours are 16-bit per channel, so each byte is scaled by 257.
on hexToRGB(h)
	set hexChars to "0123456789abcdef"
	set out to {}
	repeat with i from 2 to 6 by 2
		set hi to (offset of (character i of h) in hexChars) - 1
		set lo to (offset of (character (i + 1) of h) in hexChars) - 1
		set end of out to (hi * 16 + lo) * 257
	end repeat
	return out
end hexToRGB
