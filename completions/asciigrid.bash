# bash completion for ASCIIGrid

_asciigrid() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    opts='--input --format --title --padding --no-header --spreadsheet --align --theme --output --verbose --timeout --max-rows --rich --help --version'

    case "$prev" in
        --input|-i)
            COMPREPLY=($(compgen -f -- "$cur"))
            return 0
            ;;
        --format|-f)
            COMPREPLY=($(compgen -W "json ndjson" -- "$cur"))
            return 0
            ;;
        --theme|-T)
            COMPREPLY=($(compgen -W "mysql unicode oracle" -- "$cur"))
            return 0
            ;;
        --padding|-p)
            return 0
            ;;
        --timeout)
            return 0
            ;;
        --max-rows)
            return 0
            ;;
        --output|-o)
            COMPREPLY=($(compgen -f -- "$cur"))
            return 0
            ;;
        *)
            ;;
    esac

    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$opts" -- "$cur"))
    fi

    return 0
}

complete -F _asciigrid asciigrid
complete -F _asciigrid ASCIIGrid
