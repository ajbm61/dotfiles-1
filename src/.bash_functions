setenv() {
    name="$1"

    env_file=".env"
    env_file_named=".env-$name"

    env_file_abs="$PWD/$env_file"
    env_file_abs_named="$PWD/$env_file_named"

    if test ! -f "$env_file_abs_named"; then
        echo >&2 "env file not found: $env_file_named"
        exit 1
    fi

    echo "found $env_file_abs_named"
    if test -h "$env_file_abs"; then
        rm -v "$env_file_abs"
        ln -s "$env_file_named" "$env_file"
        echo "symlinked $env_file -> $env_file_named"
    else
        echo >&2 "ERROR $env_file_abs is not a symlink"
        exit 1
    fi
}

showrecenterrors() {
    d="$(date -u +%Y-%m-%d)"

    if test -f storage/logs/laravel.log; then
        showrecentapperrors
    elif test -f storage/logs/laravel-$d.log; then
        showrecentapperrors
    fi

    showrecentconerrors
}

find_dirs_not_perm_755() {
    find . ! -perm 755 -type d ! -wholename "*.git/*" -ls
}

find_regular_files_not_perm_644() {
    find . ! -perm 644 -type f ! -wholename "*.git/*" -ls
}

find_regular_files_with_byte_order_marks() {
    find . -type f ! -wholename "*.git*" | while read file; do
        first_3_chars=$(head -c 3 -- ${file})
        if [ "${first_3_chars}" == $'\xef\xbb\xbf' ]; then
            echo "Found BOM in: ${file}"
        fi
    done
}

# https://askubuntu.com/questions/73443/how-to-stop-the-terminal-from-wrapping-lines
nowrap() {
    tput rmam
}

# https://askubuntu.com/questions/73443/how-to-stop-the-terminal-from-wrapping-lines
wrap() {
    tput smam
}

mypyinitfix() {
    # Recursively creates __init__.pyi files.
    #
    # Options:
    #   --undo Recursively removes any __init__.pyi files.
    #   --dry-run

    dry_run=
    undo=

    if test "x$1" = "x--dry-run"; then
        dry_run=y
    fi

    if test "x$1" = "x--undo"; then
        undo=y
    fi

    if test "x$2" = "x--dry-run"; then
        dry_run=y
    fi

    if test "x$2" = "x--undo"; then
        undo=y
    fi

    prefix_msg=""
    if test "x$dry_run" = "xy"; then
        prefix_msg="[dry run] "
    fi

    folders="$(find . -type d ! -path "*/.git*" ! -path "*/tmp*" ! -path "*/res*")"
    for folder in ${folders}; do
        test -d "$folder" || continue

        init_py_file="$folder/__init__.py"
        init_pyi_file="$folder/__init__.pyi"

        if test "x$undo" = "xy"; then
            if test -f "$init_pyi_file"; then
                if test "x$dry_run" = "xy"; then
                    echo "${prefix_msg}remove $init_pyi_file"
                else
                    echo "${prefix_msg}remove $init_pyi_file"
                    rm -v "$init_pyi_file"
                fi
            fi
        else
            if test ! -f "$init_py_file"; then
                if test ! -f "$init_pyi_file"; then
                    if test "x$dry_run" = "xy"; then
                        echo "${prefix_msg}create          $init_pyi_file"
                    else
                        echo "${prefix_msg}create          $init_pyi_file"
                        touch "$init_pyi_file"
                    fi
                else
                    echo "${prefix_msg}already exists: $init_pyi_file"
                fi
            else
                echo "${prefix_msg}already exists: $init_py_file"
            fi
        fi
    done
}

internet_use() {
    lsof -P -i -n | uniq
}

internet_use_full() {
    lsof -P -i -n | cut -f 1 -d " " | uniq
}

gitkcurrent() {
    cmd=gitk
    cmd+=" -n 400"
    cmd+=" master"
    cmd+=" $(git rev-parse --abbrev-ref HEAD)"
    for remote in $(git remote); do
        for accept in origin upstream gerardroche hub; do
            if test "x$remote" = "x$accept"; then
                cmd+=" $remote/master"
            fi
        done
    done

    $cmd
}

gitkbranches() {
    cmd=gitk
    cmd+=" -n 400"
    cmd+=" --branches"
    cmd+=" master"
    cmd+=" $(git rev-parse --abbrev-ref HEAD)"
    for remote in $(git remote); do
        for accept in origin upstream gerardroche hub; do
            if test "x$remote" = "x$accept"; then
                cmd+=" $remote/master"
            fi
        done
    done

    $cmd
}

new() {
    cat="$1"
    if test "x$1" = "xfix"; then
        cat="hotfix"
    fi

    name="$2"
    git checkout -b "$cat/$name"
}

rbenv() {
    local cmd="$1"
    if [ "$#" -gt 0 ]; then
        shift
    fi

    case "$cmd" in
        rehash|shell)
            eval "$(rbenv "sh-$cmd" "$@")";;
        *)
            command rbenv "$cmd" "$@";;
    esac
}

appconsole() {
    if test -f ./bin/appconsole; then
        cmd=./bin/appconsole
    elif test -f ./vendor/bin/appconsole; then
        cmd=./vendor/bin/appconsole
    else
        cmd=appconsole
    fi

    command "$cmd" "$@"
}

dbtasks() {
    if test -f ./bin/dbtasks; then
        cmd=./bin/dbtasks
    elif test -f ./vendor/bin/dbtasks; then
        cmd=./vendor/bin/dbtasks
    else
        cmd=dbtasks
    fi

    command "$cmd" "$@"
}

pdoc() {
    if test -f ./bin/pdoc; then
        cmd=./bin/pdoc
    elif test -f ./vendor/bin/pdoc; then
        cmd=./vendor/bin/pdoc
    else
        cmd=pdoc
    fi

    command "$cmd" "$@"
}

phpcs() {
    if test -f ./vendor/bin/php-cs-fixer; then
        php -d xdebug.scream=0 ./vendor/bin/php-cs-fixer "$@"
    else
        config_file=
        if test "x$1" = "xfix"; then
            if test -f ./.php_cs; then
                config_file=./.php_cs
            elif test -f ./../.php_cs; then
                config_file=./../.php_cs
            elif test -f ./.php_cs.dist; then
                config_file=./.php_cs.dist
            else
                echo "no config found!"
                return
            fi
        fi

        echo "using php-cs-fixer config: $config_file"
        if test -n "$config_file"; then
            php-cs-fixer -vvv "$@" --config "$config_file"
        else
            php-cs-fixer -vvv "$@"
        fi
    fi
}

title() {
    echo -n -e "\033]0;$*\007"
}

toggledebug() {
    if test -f ./.debug; then
        rm ./.debug
        echo 'Debug is disabled'
    else
        touch  ./.debug
        echo 'Debug is enabled'
    fi
}

versioninfo() {
    echo -n "Hostname: "
    cat /etc/hostname

    echo -n "Uname: "
    uname -a

    echo -n "Debian: "
    cat /etc/debian_version

    echo -n "Release: "
    cat /etc/lsb-release

    echo -n "Unity: "
    unity --version

    echo -n "Gnome: "
    gnome-shell --version
}

setmygitremote() {
    git_origin_url="$(git remote get-url origin 2> /dev/null || true)"

    if test -z "$git_origin_url"; then
        echo >&2 "origin remote not found"
        return
    fi

    new_origin="$(echo "$git_origin_url" |\
        grep "^https://github.com/gerardroche/" |\
        sed '
        s_https://github.com/gerardroche/_git@github.com:gerardroche/_
        '\
    )"

    if test -n "$new_origin"; then
        git remote -v
        git remote set-url origin "$new_origin"
    fi

    git remote -v
}

wapplogs() {
    tail -f /var/log/{apache2,mysql}/{,*}{access,error,mysql}.log ./data/logs/*.log
}

wapplogs() {
    tail -f /var/log/apache2/{access,error,mysql}.log
}

wmysqllogs() {
    tail -f /var/log/mysql/{error,mysql}.log
}

wdataapplogs() {
    tail -f data/logs/*.log
}

wlaravelapplogs() {
    tail -f storage/logs/*.log
}

projects() {
    if test -n "$PROJECTS_PATH" && test -d "$PROJECTS_PATH"; then
        for project in "$PROJECTS_PATH"/*/*; do
            test -d "$project" || continue
            echo "${project#$PROJECTS_PATH/}"
        done
    fi
}

vendors() {
    if test -n "$VENDOR_PATH" && test -d "$VENDOR_PATH"; then
        for vendor in "$VENDOR_PATH"/*/*; do
            test -d "$vendor" || continue
            echo "${vendor#$VENDOR_PATH/}"
        done
    fi
}

c() {
    if test -z "$PROJECTS_PATH"; then
        return
    fi

    if test "$#" = 0 && test "$PWD" = "$PROJECTS_PATH"; then
        return
    fi

    if test -n  "$1"; then
        cd "$PROJECTS_PATH/$1"

        return
    fi

    if [[ "$PWD" = "$PROJECTS_PATH"/* ]]; then # we are within a project; go to its root

        path="$PWD"
        projects_path_depth=
        for (( i = 1; i < 10; i++ )); do
            path="$(dirname "$path")"
            if [ "$path" == "$PROJECTS_PATH" ]; then
                projects_path_depth=$i
                break
            fi
        done

        if [ "$projects_path_depth" -eq 2 ]; then
            return
        fi

        if [ "$projects_path_depth" -gt 2 ]; then
            projects_path_depth=$(expr $projects_path_depth - 2)

            path="$PWD"
            for (( i = 0; i < $projects_path_depth; i++ )); do
                path="$(dirname "$path")"
            done

            cd "$path"

            return
        fi
    else # we are not within a project; go to projects path

        cd "$PROJECTS_PATH"
    fi
}

v() {
    cd "$VENDOR_PATH/$1"
}

wslsshadd() {
    eval $(ssh-add -s)
    ssh-add ~/.ssh/id_rsa
}
