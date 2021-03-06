#!/bin/sh

## Tag version
date > /etc/vagrant_box_build_time

## Add the opencsw package site
PATH=/usr/bin:/usr/sbin:$PATH
export PATH

pkg update pkg:/package/pkg || true
pkg update --accept         || true

yes|/usr/sbin/pkgadd -d http://mirror.opencsw.org/opencsw/pkgutil-`uname -p`.pkg all
/opt/csw/bin/pkgutil -U


# get 'sudo'
/opt/csw/bin/pkgutil -y -i CSWsudo
chgrp 0 /etc/opt/csw/sudoers
ln -s /etc/opt/csw/sudoers /etc/sudoers
# get 'wget', 'GNU tar' and 'GNU sed' (also needed for Ruby)
/opt/csw/bin/pkgutil -y -i CSWwget CSWgtar CSWgsed CSWvim


## Ruby
/opt/csw/bin/pkgutil -y -i CSWgsed
/opt/csw/bin/pkgutil -y -i CSWruby18-gcc4 CSWruby18-dev CSWruby18
/opt/csw/bin/pkgutil -y -i CSWrubygems

# puppet
/opt/csw/bin/pkgutil -y -i CSWaugeas
/opt/csw/bin/pkgutil -y -i CSWrubyaugeas

/opt/csw/bin/gem install puppet  --no-ri --no-rdoc


mkdir -p /etc/puppet
mkdir -p /etc/puppet/modules

mkdir -p /opt/puppet/var
mkdir -p /opt/puppet/log
mkdir -p /opt/puppet/run
mkdir -p /opt/puppet/share/modules
mkdir -p /var/lib


# setup the vagrant key
# you can replace this key-pair with your own generated ssh key-pair
echo "Setting the vagrant ssh pub key"
mkdir /export/home/vagrant/.ssh
chmod 700 /export/home/vagrant/.ssh
touch /export/home/vagrant/.ssh/authorized_keys
if [ -f /usr/sfw/bin/wget ] ; then
  /usr/sfw/bin/wget --no-check-certificate http://github.com/mitchellh/vagrant/raw/master/keys/vagrant.pub -O /export/home/vagrant/.ssh/authorized_keys
else
  /usr/bin/wget --no-check-certificate http://github.com/mitchellh/vagrant/raw/master/keys/vagrant.pub -O /export/home/vagrant/.ssh/authorized_keys
fi
chmod 600 /export/home/vagrant/.ssh/authorized_keys
chown -R vagrant:staff /export/home/vagrant/.ssh

# Speed up SSH by disabling DNS checks for clients
echo "LookupClientHostnames=no" >> /etc/ssh/sshd_config

/usr/sbin/svcadm disable sendmail
/usr/sbin/svcadm disable asr-notify


## Fix the shells to include the /opt/csw and /usr/ucb directories
/opt/csw/bin/gsed -i -e 's#^\#PATH=.*$#PATH=/opt/csw/bin:/usr/sbin:/usr/bin:/usr/ucb#g' \
    -e 's#^\#SUPATH=.*$#SUPATH=/opt/csw/bin:/usr/sbin:/usr/bin:/usr/ucb#g' /etc/default/login
/opt/csw/bin/gsed -i -e 's#^\#PATH=.*$#PATH=/opt/csw/bin:/usr/sbin:/usr/bin:/usr/ucb#g' \
    -e 's#^\#SUPATH=.*$#SUPATH=/opt/csw/bin:/usr/sbin:/usr/bin:/usr/ucb#g' /etc/default/su

## Add the CSW libraries to the LD path
/usr/bin/crle -u -l /opt/csw/lib

## Installing the virtualbox guest additions (from the ISO)
#
echo "Installing VirtualBox Guest Additions"
echo "mail=\ninstance=overwrite\npartial=quit" > /tmp/noask.admin
echo "runlevel=nocheck\nidepend=quit\nrdepend=quit" >> /tmp/noask.admin
echo "space=quit\nsetuid=nocheck\nconflict=nocheck" >> /tmp/noask.admin
echo "action=nocheck\nbasedir=default" >> /tmp/noask.admin
DEV=`/usr/sbin/lofiadm -a /export/home/vagrant/VBoxGuestAdditions.iso`
/usr/sbin/mount -o ro -F hsfs $DEV /mnt
/usr/sbin/pkgadd -a /tmp/noask.admin -G -d /mnt/VBoxSolarisAdditions.pkg all
/usr/sbin/umount /mnt
/usr/sbin/lofiadm -d $DEV
rm -f VBoxGuestAdditions.iso




## Add loghost to /etc/hosts
/opt/csw/bin/gsed -i -e 's/localhost/localhost loghost/g' /etc/hosts

/usr/bin/cat <<'EOFTIC' > /tmp/terminfo.src
#	Reconstructed via infocmp from file: /usr/share/terminfo/s/screen
screen|VT 100/ANSI X3.64 virtual terminal,
	am, km, mir, msgr, xenl,
	colors#8, cols#80, it#8, lines#24, ncv#3, pairs#64,
	acsc=++\,\,--..00``aaffgghhiijjkkllmmnnooppqqrrssttuuvvwwxxyyzz{{||}}~~,
	bel=^G, blink=\E[5m, bold=\E[1m, cbt=\E[Z, civis=\E[?25l,
	clear=\E[H\E[J, cnorm=\E[34h\E[?25h, cr=^M,
	csr=\E[%i%p1%d;%p2%dr, cub=\E[%p1%dD, cub1=^H,
	cud=\E[%p1%dB, cud1=^J, cuf=\E[%p1%dC, cuf1=\E[C,
	cup=\E[%i%p1%d;%p2%dH, cuu=\E[%p1%dA, cuu1=\EM,
	cvvis=\E[34l, dch=\E[%p1%dP, dch1=\E[P, dl=\E[%p1%dM,
	dl1=\E[M, ed=\E[J, el=\E[K, el1=\E[1K, enacs=\E(B\E)0,
	flash=\Eg, home=\E[H, ht=^I, hts=\EH, ich=\E[%p1%d@,
	il=\E[%p1%dL, il1=\E[L, ind=^J, is2=\E)0, kbs=\177,
	kcbt=\E[Z, kcub1=\EOD, kcud1=\EOB, kcuf1=\EOC, kcuu1=\EOA,
	kdch1=\E[3~, kend=\E[4~, kf1=\EOP, kf10=\E[21~,
	kf11=\E[23~, kf12=\E[24~, kf2=\EOQ, kf3=\EOR, kf4=\EOS,
	kf5=\E[15~, kf6=\E[17~, kf7=\E[18~, kf8=\E[19~, kf9=\E[20~,
	khome=\E[1~, kich1=\E[2~, kmous=\E[M, knp=\E[6~, kpp=\E[5~,
	nel=\EE, op=\E[39;49m, rc=\E8, rev=\E[7m, ri=\EM, rmacs=^O,
	rmcup=\E[?1049l, rmir=\E[4l, rmkx=\E[?1l\E>, rmso=\E[23m,
	rmul=\E[24m, rs2=\Ec\E[?1000l\E[?25h, sc=\E7,
	setab=\E[4%p1%dm, setaf=\E[3%p1%dm,
	sgr=\E[0%?%p6%t;1%;%?%p1%t;3%;%?%p2%t;4%;%?%p3%t;7%;%?%p4%t;5%;m%?%p9%t\016%e\017%;,
	sgr0=\E[m\017, smacs=^N, smcup=\E[?1049h, smir=\E[4h,
	smkx=\E[?1h\E=, smso=\E[3m, smul=\E[4m, tbc=\E[3g,
#	Reconstructed via infocmp from file: /usr/share/terminfo/x/xterm-256color
xterm-256color|xterm with 256 colors,
	am, bce, ccc, km, mc5i, mir, msgr, npc, xenl,
	colors#256, cols#80, it#8, lines#24, pairs#32767,
	acsc=``aaffggiijjkkllmmnnooppqqrrssttuuvvwwxxyyzz{{||}}~~,
	bel=^G, blink=\E[5m, bold=\E[1m, cbt=\E[Z, civis=\E[?25l,
	clear=\E[H\E[2J, cnorm=\E[?12l\E[?25h, cr=^M,
	csr=\E[%i%p1%d;%p2%dr, cub=\E[%p1%dD, cub1=^H,
	cud=\E[%p1%dB, cud1=^J, cuf=\E[%p1%dC, cuf1=\E[C,
	cup=\E[%i%p1%d;%p2%dH, cuu=\E[%p1%dA, cuu1=\E[A,
	cvvis=\E[?12;25h, dch=\E[%p1%dP, dch1=\E[P, dl=\E[%p1%dM,
	dl1=\E[M, ech=\E[%p1%dX, ed=\E[J, el=\E[K, el1=\E[1K,
	flash=\E[?5h$<100/>\E[?5l, home=\E[H, hpa=\E[%i%p1%dG,
	ht=^I, hts=\EH, ich=\E[%p1%d@, il=\E[%p1%dL, il1=\E[L,
	ind=^J, indn=\E[%p1%dS,
	initc=\E]4;%p1%d;rgb\:%p2%{255}%*%{1000}%/%2.2X/%p3%{255}%*%{1000}%/%2.2X/%p4%{255}%*%{1000}%/%2.2X\E\\,
	invis=\E[8m, is2=\E[!p\E[?3;4l\E[4l\E>, kDC=\E[3;2~,
	kEND=\E[1;2F, kHOM=\E[1;2H, kIC=\E[2;2~, kLFT=\E[1;2D,
	kNXT=\E[6;2~, kPRV=\E[5;2~, kRIT=\E[1;2C, kb2=\EOE,
	kbs=\177, kcbt=\E[Z, kcub1=\EOD, kcud1=\EOB, kcuf1=\EOC,
	kcuu1=\EOA, kdch1=\E[3~, kend=\EOF, kent=\EOM, kf1=\EOP,
	kf10=\E[21~, kf11=\E[23~, kf12=\E[24~, kf13=\E[1;2P,
	kf14=\E[1;2Q, kf15=\E[1;2R, kf16=\E[1;2S, kf17=\E[15;2~,
	kf18=\E[17;2~, kf19=\E[18;2~, kf2=\EOQ, kf20=\E[19;2~,
	kf21=\E[20;2~, kf22=\E[21;2~, kf23=\E[23;2~,
	kf24=\E[24;2~, kf25=\E[1;5P, kf26=\E[1;5Q, kf27=\E[1;5R,
	kf28=\E[1;5S, kf29=\E[15;5~, kf3=\EOR, kf30=\E[17;5~,
	kf31=\E[18;5~, kf32=\E[19;5~, kf33=\E[20;5~,
	kf34=\E[21;5~, kf35=\E[23;5~, kf36=\E[24;5~,
	kf37=\E[1;6P, kf38=\E[1;6Q, kf39=\E[1;6R, kf4=\EOS,
	kf40=\E[1;6S, kf41=\E[15;6~, kf42=\E[17;6~,
	kf43=\E[18;6~, kf44=\E[19;6~, kf45=\E[20;6~,
	kf46=\E[21;6~, kf47=\E[23;6~, kf48=\E[24;6~,
	kf49=\E[1;3P, kf5=\E[15~, kf50=\E[1;3Q, kf51=\E[1;3R,
	kf52=\E[1;3S, kf53=\E[15;3~, kf54=\E[17;3~,
	kf55=\E[18;3~, kf56=\E[19;3~, kf57=\E[20;3~,
	kf58=\E[21;3~, kf59=\E[23;3~, kf6=\E[17~, kf60=\E[24;3~,
	kf61=\E[1;4P, kf62=\E[1;4Q, kf63=\E[1;4R, kf7=\E[18~,
	kf8=\E[19~, kf9=\E[20~, khome=\EOH, kich1=\E[2~,
	kind=\E[1;2B, kmous=\E[M, knp=\E[6~, kpp=\E[5~,
	kri=\E[1;2A, mc0=\E[i, mc4=\E[4i, mc5=\E[5i, meml=\El,
	memu=\Em, op=\E[39;49m, rc=\E8, rev=\E[7m, ri=\EM,
	rin=\E[%p1%dT, rmacs=\E(B, rmam=\E[?7l, rmcup=\E[?1049l,
	rmir=\E[4l, rmkx=\E[?1l\E>, rmm=\E[?1034l, rmso=\E[27m,
	rmul=\E[24m, rs1=\Ec, rs2=\E[!p\E[?3;4l\E[4l\E>, sc=\E7,
	setab=\E[%?%p1%{8}%<%t4%p1%d%e%p1%{16}%<%t10%p1%{8}%-%d%e48;5;%p1%d%;m,
	setaf=\E[%?%p1%{8}%<%t3%p1%d%e%p1%{16}%<%t9%p1%{8}%-%d%e38;5;%p1%d%;m,
	sgr=%?%p9%t\E(0%e\E(B%;\E[0%?%p6%t;1%;%?%p2%t;4%;%?%p1%p3%|%t;7%;%?%p4%t;5%;%?%p7%t;8%;m,
	sgr0=\E(B\E[m, smacs=\E(0, smam=\E[?7h, smcup=\E[?1049h,
	smir=\E[4h, smkx=\E[?1h\E=, smm=\E[?1034h, smso=\E[7m,
	smul=\E[4m, tbc=\E[3g, u6=\E[%i%d;%dR, u7=\E[6n,
	u8=\E[?1;2c, u9=\E[c, vpa=\E[%i%p1%dd,
EOFTIC

/usr/bin/tic /tmp/terminfo.src
rm /tmp/terminfo.src

echo "Clearing log files and zeroing disk, this might take a while"
cp /dev/null /var/adm/messages
cp /dev/null /var/log/syslog
cp /dev/null /var/adm/wtmpx
cp /dev/null /var/adm/utmpx
dd if=/dev/zero of=/EMPTY bs=1024
rm -f /EMPTY

