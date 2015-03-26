#!/usr/bin/env bash

# fzf-fs
# Copyright (C) 2015 D630, The MIT License (MIT)
# <https://github.com/D630/fzf-fs>

# -- DEBUGGING.

#printf '%s (%s)\n' "$BASH_VERSION" "${BASH_VERSINFO[5]}" && exit 0
#set -o errexit
#set -o errtrace
#set -o noexec
#set -o nounset
#set -o pipefail
#set -o verbose
#set -o xtrace
#trap '(read -p "[$BASH_SOURCE:$LINENO] $BASH_COMMAND?")' DEBUG
#exec 2>> ~/fzf-fs.log
#typeset vars_base=$(set -o posix ; set)
#fgrep -v -e "$vars_base" < <(set -o posix ; set) | \
#egrep -v -e "^BASH_REMATCH=" \
#         -e "^OPTIND=" \
#         -e "^REPLY=" \
#         -e "^BASH_LINENO=" \
#         -e "^BASH_SOURCE=" \
#         -e "^FUNCNAME=" | \
#less

# -- FUNCTIONS.

__fzffs_browser ()
{
    builtin unset -v \
        browser_pwd \
        browser_root;
    builtin typeset \
        browser_pwd=$1 \
        browser_root=/;

    if [[ $browser_pwd == ".." ]]; then
        browser_pwd="${PWD%/*}";
    else
        if [[ "${browser_pwd:-.}" == \. ]]; then
            browser_pwd="$PWD";
        else
            if [[ -d "$browser_pwd" ]]; then
                if [[ "${browser_pwd:${#browser_pwd}-1}" == "/" ]]; then
                    browser_pwd="${browser_pwd%/*}";
                else
                    browser_pwd="$browser_pwd";
                fi;
            else
                __fzffs_util_echoE "${source}:Error:79: Not a directory: '${browser_pwd}'" 1>&2;
                __fzffs_help;
                builtin return 79;
            fi;
        fi;
    fi;
    browser_pwd="${browser_pwd:-$browser_root}";

    builtin unset -v \
        browser_file \
        browser_selection;
    builtin typeset \
        browser_file= \
        browser_selection=;

    while [[ -n "$browser_pwd" ]]; do
        builtin cd "$browser_pwd";
        browser_selection="$(__fzffs_browser_select "$browser_pwd")";
        case "$browser_selection" in
            "[q]"*)
                browser_pwd=
            ;;
            "["*)
                browser_selection="${browser_selection##*\] }";
                builtin eval __fzffs_console "${browser_selection}"
            ;;
            *)
                if [[ "${browser_selection##* }" == ".." ]]; then
                    browser_pwd="${browser_pwd%/*}";
                    browser_pwd="${browser_pwd:-$browser_root}";
                    builtin continue;
                else
                    if [[ "${browser_selection##* }" == "." ]]; then
                        browser_pwd="$browser_pwd";
                        builtin continue;
                    fi;
                fi;
                browser_file="${browser_pwd}/$(__fzffs_browser_find "$browser_pwd" "${browser_selection%% *}")";
                browser_file="${browser_file//\/\//\/}";
                if [[ -d "$browser_file" ]]; then
                    browser_pwd="$browser_file";
                else
                    if [[ -e "$browser_file" ]]; then
                        __fzffs_console console/open_with "$FZF_FS_OPENER" "$browser_file";
                    else
                        browser_pwd=;
                    fi;
                fi
            ;;
        esac;
    done
}

__fzffs_browser_find ()
{
    command find -H "${1}/." ! -name . -prune -inum "$2" -exec basename '{}' \; 2> /dev/null
}

__fzffs_browser_fzf ()
{
    builtin unset -v prompt;
    builtin typeset prompt="${1/${HOME}/~}";
    __fzffs_browser_prompt;
    command fzf ${FZF_FS_DEFAULT_OPTS} --prompt="[$prompt] "
}
__fzffs_browser_ls ()
{
    function __fzffs_browser_ls_do ()
    {
        command ls ${FZF_FS_LS}${FZF_FS_SYMLINK}${ls_hidden}${ls_reverse} | command tail -n +2
    };

    builtin unset -v \
        ls_hidden \
        ls_reverse \
        ls_color;
    builtin typeset \
        ls_hidden= \
        ls_color= \
        ls_reverse=;

    command sed 's/^/_ /' "${FZF_FS_CONFIG_DIR}/env/browser_shortcuts.user";

    if ((FZF_FS_LS_REVERSE == 0)); then
        ls_reverse=;
    else
        ls_reverse=r;
    fi;
    if ((FZF_FS_LS_HIDDEN == 0)); then
        ls_hidden=;
    else
        ls_hidden=a;
    fi;
    if ((FZF_FS_LS_CLICOLOR == 0)); then
        ls_color=;
    else
        ls_color=;
    fi;

    if [[ -n "$FZF_FS_SORT" ]]; then
        __fzffs_browser_ls_do | command sort ${FZF_FS_SORT};
    else
        __fzffs_browser_ls_do;
    fi
}
__fzffs_browser_prompt ()
{
    builtin unset -v \
        base \
        left \
        mask \
        name \
        ret \
        tmp;
    builtin typeset \
        base= \
        left= \
        mask=" ... " \
        name= \
        ret= \
        tmp=;
    builtin unset -v \
        delims \
        dir \
        len_left \
        max_len;
    builtin typeset -i \
        delims= \
        dir= \
        len_left= \
        max_len="$((${COLUMNS:-80} * 35 / 100))";

    ((${#prompt} > max_len)) && {
        tmp="${prompt//\//}";
        delims="$((${#prompt} - ${#tmp}))";

        while ((dir < 2)); do
            ((dir == delims)) && builtin break;
            left="${prompt#*/}";
            name="${prompt:0:${#prompt}-${#left}}";
            prompt="$left";
            ret="${ret}${name%/}/";
            ((dir++));
        done;

        if ((delims <= 2)); then
            ret="${ret}${prompt##*/}";
        else
            base="${prompt##*/}";
            prompt="${prompt:0:${#prompt}-${#base}}";
            [[ "$ret" == "/" ]] || ret="${ret%/}";
            len_left="$((max_len - ${#ret} - ${#base} - ${#mask}))";
            ret="${ret}${mask}${prompt:${#prompt}-${len_left}}${base}";
        fi;

        prompt="$ret"
    }
}
__fzffs_browser_select ()
{
    __fzffs_browser_ls "$1" | __fzffs_browser_fzf "$1" | command sed 's/^[_ ]*//'
}
__fzffs_console ()
{
    if (($# == 0)); then
        builtin return 1;
    else
        if [[ "$1" == "console" ]]; then
            builtin shift 1;
        fi;
    fi;

    builtin unset -v \
        console_args \
        console_file \
        console_fork_background \
        console_interactive \
        console_keep \
        console_selection \
        console_terminal;
    builtin typeset \
        console_args= \
        console_file= \
        console_fork_background= \
        console_keep= \
        console_selection= \
        console_terminal=;
    builtin typeset -i console_interactive=;

    if (($# == 0)); then
        console_interactive+=1;
        while builtin :; do
            console_selection="$(__fzffs_console_select "$FZF_FS_OPENER_CONSOLE")";
            case "$console_selection" in
                "[q]"*)
                    builtin return 0
                ;;
                *)
                    console_file="${FZF_FS_CONFIG_DIR}/console/${console_selection##* }";
                    if [[ -f "$console_file" ]]; then
                        builtin unset -v console;
                        builtin typeset console=;
                        if [[ "$console_selection" == \[*\]\ set/opener_console_default ]]; then
                            builtin . "$console_file";
                            [[ -n "$console" ]] && builtin eval "$console";
                        else
                            if [[ -n "$FZF_FS_OPENER_CONSOLE" ]]; then
                                command ${FZF_FS_OPENER_CONSOLE} "$console_file";
                            else
                                builtin unset -f console_func;
                                builtin . "$console_file";
                                [[ -n "$console" ]] && builtin eval "$console";
                                if builtin typeset -f console_func > /dev/null; then
                                    console_func;
                                fi;
                            fi;
                        fi;
                        console_file=;
                    else
                        FZF_FS_OPENER_CONSOLE=;
                    fi
                ;;
            esac;
        done;
    else
        console_file="${FZF_FS_CONFIG_DIR}/${1}";
        if [[ -f "$console_file" ]]; then
            builtin shift 1;
            builtin unset -v console;
            builtin typeset console=;
            builtin unset -f console_func;
            builtin . "$console_file";
            [[ -n $console ]] && builtin eval "$console";
            if builtin typeset -f console_func > /dev/null; then
                console_func "$*";
            fi;
        else
            console_file=;
        fi;
    fi
}

__fzffs_console_fzf ()
{
    command fzf -x -i --tac --prompt=":${1:+${1} }"
}

__fzffs_console_ls ()
{
    builtin unset -v shortcuts;
    builtin typeset shortcuts="$(< "${FZF_FS_CONFIG_DIR}/env/console_shortcuts.user")";
    __fzffs_util_echoE "$shortcuts";
    __fzffs_util_echoE "[q] quit"
}

__fzffs_console_select ()
{
    __fzffs_console_ls | __fzffs_console_fzf "$1"
}

__fzffs_help ()
{
    builtin unset -v help;
    {
        builtin typeset help="$(</dev/fd/0)"
    }  <<-'HELP'
Usage
    [source] fzf-fs.sh [ -h | -i | -v | <directory> ]

Options
    -h, --help      Show this instruction
    -i, --init      Initialize configuration directory
    -v, --version   Print version

Environment variables
    FZF_FS_CONFIG_DIR
            ${XDG_CONFIG_HOME:-${HOME}/.config}/fzf-fs.d
HELP

    __fzffs_util_echoE "$help"
}

__fzffs_main ()
{
    builtin unset -v source;
    builtin typeset source=;

    if [[ -n "$BASH_VERSION" ]]; then
        source="${BASH_SOURCE[0]}";
        __fzffs_prepare_bash;
    else
        if [[ -n "$ZSH_VERSION" ]]; then
            source="${(%):-%x}";
            __fzffs_prepare_zsh;
        else
            if [[ -n "$KSH_VERSION" ]]; then
                source="$0";
                __fzffs_prepare_mksh;
            fi;
        fi;
    fi;

    builtin typeset FZF_FS_CONFIG_DIR="${FZF_FS_CONFIG_DIR:-${XDG_CONFIG_HOME:-${HOME}/.config}/fzf-fs.d}";

    case $1 in
        "-h" | "--help")
            __fzffs_help;
            __fzffs_quit;
            return 0
        ;;
        "-i" | "--init")
            builtin . fzf-fs-init;
            __fzffs_quit;
            return $?
        ;;
        "-v" | "--version")
            __fzffs_version;
            __fzffs_quit;
            return 0
        ;;
    esac;

    builtin . "${FZF_FS_CONFIG_DIR}"/env/env.user || __fzffs_util_echoE "${source}:Error:81: Environment file missing" 1>&2;

    __fzffs_browser "$1";

    __fzffs_quit
}
__fzffs_prepare_bash ()
{
    function __fzffs_quit_sh ()
    {
        builtin :
    };

    function __fzffs_util_echo ()
    {
        IFS=" " builtin printf '%b\n' "$*"
    };

    function __fzffs_util_echoE ()
    {
        IFS=" " builtin printf '%s\n' "$*"
    };

    function __fzffs_util_echon ()
    {
        IFS=" " builtin printf '%s' "$*"
    }
}
__fzffs_prepare_mksh ()
{
    function __fzffs_quit_sh ()
    {
        builtin :
    };

    function __fzffs_util_echo ()
    {
        IFS=" " builtin print -- "$*"
    };

    function __fzffs_util_echoE ()
    {
        IFS=" " builtin print -r -- "$*"
    };

    function __fzffs_util_echon ()
    {
        IFS=" " builtin print -nr -- "$*"
    }
}
__fzffs_prepare_zsh ()
{
    builtin unset -v FZF_FS_ZSH_OPTS_OLD;
    builtin set -A FZF_FS_ZSH_OPTS_OLD "$(builtin setopt)";
    builtin setopt shwordsplit;

    function __fzffs_quit_sh ()
    {
        builtin setopt +o shwordsplit;
        builtin unset -v o;
        for o in "${FZF_FS_ZSH_OPTS_OLD[@]}";
        do
            builtin setopt "$o";
        done
    };

    function __fzffs_util_echo ()
    {
        IFS=" " builtin printf '%b\n' "$*"
    };

    function __fzffs_util_echoE ()
    {
        IFS=" " builtin printf '%s\n' "$*"
    };

    function __fzffs_util_echon ()
    {
        IFS=" " builtin printf '%s' "$*"
    }
}
__fzffs_quit ()
{
    __fzffs_quit_sh;

    builtin unset -f \
        __fzffs_browser \
        __fzffs_browser_find \
        __fzffs_browser_fzf \
        __fzffs_browser_ls \
        __fzffs_browser_ls_do \
        __fzffs_browser_prompt \
        __fzffs_browser_select \
        __fzffs_console \
        __fzffs_console_fzf \
        __fzffs_console_ls \
        __fzffs_console_select \
        __fzffs_console_set \
        __fzffs_help \
        __fzffs_init \
        __fzffs_main \
        __fzffs_prepare_bash \
        __fzffs_prepare_mksh \
        __fzffs_prepare_zsh \
        __fzffs_quit \
        __fzffs_quit_sh \
        __fzffs_util_echo \
        __fzffs_util_echoE \
        __fzffs_util_echon \
        __fzffs_util_parse_flags \
        __fzffs_util_parse_macros \
        __fzffs_version \
        console_func \
        flags_func;

    builtin typeset -x \
        FZF_DEFAULT_COMMAND=$FZF_DEFAULT_COMMAND_OLD \
        FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS_OLD \
        LC_COLLATE=$LC_COLLATE_OLD \
        LC_COLLATE=C;

    builtin unset -v \
        FZF_FS_ZSH_OPTS_OLD \
        FZF_DEFAULT_COMMAND_OLD \
        FZF_DEFAULT_OPTS_OLD \
        LC_COLLATE_OLD o
} 2> /dev/null

__fzffs_util_parse_flags ()
{
    builtin unset -v REPLY;
    builtin typeset REPLY=;

    [[ "$1" == \-?* ]] && {
        if builtin . "${FZF_FS_CONFIG_DIR}/env/flags.user"; then
            while builtin read -r -n 1; do
                flags_func;
            done <<< "$1";
            builtin return 0;
        else
            builtin return 1;
        fi
    }
}

__fzffs_util_parse_macros ()
{
    console_args="$*";
    builtin . "${FZF_FS_CONFIG_DIR}/env/macros.user" 2> /dev/null;
    console_args="${console_args%% }";
    console_args="${console_args## }";
    console_args="'${console_args}'"
}

__fzffs_version ()
{
    builtin unset -v version;
    builtin typeset version=v0.2.0;

    if [[ -n "$KSH_VERSION" ]]; then
        __fzffs_util_echoE "$version";
    else
        builtin unset -v md5sum;
        builtin typeset md5sum="$(command md5sum "$source")";
        __fzffs_util_echoE "${version} (${md5sum%  *})";
    fi
}

# -- MAIN.

__fzffs_main "$1"
