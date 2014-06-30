function createFullBackup(){
    if  ! [ -d "$1" ]; then
        echo "Adresar $1 neexistuje."
        return 1
    fi
    mkdir -p "$2"
    cp -pr "$1" "$2" 2> /dev/null
    return "$?"
}

#-------------------------------------BACKUP---------------------------------
#zalohuje slozku $1
#kontroluje zda jsou soubory totozne, jmeno se predpoklada stejne
function sameFiles(){ 
    if ! [ -e "$1" ] || ! [ -e "$2" ]; then # musi existovat
       return 1
    fi
    if [ "$1" -ot "$2" ] || [ "$1" -nt "$2" ]; then # stejny cas vytvoreni
       return 1
    fi
    return 0;
}

#zmeni normalni slozku zalohy do rozdilove zalohy. Nechava pod slozky. $1 slozka ke zmeneni, $2 template slozka
function changeToDiffBackup(){ 
    target="$1"
    compareWith="$2"
    echo "" > "${target}.diff"
    #mazani z target tech, ktere jsou v compareWith
    awkScript='{if(gsub(/^'$target'\//, "")) print $0;}'
    find "$target" | awk "$awkScript" | while read line; do #cesta od podslozky
        if ! [ -d "${target}/$line" ]; then #je cesta
            if sameFiles "${target}/$line" "${compareWith}/$line"; then #stejne soubory
                echo "cp" >> "${target}.diff"
                echo "${compareWith}/${line}" >> "${target}.diff"
                echo "${target}/${line}" >> "${target}.diff"
                rm "${target}/$line"
            fi
        fi
    done
}

function backup_dir(){
    source="$1"
    destination="${source}-backup/$(date +%y-%m-%d_%k-%M-%S)"
    
    if [ "$ERR" = "1" ]; then
        echo "Kopiruji $source do $destination."
    fi
    if ! createFullBackup "$source" "$destination"; then
        echo "Zalohovani se nepovedlo."
        exit 1
    fi
    #projde *-backup a full zalohy porovna s nejnovejsi
    i=0
    template=""
    cd "${source}-backup"
    awkScript='/^[0-9]{2}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}/ {print}' # necha jen soubory ve spravnem formatu
    ls | awk "$awkScript" | sort -r | while read line; do
        path="$line"
        if [ -z "$template" ]; then
            template="$line"
            continue;
        fi
        if [ -d "$path" ] && ! [ -e "${path}.diff" ]; then
            if [ "$ERR" = "1" ]; then
                echo "Provadim rozdilovou zalohu ${path} s predlohou ${template}."
            fi
            changeToDiffBackup "$path" "$template"
        fi
    done
    echo "Uspesne zalohovano."
    exit 0
}
#-------------------------------------UNBACKUP---------------------------------
function getFile(){ # $1 je soubor vuci ...-backup.. vypisuje to vuci skriptu
    backupDirS="$(echo "$source" | awk '{gsub(/[^\/]+$/,"");print;}')"
    
    # kdyz tam soubor je, vrat ho
    if [ -e "$backupDirS$1" ]; then
        echo "$backupDirS$1"
        return 0
    fi
    
    # kdys je tam jako diff, rekurentne ho ziskej
    diffFile="$backupDirS$(echo $1 | awk 'BEGIN{FS="/"}{print $1;}').diff"
    if ! [ -e "$diffFile" ]; then
        return 1;
    fi
    
    cat "$diffFile" |  while read line; do        
        if echo "$line" | grep '^cp' > /dev/null; then # pokud je to radek kopirovat
            read a
            read b
            
            if [ "$b" = "$1" ]; then
                getFile "$a"
                return $?
            fi
        fi
    done
    return 1
}

function unbackup_dir(){
    source="$1" #... /yy-mm-dd...
    destination="$2" #.. kam se to ma ulozit (aaa)
    if [ "$ERR" = "1" ]; then
        echo "Stavim zalohu $source."
    fi

    # zkopiruje zaklad
    if ! createFullBackup "$source" "$destination"; then
        echo "Nepovedlo se postavit zalohu."
        exit 1
    fi

    if ! [ -f "${source}.diff" ]; then #pokud to neni diff zaloha
        echo "Hotovo."
        exit 0;
    fi
    
    # kopiruje rozdilove
    if [ "$ERR" = "1" ]; then
        echo "Zpracovavam rozdilovou zalohu."
    fi
    #pocetChyb=1
    
    cat "${source}.diff" |  while read line; do
        if echo "$line" | grep '^cp' > /dev/null; then # pokud je to radek kopirovat
            read a
            read b
            
            from="$(getFile "$a")"            
            b="$destination/${b}"
            if [ "$ERR" = "1" ]; then
                echo "Kopiruji $from do $b"
            fi
            cp "$from" "$b" 2> /dev/null
            if [ "$?" = "1" ]; then
                echo "Chyba pri kopirovani souboru."
            fi
        fi
    done
    
    echo "Hotovo."
    exit 0
    
}
#-------------------------------------HANDLOVANI ARGUMENTU-------------------------------
function to_abs_path(){
    path="$1"
    if [ -n "$(echo "$path" | awk '/^\//{print}')" ]; then
        echo "$path"
        return 0
    else
        ret="${PWD}/${path}"
        echo "$ret" | awk '{gsub(/(\/\.)*/,""); print;}'
        return 0
    fi
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        "-b")
            if [ "$#" -eq 2 ]; then
                backup_dir "$(to_abs_path "$2")"
                exit 0;
            else
                break;
            fi
            ;;
        "-u")
            if [ "$#" -eq 3 ]; then
                unbackup_dir "$(to_abs_path "$2")" "$(to_abs_path "$3")"
                exit 0;
            else
                break;
            fi
            ;;
        "-e")
            ERR="1"
            ;;
        *)
            break
            ;;
    esac
    shift
done

echo "Spatny vstup."
exit 1