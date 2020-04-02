set_var() {
    _REQUIRE_MANGA_NAME=true

    _PUP=$(command -v pup) || command_not_found "pup"
    _CHROME=$(command -v chromium)

    _HOST_URL="https://readcomiconline.to/"
    _COMIC_URL="$_HOST_URL/comic"
    _SEARCH_URL="$_HOST_URL/Search/SearchSuggest"
    _IMAGE_QUALITY="hq"
    _CF_FILE="$_SCRIPT_PATH/cf_clearance"
    _BYPASS_CF_SCRIPT="$_SCRIPT_PATH/bin/getCFcookie.js"
    _USER_AGENT="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/$($_CHROME --version | awk '{print $2}') Safari/537.36"
    _CF_CLEARANCE="$(get_cf_clearance)"
}

is_cf_expired() {
    local o
    o="yes"

    if [[ -f "$_CF_FILE" && -s "$_CF_FILE" ]]; then
        local d n
        d=$(date -d "$(date -r "$_CF_FILE") +15 min " +%s)
        n=$(date +%s)

        if [[ "$n" -lt "$d" ]]; then
            o="no"
        fi
    fi

    echo "$o"
}

get_cf_clearance() {
    local l
    l="$_HOST_URL"
    if [[ "$(is_cf_expired)" == "yes" ]]; then
        echo "[INFO] Wait for 5s to visit $l..." >&2
        $_BYPASS_CF_SCRIPT -u "$l" -a "$_USER_AGENT" -p "$_CHROME" \
            | $_JQ -r '.[] | select(.name == "cf_clearance") | .value' \
            | tee "$_CF_FILE"
    else
        cat "$_CF_FILE"
    fi
}

fetch_img_list() {
    # $1: manga slug
    # $2: chapter num
    $_CURL -sS "$_COMIC_URL/$1/Issue-${2}?quality=$_IMAGE_QUALITY&readType=1" \
        --header "User-Agent: $_USER_AGENT" \
        --header "cookie: cf_clearance=$_CF_CLEARANCE" \
        | grep 'lstImages.push' \
        | sed -E 's/.*push\(\"//' \
        | sed -E 's/\"\);.*//'
}

list_manga() {
    $_CURL -sS "$_SEARCH_URL" \
        --header "User-Agent: $_USER_AGENT" \
        --header "cookie: cf_clearance=$_CF_CLEARANCE" \
        --data "type=Comic&keyword=$_MANGA_NAME" \
        | $_PUP 'a' \
        | sed -E 's/.*\/Comic\//[/' \
        | sed -E 's/">/]/' \
        | sed -E 's/<\/a>//' \
        | sed -E '/^[[:space:]]*$/d' \
        | sed -E 's/[[:space:]]+//' \
        | awk '{printf $NF~"]+" ? "%s":" %s\n", $0}'
}

list_chapter() {
    # $1: manga slug
    $_CURL -sS "$_COMIC_URL/$1" \
        --header "User-Agent: $_USER_AGENT" \
        --header "cookie: cf_clearance=$_CF_CLEARANCE" \
        | pup 'td text{}' \
        | sed -E 's/^[[:space:]]+//' \
        | sed -E '/^[[:space:]]*$/d' \
        | awk '{if (NR%2) { if (NR%2!=0) {ORS="";print " "$0}} else {ORS="\n";print "+++"$0}}' \
        | sed -E 's/^[[:space:]]+//' \
        | column -t -s '+' \
        | tac
}
