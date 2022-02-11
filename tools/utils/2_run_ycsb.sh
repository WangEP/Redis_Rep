#!/bin/bash

source /home/wangep/share/redis/utils/0_parameters.sh

helpMsg() {
    echo "
$0 <opts> <args>
    <opts>
    -t  YCSB Type, have two types
        load -> load data(default)
        run  -> run the workload
    -w  workload type, have three types
        write -> 100% write(update) (default)
        read  -> 100% read
        wrbalance -> 50% write(update) + 50% read
    -r  Record count, a number (default 1000000)
    -o  Operation count, a number (default 100000000)
    -d  Request Distribution, two types
        zipfian (default)
        uniform
    -p  Other Options, use -p <subopt> <args>
        <subopts>
        ip (default node1(192.168.1.107))
        port (default 21000)
        thread (default 1)
        fieldcount (default 10)
        fieldlen (default 100)
            default value size = fieldcount * fieldlen = 1000B
    -c  Client Numbers, used with thread
        e.g.: if use 10Client and 10Thr, means have 10 Client, Each have 10 Threads
    -h  Help messages(This Message)
    "
}

runYCSB_JAVA() {
    clientid=$1
    ${YCSB_BIN} ${TYPE} redis -s -P ${WORKLOAD_DIR}/$WORKLOADTYPE \
        -p redis.host=${ENTRY_IP} \
        -p redis.port=${ENTRY_PORT} \
        -p redis.cluster=true \
        -p recordcount=${RECORDCOUNT} -p operationcount=${OPERCOUNT} \
        -p fieldlength=${FIELDLEN} -p fieldcount=$FIELDS \
        -p threadcount=${THREADS} > ${OUTPUTDIR}/${TYPE}_${WORKLOADTYPE}_${clientid}.txt 2>&1

}

runYCSB() {
    clientid=$1
    cpu_num=$2
    is_skewed=$3
    if [ ${is_skewed} == "yes" ]; then
        YCSB_DIR="/home/wangep/share/redis/YCSB-cpp-skew"
    else
        YCSB_DIR="/home/wangep/share/redis/YCSB-cpp"
    fi
    YCSB_BIN="${YCSB_DIR}/ycsb"
    WORKLOAD_DIR="${YCSB_DIR}/workloads"
    echo ${YCSB_BIN}
    TASKSET_CMD="taskset -c ${cpu_num}"
    # echo ${TASKSET_CMD}
    if [ ${TYPE} == "load" ]; then TASKSET_CMD="";fi
    ${TASKSET_CMD} ${YCSB_BIN} -${TYPE} -db redis -s -P ${WORKLOAD_DIR}/$WORKLOADTYPE \
        -p redis.hostport=${ENTRY_IP}:${ENTRY_PORT} \
        -p redis.cluster=true \
        -p recordcount=${RECORDCOUNT} -p operationcount=${OPERCOUNT} \
        -p fieldlength=${FIELDLEN} -p fieldcount=$FIELDS \
        -p status.interval=1 -p requestdistribution=${DISTRIBUTION}\
        -p threadcount=${THREADS} > \
        ${OUTPUTDIR}/${TYPE}_${WORKLOADTYPE}_${clientid}.txt 2>&1
}

cmdProcessing() {
    cmd_line=$1
    cmd_array=(`echo ${cmd_line} | tr '=' ' '`)
    case ${cmd_array[0]} in
        ip) ENTRY_IP=${cmd_array[1]};;
        port) ENTRY_PORT=${cmd_array[1]};;
        thread) THREADS=${cmd_array[1]};;
        fieldcount) FIELDS=${cmd_array[1]};;
        fieldlen) FIELDLEN=${cmd_array[1]};;
        *) helpMsg; exit ;;
    esac
}


while getopts 't:r:o:d:w:p:P:hT:f:F:c:s:' Cmd; do
    case $Cmd in
        t) TYPE=${OPTARG} ;;
        T) THREADS=${OPTARG} ;;
        f) FIELDLEN=${OPTARG} ;;
        F) FIELDS=${OPTARG} ;;
        r) RECORDCOUNT=${OPTARG} ;;
        o) OPERCOUNT=${OPTARG} ;;
        d) DISTRIBUTION=${OPTARG} ;;
        w) WORKLOADTYPE=${OPTARG} ;;
        c) CLIENT_NUM=${OPTARG} ;;
        s) SKEWED=${OPTARG} ;;
        p) cmdProcessing ${OPTARG} ;;
        h|?|*) helpMsg; exit;;
    esac
done

if [ ${TYPE} == "load" ]; then
    CLIENT_NUM=1
    THREADS=40
fi

cpunum=$(cat /proc/cpuinfo |grep "processor"|wc -l)
# echo debug ${cpunum}
corect=0;
for i in $(seq 1 ${CLIENT_NUM}); do
    if [ ${corect} -eq ${cpunum} ]; then
        corect=0;
    fi;
    runYCSB $i ${corect} ${SKEWED} &
    let corect++;
done





