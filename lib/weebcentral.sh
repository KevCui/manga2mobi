#!/usr/bin/env bash
set_var() {
    _REQUIRE_MANGA_NAME=true
    _PUP=$(command -v pup) || command_not_found "pup"
    _HOST_URL="https://weebcentral.com"
    _MANGA_URL="$_HOST_URL/series"
    _SEARCH_URL="$_HOST_URL/search/data?display_mode=Full%20Display&text="
    _MANGA_LIST="$(mktemp)"
    _CHAPTER_LIST="$(mktemp)"
}

rename_foledr() {
    # $1: manga folder
    # $2: manga slug
    # $3: chapter num
    local n name
    [[ ! -s "$_MANGA_LIST" ]] && list_manga > /dev/null
    name="$(grep "$2" "$_MANGA_LIST" | awk -F '] ' '{print $2}')"
    name="${name//:/_}"
    name="${name//\//_}"
    name="${name// /-}"
    [[ -z "${name:-}" ]] && name="$2"
    n="${name}_chapter${3}"
    mv "$1" "$n"
    echo "$n"
}

fetch_img_list() {
    # $1: manga slug
    # $2: chapter num
    local slug
    [[ ! -s "$_CHAPTER_LIST" ]] && list_chapter "$1" > /dev/null
    slug="$(grep '\['"$2"'\]' "$_CHAPTER_LIST" | awk '{print $3}')"
    "$_CURL" -sS "$_HOST_URL/chapters/$slug/images?reading_style=long_strip" | "$_PUP" 'img attr{src}'
}

list_manga() {
    local o
    o="$($_CURL -sS "$_SEARCH_URL${_MANGA_NAME// /%20}")"
    "$_PUP" 'article .text-lg .link' <<< "$o" \
        | sed 's;.*/series/;;' \
        | sed 's;/.*;;' \
        | sed 's/<//g' \
        | awk '{$1=$1};1' \
        | tr -s '\n' \
        | awk 'NR % 2 == 1 { printf "[%s] ", $0; getline; if (NR % 2 == 0) printf "%s\n", $0; else print "" }' \
        | tee "$_MANGA_LIST"
}

list_chapter() {
    # $1: manga slug
    local o
    o="$($_CURL -sS "$_MANGA_URL/${1}/full-chapter-list")"
    grep -E 'span class=""|/chapters/|text-datetime' <<< "$o" \
        | sed 's/<a.*chapters\///' \
        | sed 's/" class.*//' \
        | sed 's/.*"">//' \
        | sed 's/.*datetime="//' \
        | sed -E 's/T[0-9]{2}:[0-9]{2}:[0-9]{2}.*//' \
        | sed 's/<.*//' \
        | sed 's/Page //;s/.* //' \
        | awk '{$1=$1};1' \
        | tac \
        | awk '{ lines[NR] = $0; if (NR % 3 == 0) { printf "[%d]++%s %s\n", NR/3, lines[NR-2], lines[NR]; } }' \
        | column -t -s '++' \
        | tee "$_CHAPTER_LIST"
}
