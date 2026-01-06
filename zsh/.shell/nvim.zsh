echo "Sourcing nvim module"

vim () {

	if [ $# -eq 0 ]
	then
		nvim .
	else
        file=$1
        shift
        tasksfile=/tmp/$(uuidgen)
        pidfile=/tmp/$(uuidgen)
        jobs -p > $tasksfile
        cat $tasksfile | cut -d' '  -f4 | xargs -I {} bash -c 'ps aux | rg "\s{2,}{}"' | rg nvim | awk '{print $2" "$NF}' > $pidfile

        if cat $pidfile | rg $file
        then
            echo "File is already open"
            pid=$(cat $pidfile | rg $file | awk '{print $1}')
            job=$(cat $tasksfile | rg $pid | cut -d' ' -f1 | rg -o '[0-9]+')
            echo "Attaching to job $job"
            fg %$job
        else
            nvim $file $@
        fi
        rm $tasksfile
	fi
}

scratch() {
  lvim /tmp/scratch-$(date +%s)
}

export NVIM_FUNCTIONS_SET=1
