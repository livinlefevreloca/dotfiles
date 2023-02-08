echo "Sourcing git module"

export GITHUB_TOKEN=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

curr_branch() { git branch | rg '\*' | awk '{print $2}'; }

ga () {
    if [[ "${1}" == '--select' || "${1}" == '-s' ]]
    then
        ga $(git status -s | awk '/ [MD]|\?\?/ {print $2}' | fzf -m)
    else
        git add $@
    fi
}

grs () {
    if [[ "${1}" == '--select' || "${1}" == '-s' ]]
    then
        git restore --staged $(git status -s | awk '/^[AMD]/ {print $2}' | fzf -m)
    else
        git restore --staged $@
    fi
}

gpush () { 
    
    branch=$(curr_branch)
    
    if [[ "$branch" == 'master' ]];
    then
        echo -n "Are your sure you want to push to master? (y/n): "
        read res
        [ "$res" != 'yes' ] && return 0
    fi

    git push ${1:-} origin "$branch"; 

}
gpull () { git pull origin $(curr_branch) ${1} } 

gco() {
    branch="${1}"
    
    if [[ -z "$branch" ]];
    then
        git checkout `git branch | fzf`;
    else
        git checkout "$branch"
    fi
    gpull
}

cp_branch () {
	git branch | rg '\*.*' | cut -d' ' -f2 | pbcopy
}


pick-to-branch () {
        hash=`git log > temp && head -1 temp | cut -d' ' -f2`
        git checkout "$1"
        git cherry-pick "$hash"
        rm temp
}


fast_push () {
    git commit -am "$@"
    gpush
}

cp_commit () {
    git log | head -1 | awk '{print $2}' | tr -d '\n' | y
}

vdiff () {
    nvim -c "DiffviewOpen $@"
}

export GIT_FUNCTIONS_SET=1
