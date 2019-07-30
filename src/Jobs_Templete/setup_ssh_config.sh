#! /bin/bash
set -ex

JOB_DIR='/job'

# wait untill all workers are ready
all_workers_ready=false
while [ "$all_workers_ready" != true ]
do
    # update it to false if any woker is not ready
    all_workers_ready=true

    for i in $(seq 0 $(( ${DLWS_WORKER_NUM} - 1)) )
    do
        worker="worker${i}"
        file="${JOB_DIR}/${worker}/running/ROLE_READY"
        #echo $file

        if [ ! -f $file ]; then
        echo "${worker} not ready!"
        all_workers_ready=false
        sleep 10
        fi
    done
done

# setup ~/ssh_config
SSH_CONFIG_FILE="/home/${DLWS_USER_NAME}/.ssh/config"
>${SSH_CONFIG_FILE}
chown ${DLWS_USER_NAME} ${SSH_CONFIG_FILE}
for role_dir in ${JOB_DIR}/*/ # list directories in the form "/JOB_DIR/role/"
do
    role_dir=${role_dir%*/} # remove the trailing "/"
    if [[ $role_dir == *logs ]];
    then
        continue
    fi
    host=$(basename ${role_dir})
    port=$(cat "${role_dir}/running/SSH_PORT")
    ip=$(cat "${role_dir}/running/POD_IP")
    cat >>${SSH_CONFIG_FILE} <<EOF

Host ${host}
  HostName ${ip}
  Port ${port}
  User ${DLWS_USER_NAME}
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null

EOF

done


# generate /job/hostfile
SLOT_FILE="/job/hostfile"
>${SLOT_FILE}
chown ${DLWS_USER_NAME} ${SLOT_FILE}
for role_dir in ${JOB_DIR}/*/ # list directories in the form "/JOB_DIR/role/"
do
    role_dir=${role_dir%*/} # remove the trailing "/"
    if [[ $role_dir == *logs ]] || [[ $role_dir == *ps* ]];
    then
        continue
    fi
    host=$(basename ${role_dir})
    slots=${DLWS_NUM_GPU_PER_WORKER}
    cat >>${SLOT_FILE} <<EOF
${host} ${slots}
EOF

done