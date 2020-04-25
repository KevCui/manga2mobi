set_var() {
    _REQUIRE_MANGA_NAME=true

    _PUP=$(command -v pup) || command_not_found "pup"
    _CHROME=$(command -v chromium)

    _HOST_URL="https://mangadex.org/api"
    _CHAPTER_API="$_HOST_URL/?type=manga&id="
    _IMAGE_API="$_HOST_URL/?server=null&type=chapter&id="
    _SEARCH_URL="https://duckduckgo.com/html/?q=site:mangadex.org/title intitle:"
    _USER_AGENT="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/$($_CHROME --version | awk '{print $2}') Safari/537.36"
    _CHAPTER_LIST=$(mktemp)
    _LANGUAGE="gb"
}

fetch_img_list() {
    # $1: manga slug
    # $2: chapter num
    local i o s h p l
    i=$($_JQ -r '.chapter | to_entries | .[] | select(.value.lang_code==$lang) | select(.value.chapter==$chapter) | .key' \
        --arg lang "$_LANGUAGE" --arg chapter "$2" "$_CHAPTER_LIST" \
        | head -1)

    o=$($_CURL -sS "$_IMAGE_API${i}")
    s=$($_JQ -r '.server' <<< "$o")
    h=$($_JQ -r '.hash' <<< "$o")
    l=""
    for p in $($_JQ -r '.page_array[]' <<< "$o"); do
        l="$l""${s}${h}/${p}\n"
    done
    echo -e "$l"
}

list_manga() {
    local o m s n t l
    l=""
    o=$($_CURL -sS "$_SEARCH_URL$_MANGA_NAME" \
        -H "user-agent: $_USER_AGENT" \
        | $_PUP 'div.result')
    m=$(grep -c 'result__title' <<< "$o")
    for ((i=0; i<m; i++)); do
        s=$($_PUP 'div.result:nth-child('"$((i+1))"')' <<< "$o")
        n=$($_PUP '.result__url text{}' <<< "$s" | sed_remove_space | sed -E 's/.*\/title\///' | awk -F '/' '{printf "%s",$1}')
        if [[ "$n" ]]; then
            t=$($_PUP '.result__title text{}' --charset utf-8 <<< "$s" | sed_remove_space | awk '{printf "%s ",$0}' | sed_remove_space)
            l="$l""[$n]+++$t\n"
        fi
    done
    echo -e "$l" | column -t -s '+++'
}

list_chapter() {
    # $1: manga slug
    local o
    o=$($_CURL -sS "$_CHAPTER_API$1" | tee "$_CHAPTER_LIST")

    _RENAMED_MANGA_NAME=$($_JQ -r '.manga.title' <<< "$o")
    _RENAMED_MANGA_NAME=${_RENAMED_MANGA_NAME// /_}
    _RENAMED_MANGA_NAME=${_RENAMED_MANGA_NAME//:/_}
    _RENAMED_MANGA_NAME=${_RENAMED_MANGA_NAME//\//_}

    $_JQ -r '.chapter[] | select(.lang_code==$lang) | "[\(.chapter)]+++\(.title)+++\(.timestamp | todate)"' \
        --arg lang "$_LANGUAGE" <<< "$o" \
        | column -t -s '+++' \
        | tac
}
