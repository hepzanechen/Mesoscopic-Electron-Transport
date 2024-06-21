#!/bin/bash

LANG=en_US.UTF-8
PNAME=${PWD##*/}
QSUBTIME="9600:00:00"
NOWDIR=$(pwd)
QSUB="$PNAME.qsub"

# Initial default values for NODE and NP could be set here
NODE=1
# Predefined queue-to-CPU mapping based on known cluster configurations
declare -A queue_cpu_map=( ["new"]=32 ["old"]=32 ["new2"]=56 )


# Function to analyze queues and decide the best queue based on available nodes or least queued jobs
select_queue() {
    # Initialize an associative array to hold queue_name => [running_jobs,queued_jobs]
    declare -A queue_jobs

    # Populate the array with running and queued jobs for the three queues
    while read -r queue run que; do
        queue_jobs[$queue]="$run $que"
    done < <(qstat -q | grep -E "(new|old)" | awk '{print $1, $6, $7}')

    # Initialize variables to track the best queue
    local best_queue=""
    local min_run=999999
    local min_que=999999
    local all_queues_zero_queued_jobs=true

    # Check if all queues have zero queued jobs
    for queue in "${!queue_jobs[@]}"; do
        read run que <<< "${queue_jobs[$queue]}"
        if ((que > 0)); then
            all_queues_zero_queued_jobs=false
            break
        fi
    done

    # Determine the best queue based on the criteria
    for queue in "${!queue_jobs[@]}"; do
        read run que <<< "${queue_jobs[$queue]}"
        if $all_queues_zero_queued_jobs; then
            # If all queues have zero queued jobs, pick the one with the least running jobs
            if ((run < min_run)); then
                min_run=$run
                best_queue=$queue
            fi
        else
            # Otherwise, pick the one with the least queued jobs
            if ((que == 0)) || ((que < min_que)); then
                min_que=$que
                best_queue=$queue
            fi
        fi
    done

    # Check if new2's running jobs are less than 8, prioritize it if so
    read new2_run new2_que <<< "${queue_jobs["new2"]}"
    if ((new2_run < 7)); then
        best_queue="new2"
    fi

    echo "$best_queue"
}


# Use the function to select the best queue
BEST_QUEUE=$(select_queue)

# Echo the best queue for testing and debugging
echo "Best Queue Selected: $BEST_QUEUE"

# Determine NP based on the selected queue
NP=${queue_cpu_map[$BEST_QUEUE]}

# Echo NP for testing and debugging
echo "Number of CPUs (NP) Selected Based on Queue: $NP"

# Modify the queue line and other parameters dynamically
cat <<EOF >$QSUB
#!/bin/bash
#PBS -q $BEST_QUEUE
#PBS -V
#PBS -N $PNAME
#PBS -l nodes=$NODE:ppn=$NP
#PBS -l walltime="$QSUBTIME"
#PBS -o $NOWDIR/log.txt
#PBS -j oe
cd $NOWDIR
/home/software/matlabR2019b/bin/matlab <main.m> record.txt
sleep 1
EOF

# Submit the job
qsub $QSUB
