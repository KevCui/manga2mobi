#!/usr/bin/env bash
#
# Download manga and make .mobi
#
#/ Usage:
#/   ./ml2mobi.sh -s <manga_slug>  -c <chapter_num1,num2...> -k -d
#/
#/ Options:
#/   -s <manga_slug>   Search and find manga slug by manga slug
#/                     Attention: slug name is case sensitive
#/   -c <num1,num2...> Specify chapter id to download
#/                     Multiple numbers sepereated by ","
#/   -k                Optinal, keep downloaded manga images
#/   -d                Optinal, only download manga images, without converting mobi
#/                     This option will apply -k automatically
#/   -h | --help       Display this help message

set -e
set -u

usage() {
    printf "%b\n" "$(grep '^#/' "$0" | cut -c4-)" && exit 1
}

set_var() {
    _CURL=$(command -v curl) || command_not_found "curl"
    _WEGT=$(command -v wget) || command_not_found "wget"
    _JQ=$(command -v jq) || command_not_found "jq"
    _FZF=$(command -v fzf) || command_not_found "fzf"
    _KCC=$(command -v kcc-c2e) || command_not_found "kcc-c2e" # checkout https://github.com/ciromattia/kcc/
    _HOST_URL="https://manga4life.com"
    _MANGA_URL="$_HOST_URL/manga"
    _SEARCH_URL="$_HOST_URL/_search.php"
    _TMP_DIR="manga_$(date +%s)"
}

set_args() {
    expr "$*" : ".*--help" > /dev/null && usage
    while getopts ":hkdc:s:" opt; do
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

command_not_found() {
    # $1: command name
    printf "%b\n" '\033[31m'"$1"'\033[0m command not found!' && exit 1
}

fetch_img_list() {
    # $1: manga slug
    # $2: chapter num
    local h p l c
    h=$($_CURL -sS "$_HOST_URL/read-online/${1}-chapter-${2}.html")
    p=$(grep "vm.CurChapter =" <<< "$h" \
        | sed -E 's/.*Page\":\"//' \
        | awk -F '"' '{print $1}')
    l=$(grep "vm.CurPathName =" <<< "$h" \
        | sed -E 's/.*Name = \"//' \
        | awk -F '"' '{print $1}')

    c="000$2"
    c="${c: -4}"

    for ((i=1; i<=p; i++)); do
        local n
        n="00$i"
        n="${n: -3}"
        echo "https://$l/manga/$1/${c}-${n}.png"
    done
}

download_manga() {
    # $1: manga slug
    # $2: chapter num
    # $3: output folder
    mkdir -p "$3"

    while read -r l; do
        $_WEGT -P "$3" "$l"
    done <<< "$(fetch_img_list "$1" "$2")"

    local f
    f="$(rename_foledr "$_TMP_DIR" "$1" "$2")"

    if [[ -z ${_NO_MOBI:-} ]]; then
        convert_img_to_mobi "$f"
    fi

    if [[ -z ${_KEEP_OUTPUT:-} ]]; then
        rm -rf "$f"
    fi
}

rename_foledr() {
    # $1: manga folder
    # $2: manga slug
    # $3: chapter num
    local n
    n="${2}_chapter${3}"
    mv "$1" "$n"
    echo "$n"
}

convert_img_to_mobi() {
    # $1: manga folder
    $_KCC "$1"
}

list_chapter() {
    # $1: manga slug
    $_CURL -sS "$_MANGA_URL/$1" \
        | grep "vm.Chapters =" \
        | sed -E 's/.*vm.Chapters = //' \
        | sed -E 's/\}\]\;/\}\]/' \
        | $_JQ -sr '.[] | sort_by(.Chapter) | .[] | "Chapter [\((.Chapter | tonumber - 100000)/10)]: \(.Date)"'
}

list_manga() {
    $_CURL -sS "$_SEARCH_URL" \
        | $_JQ -r '.[] | "[\(.i)] \(.s) (\(.a))"' \
        | sed -E 's/\s\(\[\]\)//' \
        | tee manga.list
}

download_mangas() {
    # $1: manga number string
    # $2: chapter num string
    # $3: output folder
    if [[ "$2" == *","* ]]; then
        IFS=","
        read -ra ADDR <<< "$2"
        for e in "${ADDR[@]}"; do
            download_manga "$1" "$e" "$3"
        done
    else
        download_manga "$1" "$2" "$3"
    fi
}

main() {
    set_args "$@"
    set_var

    if [[ -z ${_MANGA_SLUG:-} ]]; then
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
