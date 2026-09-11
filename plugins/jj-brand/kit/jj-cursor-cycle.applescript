-- Jack & Jill: the cursor takes a different magic colour on every blink, and
-- the ground follows the system appearance when the mode is auto.
--
-- Two jobs in one agent on purpose. This process already holds the Automation
-- permission to drive Terminal, it already ticks, and it already reads the
-- active theme file — so the appearance watch costs one native read every ten
-- ticks and a subprocess only on an actual change. A second agent would need
-- its own permission grant for nothing.
--
-- THE REAL COLOURS at full saturation, on both grounds (James, 10 Sep). The
-- alternative set, re-lit so each hue clears 4.5:1 against Paper, is here and
-- unused unless the agent is started with "lit" as its second argument.
--
-- One change per blink cycle: the period is the cycle (1s = 500ms on, 500ms
-- off), so every flash differs from the one before it. Terminal's blink PHASE
-- is not observable from outside, so the switch drifts within the cycle.

property realPalette : {{65535, 32896, 16962}, {65535, 55512, 25186}, {10023, 53970, 29041}, {0, 52428, 64250}, {34952, 42405, 65535}, {63993, 31868, 57054}}
property darkLit : {{65535, 32896, 16962}, {65535, 55512, 25186}, {10023, 53970, 29041}, {0, 52428, 64250}, {34952, 42405, 65535}, {63993, 31868, 57054}}
property lightLit : {{49858, 20303, 257}, {35723, 28527, 257}, {0, 33924, 16962}, {0, 32125, 39835}, {19532, 26985, 56797}, {47802, 16705, 41891}}

on run argv
	set period to 1.0
	set useReal to true
	try
		if (count of argv) > 0 then set period to (item 1 of argv) as real
	end try
	try
		if (count of argv) > 1 then
			if (item 2 of argv) as text is "lit" then set useReal to false
		end if
	end try
	set home to POSIX path of (path to home folder)
	set activeTheme to home & ".claude/themes/jack-and-jill.json"
	set kit to home & ".claude/themes/terminal-app/"
	set modeFile to kit & ".ground-mode"
	set i to 0
	set tick to 0
	repeat
		try
			-- never launch Terminal just to colour its cursor
			tell application "System Events" to set isUp to (exists process "Terminal")
			if isUp then
				set onLight to false
				try
					set blob to read POSIX file activeTheme
					if blob contains "light-ansi" then set onLight to true
				end try

				-- the appearance watch: every tenth tick, and only in auto mode
				set tick to tick + 1
				if tick mod 10 = 0 then
					try
						set groundMode to "auto"
						try
							set groundMode to my trimmed(read POSIX file modeFile)
						end try
						if groundMode is "auto" then
							tell application "System Events" to tell appearance preferences to set sysDark to dark mode
							if (sysDark and onLight) or ((not sysDark) and (not onLight)) then
								do shell script quoted form of (kit & "jj-ground.sh") & " sync"
							end if
						end if
					end try
				end if

				if useReal then
					set pal to realPalette
				else
					if onLight then
						set pal to lightLit
					else
						set pal to darkLit
					end if
				end if
				set i to (i mod 6) + 1
				tell application "Terminal"
					set cursor color of selected tab of front window to (item i of pal)
				end tell
			end if
		end try
		delay period
	end repeat
end run

on trimmed(t)
	set out to ""
	repeat with ch in characters of t
		set c to ch as text
		if c is not return and c is not linefeed and c is not space then set out to out & c
	end repeat
	return out
end trimmed
