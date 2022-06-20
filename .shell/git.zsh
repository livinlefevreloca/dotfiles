echo "Sourcing git module"

curr_branch() { git branch | rg '\*' | awk '{print $2}'; }

gpush () { git push ${1:-} origin $(curr_branch); }
gpull () { git pull origin $(curr_branch); }

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
    nvim +DiffviewOpen
}

export GIT_FUNCTIONS_SET=1
