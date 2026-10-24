function claude --description 'Claude Code with an autonomy level: claude [--level <name>] [args]'
    set -l levels_dir ~/Work/private/looping-llama/claude/levels
    set -q CLAUDE_LEVELS_DIR; and set levels_dir $CLAUDE_LEVELS_DIR
    set -f level $CLAUDE_LEVEL
    set -f source env
    test -n "$level"; or set -f source default
    set -l args
    # Take --level off the arguments (before `--` only)
    while set -q argv[1]
        switch $argv[1]
            case --level
                set -f level $argv[2]
                set -f source flag
                set -e argv[1..2]
                continue
            case '--level=*'
                set -f level (string replace -- --level= '' $argv[1])
                set -f source flag
            case --
                set -a args $argv
                break
            case '*'
                set -a args $argv[1]
        end
        set -e argv[1]
    end
    # Subcommands (`claude mcp …`, `claude update`, …) start no session
    set -l subcommands agents attach auth auto-mode doctor gateway import install \
        kill logs mcp plugin plugins purge respawn rm setup-token stop ultrareview \
        update upgrade
    if set -q args[1]; and contains -- $args[1] $subcommands
        command claude $args
        return
    end
    test -n "$level"; or set -f level supervised
    set -l dir $levels_dir/$level
    if not test -f $dir/settings.json -a -f $dir/rules.md
        echo "claude: unknown level '$level'. Levels:" (path basename $levels_dir/*/) >&2
        return 1
    end
    echo "claude: autonomy level $level ($source)" >&2
    CLAUDE_LEVEL=$level command claude --settings $dir/settings.json \
        --append-system-prompt-file $dir/rules.md $args
end
