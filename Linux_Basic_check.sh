#!/bin/sh
echo -e "-------HOSTNAME-------"
hostname -f
echo -e "\n-------Kernel version-------"
uname -r
echo -e "\n-------ROUTING TABLE-------"
route -n
echo -e "\n-------ETHERNET CHK-------"
ip a
echo -e "\n-------Timezone CHK-------"
date +%Z
echo -e "\n-------Total Mount-------"
allfsvalue=`df -PHT | grep -E -v "Mount|tmpfs" |wc -l`
echo $allfsvalue
echo -e "\n-------Number of NFS Mount-------"
nfsvalue=`df -PHT | grep -E -v "Mount|tmpfs" | grep nfs|wc -l`
echo $nfsvalue
echo -e "\n-------Number of CIFS Mount-------"
cifsvalue=`df -PHT | grep -E -v "Mount|tmpfs" | grep cifs |wc -l`
echo $cifsvalue
echo -e "\n-------ALL FS -------"
df -PHT | grep -E -v "Mount|tmpfs"
echo -e " \n-------Mountpoint folder only -------"
df -PHT | grep -E -v "Mount|tmpfs" | awk '{print $7}' | sort -n
df -PHT | grep -E -v "Mount|tmpfs" | awk '{print $7}' | sort -n > listofmountedfs.txt
for i in `cat listofmountedfs.txt` ; do cat -e /etc/fstab | grep -v "#" | awk '{print $2}' | grep $i /etc/fstab>> /dev/null || echo -e "\n\n ERROR : $i is not in fstab" ; done
rm listofmountedfs.txt
echo -e "-------fstab Entry-------"
cat /etc/fstab
echo -e "-------resolveconf-------"
cat /etc/resolv.conf
echo -e "-------currently mounted-------"
cat /proc/mounts
echo -e "-------exportfs-------"
cat /etc/exports
echo -e "-------Disks lsblk-------"
lsblk
echo -e "-------Fdisks-------"
fdisk -l
echo -e "-------PVS-VGS-LVS-------"
pvs ; vgs ; lvs
echo -e "-------Kernel current-------"
uname -r
echo -e "-------All Kernels-------"
rpm -qa --last |grep -i kernel
echo -e "-------exported-------"
exportfs
echo -e "-------Cluster service-------"
clustat
/opt/LifeKeeper/bin/lcdstatus -q
service lifekeeper status
echo -e "-------Cluster service-------"
/opt/LifeKeeper/bin/lcdstatus -q
service lifekeeper status

echo -e "\n####################################################################################"


