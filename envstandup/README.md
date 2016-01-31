#envstandup

##Description

These scripts will stand up an infrastructure in gce, based on yaml files declaring network/address/forwarding rules, etc. These scripts are written in BASH. They will likely only work on BASH4.0. These scripts wrap around salt-cloud, and google cloud sdk, to provide a full gce standup experience. Neither tool fully configured the entire infrastructure, from vms, vm config, to network, fwrules, etc etc. salt-cloud, for all its efforts, is hindered by progress of libcloud, which intern hinders progress of their GCE module. Salt-cloud also has no concept of a map for network, as it does for vm layout. These scripts are intended to help bridge that gap a bit.

##Usage

These scripts provide documentation themselves. You can see their documentation via executation of the script with no arguments, or with the -h switch. i.e:

    $ ./env-standup.sh -h

or

    $ ./env-standup.sh

The output of help from each script is recorded under the docs directory.

##Requirements

These scripts make a lot of assumptions about your environment. These have been tested on a ubuntu 15.10 machine. They require:

- shyaml
  - Tested: 0.4.0
  - Install_guide: pip install shyaml
- jq
  - Tested: 1.4-2.1
  - Install_guide: apt-get install jq
- salt-cloud
  - Tested: 2015.8.3+ds-1
  - Install_guide: [saltstack ubunutu installation guide](https://docs.saltstack.com/en/latest/topics/installation/ubuntu.html)
- google cloud sdk
  - Tested: 94.0.0
  - Install_guide: [google cloud sdk installation guide](https://cloud.google.com/sdk/#debubu)

##Setup

First, install requirements as mentioned above.

#####Decrypt the keys:

```
$ ./env-standup.sh decrypt_keys fibdemo-1205 us-central1
```

The keys will decrypt to salt/fibdemo-1205/cloud.conf.d/

#####Copy all salt-cloud files to /etc/

Assuming files are under `/home/<user>/repos/fibdemo-salt`:

```
$ cd /etc/salt/
$ sudo cp -r /home/<user>/repos/fibdemo-salt/envstandup/salt/fibdemo-1205/* .
```

#####Validate that the files moved over correctly by calling salt-cloud:

```
$ sudo salt-cloud --list-providers
fibdemo-1205-tenant:
    ----------
    gce:
        ----------
```

#####Auth with gcloud

```
$ gcloud auth login
```

This will open a browser window, and ask you to authenticate with a user which has access to the project, fibdemo-1205.

#####Validate authentication with gcloud

```
$ gcloud auth list
```

Once installation of gcloud sdk, and salt-cloud are done, you are ready to begin using the scripts. Please refer to the readme does in docs/ or execute the scripts with -h.

The first step would be to try the env-standup.sh script like such:

```
$ ./env-standup.sh full fibdemo-1205 us-central1
```
