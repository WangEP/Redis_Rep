#!/bin/bash


source ./3_ycsb_client.sh
source ./1_build_redis_cluster.sh
source ./4_monitor.sh
source ./0_parameters.sh
source ./7_public_func.sh
source ./8_new_public_func.sh

ENTRY_IP="10.0.0.52"
ENTRY_PORT=21000
FIELDS=10
FIELDLEN=100
THREADS=1
CLIENT_NUM=150
RECORDCOUNT=10000000 # 10M
OPERCOUNT_ORI=100000 # for 60 client each have 0.5M total 20M * 4 = 80M
OPERCOUNT_FOR_SKEW=50000

MACH="4"
INS="96 88 80 72 64 56 48 40 32 24 16 8"
# INS="96 80 64 48 32 16 8"
INS="32 56 72"
WORKLOADTYPES="workloada workloadb workloadc workloadd workloadf"
DISTRIBUTION="zipfian uniform zipfian_skew"
LOG_NAME="Baseline-scale"
LOG_DIR="/home/wangep/share/redis/log/${LOG_NAME}"

moveOneSlot() {
    slot=$1
    to=$2
    ${REDIS_CLI_BIN} --cluster slot ${ENTRY_IP}:${ENTRY_PORT} \
        --cluster-from $(getNodeNameFromSlot ${slot}) \
        --cluster-to $(getNodeNameFromIPPort ${to}) \
        --cluster-aim-slot ${slot}
}

runWorkload() {
    for I in ${INS};do
        echo ">> Create the Cluster (Scale: ${I})"
        buildCluster ${MACH} ${I} ${I} ${ENTRY_PORT}
        echo ">> Create Finished"
        sleep 5
        loadData ${RECORDCOUNT} ${ENTRY_IP} ${ENTRY_PORT}
        sleep 5
        for WLT in ${WORKLOADTYPES}; do
            for dis in ${DISTRIBUTION}; do
                is_skew=no
                tag=$dis
                OPERCOUNT=$OPERCOUNT_ORI
                if [ "${dis}" == "zipfian_skew" ]; then
                    is_skew=yes
                    dis=zipfian
                    OPERCOUNT=$OPERCOUNT_FOR_SKEW
                fi
                # getRedisStat
                # startMonitor
                multiClientRun ${WLT} ${OPERCOUNT} \
                               ${dis} ${RECORDCOUNT} ${CLIENT_NUM} \
                               ${ENTRY_IP} ${ENTRY_PORT} ${is_skew}
                # stopMonitor
                # getRedisStat
                moveData ${I}_${tag} ${WLT}
                cleanLog
            done
        done
        stopCluster ${MACH}
    done
}
budTest() {
    buildCluster ${MACH} ${1} ${1} ${ENTRY_PORT}
    loadData ${RECORDCOUNT} ${ENTRY_IP} ${ENTRY_PORT}

}

runTest() {
    multiClientRun "workload${1}" ${OPERCOUNT} \
            ${2} ${RECORDCOUNT} ${3} \
            ${ENTRY_IP} ${ENTRY_PORT} no
}

# LOG_NAME="TTest_4"
# LOG_DIR="/home/wangep/share/redis/log/${LOG_NAME}"
# runWorkload

# for i in {0..1}; do
#     LOG_NAME="0_Test_${i}"
#     LOG_DIR="/home/wangep/share/redis/log/${LOG_NAME}"
#     runWorkload
# done

# buildCluster ${MACH} ${INS} ${INS} ${ENTRY_PORT}
# sleep 5
# loadData ${RECORDCOUNT} ${ENTRY_IP} ${ENTRY_PORT}

# multiClientRun workloadc ${OPERCOUNT} \
#                 zipfian ${RECORDCOUNT} ${CLIENT_NUM} \
#                 ${ENTRY_IP} ${ENTRY_PORT}


