echo "Sourcing git module"

#
# Echo the current branch
#
curr_branch() { git branch | rg '\*' | awk '{print $2}'; }

#
# git add  enhancement. Pass --select|-s to select files to add
#
ga () {
    if [[ "$1" == '--select' || "$1" == '-s' ]]
    then
        ga $(git status -s | awk '/ [MD]|\?\?/ {print $2}' | fzf -m)
    else
        git add $@
    fi
}

#
# git restore enhancement. Pass --select|-s to select files to restore
#
grs () {
    if [[ "$1" == '--select' || "$1" == '-s' ]]
    then
        git restore --staged $(git status -s | awk '/^[AMD]/ {print $2}' | fzf -m)
    else
        git restore --staged $@
    fi
}

#
# git push enhancement. Pass -pr to open a PR after pushing via the github url
#
gpush () {
    branch=$(curr_branch)
    pr=0
    if [[ "$1" == '-pr' ]]
    then
        pr=1;
        shift;
    fi

    if [[ "$branch" == 'master' ]];
    then
        echo -n "Are your sure you want to push to master? (y/n): "
        read res
        [ "$res" != 'yes' ] && return 0
    fi

    git push ${1:-} origin "$branch" >  >(tee -a /tmp/url ) 2> >(tee -a /tmp/url >&2)

    if [[ "$pr" == 1 ]]
    then
        url=$(cat /tmp/url | rg 'pull/new/add' | awk -F': ' '{print $2}' )
        echo "$url"
        if [[ ! -z "$url" ]]
        then
            open "$url"
        fi
    fi
    rm /tmp/url


}

#
# git pull the current branch
#
gpull () { git pull origin $(curr_branch) "$1" } 

#
# git checkout a given branch. If no branch is given, use fzf to select one
#
gco() {
    branch="$1"

    if [[ -z "$branch" ]];
    then
        git checkout $(git branch | fzf);
    else
        git checkout "$branch"
    fi
    gpull
}

#
# Copy the name of current branch to clipboard
#
cp_branch () {
	curr_branch | pbcopy
}

#
# grab the latest commit from the current branch and cherry-pick it to the given branch
#
pick-to-branch () {
    hash=$(git log > temp && head -1 temp | cut -d' ' -f2)
    git checkout "$1"
    git cherry-pick "$hash"
    rm temp
}

#
# Copy the latest commit hash to clipboard
#
cp_commit () {
    git log | head -1 | awk '{print $2}' | tr -d '\n' | y
}

#
# Open current repo in nvim gitdiff view
#
vdiff () {
    nvim -c "DiffviewOpen $@"
}

export GIT_FUNCTIONS_SET=1
