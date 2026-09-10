#!/bin/sh
# Prints the profile's own 16 ANSI slots and a mock of Claude Code's chrome.
# Run it INSIDE the Jack & Jill profile: every colour below is a slot reference
# (SGR 30-37 / 90-97), so what you see is exactly what the profile defines and
# exactly what the Claude Code theme points at.
printf '\n  Jack & Jill — the 16 slots as this profile paints them\n\n'
i=0
for n in black red green yellow blue magenta cyan white; do
  printf '   \033[4%dm    \033[0m \033[3%dm%-9s\033[0m' "$i" "$i" "$n"
  b=$((i+8)); printf '   \033[10%dm    \033[0m \033[9%dm%s\033[0m\n' "$i" "$i" "${n}Bright"
  i=$((i+1))
done
printf '\n  and how the theme spends them\n\n'
printf '   \033[91m✻\033[0m Claude          \033[91mclaude\033[0m / \033[93mshimmer\033[0m\n'
printf '   \033[35m│\033[0m Bash            \033[35mbashBorder\033[0m\n'
printf '   \033[95m✦\033[0m Skill           \033[95mskill · autoAccept · ultra\033[0m\n'
printf '   \033[34m?\033[0m Permission      \033[34mpermission · suggestion\033[0m\n'
printf '   \033[36m⏸\033[0m Plan mode       \033[36mplanMode · ide\033[0m\n'
printf '   \033[32m✔\033[0m Success         \033[32msuccess\033[0m   \033[31m✗\033[0m Error  \033[31merror\033[0m\n'
printf '   \033[33m⚠\033[0m Warning         \033[33mwarning\033[0m\n'
printf '   \033[92m+ added line\033[0m   \033[91m- removed line\033[0m\n'
printf '   \033[31m●\033[0m\033[91m●\033[0m\033[33m●\033[0m\033[32m●\033[0m\033[34m●\033[0m\033[36m●\033[0m\033[95m●\033[0m\033[35m●\033[0m  eight subagents, eight tellable-apart labels\n\n'
