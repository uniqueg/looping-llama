function claude-merge --description 'Let Claude merge PRs or not: claude-merge academic|personal [on|off]'
    set -l usage 'Usage: claude-merge academic|personal [on|off]'
    switch "$argv[1]"
        case a academic
            set -f profile academic
        case p personal
            set -f profile personal
        case '*'
            echo $usage >&2
            return 1
    end
    set -l file ~/.claude-$profile/settings.json
    set -l rule 'Bash(gh pr merge *)'
    switch "$argv[2]"
        case on
            set -f filter '.permissions.deny = ((.permissions.deny // []) - [$r])
                | .permissions.allow = ((.permissions.allow // []) - [$r] + [$r])'
        case off
            set -f filter '.permissions.allow = ((.permissions.allow // []) - [$r])
                | .permissions.deny = ((.permissions.deny // []) - [$r] + [$r])'
        case ''
            set -f filter ''
        case '*'
            echo $usage >&2
            return 1
    end
    if test -n "$filter"
        set -l tmp (mktemp); or return 1
        if jq --indent 2 --arg r $rule $filter $file >$tmp
            cat $tmp >$file
            rm -f $tmp
        else
            rm -f $tmp
            return 1
        end
    end
    if jq -e --arg r $rule '(.permissions.allow // []) | index($r)' $file >/dev/null
        echo "$profile: Claude may merge"
    else
        echo "$profile: Claude may not merge"
    end
end
