#!/bin/bash

# Function that runs a single Docker container. When running, a .cid file
# is created that contains the container ID. This is used to fetch the bundle
# from the container after build completion, and then to free the container.
function run_container () {
    CONTAINER_NAME=$1
    ADCORE_VERSION=$2
    echo "Starting $CONTAINER_NAME build..."
    
    echo "Executing build targeting ADCore version $ADCORE_VERSION..."
    docker run -e ADCORE_VERSION=$ADCORE_VERSION --cidfile "$CONTAINER_NAME"_id.cid isa/"$CONTAINER_NAME" 

    echo "Copying package..."
    CONTAINER_ID=$(cat "$CONTAINER_NAME"_id.cid)
    rm "$CONTAINER_NAME"_id.cid
    docker cp $CONTAINER_ID:/installSynApps/DEPLOYMENTS $(pwd)/DEPLOYMENTS/.
    mv DEPLOYMENTS/DEPLOYMENTS/* DEPLOYMENTS/.
    rm DEPLOYMENTS/cleanup.sh
    rmdir DEPLOYMENTS/DEPLOYMENTS
    
    echo "Shutting down the $CONTAINER_NAME container..."
    docker container rm $CONTAINER_ID
    
    echo "Done."
    echo
}

# Print the help message
function print_help () {
    echo
    echo "USAGE:"
    echo "  ./run_container.sh help - will display this help message."
    echo "  ./run_container.sh all - will run all docker containers sequentially."
    echo "  ./run_container.sh [Distribution Branch] - will run all containers for distro branch. Ex. debian"
    echo "  ./run_container.sh [Distribution] - will run a single container."
    echo "  ./run_container.sh [Run Target] [ADCore Release] - will run whichever target (distribution, distro branch, all) with a specific ADCore release (R3-8 and higher)"
    echo
    echo "  Ex. ./run_container.sh ubuntu18.04"
    echo "  Ex. ./run_container.sh debian"
    echo "  Ex. ./run_container.sh all"
    echo
    echo "Supported containers: [ ubuntu18.04, ubuntu19.04, ubuntu20.04, debian8, debian9, debian10, centos7, centos8 ]"
    echo
    exit
}

# First check if number of arguments is correct
if [ "$#" == "1" ];
then
TO_RUN=$1
ADCORE_RELEASE="newest"
elif [ "$#" == "2" ];
then
TO_RUN=$1
ADCORE_RELEASE=$2
else
echo
echo "Exactly 1 or 2 arguments are required for run_container.sh."
print_help
fi


# Check if input parameter is valid
if [ "$TO_RUN" != "help" ];
then
case $TO_RUN in 
    ubuntu18.04|ubuntu19.04|ubuntu20.04|debian8|debian9|debian10|centos7|centos8|debian|ubuntu|centos|all) echo "Valid option $TO_RUN. Starting Docker-Builder...";;
    *) echo "ERROR - $TO_RUN is not a supported container"
       print_help;;
esac
else
print_help
fi

TIMESTAMP=$(date '+%Y-%m-%d-%H:%M:%S')
mkdir logs

# Otherwise if TO_RUN is valid container name or all
# run the run_container function. All terminal output placed in logfile
if [ "$TO_RUN" = "all" ];
then
run_container ubuntu18.04 $ADCORE_RELEASE |& tee logs/Build-Log-$TIMESTAMP.log
run_container ubuntu19.04 $ADCORE_RELEASE |& tee -a logs/Build-Log-$TIMESTAMP.log
run_container ubuntu20.04 $ADCORE_RELEASE |& tee -a logs/Build-Log-$TIMESTAMP.log
run_container debian8 $ADCORE_RELEASE |& tee -a logs/Build-Log-$TIMESTAMP.log
run_container debian9 $ADCORE_RELEASE |& tee -a logs/Build-Log-$TIMESTAMP.log
run_container debian10 $ADCORE_RELEASE |& tee -a logs/Build-Log-$TIMESTAMP.log
run_container centos7 $ADCORE_RELEASE |& tee -a logs/Build-Log-$TIMESTAMP.log
run_container centos8 $ADCORE_RELEASE |& tee -a logs/Build-Log-$TIMESTAMP.log
elif [ "$TO_RUN" = "debian" ];
then
run_container debian8 $ADCORE_RELEASE |& tee -a logs/Build-Log-$TIMESTAMP.log
run_container debian9 $ADCORE_RELEASE |& tee -a logs/Build-Log-$TIMESTAMP.log
run_container debian10 $ADCORE_RELEASE |& tee -a logs/Build-Log-$TIMESTAMP.log
elif [ "$TO_RUN" = "ubuntu" ];
then
run_container ubuntu18.04 $ADCORE_RELEASE |& tee logs/Build-Log-$TIMESTAMP.log
run_container ubuntu19.04 $ADCORE_RELEASE |& tee -a logs/Build-Log-$TIMESTAMP.log
run_container ubuntu20.04 $ADCORE_RELEASE |& tee -a logs/Build-Log-$TIMESTAMP.log
elif [ "$TO_RUN" = "centos" ];
then
run_container centos7 $ADCORE_RELEASE |& tee -a logs/Build-Log-$TIMESTAMP.log
run_container centos8 $ADCORE_RELEASE |& tee -a logs/Build-Log-$TIMESTAMP.log
else
run_container "$TO_RUN" $ADCORE_RELEASE |& tee logs/Build-Log-$TIMESTAMP.log
fi

echo "Build done. Bundles placed in ./DEPLOYMENTS"
exit
