# Jack & Jill for the shell. Source from ~/.zshrc:
#   [ -f ~/.claude/themes/terminal-app/dist/shell/jj-shell-colors.sh ] && . ~/.claude/themes/terminal-app/dist/shell/jj-shell-colors.sh
#
# Every value here is an ANSI SLOT NUMBER, never a hex, so all of it follows the
# terminal profile and flips ground with it. Directories take Periwinkle, links
# Sky, executables Emerald, archives Coral, media Orchid, a broken link Flame.

# GNU ls / eza / most modern tools
export LS_COLORS='di=34:ln=36:so=35:pi=33:ex=32:bd=33;1:cd=33:su=31:sg=31:tw=34:ow=34:or=31;1:mi=31:*.tar=91:*.tgz=91:*.zip=91:*.gz=91:*.bz2=91:*.xz=91:*.7z=91:*.dmg=91:*.png=95:*.jpg=95:*.jpeg=95:*.gif=95:*.svg=95:*.mp4=95:*.mov=95:*.webm=95:*.pdf=95:*.ts=37:*.tsx=37:*.js=37:*.jsx=37:*.json=93:*.md=93:*.css=37:*.html=37:*.sh=32:*.zsh=32:*.py=32'
export EZA_COLORS="$LS_COLORS"

# BSD ls, which macOS ships: eleven pairs, dir blue, link cyan, exec green
export LSCOLORS='exgxcxdxbxegedabagacad'
export CLICOLOR=1

# bat and delta both have an "ansi" mode that draws with the terminal's slots
export BAT_THEME=ansi

# fzf, by slot number so it follows the ground
export FZF_DEFAULT_OPTS="--color=fg:-1,bg:-1,hl:4,fg+:15,bg+:-1,hl+:12,\
info:3,prompt:9,pointer:9,marker:2,spinner:5,header:8,border:8"

# less, so man pages stop being blue-on-black
export LESS_TERMCAP_md=$'\033[91m'   # headings: Coral
export LESS_TERMCAP_us=$'\033[36m'   # underline: Sky
export LESS_TERMCAP_so=$'\033[33m'   # search hit: Honey
export LESS_TERMCAP_me=$'\033[0m'
export LESS_TERMCAP_ue=$'\033[0m'
export LESS_TERMCAP_se=$'\033[0m'
