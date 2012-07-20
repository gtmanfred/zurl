#!/usr/bin/env zsh
pastebin() {
    case "${${(SM)1#//*/}//\/}" in
        sprunge.us)
            url="${1%\?*}"
            ;;
        raw.github.com|gist.github.com)
            [[ "${${1##*//}%%\.*}" == "gist" ]] && url=https://raw.github.com/gist/"${1##*/}" || url="$1"
            ;;
        pastebin.com)
            [[ "${${1##*com/}%\.php*}" == "raw" ]] && url="$1" || url=http://pastebin.com/raw.php\?i\="${1##*/}"
            ;;
        codepad.org)
            url="$1"/raw.txt
            ;;
        dpaste.org|dpaste.de)
            url="$1"/raw/
            ;;
        dpaste.com)
            url="$1"/plain/
            ;;
        pastebin.ca|www.pastebin.ca)
            url=http://pastebin.ca$(getlink $1 raw)
            ;;
        paste.dy.fi)
            url="${1%%\?*}"/plain
            ;;
        pastebin.org)
            url="${1%/*}"/pastebin.php\?dl\="${1##*/}"
            ;;
        pastie.org)
            if [[ "${${1##*org/}%%/*}" == "pastes" ]];then
                url="$1"
            else
                followurl $1
                url=${${(M)1#*//*/}%/}${${${(M)${(f)"$(getpaste text $URL)"}:#*download*}#*href=\"}%%\"*}
            fi
            ;;
        bpaste.net)
            url="${1%/sh*}"/raw/"${1#*ow/}"
            ;;
        fpaste.org)
            url="$1"/raw/
            ;;
        pastebin.mozilla.org)
            url="${1%/*}"/pastebin.php\?dl\="${1##*/}"
            ;;
        hpaste.org)
            url="${1%/*}"/raw/"${1##*/}"
            ;;
        paste.xinu.at)
            url=${1%/}
            ;;
        aur.archlinux.org)
            if [[ "${1##*/}" == "PKGBUILD" ]];then
                url="$1" 
            else
                if [[ "$AURLINKS" != "comments" ]];then 
                    DOUBLE=1
                    url=$(getlink $1 PKGBUILD)
                    url=https://aur.archlinux.org"$url" #"${${url##*=\'}%\'*}"
                fi
            fi
            ;;
        www.archlinux.org)
            if [[ "${${1##*org/}%%/*}" == "packages" ]];then
                repo="${${1##*ages/}%%/*}"
                package="${${1%/*}##*/}"
                url=https://projects.archlinux.org/svntogit/"$repo".git/plain/trunk/PKGBUILD\?h\=packages/"$package"
            fi
            ;;
        ompldr.org|omploader.org)
            tmp="${${1##*//}%%/*}"
            testurl="${1/$tmp/ompldr.org}"
            testomp "$testurl"
            dones=1;
            ;; 
        imgur.com)
            imageurl=(${(u)${${(SM)${(f)"$(zwget $1)"}#http*${1##*/}*\"}%%\"*}:#$1})
            #imageurl="$(curl -Ls $1 |grep -Ei ".jpg|.png"|grep -Ei "a href"|head -n1)"
            #imageurl=${(M)${(f)"$(getpaste text $1)"}:#*\.jpg*}
            #[[ -z $imageurl ]] && imageurl=${(M)${(f)"$(getpaste text $1)"}:#*\.png*}
            #imageurl="${${imageurl##*ref\=\"}%%\"*}"
            ;;
        www.youtube.com|youtu.be)
            videourl="$1";;
    esac
    if [[ -n "$url" ]];then
        vr PASTIE "$url"
    elif [[ -n "$imageurl" ]];then
        #(( $commands[curl] )) && curl -Ls -o "${ZURLDIR%/}"/"$val" "$imageurl" || ($BROWSER $imageurl && return)
        zwget $imageurl > $ZURLDIR/$val
        (( $+commands[$IMAGEOPENER] )) && "$IMAGEOPENER" "${ZURLDIR%/}"/"$val" || "$BROWSER" "$imageurl"
    elif [[ -n "$videourl" ]];then
        if [[ -n "$YOUTUBE" ]]; then
            "$YOUTUBE" "$1"
        elif (( $+commands[youtube-viewer] )); then
            youtube-viewer -mplayer="$YOUTUBEPLAYER" -mplayer_arguments="$YOUTUBEARGS" "$1"
        else
            "$BROWSER" "$1"
        fi
    elif [[ "$dones" -ne 1 ]]; then
        "$BROWSER" "$1"
    fi
}
testomp(){
    #filetype2="$(curl -Ls -I $1 |grep \^Content-Type|sed -e 'sT.*:\ \(.*/.*\);\?\ \?.*T\1Tg' )"
    filetype2=(${${${(M)${(f)"$(getpaste info "$1")"}:#Content-Type*}#Content-Type: }%%;*})
    filetype2="${filetype2%%;*}"
    filetypeis="${filetype2%/*}"
    case "$filetypeis" in 
        text)
            vr PASTIE "$1";;
        image)
            case "${filetype2#*/}" in
                gif*)
                    file=$ZURLDIR/$val
                    zwget "$1" > $file
                    (( $+commands[$GIFPLAYER] )) && "$GIFPLAYER" "${=GIFARGS[@]}" "$file" || "$BROWSER" "$1"
                    rm "$file"
                        ;;
                *)
                    zwget $1 "${ZURLDIR%/}"/"$val"
                    (( $+commands[$IMAGEOPENER] )) && "$IMAGEOPENER" "${ZURLDIR%/}"/"$val" || "$BROWSER" "$1"
                    ;;
            esac
            ;;
        *)
            "$BROWSER" "$1";;
    esac
}
vr(){
    #curl -Ls -o "${ZURLDIR%/}"/"$val" "$2"
    print -l ${${(f)"$(zwget "$2")"}%} > "${ZURLDIR%/}/$val"
    testopen
    if [[ "$?" -eq 0 ]];then
        testmulti 
        if [[ "$?" -eq 0 ]]; then
            "$MULTIPLEXER" "${=MULTIARGS[@]}" "$PASTEEDITOR ${PASTEARGS[@]} ${ZURLDIR%/}/$val"
        else
            (( $+commands[$PASTETERMINAL] )) && "$PASTETERMINAL" "${=PASTEEXEC[@]}" "zsh -c \"$PASTEEDITOR ${PASTEARGS[@]} ${ZURLDIR%/}/$val\"" || "$BROWSER" "$2"
        fi
    else
        (( $+commands[$PASTEEDITOR] )) && $PASTEEDITOR "${=OPENEDPASTEARGS[@]}" "${ZURLDIR%/}"/"$val" #|| "$BROWSER" "$2"
    fi
}

getlink(){
    [[ ${1:0:5} == "https" ]] && tmp=${1/s} || tmp=$1
    if [[ $DOUBLE -eq 1 ]]; then
        print -l ${${${(M)${(f)"$(getpaste text $tmp)"}:#*$2*}##*href=[\'\"]}%%[\'\"]*}
    else
        print -l ${${${(M)${(f)"$(getpaste text $tmp)"}:#*$2*}#*href=[\'\"]}%%[\'\"]*}
    fi
    unset DOUBLE
}

followurl(){
    local location=${${(M)${(f)"$(getpaste info $1)"}:#Location*}#Location: }
    
    if [[ -z $location ]]; then
        URL=$1
    elif [[ ${location:0:4} == "http" ]]; then
        URL=$location
    elif [[ $location[1] == "/" ]]; then
        URL="${(M)1#*//#/}${location#/}"
    fi
    unset location
    [[ $- == *i* ]] && print -l $URL && unset URL
}

testkeys(){
    while [[ -n $@ ]]; do
        case $1 in 
            info)
                info=1;;
            text)
                text=1;;
            save)
                savetext=1;;
            image)
                image=1;;
            http*)
                URL="$1";;
            -p|--port)
                shift
                port=$1
                ;;
        esac
        shift
    done
    export info text savetext URL port
}

zwget() {
    emulate -LR zsh
    local scheme empty server resource fd headerline
    IFS=/ read scheme empty server resource <<<$1
    case $scheme in
    (https:) print -u2 SSL unsupported, falling back on HTTP ;&
    (http:)
        zmodload zsh/net/tcp
        ztcp $server 80 && fd=$REPLY || return 1;;
    (*) print -u2 $scheme unsupported; return 1;;
    esac
    print -l -u$fd -- \
        "GET /$resource HTTP/1.0"$'\015' \
        "Host: $server"$'\015' \
        'Connection: close'$'\015' $'\015'
    while IFS= read -u $fd -r headerline
    do
	[[ $headerline == $'\015' ]] && break
    done
    while IFS= read -u $fd -r -e; do :; done
    ztcp -c $fd
}

getpaste(){
    testkeys "$@"
    local printtext htmlinfo
    TCP_PROMPT=""
    TCP_SILENT=0
    printtext='${tcp_lines:#*}'
    printimage='${${tcp_lines:#*}:#^[ \t]$}'
    htmlinfo='${(M)tcp_lines:#*}'
    local domain=${${(SM)URL#//*/}//\/}

    [[ -z $port ]] && port=80
    zmodload zsh/net/tcp
    ztcp $domain $port
    fd=$REPLY
    link="${URL#*$domain}"
    print -l -u $fd -- "GET $link HTTP/1.1"$'\015' "Host: $domain"$'\015' 'Connection: close'$'\015' $'\015'
    tcp_lines=(${(f)"$(while IFS= read -u $fd -r -e; do; :; done)"})
    ztcp -c $fd
    [[ -n $info ]] && print -l ${(e)htmlinfo}
    [[ -n $text ]] && print -l ${(e)printtext}
    [[ -n $image ]] && print -l ${(e)printimage}
    if [[ -n $savetext ]]; then
        [[ -z $var ]] && local var=$RANDOM
        [[ -z $ZURLDIR ]] && local ZURLDIR=/tmp
        print -l ${(e)printtext} > "$ZURLDIR/$var"
    fi
    unset domain URL saveinfo info text port tcp_lines
}

removefile (){
    sleep 5
    [[ -f "${ZURLDIR%/}"/"$val" ]] && rm "${ZURLDIR%/}"/"$val"
}
testopen(){
    if [[ -n "${(Mf)$(vim --serverlist)#PASTIE}" ]];then
        return 1
    else
        return 0
    fi
}
testmulti(){
    if (( $+commands[tmux] )) && [[ -n "${(Mf)$(tmux list-session 2>&/dev/null|grep attached)}" ]];then
        return 0
    else
        return 1
    fi
}

autoload -U regex-replace
[[ $- == *i* ]] && return
export val="$RANDOM"
while [[ -f "${ZURLDIR%/}"/"$val" ]];do
    export val="$RANDOM"
done
[[ -f /etc/zurlrc ]] && . /etc/zurlrc
[[ -f ~/.zurlrc ]] && . ~/.zurlrc
[[ -f "$XDG_CONFIG_HOME"/zurl/config ]] && . "$XDG_CONFIG_HOME"/zurl/config
export AURLINKS="${AURLINKS:-PKGBUILD}"
export BROWSER="${BROWSER:-firefox}"
export GIFPLAYER="${GIFPLAYER:-mplayer}"
export YOUTUBEPLAYER="${YOUTUBEPLAYER:-mplayer}"
export PASTEEDITOR="${PASTEBINEDITOR:-vim}"
export MULTIPLEXER="${MULTIPLEXER:-tmux}"
export SERVERNAME="${SERVERNAME:-PASTIE}"
export ZURLDIR="${ZURLDIR:-/tmp}"
export REMOVEFILE="${REMOVEFILE:-1}"
export PASTETERMINAL="${PASTETERMINAL:-termite}"
export IMAGEOPENER="${IMAGEOPENER:-feh}"
[[ -z "$PASTEEXEC" && "$PASTETERMINAL" == "termite" ]] && export PASTEEXEC="-e"
[[ -z "$GIFARGS" ]] && export GIFARGS="-loop 0 -speed 1"
[[ -z "$YOUTUBEARGS" ]] && export YOUTUBEARGS="-loop 0 -speed 1"
[[ -z "$PASTEARGS" ]] && export PASTEARGS="--servername $SERVERNAME"
[[ -z "$OPENEDPASTEARGS" ]] && export OPENEDPASTEARGS="$PASTEARGS --remote-tab-silent"
[[ -z "$MULTIARGS" ]] && export MULTIARGS="neww -n $SERVERNAME"
if [[ ! -d "$ZURLDIR" ]]; then
    mkdir "$ZURLDIR";
    if [[ $? -ne 0 ]]; then
        print "$ZURLDIR does not exist"
        exit 1;
    fi
fi



#filetype2="$(curl -Ls -I $1 |grep \^Content-Type|sed -e 'sT.*:\ \(.*/.*\);\?\ \?.*T\1Tg' )"
filetype2=(${${${(M)${(f)"$(getpaste info "$1")"}:#Content-Type*}#Content-Type: }%%;*})
filetype2="${filetype2%%;*}"
filetypeis="${filetype2%/*}"
echo $1
case "$filetypeis" in 
    image)
        case "${filetype2#*/}" in
            gif*)
                file="${ZURLDIR%/}"/"$val"
                #curl -Ls "$1" -o "$file"
                zwget $1 > $file
                (( $+commands[$GIFPLAYER] )) && "$GIFPLAYER" "${=GIFARGS[@]}" "$file" || "$BROWSER" "$1"
                rm "$file"
                    ;;
            *)
                #curl -Ls -o "${ZURLDIR%/}"/"$val" "$1"
                zwget $1 > $ZURLDIR/$val
                (( $+commands[$IMAGEOPENER] )) && "$IMAGEOPENER" "${ZURLDIR%/}"/"$val" || "$BROWSER" "$1"
                ;;
        esac
        ;;
    *)
        if [[ "$filetype2" == "text/plain" ]];then
            url="$1"
            if [[ "${${1##*//}%%/*}" == "pastebin.com" ]];then
                url="${${url//\?/\\\?}//=/\\=}"
            fi
            vr PASTIE "$url"
        else
            pastebin "$1"
        fi
        ;;
esac

[[ $REMOVEFILE -eq 0 ]] && removefile 
# vim: set filetype=zsh:
