rename_foledr() {
    # $1: manga folder
    # $2: manga slug
    # $3: chapter num
    local n
    if [[ -z "${_RENAMED_MANGA_NAME:-}" ]]; then
        n="${2}_chapter${3}"
    else
        n="${_RENAMED_MANGA_NAME}_chapter${3}"
    fi
    mv "$1" "$n"
    echo "$n"
}

convert_img_to_mobi() {
    # $1: manga folder
    $_KCC "$1"
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

download_manga() {
    # $1: manga slug
    # $2: chapter num
    # $3: output folder
    mkdir -p "$3"

    local i
    i=1
    while read -r l; do
        echo "[INFO] Downloading $l..." >&2
        $_CURL -L -g -o "${3}/${i}.jpg" "$l"
        i=$((i+1))
    done <<< "$(fetch_img_list "$1" "$2")"

    local f
    f="$(rename_foledr "$3" "$1" "$2")"

    if [[ -z ${_NO_MOBI:-} ]]; then
        convert_img_to_mobi "$f"
    fi

    if [[ -z ${_KEEP_OUTPUT:-} ]]; then
        rm -rf "$f"
    fi
}
