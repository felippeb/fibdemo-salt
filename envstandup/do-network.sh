#!/bin/bash

FIB_TRUE=1
FIB_FALSE=0
__SCRIPTVERSION="20151029"
__SCRIPTNAME="do-remote-standup.sh"
__DIRNAME=$(dirname $0)
_ECHO_DEBUG=${FIB_ECHO_DEBUG:-$FIB_FALSE}
__LOGREDIRECT=""

__check_unparsed_options() {
    shellopts="$1"
    unparsed_options=$( echo "$shellopts" | grep -E '(^|[[:space:]])[-]+[[:alnum:]]' )
    if [ "$unparsed_options" != "" ]; then
        usage
        echo
        echoerror "options are only allowed before install arguments"
        echo
        exit 1
    fi
}

_COLORS=${FIB_COLORS:-$(tput colors 2>/dev/null || echo 0)}
__detect_color_support() {
    if [ $? -eq 0 ] && [ "$_COLORS" -gt 2 ]; then
        RC="\033[1;31m"
        GC="\033[1;32m"
        BC="\033[1;34m"
        YC="\033[1;33m"
        EC="\033[0m"
    else
        RC=""
        GC=""
        BC=""
        YC=""
        EC=""
    fi
}
__detect_color_support


echoerror() {
    printf "${RC} * ERROR${EC}: %s\n" "$@" 1>&2;
}

echoinfo() {
    printf "${GC} * INFO${EC}: %s\n" "$@";
}

echowarn() {
    printf "${YC} * WARN${EC}: %s\n" "$@";
}

echodebug() {
    if [ "$_ECHO_DEBUG" -eq $FIB_TRUE ]; then
        printf "${BC} * DEBUG${EC}: %s\n" "$@";
    fi
}

read_keys() {
    while [ "$1" ]; do
        IFS=$'\0' read -r -d '' "$1" || return 1
        shift
    done
}

__saltcloud_output_handler() {
    if ((_ECHO_DEBUG)); then
        echodebug "$1"
    else
        if [ "$(echo "$1" | egrep 'creationTimestamp')" ]; then
            echoinfo "$2 $3 successful"
        elif [ "$(echo "$1" | egrep 'alreadyExists')" ]; then
            echowarn "$2 $3 already exists"
        elif [ "$(echo "$1" | egrep 'ERROR' | egrep -v 'alreadyExists')" ]; then
            echoerror "$2 $3 had errors"
            echoerror "$1"
        fi
    fi
}

__gcloud_output_handler() {
    if ((_ECHO_DEBUG)); then
        echodebug "$1"
    else
        if [ "$(echo "$1" | egrep '^Created')" ]; then
            echoinfo "$2 $3 successful"
        elif [ "$(echo "$1" | egrep 'already\ exists')" ]; then
            echowarn "$2 $3 already exists"
        elif [ "$(echo "$1" | egrep 'ERROR' | egrep -v 'already\ exists')" ]; then
            echoerror "$2 $3 had errors"
            echoerror "$1"
        fi
    fi
}

create_fwrule() {
    fw_rule_name=$1
    while read_keys key value; do
    local $(echo $key)="$(echo $value)"
    done < <(cat ${__DIRNAME}/network/${PROJECT}/fwrules-${NETWORK}.yaml | shyaml key-values-0 ${fw_rule_name})
    OUTPUT="$(sudo salt-cloud -l error -f create_fwrule ${PROJECT}-tenant name=${fw_rule_name} network=${NETWORK%post} src_tags=${src_tags} src_range=${src_range} allow=${allow} dst_tags=${dst_tags} 2>&1)"
    __saltcloud_output_handler "${OUTPUT}" "rule" "${fw_rule_name}"
}

delete_fwrule() {
    fw_rule_name=$1
    OUTPUT="$(sudo salt-cloud -l error -f delete_fwrule ${PROJECT}-tenant name=${fw_rule_name} 2>&1)"
    __saltcloud_output_handler "${OUTPUT}" "rule" "${fw_rule_name}"
}

create_address() {
    address_name=$1
    while read_keys key value; do
    local $(echo $key)="$(echo $value)"
    done < <(cat ${__DIRNAME}/network/${PROJECT}/address-${NETWORK}.yaml | shyaml key-values-0 ${address_name})
    OUTPUT="$(sudo salt-cloud -l error -f create_address ${PROJECT}-tenant name=${address_name} region=${REGION} 2>&1)"
    echoinfo "output of create attempt for address: ${address_name}"
    __saltcloud_output_handler "${OUTPUT}" "address" "${address_name}"
    if [[ ${address_name} =~ haproxy ]] || [[ ${address_name} =~ nginx ]] || [[ ${address_name} =~ esagg ]]; then
        echoinfo "updating forwardingrules file with new ip addresses"
        external_address=$(salt-cloud -f show_address ${PROJECT}-tenant name=${address_name} region=${REGION} --output=json -l error| jq -c -r '.["'${PROJECT}'-tenant"].gce.address')
        echoinfo "External Address is: ${external_address}"
        sed -i "s/${address_name}/${external_address}/g" ${__DIRNAME}/network/${PROJECT}/forwardingrules-${NETWORK}.yaml
    fi
}

delete_address() {
    address_name=$1
    while read_keys key value; do
    local $(echo $key)="$(echo $value)"
    done < <(cat ${__DIRNAME}/network/${PROJECT}/address-${NETWORK}.yaml | shyaml key-values-0 ${address_name})
    OUTPUT="$(sudo salt-cloud -l error -f delete_address ${PROJECT}-tenant name=${address_name} region=${REGION} 2>&1)"
    echoinfo "output of deletion attempt for address: ${address_name}"
    __saltcloud_output_handler "${OUTPUT}" "address" "${address_name}"
}

create_network() {
    network_name=$1
    while read_keys key value; do
    local $(echo $key)="$(echo $value)"
    done < <(cat ${__DIRNAME}/network/${PROJECT}/networks.yaml | shyaml key-values-0 ${network_name})
    OUTPUT="$(sudo salt-cloud -l error -f create_network ${PROJECT}-tenant name=${network_name} cidr=${cidr} 2>&1)"
    echoinfo "output of create attempt for network: ${network_name}"
    __saltcloud_output_handler "${OUTPUT}" "network" "${network_name}"
}

delete_network() {
    network_name=$1
    OUTPUT="$(sudo salt-cloud -l error -f delete_network ${PROJECT}-tenant name=${network_name} 2>&1)"
    echoinfo "output of deletion attempt for network: ${network_name}"
    __saltcloud_output_handler "${OUTPUT}" "network" "${network_name}"
}

create_targetpool() {
    pool_name=$1
    while read_keys key value; do
    local $(echo $key)="$(echo $value)"
    done < <(cat ${__DIRNAME}/network/${PROJECT}/targetpools-${NETWORK}.yaml | shyaml key-values-0 ${pool_name})
    echoinfo "creating targetpool: ${pool_name}"
    if [[ ${health_check} == none ]]; then
        OUTPUT="$(gcloud compute --project "${PROJECT}" target-pools create "${pool_name}" --region "${REGION}" --session-affinity "${session_affinity}" -q 2>&1)"
        echoinfo "output of creation attempt for targetpool: ${pool_name}"
        __gcloud_output_handler "${OUTPUT}" "targetpool" "${pool_name}"
    else
        OUTPUT="$(gcloud compute --project "${PROJECT}" target-pools create "${pool_name}" --region "${REGION}" --session-affinity "${session_affinity}" --health-check "${health_check}" -q 2>&1)"
        __gcloud_output_handler "${OUTPUT}" "targetpool" "${pool_name}"
        echo "${OUTPUT}"
    fi
    echoinfo "adding instances to  targetpool: ${pool_name}"
    OUTPUT="$(gcloud compute --project "${PROJECT}" target-pools add-instances ${pool_name} --instances "${instances}" --zone "${zone}" -q 2>&1)"
    echoinfo "output for adding instances to targetpool: ${pool_name}"
    __gcloud_output_handler "${OUTPUT}" "add instances" "${pool_name}"
}

delete_targetpool() {
    pool_name=$1
    OUTPUT="$(gcloud compute --project "${PROJECT}" forwarding-rules create "${frule_name}" --region "${REGION}" --address "${address}" --ip-protocol "${ip_protocol}" --port-range "${port_range}" --target-pool "${target_pool}" -q 2>&1)"
    echoinfo "output of deletion attempt for targetpool: ${pool_name}"
    __gcloud_output_handler "${OUTPUT}" "targetpools" "${pool_name}"
}

create_forwardingrule() {
    frule_name=$1
    while read_keys key value; do
    local $(echo $key)="$(echo $value)"
    done < <(cat ${__DIRNAME}/network/${PROJECT}/forwardingrules-${NETWORK}.yaml | shyaml key-values-0 ${frule_name})
    OUTPUT="$(gcloud compute --project "${PROJECT}" forwarding-rules create "${frule_name}" --region "${REGION}" --address "${address}" --ip-protocol "${ip_protocol}" --port-range "${port_range}" --target-pool "${target_pool}" -q 2>&1)"
    echoinfo "output of creation attempt for forwardingrule: ${frule_name}"
    __gcloud_output_handler "${OUTPUT}" "forwardingrule" "${frule_name}"
}

delete_forwardingrule() {
    frule_name=$1
    OUTPUT="$(gcloud compute --project "${PROJECT}" forwarding-rules delete "${frule_name}" --region "${REGION}" -q 2>&1)"
    echoinfo "output of deletion attempt for forwardingrule: ${frule_name}"
    __gcloud_output_handler "${OUTPUT}" "forwardingrule" "${frule_name}"
}

usage() {
    cat << EOT

  Usage :  ${__SCRIPTNAME} [options] <install-type> <network> <project> <region>

  Install Types:
    - delete_defaultnetwork
    - create_fwrule
    - delete_fwrule
    - create_address
    - delete_address
    - create_network
    - delete_network
    - create_route
    - delete_route
    - create_targetpool
    - delete_targetpool
    - create_forwardingrule
    - delete_forwardingrule

  Regions:
    - us-central1
    - us-east1
    - asia-east1
    - europe-west1

  Examples:
    - ${__SCRIPTNAME}
    - ${__SCRIPTNAME} create_fwrule infra1 fibdemo us-central1
    - ${__SCRIPTNAME} -D create_route int1 fibdemo us-east1

  Options:
  -h  Display this message
  -v  Display script version
  -D  Show debug output.
  -l  Log File Name
EOT
}

while getopts ":hvl:D" opt
do
    case "${opt}" in
        h )
            usage; exit 0
            ;;
        l )
            __LOGFILE=$OPTARG
            __LOGREDIRECT=">> ${__LOGFILE}"
            ;;
        D )
            _ECHO_DEBUG=$FIB_TRUE
            _SALT_DEBUG="-l debug"
            ;;
        v )
            echo "$0 -- Version $__SCRIPTVERSION"; exit 0
            ;;
        \?)
            usage
            echo
            echoerror "Option does not exist : $OPTARG"
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))

# Define install-type
if [ "$#" -eq 0 ];then
    usage
    echo
    echoerror "<install-type> is a required argument"
    exit 1
else
    __check_unparsed_options "$*"
    INSTALLTYPE=$1
    shift
fi

# Define network
if [ "$#" -eq 0 ];then
    usage
    echo
    echoerror "<network> is a required argument"
    exit 1
else
    __check_unparsed_options "$*"
    NETWORK=$1
    shift
fi

# Define gce project name
if [ "$#" -eq 0 ];then
    usage
    echo
    echoerror "<project> is a required argument"
    exit 1
else
    __check_unparsed_options "$*"
    PROJECT=$1
    shift
fi

# Define gce REGION name
if [ "$#" -eq 0 ];then
    usage
    echo
    echoerror "<region> is a required argument"
    exit 1
else
    __check_unparsed_options "$*"
    if [ "$(echo "$1" | egrep '^(us-east1|us-central1|asia-east1|europe-west1)$')" = "" ]; then
        echo "Unknown region: $1 (valid: us-east1, us-central1, asia-east1, europe-west1)"
        exit 1
    else
        REGION=$1
        shift
    fi
fi

# Check for any unparsed arguments. Should be an error.
if [ "$#" -gt 0 ]; then
    __check_unparsed_options "$*"
    usage
    echo
    echoerror "Too many arguments."
    exit 1
fi

case "$INSTALLTYPE" in
    delete_defaultnetwork)
        for KEYNAME in $(cat ${__DIRNAME}/network/${PROJECT}/fwrules-default.yaml | shyaml keys); do
            echoinfo "deleting firewall rule: ${KEYNAME}"
            ( delete_fwrule ${KEYNAME} ${__LOGREDIRECT} 2>&1 ) &
        done
        wait
        delete_network default ${__LOGREDIRECT} 2>&1
        ;;
    create_fwrule)
        for KEYNAME in $(cat ${__DIRNAME}/network/${PROJECT}/fwrules-${NETWORK}.yaml | shyaml keys); do
            echoinfo "creating firewall rule: ${KEYNAME}"
            ( create_fwrule ${KEYNAME} ${__LOGREDIRECT} 2>&1 ) &
        done
        wait
        ;;
    delete_fwrule)
        for KEYNAME in $(cat ${__DIRNAME}/network/${PROJECT}/fwrules-${NETWORK}.yaml | shyaml keys); do
            echoinfo "deleting firewall rule: ${KEYNAME}"
            ( delete_fwrule ${KEYNAME} ${__LOGREDIRECT} 2>&1 ) &
        done
        wait
        ;;
    create_address)
        for KEYNAME in $(cat ${__DIRNAME}/network/${PROJECT}/address-${NETWORK}.yaml | shyaml keys); do
            echoinfo "creating address: ${KEYNAME}"
            ( create_address ${KEYNAME} ${__LOGREDIRECT} 2>&1 ) &
        done
        wait
        ;;
    delete_address)
        for KEYNAME in $(cat ${__DIRNAME}/network/${PROJECT}/address-${NETWORK}.yaml | shyaml keys); do
            echoinfo "deleting address: ${KEYNAME}"
            ( delete_address ${KEYNAME} ${__LOGREDIRECT} 2>&1 ) &
        done
        wait
        ;;
    create_network)
        create_network ${NETWORK} ${__LOGREDIRECT} 2>&1
        ;;
    delete_network)
        delete_network ${NETWORK} ${__LOGREDIRECT} 2>&1
        ;;
    create_targetpool)
        for KEYNAME in $(cat ${__DIRNAME}/network/${PROJECT}/targetpools-${NETWORK}.yaml | shyaml keys); do
            echoinfo "creating targetpool: ${KEYNAME}"
            ( create_targetpool ${KEYNAME} ${__LOGREDIRECT} 2>&1 ) &
        done
        wait
        ;;
    delete_targetpool)
        for KEYNAME in $(cat ${__DIRNAME}/network/${PROJECT}/targetpools-${NETWORK}.yaml | shyaml keys); do
            echoinfo "deleting targetpool: ${KEYNAME}"
            ( delete_targetpool ${KEYNAME} ${__LOGREDIRECT} 2>&1 ) &
        done
        wait
        ;;
    create_forwardingrule)
        for KEYNAME in $(cat ${__DIRNAME}/network/${PROJECT}/forwardingrules-${NETWORK}.yaml | shyaml keys); do
            echoinfo "creating forwardingrule: ${KEYNAME}"
            ( create_forwardingrule ${KEYNAME} ${__LOGREDIRECT} 2>&1 ) &
        done
        wait
        ;;
    delete_forwardingrule)
        for KEYNAME in $(cat ${__DIRNAME}/network/${PROJECT}/forwardingrules-${NETWORK}.yaml | shyaml keys); do
            echoinfo "deleting forwardingrule: ${KEYNAME}"
            ( delete_forwardingrule ${KEYNAME} ${__LOGREDIRECT} 2>&1 ) &
        done
        wait
        ;;
    *)
        usage
        echo
        echoerror "Invalid <install-type> selected: $OPTARG"
        exit 1
        ;;
esac
