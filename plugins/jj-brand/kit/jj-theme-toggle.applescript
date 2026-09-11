-- Jack & Jill: one click cycles the ground through auto, dark and light.
--
--   auto   follow the system appearance (the agent watches it)
--   dark   pinned, whatever the system says
--   light  pinned
--
-- All the work is in jj-ground.sh, so the Dock, the /jj-brand:ground command
-- and any shell run the SAME implementation. This wrapper exists only to give
-- the click a home and to say what happened.

on run
	set home to POSIX path of (path to home folder)
	set ground to home & ".claude/themes/terminal-app/jj-ground.sh"
	try
		set said to do shell script quoted form of ground & " cycle"
		display notification said with title "Jack & Jill"
	on error msg
		display alert "Jack & Jill" message msg as warning
	end try
end run
