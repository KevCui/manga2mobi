#!/usr/bin/env bash
#
# Download manga and make .mobi
#
#/ Usage:
#/   ./manga2mobi.sh -s <manga_slug> -c <chapter_num1,num2...> -k -d -f <source>
#/
#/ Options:
#/   -s <manga_slug>   Search and find manga slug by manga slug
#/                     Attention: slug name is case sensitive
#/   -c <num1,num2...> Specify chapter id to download
#/                     Multiple numbers sepereated by ","
#/   -k                Optinal, keep downloaded manga images
#/   -d                Optinal, only download manga images, without converting mobi
#/                     This option will apply -k automatically
#/   -f <source>       Optinal, from which manga source
#/                     available source: mangalife, kissmanga
#/                     mangalife is set by default
#/   -h | --help       Display this help message

set -e
set -u

usage() {
    printf "%b\n" "$(grep '^#/' "$0" | cut -c4-)" && exit 1
}

set_common_var() {
    _CURL=$(command -v curl)
    _WEGT=$(command -v wget)
    _JQ=$(command -v jq)
    _FZF=$(command -v fzf)
    _KCC=$(command -v kcc-c2e)

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
    main "$@"
fi
