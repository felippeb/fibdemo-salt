#!/bin/bash

FIB_TRUE=1
FIB_FALSE=0
__SCRIPTVERSION="20160130"
__SCRIPTNAME="env-standup.sh"
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

decrypt_keys() {
    if test ! -f ${__DIRNAME}/salt/${PROJECT}/cloud.conf.d/gce-support-account.json; then
        if [ -z "${GPGPASSWORD}" ]; then
            echoinfo "decrypt salt gce support account key:"
            if gpg --yes -q --no-use-agent -o ${__DIRNAME}/salt/${PROJECT}/cloud.conf.d/gce-support-account.json ${__DIRNAME}/salt/${PROJECT}/cloud.conf.d/gce-support-account.json.gpg; then
                chmod 400 ${__DIRNAME}/salt/${PROJECT}/cloud.conf.d/gce-support-account.json
            else
                echoerror "key failed to decrypt, abort"
                exit 1
            fi
        else
            echoinfo "decrypt salt gce support account key with GPGPASSWORD:"
            if gpg --batch --no-tty --passphrase ${GPGPASSWORD} --decrypt --yes -q --no-use-agent -o ${__DIRNAME}/salt/${PROJECT}/cloud.conf.d/gce-support-account.json ${__DIRNAME}/salt/${PROJECT}/cloud.conf.d/gce-support-account.json.gpg; then
                chmod 400 ${__DIRNAME}/salt/${PROJECT}/cloud.conf.d/gce-support-account.json
            else
                echoerror "key failed to decrypt, abort"
                exit 1
            fi
        fi
    fi
    if test ! -f ${__DIRNAME}/salt/${PROJECT}/cloud.conf.d/id_rsa_saltbot; then
        if [ -z "${GPGPASSWORD}" ]; then
            echoinfo "decrypt saltbot user sshkey:"
            if gpg --yes -q --no-use-agent -o ${__DIRNAME}/salt/${PROJECT}/cloud.conf.d/id_rsa_saltbot ${__DIRNAME}/salt/${PROJECT}/cloud.conf.d/id_rsa_saltbot.gpg; then
              chmod 400 ${__DIRNAME}/salt/${PROJECT}/cloud.conf.d/id_rsa_saltbot
            else
              echoerror "key failed to decrypt, abort"
              exit 1
            fi
        else
            echoinfo "decrypt saltbot user sshkey with GPGPASSWORD:"
            if gpg --batch --no-tty --passphrase ${GPGPASSWORD} --decrypt --yes -q --no-use-agent -o ${__DIRNAME}/salt/${PROJECT}/cloud.conf.d/id_rsa_saltbot ${__DIRNAME}/salt/${PROJECT}/cloud.conf.d/id_rsa_saltbot.gpg; then
              chmod 400 ${__DIRNAME}/salt/${PROJECT}/cloud.conf.d/id_rsa_saltbot
            else
              echoerror "key failed to decrypt, abort"
              exit 1
            fi
        fi
    fi
    if test ! -f ${__DIRNAME}/salt/${PROJECT}/cloud.conf.d/salt01-id-rsa; then
        if [ -z "${GPGPASSWORD}" ]; then
            echoinfo "decrypt salt master sshkey:"
            if gpg --yes -q --no-use-agent -o ${__DIRNAME}/salt/${PROJECT}/cloud.conf.d/salt01-id-rsa ${__DIRNAME}/salt/${PROJECT}/cloud.conf.d/salt01-id-rsa.gpg; then
              chmod 400 ${__DIRNAME}/salt/${PROJECT}/cloud.conf.d/salt01-id-rsa
            else
              echoerror "key failed to decrypt, abort"
              exit 1
            fi
        else
            echoinfo "decrypt salt master sshkey with GPGPASSWORD:"
            if gpg --batch --no-tty --passphrase ${GPGPASSWORD} --decrypt --yes -q --no-use-agent -o ${__DIRNAME}/salt/${PROJECT}/cloud.conf.d/salt01-id-rsa ${__DIRNAME}/salt/${PROJECT}/cloud.conf.d/salt01-id-rsa.gpg; then
              chmod 400 ${__DIRNAME}/salt/${PROJECT}/cloud.conf.d/salt01-id-rsa
            else
              echoerror "key failed to decrypt, abort"
              exit 1
            fi
        fi
    fi
}

delete_defaultnetwork() {
    echoinfo "deleting default gce network for project: ${PROJECT}"
    ( ${__DIRNAME}/do-network.sh delete_defaultnetwork default ${PROJECT} ${REGION} ${__LOGREDIRECT} 2>&1 )
}

create_networks() {
    for NETWORKNAME in "${NETWORKLIST[@]}"; do
        echoinfo "creating network ${NETWORKNAME} in project: ${PROJECT}"
        ( bash ${__DIRNAME}/do-network.sh create_network ${NETWORKNAME} ${PROJECT} ${REGION} ${__LOGREDIRECT} 2>&1 )
    done
    wait
}

create_addresses() {
    for ADDRESSNET in "${NETWORKLIST[@]}"; do
        echoinfo "creating addresses for network: ${ADDRESSNET} in project: ${PROJECT}"
        ( bash ${__DIRNAME}/do-network.sh create_address ${ADDRESSNET} ${PROJECT} ${REGION} ${__LOGREDIRECT} 2>&1 ) &
    done
    wait
}

create_targetpools() {
    for POOLNET in "${NETWORKLIST[@]}"; do
        echoinfo "creating target-pools for network: ${POOLNET} in project: ${PROJECT}"
        ( bash ${__DIRNAME}/do-network.sh create_targetpool ${POOLNET} ${PROJECT} ${REGION} ${__LOGREDIRECT} 2>&1 ) &
    done
    wait
}

create_forwardingrules() {
    for FRULENET in "${NETWORKLIST[@]}"; do
        echoinfo "creating forwarding-rules for network: ${FRULENET} in project: ${PROJECT}"
        ( bash ${__DIRNAME}/do-network.sh create_forwardingrule ${FRULENET} ${PROJECT} ${REGION} ${__LOGREDIRECT} 2>&1 ) &
    done
    wait
}

create_fwrules() {
    for FWRULENET in "${NETWORKLIST[@]}"; do
        echoinfo "creating initial firewall rules for network: ${FWRULENET} in project: ${PROJECT}"
        ( bash ${__DIRNAME}/do-network.sh create_fwrule ${FWRULENET} ${PROJECT} ${REGION} ${__LOGREDIRECT} 2>&1 ) &
        wait
    done
}

saltmaster_standup() {
    echoinfo "standing up salt masters from ./salt/cloud.maps.d/${PROJECT}/saltmaster.conf"
    ( salt-cloud -P -m /etc/salt/cloud.maps.d/saltmaster.conf -y -l debug ${__LOGREDIRECT} 2>&1 )
}

remote_saltmaster_env_standup() {
    for REMOTESALTNET in "${NETWORKLIST[@]}"; do
        echoinfo "stand up envs from remote saltmasters for network: ${REMOTESALTNET} in project: ${PROJECT}"
        ( bash ${__DIRNAME}/do-remote-standup.sh ${REMOTESALTNET} ${PROJECT} ${REGION} ${__LOGREDIRECT} 2>&1 ) &
    done
    wait
}

usage() {
    cat << EOT

  Usage :  ${__SCRIPTNAME} [options] <install-type> <project> <region>

  Installation types:
    - decrypt_keys
    - full
    - firewall-rules
    - target-pools
    - forwarding-rules
    - saltmasterstandup
    - nodestandup

  Examples:
    - ${__SCRIPTNAME}
    - ${__SCRIPTNAME} full fibdemo us-central1
    - ${__SCRIPTNAME} -n int1 firewall-rules fibdemo us-central1
    - ${__SCRIPTNAME} -n infra1 -n int1 target-pools fibdemo us-east1
    - ${__SCRIPTNAME} -n all -l /tmp/fibdemo-standup.log firewall-rules fibdemo us-central1

  Options:
  -h  Display this message
  -v  Display script version
  -D  Show debug output.
  -n  GCE Network Name. If unset, will default to a set of predetermined networks based on project.
  -l  Log File Name
EOT
}

while getopts ":hvn:l:D" opt
do
    case "${opt}" in
        h )
            usage; exit 0
            ;;
        n )
            NETWORKLIST+=( "$OPTARG" )
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

# Define installation type
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

# Define gce region name
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

# Define network list
if [ "${#NETWORKLIST[@]}" -eq 0 ] || [ "${NETWORKLIST[0]}" == "all" ];then
    if [ "${PROJECT}" == "fibdemo" ]; then
        NETWORKLIST=(fibdemo)
    fi
fi

case "$INSTALLTYPE" in
    decrypt_keys)
        decrypt_keys
        ;;
    full)
        echoinfo "Proceeding with full installation in project: ${PROJECT}"
        decrypt_keys
        delete_defaultnetwork
        create_networks
        create_addresses
        create_targetpools
        create_forwardingrules
        create_fwrules
        saltmaster_standup
        remote_saltmaster_env_standup
        ;;
    firewall-rules)
        create_fwrules
        ;;
    target-pools)
        create_targetpools
        ;;
    forwarding-rules)
        create_addresses
        create_targetpools
        create_forwardingrules
        ;;
    saltmasterstandup)
        saltmaster_standup
        ;;
    nodestandup)
        remote_saltmaster_env_standup
        ;;
    *)
        usage
        echo
        echoerror "Invalid <install-type> selected: $OPTARG"
        exit 1
        ;;
esac
