# fish completion for ASCIIGrid

complete -c asciigrid -l input -s i -r -d 'Input file path' -f
complete -c asciigrid -l format -s f -r -d 'Input format' -f -a 'json ndjson'
complete -c asciigrid -l title -s t -r -d 'Table title'
complete -c asciigrid -l padding -s p -r -d 'Cell padding (default: 1)'
complete -c asciigrid -l no-header -s H -d 'Disable header separator'
complete -c asciigrid -l spreadsheet -s s -d 'Enable spreadsheet labels'
complete -c asciigrid -l align -s a -d 'Right-align numeric values'
complete -c asciigrid -l theme -s T -r -d 'Border theme' -f -a 'mysql unicode oracle'
complete -c asciigrid -l output -s o -r -d 'Write output to file' -f
complete -c asciigrid -l verbose -s v -d 'Enable verbose output'
complete -c asciigrid -l timeout -r -d 'Timeout for stdin (0 = disabled)'
complete -c asciigrid -l rich -d 'Preserve JSON value types'
complete -c asciigrid -l help -s h -d 'Show help'
complete -c asciigrid -l version -d 'Show version'