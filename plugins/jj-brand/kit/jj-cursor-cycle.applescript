-- Jack & Jill: the cursor takes a different magic colour on every blink.
--
-- Terminal has no dynamic-colour escape code (no OSC 12), so the only route is
-- its scripting dictionary, where `cursor color` is a settable per-tab property
-- (`pcuc`). This is one long-running osascript process with the loop INSIDE it:
-- spawning a process per tick would cost more than the effect.
--
-- THE REAL COLOURS at full saturation, on both grounds (James, 10 Sep). The
-- alternative set, re-lit so each hue clears 4.5:1 against Paper, is here and
-- unused unless the agent is started with "lit" as its second argument: on the
-- light ground the true Honey measures 1.31:1, which is a faint cursor and a
-- hard-to-read glyph beneath a block one. Deliberate.
--
-- One change per blink cycle: the period is the cycle (1s = 500ms on, 500ms
-- off), so every flash differs from the one before it. Terminal's blink PHASE
-- is not observable from outside, so the switch drifts within the cycle and
-- sometimes lands mid-flash rather than in the dark half.

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
	set activeTheme to (POSIX path of (path to home folder)) & ".claude/themes/jack-and-jill.json"
	set i to 0
	repeat
		try
			-- never launch Terminal just to colour its cursor
			tell application "System Events" to set isUp to (exists process "Terminal")
			if isUp then
				if useReal then
					set pal to realPalette
				else
					set onLight to false
					try
						set blob to read POSIX file activeTheme
						if blob contains "light-ansi" then set onLight to true
					end try
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
