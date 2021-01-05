#!/bin/bash

set -e

# Load input parser functions
setup=$( cd "$(dirname "$0")" ; pwd )

# This function gets called by opts_ParseArguments when --help is specified
usage() {
    # header text
    echo "
$log_ToolName: Submitting script for running MPP on Slurm managed computing clusters

Usage: $log_ToolName
                    [--job-name=<name for job allocation>] default=MsBrain
                    [--partition=<request a specific partition>] default=RM-shared
                    [--exclude=<node(s) to be excluded>] default=""
                    [--nodes=<minimum number of nodes allocated to this job>] default="1"
                    [--time=<limit on the total run time of the job allocation>] default="1"
                    [--ntasks=<maximum number of tasks>] default=1
                    [--mem=<specify the real memory required per node>] default=2gb
                    [--export=<export environment variables>] default=ALL
                    [--mail-type=<type of mail>] default=FAIL,END
                    [--mail-user=<user email>] default=msbrain2021@gmail.com

                    [--printcom=command]                if 'echo' specified, will only perform a dry run.
        PARAMETERs are [ ] = optional; < > = user supplied value

        Values default to running the example with sample data
    "
    # automatic argument descriptions
    opts_ShowArguments
}


input_parser() {
    # Load input parser functions
    . "./opts.shlib" "$@"

    opts_AddOptional '--job-name' 'jobName' 'name for job allocation' "an optional value; specify a name for the job allocation. Default: MsBrain" "MsBrain"
    opts_AddOptional '--partition' 'partition' 'request a specifi partition' "an optional value; request a specific partition for the resource allocation (e.g. standard, workstation). Default: RM-shared" "RM-shared"
    opts_AddOptional  '--exclude' 'exclude' 'node to be excluded' "an optional value; Explicitly exclude certain nodes from the resources granted to the job. Default: None" ""
    opts_AddOptional  '--nodes' 'nodes' 'minimum number of nodes allocated to this job' "an optional value; iIf a job node limit exceeds the number of nodes configured in the partiition, the job will be rejected. Default: 1" "1"
    opts_AddOptional  '--time' 'time' 'limit on the total run time of the job allocation' "an optional value; When the time limit is reached, each task in each job step is sent SIGTERM followed by SIGKILL. Format: days-hours:minutes:seconds. Default 2 hours: None" "05:00:00"
    opts_AddOptional '--ntasks' 'nTasks' 'maximum number tasks' "an optional value; sbatch does not launch tasks, it requests an allocation of resources and submits a batch script. This option advises the Slurm controller that job steps run within the allocation will launch a maximum of number tasks and to provide for sufficient resources. Default: 1" "1"
    opts_AddOptional  '--mem' 'mem' 'specify the real memory requried per node' "an optional value; specify the real memory required per node. Default: 2gb" "2gb"
    opts_AddOptional  '--export' 'export' 'export environment variables' "an optional value; Identify which environment variables from the submission environment are propagated to the launched application. Note that SLURM_* variables are always propagated. Default: All of the users environment will be loaded (either from callers environment or clean environment" "ALL"
    opts_AddOptional  '--mail-type' 'mailType' 'type of mail' "an optional value; notify user by email when certain event types occur. Default: FAIL,END" "FAIL,END"
    opts_AddOptional  '--mail-user' 'mailUser' 'user email' "an optional value; User to receive email notification of state changes as defined by --mail-type. Default: msbrain2021@gmail.com" "msbrain2021@gmail.com"

    #opts_AddMandatory '--subjectPath' 'subjectPath' 'path to file with subject IDs' "a required value; path to a file with the IDs of the subject to be processed must be absolute path (e.g. /pylon5/med200002p/liw82/KLU/90*/80*)" "--subject" "--subjectList" "--subjList"    
    opts_AddOptional '--printcom' 'RUN' 'do (not) perform a dray run' "an optional value; If RUN is not a null or empty string variable, then this script and other scripts that it calls will simply print out the primary commands it otherwise would run. This printing will be done using the command specified in the RUN variable, e.g., echo" "" "--PRINTCOM" "--printcom"


    opts_ParseArguments "$@"

    # Display the parsed/default values
    opts_ShowValues
    set -x
    # Make slurm logs directory
    mkdir -p "$(dirname "$0")"/logs/slurm
 #   mapfile -t subjectArr < fold.txt
    mapfile -t subjectArr < subjectlist_01052021.txt
  
    echo ${subjectArr[10]}
    files=${#subjectArr[@]}
    echo $files
	queuing_command="sbatch \
        --job-name=MsBrain \
        --partition=$partition \
        --exclude=$exclude \
        --nodes=$nodes \
        --time=$time \
        --ntasks=$nTasks \
        --export=$export \
        --mail-type=$mailType \
        --mail-user=msbrain2021@gmail.com \
        --mem=$mem \
        --array=0-$files \
        --ntasks-per-node=186"
    #${queuing_command} test.sh --subjectPath=${subjectArr[$SLURM_ARRAY_TASK_ID]}
    echo $SLURM_ARRAY_TASK_ID
    ${queuing_command} CRC.sh \
          --subjectPath=${subjectArr[$SLURM_ARRAY_TASK_ID]} \
          --printcom=$RUN
}

input_parser "$@"
