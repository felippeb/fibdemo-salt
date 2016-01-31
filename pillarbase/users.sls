users:
  root:
    password: '$6$KbU0L8Rx$A2im8uROtD1o3rOBnx2fEKkgbtVw6nQxp.0abTvMk1BRc6D5SltPoMj8tcVHFpexAz7/fnef1CjF/35VxIvmq0'
    home: /root
    createhome: false
  collectdbot:
    fullename: collectd sudoer bot
    password: '*'
    home: /usr/share/collectd/
    createhome: False
    sudouser: True
    sudo_rules:
      - 'ALL=(ALL) NOPASSWD: /usr/bin/docker *'
    shell: /bin/false
  felippeb:
    fullname: felippe burk
    password: 'x'
    home: /home/felippeb
    groups:
      - 'docker'
      - 'adm'
    createhome: True
    sudouser: True
    sudo_rules:
      - 'ALL=NOPASSWD: ALL'
    shell: /bin/bash
    ssh_auth_file:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCtHLhJldt/tlcUKH4PIzrifAVjFbK2NSdRXGttPUjGo1D112DvGei7xlqA4INVpgnGf5wnmFfJmgkxaZBsWXiAwxXp1QRhvwTFKoVXTGCik4ALULykaCAIu/L/zFMDn3PVGPlc1Bi5rkb5p2Wo+LuBCaYtY+1gkFRGpdFsIFm9oGHKWv+f88aGBQbEyep7wLi3egZycifwo6/i9g8C1PFeOb29CGRNe1OdZ6NO29W7JSmFg8elJylz56+rG79mKaLz22+Gr2RXH1d6xtJT9O2Tncg77mVmizeE5BAv/kmaVBrFEXgwGDJiwSqA0xPFPwxjRHcjqNnF3m/fNswxsY/1 felippeb@felippeb-lappy
