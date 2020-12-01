#!/bin/bash

# call singularity exec <path_to_image> <command> 
#SBATCH --error=./logs/slurm/slurm-%A_%a.err
#SBATCH --output=./logs/slurm/slurm-%A_%a.out

module purge # Make sure the modules environment is sane
module load singularity
# or use #SBATCH --export=all module purge module load gcc/5.2.0 fsl/5.0.11-centos matlab/R2019b singularity
export FS_LICENSE=/pylon5/med200002p/liw82/license.txt
# The hostname from which sbatch was invoked (e.g. cluster)
SERVER=$SLURM_SUBMIT_HOST
# The name of the node running the job script (e.g. node10)
NODE=$SLURMD_NODENAME
# The directory from which sbatch was invoked (e.g. proj/DBN/src/data/MPP)
SERVERDIR=$SLURM_SUBMIT_DIR
LIW82=/pylon5/med200002p/liw82
IMAGE=/pylon5/med200002p/liw82/freesurfer_7.1.1.sif
# This function gets called by opts_ParseArguments when --help is specified
usage() {
    CURDIR="$(pwd)"
    # debug for folders 
    echo $FS_LICENSE
    echo $CURDIR
    echo $LIW82

    # header text
    echo "
$log_ToolName: Queueing script for running MPP on Slurm-based computing clusters

Usage: $log_ToolName
                    --subjectIDs=<ID>                Path to folder with subject images
                    --scanIDs=<ID>           File path or list with subject IDs
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

    opts_AddMandatory '--subjectIDs' 'subjectIDs' 'path to file with subject IDs' "a required value; path to a file with the IDs of the subject to be processed (e.g. /mnt/storinator/edd32/data/raw/ADNI/subjects.txt)" "--subject" "--subjectList" "--subjList"
    opts_AddMandatory '--scanIDs' 'subjects' 'path to file with subject IDs' "a required value; path to a file with the IDs of the subject to be processed (e.g. /mnt/storinator/edd32/data/raw/ADNI/subjects.txt)" "--subject" "--subjectList" "--subjList"
    opts_AddOptional '--printcom' 'RUN' 'do (not) perform a dray run' "an optional value; If RUN is not a null or empty string variable, then this script and other scripts that it calls will simply print out the primary commands it otherwise would run. This printing will be done using the command specified in the RUN variable, e.g., echo" "" "--PRINTCOM" "--printcom"

    opts_ParseArguments "$@"

    # Display the parsed/default values
    opts_ShowValues
}


setup() {
    SSH=/usr/bin/ssh
    
    # The directory holding the data for the subject correspoinding ot this job
    # pass the path to each scan for each subject to each job -lw
    BASE=$LIW82/KLU/$subjectIDs/$scanIDS
    IMAGEDIR=$BASE/converted/Hires/${SCANIDs}_Hires.nii
    
    # Node directory that where computation will take place
    SUBJECTDIR=$BASE/step_01_Freesurfer/
    rm -r SUBJECTDIR
    mkdir -p $SUBJECTDIR

    NCPU=`scontrol show hostnames $SLURM_JOB_NODELIST | wc -l`
    echo ------------------------------------------------------
    echo ' This job is allocated on '$NCPU' cpu(s)'
    echo ------------------------------------------------------
    echo SLURM: sbatch is running on $SERVER
    echo SLURM: server calling directory is $SERVERDIR
    echo SLURM: node is $NODE
    echo SLURM: node working directory is $SUBJECTDIR
    echo SLURM: job name is $SLURM_JOB_NAME
    echo SLURM: master job identifier of the job array is $SLURM_ARRAY_JOB_ID
    echo SLURM: job array index identifier is $SLURM_ARRAY_TASK_ID
    echo SLURM: job identifier-sum master job ID and job array index-is $SLURM_JOB_ID
    echo ' '
    echo ' '


    # Location of subject folder
    studyFolderBasename=`basename $BASE`;

    # Report major script control variables 
	echo "ID: $subjectIDs"
    echo "Scan: $scanIDs"
	echo "printcom: ${RUN}"

    # Create log folder
    LOGDIR="${SUBJECTDIR}/logs/"
    mkdir -p $LOGDIR

}

# Join function with a character delimiter
join_by() { local IFS="$1"; shift; echo "$*"; }

main() {
    ###############################################################################
	# Inputs:
	#
	# Scripts called by this script do NOT assume anything about the form of the
	# input names or paths. This batch script assumes the following raw data naming
	# convention, e.g.
	#
	# ${SubjectID}/${class}/${domainX}/${SubjectID}_${class}_${domainY}1.nii.gz
	# ${SubjectID}/${class}/${domainX}/${SubjectID}_${class}_${domainY}2.nii.gz
    # ...
	# ${SubjectID}/${class}/${domainX}/${SubjectID}_${class}_${domainY}n.nii.gz
    ###############################################################################

    cd $BASE

    # Submit to be run the MPP.sh script with all the specified parameter values
    singularity exec $IMAGE recon-all -sd $SUBJECTDIR -i $IMAGEDIR -s $scanIDs -all
        1> $LOGDIR/$SubjectID.out \
        2> $LOGDIR/$SubjectID.err
}

cleanup() {

    crc-job-stats.py # gives stats of job, wall time, etc.
}

early() {
	echo ' '
	echo ' ############ WARNING:  EARLY TERMINATION #############'
	echo ' '
}

input_parser "$@"
setup
main
cleanup

trap 'early; cleanup' SIGINT SIGKILL SIGTERM SIGSEGV

# happy end
exit 0
