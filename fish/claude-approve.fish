function claude-approve --description 'Record your review of a PR for the level gate: claude-approve <PR URL> [--revoke]'
    set -l usage 'Usage: claude-approve <PR URL> [--revoke]'
    if not set -q argv[1]
        echo $usage >&2
        return 1
    end
    # https://github.com/<owner>/<repo>/pull/<n>
    set -l parts (string match -r '^https://github\.com/([^/]+)/([^/]+)/pull/([0-9]+)' -- $argv[1])
    if test (count $parts) -ne 4
        echo $usage >&2
        return 1
    end
    set -l marker ~/.local/state/claude-levels/approved/$parts[2]/$parts[3]/$parts[4]
    if test "$argv[2]" = --revoke
        rm -f $marker
        echo "Approval revoked: $argv[1]"
        return
    end
    # Current gh login first, then each persona's (the PR may be another persona's)
    set -l head
    for dir in "$GH_CONFIG_DIR" ~/.config/gh-*
        set head (GH_CONFIG_DIR=$dir gh pr view $parts[4] --repo $parts[2]/$parts[3] \
            --json headRefOid --jq .headRefOid 2>/dev/null)
        and break
    end
    if test -z "$head"
        echo "claude-approve: could not read $argv[1] with any gh login" >&2
        return 1
    end
    mkdir -p (path dirname $marker); or return 1
    echo $head >$marker
    echo "Approved $argv[1] at "(string sub -l 7 $head)" (new pushes need a new approval)"
end
