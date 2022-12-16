#!/bin/bash

CINAME=`uname -n | cut -d. -f1`

cd /var/tmp/
OP=UNIXBKP

PATH=$PATH:/opt/VRTSvcs/bin:/opt/VRTS/bin; export PATH


if [ ! -d ${OP} ];then
        mkdir ${OP}
else
   echo "UNIXBKP Folder already present, renaming it as UNIXBKP-DATE-TIME"
   DATE=`date +"%d-%m-%y-%H-%M-%S"`
   mv /var/tmp/${OP} /var/tmp/${OP}-${DATE}
   mkdir ${OP}
fi


blankline()
{
        echo "" >> /var/tmp/${OP}/${CINAME}
}

echo "Running Initial checks"


echo LAST REBOOT: $(who -b | awk '{print $3,$4}') >> /var/tmp/${OP}/${CINAME}
blankline

echo UPTIME DAYS: $(uptime | awk '{print $3, $4}') >> /var/tmp/${OP}/${CINAME}
blankline

echo UNAME: $(uname -a) >> /var/tmp/${OP}/${CINAME}
blankline

cat /proc/version >> /var/tmp/${OP}/${CINAME}
blankline

# any nfs shares running
if [ $(showmount -e ${CINAME} 2> /dev/null | wc -l) -eq 0 ];then
        echo NFS SHARES: NA >> /var/tmp/${OP}/${CINAME}
else
        echo NFS SHARES: CONFIGURED >> ${OP}/${CINAME}
        showmount -e ${CINAME} >> /var/tmp/${OP}/${CINAME}-NFS-Shares
        cp -p /etc/exports /var/tmp/${OP}/${CINAME}-exports
fi
blankline

# collect all mounted file systems
echo FILESYSTEMS: >> /var/tmp/${OP}/${CINAME}
cat /proc/scsi/scsi > /var/tmp/${OP}/${CINAME}-proc-scsi-scsi
cat /proc/meminfo > /var/tmp/${OP}/${CINAME}-proc-meminfo
cat /proc/cpuinfo > /var/tmp/${OP}/${CINAME}-proc-cpuinfo
cat /proc/mounts > /var/tmp/${OP}/${CINAME}-proc-mounts
free -m > /var/tmp/${OP}/${CINAME}-free-m
swapon -s > /var/tmp/${OP}/${CINAME}-swapon-s
mount >> /var/tmp/${OP}/${CINAME}-mount
blankline

echo "Collecting DG info"
echo LVM diskgroups: >> ${OP}/${CINAME}
vgs > /var/tmp/${OP}/${CINAME}-vgs
pvs > /var/tmp/${OP}/${CINAME}-pvs
lvs > /var/tmp/${OP}/${CINAME}-lvs
pvdisplay > /var/tmp/${OP}/${CINAME}-pvdisplay
vgdisplay > /var/tmp/${OP}/${CINAME}-vgdisplay
lvdisplay > /var/tmp/${OP}/${CINAME}-lvdisplay

# list full ifconfig -a output
echo IFCONFIG A: >> /var/tmp/${OP}/${CINAME}
ifconfig -a > /var/tmp/${OP}/${CINAME}-ifconfig-a
ip a > /var/tmp/${OP}/${CINAME}-ip-a
blankline

echo ROUTE : >> /var/tmp/${OP}/${CINAME}
netstat -nr > /var/tmp/${OP}/${CINAME}-netstat-nr
ip r s > /var/tmp/${OP}/${CINAME}-ip-r-s
ss -tulpn > /var/tmp/${OP}/${CINAME}-ss-tulpn
lsof -i -P -n > /var/tmp/${OP}/${CINAME}-lsof-i-P-n
blankline


# NIC port info
for nic in $(ifconfig | egrep "^eth|^en" | awk '{print $1}')
do
        ethtool -i $nic  >> /var/tmp/${OP}/${CINAME}-${nic}
done

# collect bonding info
if [ -d /proc/net/bonding ];then
        echo " Collecting Bond inforamtion " >> /var/tmp/${OP}/${CINAME}
        for bond in `ls /proc/net/bonding`
        do
        echo "==========  Configured - ${bond} ============" >> /var/tmp/${OP}/${CINAME}
        cat /proc/net/bonding/${bond} >> /var/tmp/${OP}/${CINAME}-${bond}
        done
else
        echo "No Bonding" >> /var/tmp/${OP}/${CINAME}
fi
blankline

if [ -d /sys/class/fc_host ];then
echo "Online HBAs" >> /var/tmp/${OP}/${CINAME}
ls -ld /sys/class/fc_host/host*/device >> /var/tmp/${OP}/${CINAME}
systool -c fc_host >> /var/tmp/${OP}/${CINAME}-systool-c-fc_host
systool -c fc_host -v >> /var/tmp/${OP}/${CINAME}-systool-c-fc_host-v
        for port in `ls /sys/class/fc_host`
        do
        if [ `cat /sys/class/fc_host/${port}/port_state` = Online ];then
        WWN=`cat /sys/class/fc_host/${port}/port_name | sed -e 's/^0x//'`
        echo "Online port = $port - $WWN" >> /var/tmp/${OP}/${CINAME}
                fi
        done
else
        echo "No Online HBAs" >> /var/tmp/${OP}/${CINAME}
fi
blankline


if [ $(vxdg list 2> /dev/null | wc -l) -eq 0 ];then
        echo NO VERITAS DG : NA >> /var/tmp/${OP}/${CINAME}
else
        echo "Collecting DG info"
        # collect as veritas diskgroups
        echo VERITAS INFO: >> /var/tmp/${OP}/`uname -n`
        vxdg list >> /var/tmp/${OP}/`uname -n`-vxdg-list
        vxprint -ht >> /var/tmp/${OP}/`uname -n`-vxprint-ht
        vxdisk -o alldgs -e list >> /var/tmp/${OP}/`uname -n`-vxdisk-o-alldgs-e-list
        vxdmpadm listctlr all >> /var/tmp/${OP}/`uname -n`-vxdmpadm-listctlr-all
        vxdmpadm listenclosure all >> /var/tmp/${OP}/`uname -n`-vxdmpadm-listenclosure-all
        for DG in `vxdg list | grep -v NAME| awk '{print $1}'`
        do
                vxprint -htg $DG >> /var/tmp/${OP}/`uname -n`-vxprint-htg-${DG}
                vxdisk -o alldgs -g $DG -e list >> /var/tmp/${OP}/`uname -n`-vxdisk-o-alldgs-g-${DG}-e-list
        done
blankline
fi


# collect vcs status
if [ -f /opt/VRTSvcs/bin/hastatus ];then
        echo HA STATUS: >> /var/tmp/${OP}/${CINAME}
        ps -aef | grep -i had >> /var/tmp/${OP}/${CINAME}
        /opt/VRTSvcs/bin/hastatus -sum >> /var/tmp/${OP}/${CINAME}-hastatus
        lltstat -vvn  | sed -n '/LLT/,/CONNWAIT/p' >> /var/tmp/${OP}/${CINAME}-lltstat-vvn
        gabconfig -a >> /var/tmp/${OP}/${CINAME}-gabconfig-a
        gabconfig -l >> /var/tmp/${OP}/${CINAME}-gabconfig-l
        /opt/VRTSvcs/bin/haagent -list >> /var/tmp/${OP}/${CINAME}-haagent-list
        /opt/VRTSvcs/bin/haclus -display >> /var/tmp/${OP}/${CINAME}-haclus-display
        /opt/VRTSvcs/bin/hasys -list >> /var/tmp/${OP}/${CINAME}-hasys-list
        /opt/VRTSvcs/bin/hagrp -list >> /var/tmp/${OP}/${CINAME}-hagrp-list
        /opt/VRTSvcs/bin/hares -list >> /var/tmp/${OP}/${CINAME}-hares-list
                cp -p /etc/VRTSvcs/conf/config/main.cf /var/tmp/${OP}/${CINAME}-VCS-main.cf
                cp -p /etc/VRTSvcs/conf/config/types.cf /var/tmp/${OP}/${CINAME}-VCS-types.cf
                cp -p /etc/VRTSvcs/conf/config/main.cmd /var/tmp/${OP}/${CINAME}-VCS-main.cmd
                tar cf /var/tmp/${OP}/${CINAME}-VRTSvcs.tar /etc/VRTSvcs
        blankline
else
        echo HA STATUS: NO VCS >> /var/tmp/${OP}/${CINAME}
        blankline
fi

echo "Oracle - Process check"
echo " Oracle DB Check " >> /var/tmp/${OP}/${CINAME}
ps -aef | grep -i pmon >> /var/tmp/${OP}/${CINAME}
ps -aef > /var/tmp/${OP}/${CINAME}-ps-aef
blankline

# output from dmidecode
dmidecode > /var/tmp/${OP}/${CINAME}-dmidecode

# output from fdisk and lsblk
fdisk -l > /var/tmp/${OP}/${CINAME}-fdisk-l
lsblk > /var/tmp/${OP}/${CINAME}-lsblk
blkid > /var/tmp/${OP}/${CINAME}-blkid
ls -l /dev/mapper/ > /var/tmp/${OP}/${CINAME}-dev-mapper
ls -l /dev/disk/by-uuid > /var/tmp/${OP}/${CINAME}-dev-disk-by-uuid
ls -l /dev/disk/by-id/ > /var/tmp/${OP}/${CINAME}-dev-disk-by-id
lspci -mm -nn > /var/tmp/${OP}/${CINAME}-lspci-mm-nn
lspci -v > /var/tmp/${OP}/${CINAME}-lspci-v
ipcs -l > /var/tmp/${OP}/${CINAME}-ipcs-l
dmsetup info -c > /var/tmp/${OP}/${CINAME}-dmsetup-info-c
crontab -l >> /var/tmp/${OP}/${CINAME}-crontab-l
cp -p /etc/fstab /var/tmp/${OP}/${CINAME}-fstab
cp -p /etc/sysctl.conf /var/tmp/${OP}/${CINAME}-sysctl.conf
cp -p /etc/shadow /var/tmp/${OP}/${CINAME}-shadow
cp -p /etc/passwd /var/tmp/${OP}/${CINAME}-passwd
cp -p /etc/sssd/sssd.conf /var/tmp/${OP}/${CINAME}-sssd.conf
cp -p /etc/ssh/sshd_config /var/tmp/${OP}/${CINAME}-sshd_config
cp -p /etc/resolv.conf /var/tmp/${OP}/${CINAME}-resolv.conf
cp -p /etc/ntp.conf /var/tmp/${OP}/${CINAME}-ntp.conf
cp -p /etc/dhcpd.conf /var/tmp/${OP}/${CINAME}-dhcpd.conf
cp -p /etc/lvm/lvm.conf /var/tmp/${OP}/${CINAME}-lvm.conf
sysctl -a > /var/tmp/${OP}/${CINAME}-sysctl-a
rpm -qa --last > /var/tmp/${OP}/${CINAME}-rpm-qa-last
iptables -L > /var/tmp/${OP}/${CINAME}-iptables-L
postconf > /var/tmp/${OP}/${CINAME}-postconf
postconf -n > /var/tmp/${OP}/${CINAME}-postconf-n
chkconfig --list > /var/tmp/${OP}/${CINAME}-chkconfig-list
service --status-all > /var/tmp/${OP}/${CINAME}-service-status-all
systemctl list-unit-files |egrep "generated|static|enabled|disabled" | cut -c40-50|sort|uniq -c  >> /var/tmp/${OP}/${CINAME}
systemctl list-unit-files |egrep "generated" > /var/tmp/${OP}/${CINAME}-systemctl-generated
systemctl list-unit-files |egrep "static" > /var/tmp/${OP}/${CINAME}-systemctl-static
systemctl list-unit-files |egrep "disabled" > /var/tmp/${OP}/${CINAME}-systemctl-disabled
systemctl list-unit-files |egrep "enabled" > /var/tmp/${OP}/${CINAME}-systemctl-enabled
systemctl list-units --state failed > /var/tmp/${OP}/${CINAME}-systemctl-failed
tar cf /var/tmp/${OP}/${CINAME}-lvm.tar /etc/lvm
tar cf /var/tmp/${OP}/${CINAME}-ssh.tar /etc/ssh
tar cf /var/tmp/${OP}/${CINAME}-sssd.tar /etc/sssd
tar cf /var/tmp/${OP}/${CINAME}-postfix.tar /etc/postfix
df -hT > /var/tmp/${OP}/${CINAME}-dh-hT
