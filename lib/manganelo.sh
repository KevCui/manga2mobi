#!/usr/bin/env bash
set_var() {
    _HOST_URL="https://manganelo.com"
    _MANGA_URL="https://manganelo.com/manga/"
    _CHAPTER_URL="https://manganelo.com/chapter/"
    _SEARCH_URL="$_HOST_URL/getstorysearchjson"
    _REQUIRE_MANGA_NAME=true
    _PUP=$(command -v pup) || command_not_found "pup"
}

fetch_img_list() {
    # $1: manga slug
    # $2: chapter num
    $_CURL -sS -L "$_CHAPTER_URL${1}/chapter_${2}" \
        | $_PUP 'img attr{src}' \
        | grep 'chapter'
}

list_manga() {
    $_CURL -sS "$_SEARCH_URL" --data-raw "searchword=${_MANGA_NAME// /_}" \
        | $_JQ -r '.[] | "[\(.nameunsigned)] \(.name)"' \
        | sed -E 's/<span style="color: #FF530D;font-weight: bold;">//g' \
        | sed -E 's/<\/span>//g'
}

list_chapter() {
    # $1: manga slug
    local o m s n t l
    o=$($_CURL -sS -L "$_MANGA_URL$1")

    _RENAMED_MANGA_NAME=$($_PUP 'h1 text{}' <<< "$o")
    _RENAMED_MANGA_NAME=${_RENAMED_MANGA_NAME// /_}
    _RENAMED_MANGA_NAME=${_RENAMED_MANGA_NAME//:/_}
    _RENAMED_MANGA_NAME=${_RENAMED_MANGA_NAME//\//_}

    l=""
    m=$(grep -c 'li class' <<< "$o")
    for ((i=m; i>0; i--)); do
        s=$($_PUP 'li:nth-child('"$i"')' <<< "$o")
        n=$($_PUP '.chapter-name text{}' <<< "$s" | sed_remove_space)
        t=$($_PUP '.chapter-time text{}' <<< "$s" | sed_remove_space)
        l="$l$n+++$t\n"
    done
    echo -e "$l" | column -t -s '+++'
}
