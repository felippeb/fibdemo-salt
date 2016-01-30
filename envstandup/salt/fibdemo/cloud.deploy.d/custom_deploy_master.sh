#!/bin/bash

SALTMASTER=$1
POD=$2
VMHOSTNAME=$(cat /etc/hostname)

cat << EOF > /tmp/saltstack.pub
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v2.0.22 (GNU/Linux)

mQENBFOpvpgBCADkP656H41i8fpplEEB8IeLhugyC2rTEwwSclb8tQNYtUiGdna9
m38kb0OS2DDrEdtdQb2hWCnswxaAkUunb2qq18vd3dBvlnI+C4/xu5ksZZkRj+fW
tArNR18V+2jkwcG26m8AxIrT+m4M6/bgnSfHTBtT5adNfVcTHqiT1JtCbQcXmwVw
WbqS6v/LhcsBE//SHne4uBCK/GHxZHhQ5jz5h+3vWeV4gvxS3Xu6v1IlIpLDwUts
kT1DumfynYnnZmWTGc6SYyIFXTPJLtnoWDb9OBdWgZxXfHEcBsKGha+bXO+m2tHA
gNneN9i5f8oNxo5njrL8jkCckOpNpng18BKXABEBAAG0MlNhbHRTdGFjayBQYWNr
YWdpbmcgVGVhbSA8cGFja2FnaW5nQHNhbHRzdGFjay5jb20+iQE4BBMBAgAiBQJT
qb6YAhsDBgsJCAcDAgYVCAIJCgsEFgIDAQIeAQIXgAAKCRAOCKFJ3le/vhkqB/0Q
WzELZf4d87WApzolLG+zpsJKtt/ueXL1W1KA7JILhXB1uyvVORt8uA9FjmE083o1
yE66wCya7V8hjNn2lkLXboOUd1UTErlRg1GYbIt++VPscTxHxwpjDGxDB1/fiX2o
nK5SEpuj4IeIPJVE/uLNAwZyfX8DArLVJ5h8lknwiHlQLGlnOu9ulEAejwAKt9CU
4oYTszYM4xrbtjB/fR+mPnYh2fBoQO4d/NQiejIEyd9IEEMd/03AJQBuMux62tjA
/NwvQ9eqNgLw9NisFNHRWtP4jhAOsshv1WW+zPzu3ozoO+lLHixUIz7fqRk38q8Q
9oNR31KvrkSNrFbA3D89uQENBFOpvpgBCADJ79iH10AfAfpTBEQwa6vzUI3Eltqb
9aZ0xbZV8V/8pnuU7rqM7Z+nJgldibFk4gFG2bHCG1C5aEH/FmcOMvTKDhJSFQUx
uhgxttMArXm2c22OSy1hpsnVG68G32Nag/QFEJ++3hNnbyGZpHnPiYgej3FrerQJ
zv456wIsxRDMvJ1NZQB3twoCqwapC6FJE2hukSdWB5yCYpWlZJXBKzlYz/gwD/Fr
GL578WrLhKw3UvnJmlpqQaDKwmV2s7MsoZogC6wkHE92kGPG2GmoRD3ALjmCvN1E
PsIsQGnwpcXsRpYVCoW7e2nW4wUf7IkFZ94yOCmUq6WreWI4NggRcFC5ABEBAAGJ
AR8EGAECAAkFAlOpvpgCGwwACgkQDgihSd5Xv74/NggA08kEdBkiWWwJZUZEy7cK
WWcgjnRuOHd4rPeT+vQbOWGu6x4bxuVf9aTiYkf7ZjVF2lPn97EXOEGFWPZeZbH4
vdRFH9jMtP+rrLt6+3c9j0M8SIJYwBL1+CNpEC/BuHj/Ra/cmnG5ZNhYebm76h5f
T9iPW9fFww36FzFka4VPlvA4oB7ebBtquFg3sdQNU/MmTVV4jPFWXxh4oRDDR+8N
1bcPnbB11b5ary99F/mqr7RgQ+YFF0uKRE3SKa7a+6cIuHEZ7Za+zhPaQlzAOZlx
fuBmScum8uQTrEF5+Um5zkwC7EXTdH1co/+/V/fpOtxIg4XO4kcugZefVm5ERfVS
MA==
=dtMN
-----END PGP PUBLIC KEY BLOCK-----
EOF

cat /tmp/saltstack.pub | sudo apt-key add -
sudo sh -c "echo 'deb http://repo.saltstack.com/apt/ubuntu/14.04/amd64/latest trusty main' >> /etc/apt/sources.list"

#install salt-master
sudo apt-get update && sudo apt-get -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold install salt-master salt-cloud salt-api python-setuptools

cat << 'EOF' > /tmp/root-known-hosts
EOF
sudo mv /tmp/root-known-hosts /root/.ssh/known_hosts

cat << 'EOF' > /tmp/root-ssh-id-rsa
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAqOGNfVHUIqBab2SMICqeHFEjAqX6PoPL2rEH3ufOA/oh15J6
mHMkhcmA+fMDyR8JI8XT1vJ2evNBwj5LC7cmhp63U5PTWWGBTK6/XCC2VFtlRjR/
6h9JXrRxUtqnFl+MBmM0rCrSCMmwJ7SbykQHAbLuTNLrEzuzgUl44iUvX/K6MA9K
agYxHSPWpxr7gpUpp4J6qYn/nFarO183sDYly2bfjelb96wVl26QLn7nxoTcW9if
Dw37Gr9ARqG3FoBTtDvigac+slhWd9RN4J1NbRobm5dG+gZPUUWM4zYX00CCBvRu
0UWWGLpWzenW9eCzFYWyp1PO0XQrC1KC5/AnrQIDAQABAoIBAFg/dLYVumpVrKwk
uGxemLxnUYoivT9Jk461j01Vh/vgCysgqdtb36vhffoemM3R3+7Hg0kA7hSVZLlh
38lBbWpPKbEMwBYms3AkqG410dEG6UbkTCtFKgvI8qa/ByzTxNHZqT6GKbbZ3akB
4Z6yKY8jtw6B8MDeI5DdmcNidv0FehPBAMpGXh81JeTBK/Us1i974uJuQW8s3mM1
H0PXRByISDBgRiXzB8U5L94G6fIL7kEx8OorKI5wn4T2HdWUKtg8LbNmkj6fpfIl
E44nnrwqkKPHGI2fuflwaOiF/UX2zaxefmF5jp73y82JLq9nxjn5EzEaVXYPCiKR
i07X/kECgYEA1OfwMi33ptBkgDWMKn09Olkh0qWpMKswxyYU2sl3v2ek93CC6GnI
4xhiOiPGTLxy3rT7gVRRxpUKcyezUF17L1MmOG7rTp8Yk9okIGKZdfKLPu/XvL2q
AmdqkL8apizV0CaaBOtb28y6vOIxSM5Jh70C4Lj9SVAZhsMTIR7Gb7kCgYEAyxBk
boUr+aAh9XlxoKNSMtIm7djmxlHYuA2Mua2J4PERbH95F0bz6gdQ85FcYBEZFxMP
ZPQZq9Tcc2ALR6wpmoQqiTMo+b1Ex4V14ynRsMm974GTC1vy/bYQQGJAFuo3p/C8
41PYeVUV15E7clO8gPwmr3fq247s7rHNNGwwqZUCgYEAsx3ulkjV8SGha7uhEJ4M
xOn36qA0lx1vDBydrvOQKxenUgT2HVHiECyTdxZh3m0stvDMJyIpKkh5YigkU5hR
6p6pqRCoJpzysHD1s8lAElrbizd86O0n+p3GqcAdS3Cs8VGIglsADQtQj1g83mOu
uOPrZ+Q6M1OQJjA4B8U8bQECgYB/TbGI0Bg3kLp5aD9iE8Gudq1NI1PaNOmGyYfV
yAPOb5Maz/ecLjEwIJIRgKnG2DFAlARsp9OINBRYiHfJ4Rbb9cus49PmbU+3PeYg
GdGJ4ZAfnL4Quv5lLESX+IBxXTizImtooOHvfvYIhNYd4H0m5+1gx+8G4l2LbxBU
sxb22QKBgEXqB9WrxEGfR+CCVsOTfk/y70hC0NgiLNvy3e8PZN3EixDEPCck9vQN
1y+SKFIzoKqnO9QBk/Pa0XU/IzrYgyDFexwv7mjk95H39PtEld+NKjAYg8IqVfvW
0RXcU/mAy+GRLCIeyZu1ILXeroWQkRzSGEDUxaKYO5EHWYZMz7wW
-----END RSA PRIVATE KEY-----
EOF
sudo mv /tmp/root-ssh-id-rsa /root/.ssh/id_rsa

cat << 'EOF' > /tmp/root-ssh-id-rsa-pub
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCo4Y19UdQioFpvZIwgKp4cUSMCpfo+g8vasQfe584D+iHXknqYcySFyYD58wPJHwkjxdPW8nZ680HCPksLtyaGnrdTk9NZYYFMrr9cILZUW2VGNH/qH0letHFS2qcWX4wGYzSsKtIIybAntJvKRAcBsu5M0usTO7OBSXjiJS9f8rowD0pqBjEdI9anGvuClSmngnqpif+cVqs7XzewNiXLZt+N6Vv3rBWXbpAufufGhNxb2J8PDfsav0BGobcWgFO0O+KBpz6yWFZ31E3gnU1tGhubl0b6Bk9RRYzjNhfTQIIG9G7RRZYYulbN6db14LMVhbKnU87RdCsLUoLn8Cet salt01@fibdemo
EOF
sudo mv /tmp/root-ssh-id-rsa-pub /root/.ssh/id_rsa.pub

sudo chown -R 400 /root/.ssh/*


cat << 'EOF' > /tmp/saltmaster
auto_accept: true
max_open_files: 100000
worker_threads: 20
file_roots:
  base:
    - /srv/salt
fileserver_backend:
  - roots
  - git
fileserver_followsymlinks: False
gitfs_provider: gitpython
gitfs_remotes:
  - git@github.com:rhohan/fibdemo-salt.git:
    - root: saltbase
    - base: master
ext_pillar:
  - git:
    - master git@github.com:rhohan/fibdemo-salt.git:
      - root: pillarbase
      - env: base
EOF
sudo mv /tmp/saltmaster /etc/salt/master.d/master.conf

sudo service salt-master restart

#install salt-minion

cat << EOF > /tmp/salt-minion
master: ${VMHOSTNAME}
EOF

cat << EOF > /tmp/salt-minion-grains
grains:
  roles:
    - saltmaster
EOF

cat << EOF > /tmp/salt-minion-id
${VMHOSTNAME}
EOF

sudo mkdir -p /etc/salt/minion.d/
sudo mv /tmp/salt-minion-id /etc/salt/minion_id
sudo mv /tmp/salt-minion /etc/salt/minion.d/master.conf
sudo mv /tmp/salt-minion-grains /etc/salt/minion.d/grains.conf

sudo apt-get -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confnew install salt-minion

sudo service salt-minion restart

echo "===== sleeping 20 to allow time for master to update"
sleep 20
sudo salt-call state.highstate
