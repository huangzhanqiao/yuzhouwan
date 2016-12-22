#!/bin/sh
# nohup bash /home/yuzhouwan/yuzhouwan-monitor/gc_monitor2.sh "/data07/yuzhouwan/dumps" "27259" "75" "10" >> /data07/yuzhouwan/pid_27259_gc_monitor2.log &
# need create $DUMP_OUTPUT_PATH firstly

DUMP_OUTPUT_PATH="$1"
PROCESS_ID="$2"
OLD_PERCENT_THRESHOLD="$3"
OVER_THRESHOLD_COUNT="$4"

if [ -z "$DUMP_OUTPUT_PATH" -o -z "$PROCESS_ID" -o -z "$OLD_PERCENT_THRESHOLD"  -o -z "$OVER_THRESHOLD_COUNT" ]; then
    echo "Usage: gc_monitor2.sh <gc log file> <dump output path> <gc time threshold second> <process id>"
    echo 'Example: gc_monitor2.sh "/data01/yuzhouwan/dumps" "29140" "75" "10"'
    exit
fi

GLOBAL_COUNT=0
GLOBAL_LAST_GC_DATE=`date '++%Y%m%d%H%M%S'`
LONG_GC_MESSAGE_TITLE="Long GC Warning"

longGc() {
    if [ "$DUMP_OUTPUT_PATH" = "" -o "$OLD_PERCENT_THRESHOLD" = ""  -o "$PROCESS_ID" = "" ]; then
        return 0
    fi
    count=0
    while [ $(echo "${count}<${OVER_THRESHOLD_COUNT}" | bc) -eq 1 ]; do
        # jstat -gcutil 16125
        # S0     S1     E      O      P     YGC     YGCT    FGC    FGCT     GCT
        # 0.00  96.03  92.77  49.71  34.07  11855  803.209   255   15.829  819.039
        oldPercent=`jstat -gcutil ${PROCESS_ID} | awk '{print $4}' | sed '1d'`

        if [ -z ${oldPercent} ]; then
            return 1
        fi
        echo "Current Old Generation used percent: ${oldPercent} %"
        if [ $(echo "${OLD_PERCENT_THRESHOLD}<${oldPercent}" | bc) -eq 1 ]; then
            count=$(echo "${count}+1" | bc)
            echo "Overload threshold: (${count}/${OVER_THRESHOLD_COUNT})"
        else
            return 2
        fi
        sleep 1
    done
    if [ $(echo "${count}==${OVER_THRESHOLD_COUNT}" | bc) -eq 1 ]; then
        return 0
    else
        return 2
    fi
}

dealAlert() {
    longGc
    checkResult=$?
    if [ ${checkResult} -eq 0 ]; then
        # 2016_12_13-17:01:11
        NOW=`date '+%Y_%m_%d-%H:%M:%S'`
        if [ -z ${DUMP_OUTPUT_PATH} ]; then
            BASIC_PATH=`printf "%s%s" "./" "pid_${PROCESS_ID}_date_${NOW}"`
        else
            BASIC_PATH=`printf "%s%s%s" "${DUMP_OUTPUT_PATH}" "/" "pid_${PROCESS_ID}_date_${NOW}"`
        fi
        DUMP_PATH=`printf "%s%s" "${BASIC_PATH}" ".hprof"`
        JSTACK_PATH=`printf "%s%s" "${BASIC_PATH}" ".jstack"`
        echo "Process ID [${PROCESS_ID}] could happening long GC!!!"
        echo "Now dump: ${DUMP_PATH}"
        # jmap -dump:live,format=b,file=/data/yuzhouwan/dumps/pid_29140_date_2016_12_14-09:26:37.hprof 29140
        DUMP_EXEC=`printf "%s%s%s" "-dump:live,format=b,file=" "${DUMP_PATH}" " ${PROCESS_ID}"`
        jmap ${DUMP_EXEC}
        echo "Jstack info: ${JSTACK_PATH}"
        jstack -l "${PROCESS_ID}" >> "${JSTACK_PATH}"
        echo "Exec: jmap ${DUMP_EXEC}"

        if [ ${GLOBAL_COUNT} -ne 0 -a $(( `date '+%Y%m%d%H%M%S'` - $GLOBAL_LAST_GC_DATE )) -gt $(echo "${OVER_THRESHOLD_COUNT}*2" | bc) ]; then
            GLOBAL_LAST_GC_DATE=`date '++%Y%m%d%H%M%S'`
            GLOBAL_COUNT=0
        fi

        if [ ${GLOBAL_COUNT} -eq 0 ]; then
            sendMessage
        fi

        GLOBAL_COUNT=$(echo "${GLOBAL_COUNT}+1" | bc)
        echo "GLOBAL_COUNT: $GLOBAL_COUNT"

        if [ $(echo "${GLOBAL_COUNT}==5" | bc) -eq 1 ]; then
            GLOBAL_COUNT=0
            skillCooling
        fi
    elif [ ${checkResult} -eq 2 ]; then
        echo "Process is healthy."
    else
        echo "Cannot catch Old Generation used size!"
    fi
}

sendMessage() {
    echo "Sending Alert Message..."
    message="[Machine HostName]: `hostname` \r\n [Process ID]: ${PROCESS_ID} \r\n [Old Generation Percent Threshold]: ${OLD_PERCENT_THRESHOLD}% \r\n [Old Generation Percent Now]: ${oldPercent}% \r\n [The length of time beyond the threshold]: ${OVER_THRESHOLD_COUNT}s \r\n [Dump file path]: ${DUMP_PATH}"
    echo -e "Title: ${LONG_GC_MESSAGE_TITLE} \n Message: ${message}"
    echo "${message}" | mail -s "${LONG_GC_MESSAGE_TITLE}" 1571805553@qq.com
}

skillCooling() {
    echo "Skill cooling..."
    sleepCountDown=61
    while [ $(echo "${sleepCountDown}>1" | bc) -eq 1 ]; do
        sleepCountDown=$(echo "${sleepCountDown}-1" | bc)
        echo "Skill cooling... ${sleepCountDown} second"
        sleep 1
    done
}

echo "Begin monitor..."
echo "Process ID is '$PROCESS_ID'"
while true; do
    dealAlert
    sleep 1
done