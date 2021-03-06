#!/usr/bin/env bash
#
# Download manga and generate .mobi file
#
#/ Usage:
#/   ./manga2mobi.sh -s <manga_slug> -c <id1,id2...> -k -d -f <source>
#/
#/ Options:
#/   -s <manga_slug>   Search and find manga slug by manga slug
#/                     Attention: slug name is case sensitive
#/   -c <id>           Specify chapter ID to download
#/      <id1,id2...>   Multiple chapter IDs sepereated by ","
#/      <id1-id2>      Use "-" to indicate the range of chapters
#/   -k                Optinal, keep downloaded manga images
#/   -d                Optinal, only download manga images, without converting mobi
#/                     This option will apply -k automatically
#/   -f <source>       Optinal, from which manga source
#/                     available source: ["mangalife", "kissmanga", "manganelo", "mangadex", "readcomic"]
#/                     mangalife is set by default
#/   -h | --help       Display this help message

set -e
set -u

usage() {
    printf "%b\n" "$(grep '^#/' "$0" | cut -c4-)" && exit 1
}

set_common_var() {
    _CURL=$(command -v curl) || command_not_found "curl"
    _JQ=$(command -v jq) || command_not_found "jq"
    _FZF=$(command -v fzf) || command_not_found "fzf"
    _KCC=$(command -v kcc-c2e) || command_not_found "kcc-c2e"

    if [[ -z "${KCC_OPTION:-}" ]]; then
        _KCC_OPTION="-g 1 -m"
    else
        _KCC_OPTION="$KCC_OPTION"
    fi
    _SCRIPT_PATH=$(dirname "$0")
    _TMP_DIR="${_SCRIPT_PATH}/manga_$(date +%s)"
}

set_args() {
    expr "$*" : ".*--help" > /dev/null && usage
    while getopts ":hkdc:s:f:" opt; do
        case $opt in
            s)
                _MANGA_SLUG="$OPTARG"
                ;;
            c)
                _CHAPTER_NUM="$OPTARG"
                ;;
            k)
                _KEEP_OUTPUT=true
                ;;
            d)
                _NO_MOBI=true
                _KEEP_OUTPUT=true
                ;;
            f)
                _MANGA_SOURCE="$OPTARG"
                ;;
            h)
                usage
                ;;
            \?)
                echo "Invalid option: -$OPTARG" >&2
                usage
                ;;
        esac
    done
}

import_source() {
    # $1: manga source

    # shellcheck source=./lib/common.sh
    . "$_SCRIPT_PATH/lib/common.sh"

    if [[ -z ${1:-} ]]; then
        # shellcheck source=./lib/mangalife.sh
        . "$_SCRIPT_PATH/lib/mangalife.sh"
    else
        # shellcheck source=./lib/mangalife.sh
        # or shellcheck source=./lib/kissmanga.sh
        . "$_SCRIPT_PATH/lib/${1}.sh"
    fi
}

command_not_found() {
    # $1: command name
    printf "%b\n" '\033[31m'"$1"'\033[0m command not found!' && exit 1
}

set_var() {
    # Declare all global variables used in lib/<source>.sh
    # This function should be overwritten in lib/<source>.sh
    return
}

list_manga() {
    # Show a manga list
    # Output format: [<manga_slug>] <manga_name_or_alias>
    # This function should be overwritten in lib/<source>.sh
    return
}

list_chapter() {
    # Show chapter list
    # $1: manga slug
    # Output format: Chapter [<chapter_num>]: <creat_date>
    # This function should be overwritten in lib/<source>.sh
    return
}

cleanup() {
    [[ -n ${_TMP_DIR:-} ]] && rm -rf "$_TMP_DIR"
}

main() {
    set_args "$@"
    set_common_var
    import_source "${_MANGA_SOURCE:-}"
    set_var

    if [[ -z ${_MANGA_SLUG:-} ]]; then
        if [[ -n ${_REQUIRE_MANGA_NAME:-} ]]; then
            echo -n ">> Enter manga name to search: "
            read -r _MANGA_NAME
        fi
        _MANGA_SLUG=$(list_manga | $_FZF | awk -F']' '{print $1}' | sed -E 's/^\[//')
    fi

    if [[ -n ${_MANGA_SLUG:-} ]]; then
        if [[ -z ${_CHAPTER_NUM:-} ]];then
            list_chapter "$_MANGA_SLUG"
            echo -n ">> Enter a chapter id: "
            read -r _CHAPTER_NUM
        fi
        download_mangas "$_MANGA_SLUG" "$_CHAPTER_NUM" "$_TMP_DIR"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    trap cleanup EXIT
    main "$@"
fi
