# World file should be manually moved to $backupFolder, at the first start.

#Multi-Mc instance save folder
saveFolder=
saveFolderSize=

#Multi-Mc instance name, I.E the name of the instance folder.
instanceName=
#World Name
world=

backupFolder=
backupLimit=
backupIntervalS=


function backupLimitRoutine () {
    if [ $(ls -1 $backupFolder | wc -l) -gt $backupLimit ]; then
        oldestBackup=$(ls -tr $backupFolder | head -1)
        printf "LOG: Deleting oldest backup  $oldestBackup\n"
        rm -r $backupFolder/$oldestBackup
    fi
}

function doBackup () {
    currentDate=$(date +%m-%d_%H-%M)
    cp -r $saveFolder/$world $backupFolder/$currentDate
    printf "LOG: Backup done at $currentDate\n"
    backupLimitRoutine
}

function setRamdisk () {
    mkdir -p $saveFolder
    if [ $(free -m | grep Mem | awk '{print $7}') -gt $saveFolderSize ]; then
        sudo mount -t tmpfs -o size=${saveFolderSize}m  tmpfs $saveFolder
        lastBackup=$(ls -t $backupFolder | head -1)
        rm -r $saveFolder/$world
        cp -r $backupFolder/$lastBackup $saveFolder/$world
        printf "LOG: Last backup of $lastBackup moved to ramdisk\n" 
        printf "LOG: Ramdisk created at $saveFolder with size of $saveFolderSize MB\n"
    else
        printf "CRASH: Not enough RAM to mount ramdisk !\n"
        exit -1
    fi
}

function unsetRamdisk () {
    sudo umount $saveFolder
    printf "LOG: Ramdisk removed\n"
}

function routine () {
    printf "LOG: Main routine started \n"
    while [ -d "/proc/$1" ]
    do
        sleep $backupIntervalS
        doBackup
    done
    stop
}

function start () {
    setRamdisk 
    multimc -l $instanceName > /dev/null 2>&1 &
    routine $!
}

function stop () {
    printf "LOG: Stoping..."
    doBackup
    unsetRamdisk 
    exit 
}

trap 'trap " " SIGINT SIGTERM SIGHUP; kill 0; wait; stop' SIGINT SIGTERM SIGHUP

start
