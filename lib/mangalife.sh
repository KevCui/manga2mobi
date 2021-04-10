#!/usr/bin/env bash
set_var() {
    _HOST_URL="https://manga4life.com"
    _MANGA_URL="$_HOST_URL/manga"
    _SEARCH_URL="$_HOST_URL/search/"
    _MANGA_LIST="./mangalife.list"
}

is_mangalist_expired() {
    local o
    o="yes"

    if [[ -f "$_MANGA_LIST" && -s "$_MANGA_LIST" ]]; then
        local d n
        d=$(date -d "$(date -r "$_MANGA_LIST") +1 days" +%s)
        n=$(date +%s)

        if [[ "$n" -lt "$d" ]]; then
            o="no"
        fi
    fi

    echo "$o"
}

fetch_img_list() {
    # $1: manga slug
    # $2: chapter num
    local h p cp l c d in cn
    if [[ "$2" = *"_"* ]]; then
        in=$(awk -F '_' '{print $1}' <<< "$2")
        cn=$(awk -F '_' '{print $2}' <<< "$2")
    else
        in="1"
        cn="$2"
    fi
    h=$($_CURL -sS "$_HOST_URL/read-online/${1}-chapter-${cn}-index-${in}.html")
    p=$(grep "vm.CurChapter = {" <<< "$h" \
        | sed -E 's/.*Page\":\"//' \
        | awk -F '"' '{print $1}')
    cp=$(grep 'val.PathName' <<< "$h" \
        | awk '{print $1}')
    l=$(grep "$cp = \"" <<< "$h" \
        | sed -E 's/.*'"$cp"' = \"//' \
        | awk -F '"' '{print $1}')
    d=$(grep 'Directory"' <<< "$h" \
        | grep "vm." \
        | grep "}];" \
        | sed -E 's/.*= \[/\[/;s/}\];/}\]/' \
        | "$_JQ" -r '.[] | select(.Chapter=="'"$((in*100000+cn*10))"'") | .Directory')

    c="000$cn"

    if [[ "$c" == *"."* ]]; then
        local e
        e="${c: -1}"
        c=$(sed -E 's/\..*//' <<< "$c")
        c="${c: -4}.$e"
    else
        c="${c: -4}"
    fi

    for ((i=1; i<=p; i++)); do
        local n
        n="00$i"
        n="${n: -3}"
        echo "https://$l/manga/$1/$d/${c}-${n}.png"
    done
}

list_manga() {
    if [[ "$(is_mangalist_expired)" == "yes" ]]; then
        $_CURL -sS "$_SEARCH_URL" \
            | grep 'vm.Directory = ' \
            | sed -E 's/vm.Directory = //' \
            | $_JQ -r '.[] | "[\(.i)] \(.s) (\(.al))"' 2>/dev/null \
            | sed -E 's/\s\(\[\]\)//' \
            | tee "$_MANGA_LIST"
    else
        cat "$_MANGA_LIST"
    fi
}

list_chapter() {
    # $1: manga slug
    $_CURL -sS "$_MANGA_URL/$1" \
        | grep "vm.Chapters =" \
        | sed -E 's/.*vm.Chapters = //' \
        | sed -E 's/\}\]\;/\}\]/' \
        | $_JQ -sr '.[] | sort_by(.Chapter) | .[] | if .Chapter > "200000" then "Chapter [\(.Chapter | tonumber / 100000 | floor)_\((.Chapter | tonumber % 100000)/10)]: \(.Date)" else "Chapter [\((.Chapter | tonumber % 100000)/10)]: \(.Date)" end'
}
