echo "Sourcing git module"

#
# Echo the current branch
#
curr_branch () {
	git branch | rg '\*' | awk '{print $2}'
}

#
# git add  enhancement. Pass --select|-s to select files to add
#


ga () {
	if [[ ! -z "$1" ]]
	then
		git add $@
		return 0
	fi
	files=$(gs -s | rg '^[ \?]' | fzf -m --preview \
        'fil=$(echo {} | awk '"'"'$1 ~ /M+/ {print $2}'"'"'); \
        if [ ! -z $fil ]; \
            then git diff --color=always $fil | bat --style=plain --color=always -l diff | delta;
        else; \
            bat --color=always $(echo {} | xargs | cut -d" " -f2); \
        fi | less -r' \
        | xargs -I {} echo {} | cut -d" " -f2)
	if [[ ! -n "$files" ]]
	then
		return 0
	fi
	echo $files
	git add $(echo $files | xargs)
}

#
# git restore enhancement. Pass --select|-s to select files to restore
#
gr () {
	local staged
	while getopts ":s" opt
	do
		case ${opt} in
			(s) staged='--staged'  ;;
			(\?) echo "Invalid Option: -$OPTARG" >&2
				return 1 ;;
		esac
	done
	shift $((OPTIND -1))
	if [[ ! -z "$1" ]]
	then
		git restore ${staged} $@
		return 0
	fi
	if [[ ! -z "$staged" ]]
	then
		git restore --staged $(git status -s | rg -v '^ ' | fzf -m --preview 'bat --color=always $(echo {} | awk '"'"'$0 ~ /[\?AMD]/ {print $2}'"'"') | less -r' | xargs -I {} echo {} | cut -d" " -f2)
	else
		git restore $(git status -s | rg '^ ' | fzf -m --preview 'bat --color=always $(echo {} | awk '"'"'$0 ~ /^ [AMD]/ {print $2}'"'"') | less -r' | xargs -I {} echo {} | cut -d" " -f2)
	fi
}


gbrowse () {
	local files
	files=$(gs -s | rg '^[ \?][^D]' | fzf -0 -m --preview \
        'fil=$(echo {} | awk '"'"'$1 ~ /M+/ {print $2}'"'"'); \
        if [ ! -z $fil ]; \
            then git diff --color=always $fil | bat --style=plain --color=always -l diff;
        else; \
            bat --color=always $(echo {} | xargs | cut -d" " -f2); \
        fi | less -r' \
        | xargs -I {} echo {} | cut -d" " -f2)
	if [[ ! -n "$files" ]]
	then
		return 0
	else
		nvim $files
	fi
}

gselect() {
    echo $(gs -s | rg '^[ \?][^D]' | fzf -0 -m --preview \
        'fil=$(echo {} | awk '"'"'$1 ~ /M+/ {print $2}'"'"'); \
        if [ ! -z $fil ]; \
            then git diff --color=always $fil | bat --style=plain --color=always -l diff;
        else; \
            bat --color=always $(echo {} | xargs | cut -d" " -f2); \
        fi | less -r' \
        | xargs -I {} echo {} | cut -d" " -f2)
}

#
# git push enhancement. Pass -pr to open a PR after pushing via the github url
#
gpush () {
	branch=$(curr_branch)
	pr=0
	if [[ "$1" == '-pr' ]]
	then
		pr=1
		shift
	fi
	if [[ "$branch" == 'master' ]]
	then
		echo -n "Are your sure you want to push to master? (y/n): "
		read res
		[ "$res" != 'yes' ] && return 0
	fi
	git push ${1:-} origin "$branch" > >(tee -a /tmp/url ) 2> >(tee -a /tmp/url >&2)
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
gpull () {
	if [[ ! -n "$1" ]]
	then
		git pull origin $(curr_branch) --ff-only
		return 0
	fi
	git pull origin $(curr_branch) $@
}

#
# git checkout a given branch. If no branch is given, use fzf to select one
#
gcob () {
	local branch="$1"
	if [[ -z "$branch" ]]
	then
		branch=$(_branch)
		if [[ -z "$branch" ]]
		then
			return 0
		fi
		git checkout "$branch"
	else
		git checkout "$branch"
	fi
	gpull
}

delbranch () {
	branches=$(_branch)
	if [[ -z "$branches" ]]
	then
		return 0
	fi
	echo "deleting branches: $branches"
	git branch -D $(echo "$branches")
}


#
# select a branch
#

_branch() {
    local preview_command='echo $(git rev-list --left-right --count master...$(echo {} | tr -d " ")  | tr -s " " | awk '"'"'{print "Behind branch master by: "$1" commits <--> Ahead of branch master by "$2" commits"}'"'"') && printf "\n" && git diff --color=always master $(echo {} | tr -d " ") --stat | tr -s " " | less -r'
    echo $(git branch | fzf -m --preview $preview_command)
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
	git log | head -1 | awk '{print $2}' | tr -d '\n' | pbcopy
}

#
# Open current repo in nvim gitdiff view
#
vdiff () {
	nvim -c "DiffviewOpen $@"
}

open_pr () {
	if ! git status > /dev/null 2>&1
	then
		echo "Not a git repo"
		return 1
	fi
	if gh pr view
	then
		open $(gh pr view | rg 'url:\s+(.*)' -r '$1')
	else
		commit_message="${1}"
		if gh pr create -t "${commit_message}"
		then
			echo "PR created!"
			open $(gh pr view | rg 'url:\s+(.*)' -r '$1')
		else
			echo "Failed to create PR"
		fi
	fi
}

gprev () {
	if [[ ! -d ./.git ]]
	then
		echo "Not a git repository"
		return 1
	fi
	nvim $(gd --name-only master HEAD  | fzf --bind 'ctrl-k:preview-up,ctrl-j:preview-down,ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down,ctrl-g:preview-bottom,ctrl-b:preview-top'  --preview 'git diff -U"$(cat {} | wc -l)" master HEAD {} | delta')
}

export GIT_FUNCTIONS_SET=1
