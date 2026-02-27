# Colorscheme
COLOR_CWD='blue'
COLOR_GIT='cyan'
COLOR_SUCCESS='green'
COLOR_FAILURE='red'
COLOR_TIME='cyan'

SYMBOL_GIT_BRANCH='⑂'
SYMBOL_GIT_MODIFIED='*'
SYMBOL_GIT_PUSH='↑'
SYMBOL_GIT_PULL='↓'

# Assign prompt symbol based on OS
case "$(uname)" in
    Darwin)
        PS_SYMBOL=''
        ;;
    Linux)
        PS_SYMBOL='$'
        ;;
    *)
        PS_SYMBOL='%'
        ;;
esac


_git_info() {
    hash git 2>/dev/null || return  # git not found

    # get current branch
    local ref=$(git symbolic-ref --short HEAD 2>/dev/null)

    if [[ -n "$ref" ]]; then
        # prepend branch symbol
        ref=$SYMBOL_GIT_BRANCH$ref
    else
        # get most recent tag or abbreviated unique hash
        ref=$(git describe --tags --always 2>/dev/null)
    fi

    [[ -n "$ref" ]] || return   # not a git repo

    local marks

    # scan first two lines of output from `git status`
    while IFS= read -r line; do
        if [[ $line =~ ^## ]]; then # header line
            [[ $line =~ ahead\ ([0-9]+) ]] && marks+=" $SYMBOL_GIT_PUSH$match[1]"
            [[ $line =~ behind\ ([0-9]+) ]] && marks+=" $SYMBOL_GIT_PULL$match[1]"
        else # branch is modified if output contains more lines after the header line
            marks="$SYMBOL_GIT_MODIFIED$marks"
            break
        fi
    done < <(git status --porcelain --branch 2>/dev/null)  # note the space between the two <

    # print without a trailing newline
    printf " $ref$marks"
}


_config_prompt() {
    # Color coding based on exit code of the previous command.  Note this must
    # be dealt with in the beginning of the function, otherwise the $? will not
    # match the right command executed.

    if [[ $? -eq 0 ]]; then
        local symbol="%F{$COLOR_SUCCESS}$PS_SYMBOL%f"
    else
        local symbol="%F{$COLOR_FAILURE}$PS_SYMBOL%f"
    fi

    local cwd="%F{$COLOR_CWD}%~%f"
    local git="%F{$COLOR_GIT}$(_git_info)%f"
    local time="%F{$COLOR_TIME}%D{%H:%M:%S}%f"

    PROMPT="$cwd$git $symbol "
    RPROMPT="$time"
}


# useful zsh hook functions

precmd() {  # run before each prompt
    _config_prompt
}


preexec() { # run after user command is read and about to execute
}


chpwd() { # run when changing current working directory
}
