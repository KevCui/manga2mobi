set_var() {
    _HOST_URL="https://kissmanga.org"
    _MANGA_URL="$_HOST_URL/manga"
    _SEARCH_URL="$_HOST_URL/Search/SearchSuggest?keyword="
    _CHAPTER_URL="$_HOST_URL/chapter"
    _REQUIRE_MANGA_NAME=true
    _PUP=$(command -v pup) || command_not_found "pup"
}

fetch_img_list() {
    # $1: manga slug
    # $2: chapter num
    $_CURL -sS "$_CHAPTER_URL/$1/chapter_${2}" \
        | $_PUP 'img attr{src}' \
        | grep https
}

list_manga() {
    $_CURL -sS "$_SEARCH_URL$_MANGA_NAME" \
        | $_PUP '.item_search_link' \
        | sed -E 's/.*\/manga\//[/' \
        | sed -E 's/">/]/'\
        | sed -E 's/<\/a>//' \
        | sed -E '/^[[:space:]]*$/d' \
        | sed -E 's/[[:space:]]+//' \
        | awk '{printf $NF~"]+" ? "%s":" %s\n", $0}'
}

list_chapter() {
    # $1: manga slug
    $_CURL -sS "$_MANGA_URL/$1" \
        | pup '.listing div text{}' \
        | grep -v "Chapter name" \
        | grep -v "Day Added" \
        | sed -E '/^[[:space:]]*$/d' \
        | awk '{if (NR%3) { if (NR%3!=1) {ORS="";print " "$0}} else {ORS="\n";print "+++"$0}}' \
        | sed -E 's/^[[:space:]]+//' \
        | column -t -s '+' \
        | tac
}
