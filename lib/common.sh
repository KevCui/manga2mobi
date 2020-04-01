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

    while read -r l; do
        $_WGET -P "$3" "$l"
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
