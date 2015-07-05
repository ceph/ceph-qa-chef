# Use our pip mirror
include_recipe "ceph-qa::pip_mirror"

#Fail if ubuntu != 1000 UID
if node['etc']['passwd']['ubuntu']['uid'] != 1000
 raise "The ubuntu user should be UID of 1000. It is not. Re-image this machine."
end


# remove ceph packages (if any)
#  FIXME: possibly remove this when teuthology starts using debs.
execute "remove ceph packages" do
  command <<-EOH
  apt-get purge -f -y --force-yes ceph || true
  apt-get purge -f -y --force-yes ceph-common || true
  apt-get purge -f -y --force-yes libcephfs1 || true
  apt-get purge -f -y --force-yes radosgw || true
  apt-get purge -f -y --force-yes python-ceph || true
  apt-get purge -f -y --force-yes librbd1 || true
  apt-get purge -f -y --force-yes librados2 || true
  EOH
end
execute "remove /etc/ceph" do
  command 'rm -rf /etc/ceph'
end
execute "remove old source entries" do
  command 'rm -f /etc/apt/sources.list.d/*.list'
end

#Setup calxeda repo for quantal arm nodes.
if node[:languages][:ruby][:host_cpu] == "arm"
  case node[:platform]
  when "ubuntu"
    case node[:platform_version]
    when "12.10"
      cookbook_file '/etc/apt/sources.list.d/calxeda.list' do
        source "calxeda-quantal.list"
        mode 0644
        owner "root"
        group "root"
      end
    end
  end
end

#Setup sources.list to use our apt mirror.
if node[:languages][:ruby][:host_cpu] != "arm"
  case node[:platform]
  when "ubuntu"
    case node[:platform_version]
    when "12.04"
      cookbook_file '/etc/apt/sources.list' do
        source "sources.list.precise"
        mode 0644
        owner "root"
        group "root"
      end
    when "12.10"
      cookbook_file '/etc/apt/sources.list' do
        source "sources.list.quantal"
        mode 0644
        owner "root"
        group "root"
      end
    when "14.04"
      cookbook_file '/etc/apt/sources.list' do
        source "sources.list.trusty"
        mode 0644
        owner "root"
        group "root"
      end
    end
  end
end

if node[:languages][:ruby][:host_cpu] != "arm"
  cookbook_file '/etc/cron.weekly/kernel-clean' do
    source "kernel-clean"
    mode 0755
    owner "root"
    group "root"
  end
  execute "Restarting Cron" do
    command "service cron restart"
  end
end

#Repo for libgoogle/tcmalloc.
if node[:languages][:ruby][:host_cpu] == "arm"
  cookbook_file '/etc/apt/sources.list.d/perftools.list' do
    source "perftools.list"
    mode 0644
    owner "root"
    group "root"
  end
end

execute "add autobuild gpg key to apt" do
  command <<-EOH
  wget -q -O- 'http://git.ceph.com/?p=ceph.git;a=blob_plain;f=keys/autobuild.asc;hb=HEAD' \
  | sudo apt-key add -
  EOH
end

#tgt/libleveldb:
tgt_content = "deb http://ceph.com/packages/ceph-extras/debian/ #{node.lsb.codename} main\n"
file '/etc/apt/sources.list.d/ceph-extras.list' do
  owner 'root'
  group 'root'
  mode '0644'
  only_if { node[:platform_version] == "12.04" }
  content tgt_content
end

# blkin libraries, only trusty has new enough lttng for these
if node[:platform] == "ubuntu" and node[:platform_version] == "14.04"
  file '/etc/apt/sources.list.d/blkin.list' do
    owner 'root'
    group 'root'
    mode '0644'
    content "deb [arch=amd64] http://apt-mirror.front.sepia.ceph.com/blkin/ trusty main\n"
  end
  execute "apt-get update" do
    command "apt-get update"
  end
  package 'blkin'
  package 'lttng-tools'
end

execute "add release gpg key to apt" do
  command <<-EOH
  wget -q -O- 'http://git.ceph.com/?p=ceph.git;a=blob_plain;f=keys/release.asc' \
  | sudo apt-key add -
  EOH
end

directory '/home/ubuntu/.cpan/CPAN/' do
  owner "ubuntu"
  group "ubuntu"
  mode "0755"
  recursive true
end
cookbook_file '/home/ubuntu/.cpan/CPAN/MyConfig.pm' do
  source "CPANConfig.pm"
  mode 0755
  owner "ubuntu"
  group "ubuntu"
end

directory '/root/.cpan/CPAN/' do
  owner "root"
  group "root"
  mode "0755"
  recursive true
end
cookbook_file '/root/.cpan/CPAN/MyConfig.pm' do
  source "CPANConfig.pm"
  mode 0755
  owner "root"
  group "root"
end


# do radosgw recipe first, because it updates the apt sources and runs
# apt-get update for us too.
if node[:platform] == "ubuntu" and (node[:platform_version] == "10.10" or node[:platform_version] == "11.10" or node[:platform_version] == "12.04" or node[:platform_version] == "12.10" or node[:platform_version] == "14.04")
  include_recipe "ceph-qa::radosgw"
else
  Chef::Log.info("radosgw not supported on: #{node[:platform]} #{node[:platform_version]}")

  # der.. well, run update.
  execute 'apt-get update' do
    command <<-'EOH'
      apt-get update || apt-get update || true
    EOH
  end
end


if node[:languages][:ruby][:host_cpu] == "arm"
  if node[:platform_version] == "12.10"
    execute "import calxeda key" do
      command "apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 86E4C5D27E957C4D"
    end
    execute "apt-get update" do
      command "apt-get update"
    end
    package 'linux-image-3.5.0-1000-highbank'
    package 'linux-tools-common'
    package 'linux-tools-3.5.0-1000'
  end
end

package 'apt' do
  action :upgrade
end


# for s3-tests
package 'python-pip'
package 'python-virtualenv'
package 'python-dev'
package 'libevent-dev'

#CPAN
package 'perl'
package 'libwww-perl'

package 'lsb-release'
package 'build-essential'
package 'sysstat'
package 'gdb'
package 'python-configobj'
package 'python-gevent'

# for running ceph
package 'libedit2'
package 'libssl0.9.8'
if node[:platform_version] >= "12.10"
  package 'libgoogle-perftools4'
else
  package 'libgoogle-perftools0'
end

if node[:platform_version] >= "12.10"
  if node[:platform_version] >= "13.10"
    package 'libboost-thread1.54.0'
  else
    package 'libboost-thread1.49.0'
  end
else
  package 'libboost-thread1.46.1'
end


package 'cryptsetup-bin'
package 'xfsprogs'
package 'gdisk'
package 'parted'

if node[:languages][:ruby][:host_cpu] != "arm"
  # for setting BIOS settings
  package 'smbios-utils'
end

case node[:platform]
when "ubuntu"
  case node[:platform_version]
  when "10.10"
    package 'libcrypto++8'
  when "11.10", "12.04", "12.10", "13.04", "13.10", "14.04"
    package 'libcrypto++9'
  else
    Chef::Log.fatal("Unknown ubuntu release: #{node[:platform_version]}")
    exit 1
  end
else
  Chef::Log.fatal("Unknown platform: #{node[:platform]}")
  exit 1
end

#openmpi-common conflicts with mpitch stuff.
package 'openmpi-common' do
  action :remove
end

package 'libuuid1'
package 'libfcgi'
package 'btrfs-tools'

# for compiling helpers and such
package 'libatomic-ops-dev'

# used by workunits
package 'git-core'
package 'attr'
package 'dbench'
package 'bonnie++'
package 'iozone3'

# No ltp-kernel-test package on quantal
if node[:platform_version] < "12.10"
  package 'ltp-kernel-test'
end
package 'valgrind'
package 'python-nose'
package 'mpich2'
if node[:platform_version] <= "13.04"
  package 'libmpich2-3'
else
  package 'mpich'
end
package 'libmpich2-dev'
package 'ant'

# used by the xfstests tasks
package 'libtool'
package 'automake'
package 'gettext'
package 'uuid-dev'
package 'libacl1-dev'
package 'bc'
package 'xfsdump'
package 'dmapi'
package 'xfslibs-dev'
package 'libattr1-dev'
package 'quota'
package 'libcap2-bin'
package 'libncurses5-dev'
package 'lvm2'
package 'gawk'

ruby_block "edit LVM config" do
  block do
    rc = Chef::Util::FileEdit.new("/etc/lvm/lvm.conf")
    rc.search_file_replace_line(/types =/, "types = [ \"rbd\", 1024 ]")
    rc.write_file
  end
end

#For Mark Nelson:
if node[:languages][:ruby][:host_cpu] != "arm"
  package 'sysprof'
end
package 'vim'
package 'pdsh'
package 'collectl'
service "collectl" do
  action [:disable,:stop]
end

# for blktrace and seekwatcher
package 'blktrace'
package 'python-numpy'
package 'python-matplotlib'
package 'mencoder'

# for qemu
if node[:platform_version] >= "13.04"
  package 'qemu-system-x86'
else
  package 'kvm'
end
package 'genisoimage'

# for json_xs to investigate JSON by hand
package 'libjson-xs-perl'
# for pretty-printing xml
package 'xml-twig-tools'

# for java bindings, hadoop, etc.
package 'default-jdk'
package 'junit4'

#tgt
package 'tgt' do
  options "--allow-unauthenticated"
end
package 'open-iscsi'
# for disk/etc monitoring
package 'smartmontools'
package 'nagios-nrpe-server'

# for samba testing
package 'cifs-utils'

#DistCC for arm
package 'distcc'

if node[:languages][:ruby][:host_cpu] == "arm"
  cookbook_file '/etc/default/distcc' do
    source "distcc"
    mode 0644
    owner "root"
    group "root"
  end
  service "distcc" do
    action [:enable,:start]
  end
end

if node[:languages][:ruby][:host_cpu] != "arm"
  if node[:platform] == "ubuntu"
    file '/etc/grub.d/02_force_timeout' do
      owner 'root'
      group 'root'
      mode '0755'
      content <<-EOH
    cat <<EOF
    set timeout=5
    EOF
      EOH
    end
  end
end

#NTP
include_recipe "ceph-qa::ntp-deb"

execute "add user_xattr to root mount options in fstab" do
  # fugly but works! which is more than i can say for the "mount"
  # resource, which doesn't seem to like a rootfs with an unknown UUID
  # at all.
  command <<-'EOH'
    perl -pe 'if (m{^([^#]\S*\s+/\s+\S+\s+)(\S+)(\s+.*)$}) { $_="$1$2,user_xattr$3\n" unless $2=~m{(^|,)user_xattr(,|$)}; }' -i.bak /etc/fstab
  EOH
end

execute "enable xattr for this boot" do
  command "mount -o remount,user_xattr /"
end

execute "allow fuse mounts to be used by non-owners" do
  command "grep -q ^user_allow_other /etc/fuse.conf || echo user_allow_other >> /etc/fuse.conf"
end

execute "add user ubuntu to group fuse" do
  command "adduser ubuntu fuse"
end

file '/etc/fuse.conf' do
  mode "0644"
end

execute "add user ubuntu to group kvm" do
  command "adduser ubuntu kvm"
end

directory '/home/ubuntu/.ssh' do
  owner "ubuntu"
  group "ubuntu"
  mode "0755"
end

execute "set up ssh keys" do
  command <<-'EOH'
    URL=https://raw.github.com/ceph/keys/autogenerated/ssh/%s.pub
    export URL
    ssh-import-id -o /home/ubuntu/.ssh/authorized_keys @all
    sort -u </home/ubuntu/.ssh/authorized_keys >/home/ubuntu/.ssh/authorized_keys.sort
    mv /home/ubuntu/.ssh/authorized_keys.sort /home/ubuntu/.ssh/authorized_keys
    chown ubuntu.ubuntu /home/ubuntu/.ssh/authorized_keys
  EOH
end

#Unfortunately no megacli/arecacli package for ubuntu -- Needed for raid monitoring and smart.
cookbook_file '/usr/sbin/megacli' do
  source "megacli"
  mode 0755
  owner "root"
  group "root"
end
cookbook_file '/usr/sbin/cli64' do
  source "cli64"
  mode 0755
  owner "root"
  group "root"
end


#Custom netsaint scripts for raid/disk/smart monitoring:
directory "/usr/libexec/" do
  owner "root"
  group "root"
  mode "0755"
  action :create
end
cookbook_file '/usr/libexec/raid.pl' do
  source "raid.pl"
  mode 0755
  owner "root"
  group "root"
end
cookbook_file '/usr/libexec/smart.pl' do
  source "smart.pl"
  mode 0755
  owner "root"
  group "root"
end
cookbook_file '/usr/libexec/diskusage.pl' do
  source "diskusage.pl"
  mode 0755
  owner "root"
  group "root"
end


#SSH template for no strict host checking:
cookbook_file '/etc/ssh/ssh_config' do
  source "ssh_config"
  mode 0755
  owner "root"
  group "root"
end

execute "add ubuntu to disk group" do
  command <<-'EOH'
    usermod -a -G disk ubuntu
  EOH
end


if node[:languages][:ruby][:host_cpu] != "arm"
  execute "enable kernel logging to console" do
    command <<-'EOH'
      set -e
      f=/etc/default/grub
      #Mira are ttyS2
      miracheck=$(uname -n | grep -ic mira || true)
      typicacheck=$(uname -n | grep -ic typica || true)
      # if it has a setting, make sure it's to ttyS1
      if [ $miracheck -gt 0 ]
      then
      if grep -q '^GRUB_CMDLINE_LINUX=.*".*console=tty0 console=ttyS[012],115200' $f; then sed 's/console=ttyS[012]/console=ttyS2/' <$f >$f.chef; fi
      else
      if [ $typicacheck -gt 0 ]
      then
      if grep -q '^GRUB_CMDLINE_LINUX=.*".*console=ttyS[012],115200' $f; then sed 's/console=ttyS[012]/console=ttyS0/' <$f >$f.chef; fi
      else
      if grep -q '^GRUB_CMDLINE_LINUX=.*".*console=ttyS[01],115200' $f; then sed 's/console=ttyS[01]/console=ttyS1/' <$f >$f.chef; fi
      fi
      fi

      # if it has no setting, add it
      if [ $miracheck -gt 0 ]
      then
      if ! grep -q '^GRUB_CMDLINE_LINUX=.*".* console=tty0 console=ttyS[012],115200.*' $f; then sed 's/^GRUB_CMDLINE_LINUX="\(.*\)"$/GRUB_CMDLINE_LINUX="\1 console=tty0 console=ttyS2,115200"/' <$f >$f.chef; fi
      else
      if [ $typicacheck -gt 0 ]
      then
      if ! grep -q '^GRUB_CMDLINE_LINUX=.*".*console=ttyS[012],115200.*' $f; then sed 's/^GRUB_CMDLINE_LINUX="\(.*\)"$/GRUB_CMDLINE_LINUX="\1 console=ttyS0,115200"/' <$f >$f.chef; fi
      else
      if ! grep -q '^GRUB_CMDLINE_LINUX=.*".* console=ttyS[01],115200.*' $f; then sed 's/^GRUB_CMDLINE_LINUX="\(.*\)"$/GRUB_CMDLINE_LINUX="\1 console=ttyS1,115200"/' <$f >$f.chef; fi
      fi
      fi


      # if we did something; move it into place.  update-grub done below.
      if [ -f $f.chef ] ; then mv $f.chef $f; fi

      #Remove quiet kernel output:
      sed -i 's/quiet//g' $f
      serialcheck=$(grep -ic serial $f || true)
      if [ $serialcheck -eq 0 ]
      then
      if [ $miracheck -gt 0 ]
      then
      echo "" >> $f
      echo "GRUB_TERMINAL=serial" >> $f
      echo "GRUB_SERIAL_COMMAND=\"serial --unit=2 --speed=115200 --stop=1\"" >> $f
      else
      if [ $typicacheck -gt 0 ]
      then
      echo "" >> $f
      echo "GRUB_TERMINAL=serial" >> $f
      echo "GRUB_SERIAL_COMMAND=\"serial --unit=0 --speed=115200 --stop=1\"" >> $f
      else
      echo "" >> $f
      echo "GRUB_TERMINAL=serial" >> $f
      echo "GRUB_SERIAL_COMMAND=\"serial --unit=1 --speed=115200 --stop=1\"" >> $f
      fi
      fi
      fi

      #Don't hide grub menu

      sed -i 's/^GRUB_HIDDEN_TIMEOUT.*//g' $f

      #No PCI reallocation (breaks 10 gig on burnupi)
      sed -i 's;" console=ttyS;"pci=realloc=off console=ttyS;g' $f

      #set verbose kernel output via dmesg:
      if ! grep -q dmesg /etc/rc.local; then sed -i 's/^exit 0/dmesg -n 7\nexit 0/g' /etc/rc.local; fi
    EOH
  end
end

if node[:languages][:ruby][:host_cpu] != "arm"
  execute 'update-grub' do
  end
end


if node[:languages][:ruby][:host_cpu] != "arm"
  cookbook_file '/etc/init/ttyS1.conf' do
     source 'ttyS1.conf'
     mode 0644
     owner "root"
     group "root"
     notifies :start, "service[ttyS1]"
  end

  if node['hostname'].match(/^(mira)/)
    cookbook_file '/etc/init/ttyS2.conf' do
       source 'ttyS2.conf'
       mode 0644
       owner "root"
       group "root"
       notifies :start, "service[ttyS2]"
    end
  end

  service "ttyS1" do
    # Default provider for Ubuntu is Debian, and :enable doesn't work
    # for Upstart services unless we change provider.  Assume Upstart
    provider Chef::Provider::Service::Upstart
    action [:enable,:start]
  end

  if node['hostname'].match(/^(mira)/)
    service "ttyS2" do
      # Default provider for Ubuntu is Debian, and :enable doesn't work
      # for Upstart services unless we change provider.  Assume Upstart
      provider Chef::Provider::Service::Upstart
      action [:enable,:start]
    end
  end
end


#NFS servers uport per David Z.
package 'nfs-kernel-server'

#Static IP
package 'ipcalc'

if !node['hostname'].match(/^(vpm)/)

  execute "set up static IP in /etc/hosts" do
    command <<-'EOH'
      cidr=$(ip addr show dev eth0 | grep -iw inet | awk '{print $2}')
      ip=$(echo $cidr | cut -d'/' -f1)
      hostname=$(uname -n)
      sed -i "s/^127.0.1.1[\t]$hostname.front.sepia.ceph.com/$ip\t$hostname.front.sepia.ceph.com/g" /etc/hosts
    EOH
  end
  execute "set up static IP and 10gig interface" do
    command <<-'EOH'
      dontrun=$(grep -ic inet\ static /etc/network/interfaces)
      if [ $dontrun -eq 0 ]
      then
      cidr=$(ip addr show dev eth0 | grep -iw inet | awk '{print $2}')
      ip=$(echo $cidr | cut -d'/' -f1)
      miracheck=$(uname -n | grep -ic mira)
      armcheck=$(uname -m | grep -ic arm)
      netmask=$(ipcalc $cidr | grep -i netmask | awk '{print $2}')
      gateway=$(route -n | grep ^0.0 | awk '{print $2}')
      broadcast=$(ipcalc $cidr | grep -i broad | awk '{print $2}')
      octet1=$(echo $ip | cut -d'.' -f1)
      octet2=$(echo $ip | cut -d'.' -f2)
      octet3=$(echo $ip | cut -d'.' -f3)
      octet4=$(echo $ip | cut -d'.' -f4)
      octet3=$(($octet3 + 13))
      if [ $armcheck -gt 0 ]
      then
      dev=eth1
      else
      dev=eth2
      fi
      if [ $miracheck -gt 0 ]
      then
      sed -i "s/iface eth0 inet dhcp/\
      iface eth0 inet static\n\
            address $ip\n\
            netmask $netmask\n\
            gateway $gateway\n\
            broadcast $broadcast\n\
      \n\
      /g" /etc/network/interfaces
      else
      typicacheck=$(uname -n | grep -ic typica)
      if [ $typicacheck -gt 0 ]
      then
      sed -i "s/iface eth0 inet dhcp/\
      iface eth0 inet static\n\
            address $ip\n\
            netmask $netmask\n\
            gateway $gateway\n\
            broadcast $broadcast\n\
            up route add -net 10.99.118.0\/24 gw 172.20.133.1 dev eth0\n\
            up route add -net 10.214.128.0\/20 gw 172.20.133.1 dev eth0\n\
            up route add -net 10.214.0.0\/20 gw 172.20.133.1 dev eth0\n\
      \n\
      /g" /etc/network/interfaces
      else
      sed -i "s/iface eth0 inet dhcp/\
      iface eth0 inet static\n\
            address $ip\n\
            netmask $netmask\n\
            gateway $gateway\n\
            broadcast $broadcast\n\
      \n\
      auto $dev\n\
      iface $dev inet static\n\
            address $octet1.$octet2.$octet3.$octet4\n\
            netmask $netmask\
      /g" /etc/network/interfaces
      fi
      fi
      fi
    EOH
  end
end

execute "Installing CPAN Amazon::S3" do
  command "cpan  Amazon::S3"
end

if node['hostname'].match(/^(plana|burnupi|mira|vpm|tala|saya|dubia|apama|rhoda|magna|typica)/)
#Static DNS
  file '/etc/resolvconf/resolv.conf.d/base' do
    owner 'root'
    group 'root'
    mode '0755'
    content <<-EOH
      nameserver 10.214.128.4
      nameserver 10.214.128.5
      search front.sepia.ceph.com sepia.ceph.com
    EOH
  end
end

if node['hostname'].match(/^(magna)/)
  file '/etc/resolvconf/resolv.conf.d/base' do
    owner 'root'
    group 'root'
    mode '0755'
    content <<-EOH
      nameserver 10.10.160.1
      search ceph.redhat.com front.sepia.ceph.com sepia.ceph.com
    EOH
  end
end

if node['hostname'].match(/^(typica)/)
  file '/etc/resolvconf/resolv.conf.d/base' do
    owner 'root'
    group 'root'
    mode '0755'
    content <<-EOH
      nameserver 172.20.132.1
      nameserver 172.20.132.2
      search front.sepia.ceph.com sepia.ceph.com
    EOH
  end
end


#Nagios sudo (for raid utilities)
file '/etc/sudoers.d/90-nagios' do
  owner 'root'
  group 'root'
  mode '0440'
  content <<-EOH
    nagios ALL=NOPASSWD: /usr/sbin/megacli, /usr/sbin/cli64, /usr/sbin/smartctl, /usr/sbin/smartctl
  EOH
end

#Modules @ Boot
cookbook_file '/etc/modules' do
  source "modules"
  owner 'root'
  group 'root'
  mode '0644'
end

#Nagios nrpe config
cookbook_file '/etc/nagios/nrpe.cfg' do
  source "nrpe.cfg"
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, "service[nagios-nrpe-server]"
end

service "nagios-nrpe-server" do
  action [:enable,:start]
end

#nagios nrpe settings
file '/etc/default/nagios-nrpe-server' do
  owner 'root'
  group 'root'
  mode '0644'
  content <<-EOH
    DAEMON_OPTS="--no-ssl"
  EOH
end

if node['hostname'].match(/^(plana|burnupi|mira|vpm|tala|saya|dubia|apama|rhoda|magna|typica)/)
  execute "Restarting resolvdns" do
    command <<-'EOH'
      sudo service resolvconf restart
    EOH
  end
end

execute "Enabling auto-fsck fix to prevent boot hangup" do
  command <<-'EOH'
    sudo sed -i 's/FSCKFIX=no/FSCKFIX=yes/g' /etc/default/rcS || true
  EOH
end

bash "ssh_max_sessions" do
  user "root"
  cwd "/etc/ssh"
  code <<-EOT
    echo "MaxSessions 1000" >> sshd_config
  EOT
  not_if {File.read("/etc/ssh/sshd_config") =~ /MaxSessions/}
end

if node[:platform_version] >= "13.04"
  execute "Restarting SSH via service on Saucy and above" do
    command <<-'EOH'
      sudo service ssh restart
    EOH
  end
else
  service "ssh" do
    action [:restart]
  end
end

# include a dummy nfs export so that the nfs kernel server starts
file '/etc/exports' do
 owner 'root'
  group 'root'
  mode '0644'
  content <<-EOH
# /etc/exports: the access control list for filesystems which may be exported
#               to NFS clients.  See exports(5).
#
# Example for NFSv2 and NFSv3:
# /srv/homes       hostname1(rw,sync,no_subtree_check) hostname2(ro,sync,no_subtree_check)
#
# Example for NFSv4:
# /srv/nfs4        gss/krb5i(rw,sync,fsid=0,crossmnt,no_subtree_check)
# /srv/nfs4/homes  gss/krb5i(rw,sync,no_subtree_check)
#
# dummy export just to make nfs_kernel_start
/tmp    1.1.1.1(ro,sync,no_subtree_check)
EOH
end
if node[:platform_version] >= "14.04"
  execute "Restarting NFS via service on Trusty and above" do
    command <<-'EOH'
      sudo service nfs-kernel-server restart
    EOH
  end
end

file '/ceph-qa-ready' do
  content "ok\n"
end

