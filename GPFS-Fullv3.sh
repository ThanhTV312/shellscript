#!/bin/bash
echo "***Script by ThanhTV***"
echo "***Please read a Read Me file carefully***"
###------- Golbal Menu 
echo "Select the operation: "
echo "  1)Press 1 to Install GPFS on Node"
echo "  2)Press 2 to Uninstall GPFS on Node"
echo "  3)Press 3 to Create GPFS Cluster, NSD"
echo "  4)Press 4 to Create File System"
echo "  5)Press 5 to Install GPFS GUI"
echo "  6)Press 6 to Exit"
echo -n "Enter choice: "
dir1=/root
cd "$dir1"
read n
###-------------------------------------------------------------- Function --------------------------------------------
#Function 1: Install GPFS Eviroment and Software
function InstallGPFS
{
###-------------------Enviroment
## Update hosts file:
#-e and using \t 
echo -e "172.20.10.21\tgpfs-node1
172.20.10.22\tgpfs-node2
172.20.10.23\tgpfs-node3" >> /etc/hosts;
#Stop&disable the Firewall
systemctl stop firewalld;
systemctl disable firewalld;
systemctl mask --now firewalld;
#Disable Secure Linux
#sed -e 's/pattern1/pattern2/g' full_path_to_file/file
#sed -e 's/${VAR1}/${VAR2}/g' ${VAR3}
var1='SELINUX=enforcing';
var2='SELINUX=disabled';
sed -i -e "s&$var1&$var2&g" /etc/selinux/config;
#sed -i -e 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
# Configure SSH authentication between nodes (run on BOTH nodes):
ssh-keygen -t rsa -N "";
# copy public key to cluster servers
ssh-copy-id root@gpfs-node1;
ssh-copy-id root@gpfs-node2;
ssh-copy-id root@gpfs-node3;
touch ~/.hushlogin;
touch /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys;
cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys;
#ssh root@dc-ecm-cpe01
#ssh root@dc-ecm-cpe02
# Update mmdsh
echo 'PATH=$PATH:/usr/lpp/mmfs/bin' >> .bashrc;
echo $PATH;
#ntp
#timedatectl list-timezones
timedatectl set-timezone Asia/Ho_Chi_Minh;
yum install -y ntp;
ntpdate 172.20.10.1;
systemctl enable ntpd;
systemctl start ntpd;
#Mount DVD local repo
mkdir /opt/rhel-iso;
mount /dev/sr0 /opt/rhel-iso;
cat > /etc/yum.repos.d/dvd.repo <<EOF;
[DVD]
name=DVD
baseurl=file:///opt/rhel-iso
enabled=1
gpgcheck=0
EOF
#Delete Junk Character for IP Address Insert
echo "#Delete Junk Character
stty erase ^?
stty erase ^H
#stty erase ^h" >> .bashrc;
###-------------------Install dependency packages:
#yum --noplugins install -y kernel-devel gcc gcc-c++ ksh autoconf make
yum --noplugins install -y cpp gcc gcc-c++ binutils ksh m4 glibc-headers glibc-devel libstdc++-devel ntp;
yum install -y kernel-headers-$(uname -r);
yum install -y kernel-devel-$(uname -r);
## Install Spectrum Scale on Node:
dir1=/root;
cd "$dir1";
tar zxvf Spectrum_Scale_STD_500_x86_64_LNX.tar.gz;
chmod +x Spectrum_Scale_Standard-5.0.1.2-x86_64-Linux-install;
sh Spectrum_Scale_Standard-5.0.1.2-x86_64-Linux-install --silent;
dir2=/usr/lpp/mmfs/5.0.1.2/gpfs_rpms;
cd "$dir2";
rpm -ivh gpfs.base* gpfs.gpl* gpfs.license* gpfs.gskit* gpfs.msg* gpfs.compression* gpfs.docs* gpfs.ext*;
#rpm -ivh /usr/lpp/mmfs/5.0.1.2/gpfs_rpms/gpfs.base* /usr/lpp/mmfs/5.0.1.2/gpfs_rpms/gpfs.gpl* /usr/lpp/mmfs/5.0.1.2/gpfs_rpms/gpfs.license* \
#/usr/lpp/mmfs/5.0.1.2/gpfs_rpms/gpfs.gskit* /usr/lpp/mmfs/5.0.1.2/gpfs_rpms/gpfs.msg* /usr/lpp/mmfs/5.0.1.2/gpfs_rpms/gpfs.compression* /usr/lpp/mmfs/5.0.1.2/gpfs_rpms/gpfs.docs*
# Compiling modules
export PATH=$PATH:/usr/lpp/mmfs/bin/;
/usr/lpp/mmfs/bin/mmbuildgpl;
##-------- Map LUN
#Scan new disk without reboot
for i in {0..2}; do echo "- - -" > /sys/class/scsi_host/host$i/scan; done;
iscsiadm -m discovery -t st -p 172.20.10.12;
iscsiadm -m node -p 172.20.10.12 -l;
iscsiadm -m session --rescan;
iscsiadm -m session -P 3;
#---
echo "Completed to Install GPFS on this Node: ";
hostname;
echo "Need to Install GPFS on all Nodes";
echo "When all Nodes already Install GPFS, Next step is Create GFPS Cluslter, NSD";
}
#Function 2: Install GPFS GUI
function InstallGUI
{
echo " Script Install GPFS GUI by ThanhTV ";
#Install GPFS GUI on This Node
echo "  Install GPFS GUI on This Node ";
hostname;
yum install -y postgresql-contrib postgresql-server;
# Download and up file boost-regex-1.53 to /root
yum install -y libboost_regex.so.1.53*;
dir2=/usr/lpp/mmfs/5.0.1.2/gpfs_rpms;
cd "$dir2";
rpm -ivh gpfs.ext*;
rpm -ivh /usr/lpp/mmfs/5.0.1.2/zimon_rpms/rhel7/gpfs.gss.pmcollector* /usr/lpp/mmfs/5.0.1.2/zimon_rpms/rhel7/gpfs.gss.pmsensors*;
rpm -ivh /usr/lpp/mmfs/5.0.1.2/gpfs_rpms/gpfs.gui* /usr/lpp/mmfs/5.0.1.2/gpfs_rpms/gpfs.java*;
export PATH=$PATH:/usr/lpp/mmfs/bin/;
systemctl enable gpfsgui;
mmperfmon config generate --collectors gpfs-node1;
mmchnode --perfmon -N gpfs-node1,gpfs-node2,gpfs-node3;
systemctl enable pmcollector;
systemctl stop pmcollector;
systemctl start pmcollector;
systemctl enable pmsensors;
systemctl stop pmsensors;
systemctl start pmsensors;
#Enable capacity data collection
mmperfmon config update GPFSDiskCap.restrict=gpfs-node1 GPFSDiskCap.period=86400;
systemctl stop gpfsgui;
systemctl start gpfsgui;
systemctl status gpfsgui;
/usr/lpp/mmfs/gui/cli/mkuser admin -g SecurityAdmin;
echo "The default user is admin";
echo "The default password is admin001";
echo "Completed to Install GPFS GUI on this Node";
hostname;
}
#--- Function Destroy GPFS Cluster, NSD
function DestroyCluster
{
export PATH=$PATH:/usr/lpp/mmfs/bin/;
echo " Destroy GPFS Cluster, NSD ";
#Unmount all GPFS file systems on all nodes
mmumount all -a;
#Remove each GPFS File systems
mmdelfs gpfs;
#Remove the NSD volume
mmdelnsd nsd1;
mmdelnsd nsd2;
mmlsnsd;
#Remove the tiebreaker disks
mmchconfig tiebreakerdisks=no;
mmdelnsd tiebreaker;
mmlsnsd;
#--- Remove the GUI node from the GUI_MGT_SERVERS node class (Option)
#mmchnodeclass GUI_MGMT_SERVERS delete -N guinode
systemctl stop gpfsgui;
mmchnodeclass GUI_MGMT_SERVERS delete -N gpfs-node1,gpfs-node2,gpfs-node3;
mmlsnodeclass;
#Shutdown GPFS nodes
mmshutdown -a;
mmgetstate -a;
mmlscluster;
}
#--- Function Uninstall GPFS Pakages
function UninstallGPFS
{
#--- Uninstall GPFS on This Node
echo " Uninstall GPFS Pakages ";
yum remove -y gpfs.crypto* gpfs.adv* gpfs.ext* gpfs.gpl* gpfs.license* gpfs.msg* gpfs.compression* gpfs.base* gpfs.docs* gpfs.gskit*;
rpm -qa | grep gpfs;
#Remove the /var/mmfs and /usr/lpp/mmfs directories
rm -Rf /var/mmfs/;
rm -Rf /usr/lpp/mmfs;
#Remove all files that start with mm from the /var/adm/ras directory.
rm -rf /var/adm/ras/mm*;
#Remove /tmp/mmfs directory and its content
rm -Rf /tmp/mmfs;
#--- Uninstall GPFS GUI on This Node
#Stop GUI
systemctl stop gpfsgui;
#Sudo
export SUDO_USER=gpfsadmin;
#Clean up the GUI database
psql postgres postgres -c "drop schema fscc cascade";
#Remove the GUI package
yum remove -y gpfs.gui* gpfs.java*;
#Uninstall the performance monitoring tool
yum remove -y gpfs.gss.pmsensors* gpfs.gss.pmcollector* pmswift* gpfs.pm-ganesha*;
rpm -qa | grep gpfs;
echo "Completed to Uninstall GPFS on this Node: ";
hostname;
}
function UninstallGPFSOther
{
echo "Uninstall GPFS on Other Node ";
#Delete Junk Character for IP Address Insert
echo "#Delete Junk Character
stty erase ^?
stty erase ^H
stty erase ^h" >> .bashrc;
echo " Type the IP address or hostname: ";
read server;
#--- Uninstall GPFS Pakages Function
ssh root@$server "$(declare -f UninstallGPFS);UninstallGPFS";
}
###------------------------------------------------------------------------- Condition -----------------------------------------------------
###------Install GPFS on Node
if [ $n == 1 ];
then
##----- Install Node Menu
{
echo "***Script Install GPFS on Other Node by ThanhTV***"
echo "*** Reference IBM: https://www.ibm.com/support/knowledgecenter/STXKQY_5.0.1/com.ibm.spectrum.scale.v5r01.doc/bl1ins_manuallyinstallingonlinux_packages.htm ***"
echo "Select the operation: "
echo "  1)Press 1 to install GPFS on This Node"
echo "  2)Press 2 to install GPFS on Other Node"
echo "  3)Press 3 to exit"
echo -n "Enter choice: "
read m
#Install GPFS on Node
if [ $m == 1 ];
then
{
echo "  Install GPFS on This Node "
#Prepare Installl
echo "***Script Setup Enviroment and Install GPFS by ThanhTV***"
echo "Please! Up the install file: /root/Spectrum_Scale_STD_500_x86_64_LNX.tar.gz"
echo "Please! Mount the DVD install to server"
read -n 1 -s -r -p "Press Enter to continue if all prepare tasks have done!"
InstallGPFS
export PATH=$PATH:/usr/lpp/mmfs/bin/
cd "$dir1"
sh GPFS-Fullv3.sh
}
#Install GPFS on Other Node
elif [ $m == 2 ];
then
{
echo "  Install GPFS on Other Node "
echo "Type the IP address or hostname: "
read server
stty erase ^?
stty erase ^H
stty erase ^h
scp /root/GPFS-Fullv3.sh root@$server:/root/
ssh root@$server "$(declare -f InstallGPFS);InstallGPFS"
cd "$dir1"
sh GPFS-Fullv3.sh
}
#Back to Menu
else
cd "$dir1"
sh GPFS-Fullv3.sh
fi
}
###------Uninstall GPFS on Node
elif [ $n == 2 ];
then
{
###------- Uninstall Menu 
echo "***Script by ThanhTV***"
echo "***Please read a Read Me file carefully***"
echo "*** Reference IBM: https://www.ibm.com/support/knowledgecenter/en/STXKQY_5.0.1/com.ibm.spectrum.scale.v5r01.doc/bl1ins_uninstall.htm ***"
option=0
until [ "$option" = "3" ]; do
echo "Select the operation: "
echo "  1)Press 1 to Uninstall GPFS on This Node "
echo "  2)Press 2 to Uninstall GPFS on Other Node"
echo "  3)Press 3 to Exit"
echo -n "Enter choice: "
read option
case $option in
#----- Uninstall GPFS on This Node
   1)DestroyCluster && UninstallGPFS;;
#----- Uninstall GPFS on Other Node
   2)UninstallGPFSOther;;
   3)exit;;
   * )echo " Invalid Option. Try again! ";;
esac
done
}
###------Create GPFS Cluster, NSD
elif [ $n == 3 ];
then
{
echo "***Script Create Cluster and NSD for GPFS by ThanhTV***"
# Create node description
export PATH=$PATH:/usr/lpp/mmfs/bin/
#vi /root/NodeDescFile
cat > /root/NodeDescFile <<EOF
gpfs-node1:quorum-manager
gpfs-node2:quorum-manager
gpfs-node3:quorum-client
EOF
#create cluster
mmcrcluster -N /root/NodeDescFile -p gpfs-node1 -s gpfs-node2 -r /usr/bin/ssh -R /usr/bin/scp -C gpfs-cluster
mmchconfig unmountOnDiskFail=yes -N gpfs-node3
# Accept license
mmchlicense server --accept -N gpfs-node1,gpfs-node2,gpfs-node3
mmlslicense -L
# Create disk.stanza
cat > /root/disk.stanza <<EOF
%nsd: device=/dev/sdb nsd=nsd1 servers=gpfs-node1,gpfs-node2 usage=dataAndMetadata failureGroup=1 pool=system
%nsd: device=/dev/sdc nsd=nsd2 servers=gpfs-node1,gpfs-node2 usage=dataAndMetadata failureGroup=1 pool=system
EOF
#Create NSD
mmcrnsd -F /root/disk.stanza -v no
#Start cluster
mmstartup -a
mmgetstate -aL
#Wait a minnute
echo "Wait a minutes to start cluster"
sleep 1m
mmgetstate -aL
#---
echo "Completed to Create Cluster and NSD for GPFS"
echo "Next step is Create File System GPFS"
cd "$dir1"
sh GPFS-Fullv3.sh
}
###------Create File System
elif [ $n == 4 ];
then
{
echo "***Script Create File System by ThanhTV***"
function CreateFS 
{
option2=0
until [ "$option2" = "5" ]; do
#------ Create FS Menu
echo "Select the operation: "
echo "  1)Press 1 to startup all node again"
echo "  2)Press 2 to check state"
echo "  3)Press 3 create file system"
echo "  4)Press 4 to mount all file system"
echo "  5)Press 5 to exit"
 echo -n "Enter choice: "
 read option2
 echo ""
 case $option2 in
 1 ) mmstartup -a;;
 2 ) mmgetstate -aL;;
 3 ) mmcrfs gpfs -F /root/disk.stanza -T /gpfs -B 1M -A yes -v yes && mmlsfs all;;
 4 ) /usr/lpp/mmfs/bin/mmmount all -a && df -h;;
 5 ) sh GPFS-Fullv3.sh;;
 * ) CreateFS;;
 esac
 done
}
CreateFS
}
###------ Install GUI
elif [ $n == 5 ];
then
{
echo "***Script Install GPFS on Other Node by ThanhTV***"
echo "Select the operation: "
echo "  1)Press 1 to install GPFS GUI on This Node"
echo "  2)Press 2 to install GPFS GUI on Other Node"
echo "  3)Press 3 to exit"
echo -n "Enter choice: "
read p
#Install GPFS GUI on This Node
if [ $p == 1 ];
then
{
InstallGUI
#Back to Menu
cd "$dir1"
sh GPFS-Fullv3.sh
}
elif [ $p == 2 ];
then
{
echo "  Install GPFS GUI on Other Node "
Install GPFS GUI on Other Node
stty erase ^?
stty erase ^H
stty erase ^h
echo "Type the IP address or hostname: "
read server
ssh root@$server "$(declare -f InstallGUI);InstallGUI"
cd "$dir1"
sh GPFS-Fullv3.sh
}
#Back to Menu
else
cd "$dir1"
sh GPFS-Fullv3.sh
fi
}
###------Exit Menu
elif [ $n == 6 ];
then
echo " Exit ! "
exit
else
echo "***Invalid Option***"
dir1=/root
cd "$dir1"
sh GPFS-Fullv3.sh
fi
#-------- clean up ------
#hosts
#cp /etc/hosts /etc/hosts.bak
#cat /etc/hosts | sort | uniq > /etc/hosts.txt
#mv /etc/hosts.txt /etc/hosts
#.bashrc
#cp .bashrc .bashrc.bak
#cat .bashrc| sort | uniq > .bashrc.txt
#mv .bashrc.txt .bashrc