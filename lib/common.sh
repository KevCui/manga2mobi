#!/usr/bin/env bash
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
    eval "$_KCC" "$_KCC_OPTION" "$1"
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

    local i j s m f p
    if [[ "$2" == *"-"* ]]; then
        s=$(awk -F'-' '{print $1}' <<< "$2")
        m=$(awk -F'-' '{print $2}' <<< "$2")
    else
        s="$2"
        m="$2"
    fi

    p=""
    if [[ "$s" == *"_"* || "$m" == *"_"* ]]; then
        p="$(awk -F'_' '{print $1}' <<< "$s")_"
        s=$(awk -F'_' '{print $2}' <<< "$s")
        m=$(awk -F'_' '{print $2}' <<< "$m")
    fi

    i=1
    for j in $(seq "$s" .5 "$m"); do
        j=${j/.0/}
        while read -r l; do
            if [[ -n "$l" ]]; then
                echo "[INFO] Downloading $l..." >&2
                download_img_file "$l" "${3}/${i}.jpg"
                i=$((i+1))
            fi
        done <<< "$(fetch_img_list "$1" "${p}${j}")"
    done

    if [[ -n "$(ls "$3")" ]]; then
        f="$(rename_foledr "$3" "$1" "$2")"
        [[ -z ${_NO_MOBI:-} ]] && convert_img_to_mobi "$f"
        [[ -z ${_KEEP_OUTPUT:-} ]] && rm -rf "$f" || return 0
    fi
}

download_img_file () {
    # $1: input URL
    # $2: output file
    local s
    s="$($_CURL -L -g -o "$2" "$1" -H "Referer: $_HOST_URL")"
    if [[ "$s" -ne 0 ]]; then
        echo "[WARNING] Download was aborted. Retry..." >&2
        download_img_file "$1" "$2"
    fi
    if [[ ! -s "$2" ]]; then
        echo "[WARNING] Image file is empty. Retry..." >&2
        download_img_file "$1" "$2"
    fi
    if [[ $(file "$2") == *"HTML document"* ]]; then
        if grep -qi "connection time-out" "$2" \
            || grep -qi "origin error"; then
            download_img_file "$1" "$2"
        else
            echo "[ERROR] $1 is not an image file! Wrong manga slug?" >&2
            exit 1
        fi
    fi
}

sed_remove_space() {
    sed -E '/^[[:space:]]*$/d;s/^[[:space:]]+//;s/[[:space:]]+$//'
}
