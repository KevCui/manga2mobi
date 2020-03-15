set_var() {
    _HOST_URL="https://manga4life.com"
    _MANGA_URL="$_HOST_URL/manga"
    _SEARCH_URL="$_HOST_URL/_search.php"
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

list_manga() {
    $_CURL -sS "$_SEARCH_URL" \
        | $_JQ -r '.[] | "[\(.i)] \(.s) (\(.a))"' \
        | sed -E 's/\s\(\[\]\)//' \
        | tee manga.list
}

list_chapter() {
    # $1: manga slug
    $_CURL -sS "$_MANGA_URL/$1" \
        | grep "vm.Chapters =" \
        | sed -E 's/.*vm.Chapters = //' \
        | sed -E 's/\}\]\;/\}\]/' \
        | $_JQ -sr '.[] | sort_by(.Chapter) | .[] | "Chapter [\((.Chapter | tonumber % 100000)/10)]: \(.Date)"'
}
