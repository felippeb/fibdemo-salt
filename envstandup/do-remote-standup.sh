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

find_saltmaster() {
    echoinfo "finding saltmaster in ${NETWORK}"
    SALTMASTER_IP=$(salt-cloud -S --out=json -l quiet | jq -c -r '.["'${PROJECT}'-tenant"].gce.salt01.public_ips[0]')
    SALTBOTSSH="ssh saltbot@${SALTMASTER_IP} -i ${__DIRNAME}/salt/${PROJECT}/cloud.conf.d/id_rsa_saltbot -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oControlPath=none -oPasswordAuthentication=no -oChallengeResponseAuthentication=no -oPubkeyAuthentication=yes -oKbdInteractiveAuthentication=no"
}

saltcloud_setup() {
    echoinfo "rsyncing up salt cloud files"
    ( ${SALTBOTSSH} "if [ ! -d /tmp/saltcloud ]; then mkdir /tmp/saltcloud/; fi" ${__LOGREDIRECT} 2>&1 )
    ( rsync -arv -e "ssh -i ${__DIRNAME}/salt/${PROJECT}/cloud.conf.d/id_rsa_saltbot -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oControlPath=none -oPasswordAuthentication=no -oChallengeResponseAuthentication=no -oPubkeyAuthentication=yes -oKbdInteractiveAuthentication=no" ${__DIRNAME}/salt/${PROJECT}/cloud* saltbot@${SALTMASTER_IP}:/tmp/saltcloud/ ${__LOGREDIRECT} 2>&1 )
    ( ${SALTBOTSSH} sudo rsync -arv /tmp/saltcloud/* /etc/salt/ ${__LOGREDIRECT} 2>&1 )
    ( ${SALTBOTSSH} sudo chown -R root:root /etc/salt/cloud* ${__LOGREDIRECT} 2>&1 )
    echoinfo "updating apache-libcloud version (required for salt-cloud)"
    ( ${SALTBOTSSH} sudo easy_install -U apache-libcloud ${__LOGREDIRECT} 2>&1 )
}

remote_nodestandup() {
    echoinfo "standing up map file ${NETWORK}.conf from node salt01-${NETWORK}"
    if [ -z ${MAP} ]; then
        ( ${SALTBOTSSH} sudo salt-cloud -P -m /etc/salt/cloud.maps.d/${NETWORK}.conf -y ${_SALT_DEBUG} ${__LOGREDIRECT} 2>&1 )
    else
        ( ${SALTBOTSSH} sudo salt-cloud -P -m /etc/salt/cloud.maps.d/${NETWORK}-${MAP}.conf -y ${_SALT_DEBUG} ${__LOGREDIRECT} 2>&1 )
    fi
}

post_install_cleanup() {
    echoinfo "cleaning up old saltbot ids"
    ( ${SALTBOTSSH} sudo salt-key -d '*-saltbot' -y ${__LOGREDIRECT} 2>&1 )
}

usage() {
    cat << EOT

  Usage :  ${__SCRIPTNAME} [options] <network> <project> <region>

  Regions:
    - us-central1
    - us-east1
    - asia-east1
    - europe-west1

  Examples:
    - ${__SCRIPTNAME}
    - ${__SCRIPTNAME} infra1 fibdemo us-central1
    - ${__SCRIPTNAME} -m vds int1 fibdemo us-east1
    - ${__SCRIPTNAME} -D -l /var/log/fibdemo.log log1 fibdemo us-central1

  Options:
  -h  Display this message
  -v  Display script version
  -D  Show debug output.
  -m  Map name.
  -l  Log File Name
EOT
}

while getopts ":hvm:l:D" opt
do
    case "${opt}" in
        h )
            usage; exit 0
            ;;
        m ) 
            MAP=$OPTARG
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

__LOGFILE="/var/log/${PROJECT}.log"

echoinfo "configuring salt01-${NETWORK} in project: ${PROJECT} for salt-cloud and installing further nodes"
find_saltmaster
saltcloud_setup
remote_nodestandup
post_install_cleanup
