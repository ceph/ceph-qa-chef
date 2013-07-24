#Network Management causing bind errors on monitors
#Service method does not work right here either.

if !node['hostname'].match(/^(vpm)/)
  execute "Disabling Network manager" do
    command <<-'EOH'
    chkconfig network on
    chkconfig NetworkManager off
    service NetworkManager stop
    EOH
  end
end

package 'redhat-lsb'
package 'sysstat'
package 'gdb'
package 'python-configobj'
  
# for running ceph
package 'libedit'
package 'openssl-devel'
package 'google-perftools-devel'
package 'boost-thread'
package 'xfsprogs'
package 'gdisk'
package 'parted'
package 'libgcrypt'
package 'cryptopp-devel'
package 'cryptopp'

#ceph deploy
package 'python-virtualenv'

# for setting BIOS settings
package 'smbios-utils'

package 'openssl'

package 'libuuid'
package 'fcgi-devel'
package 'btrfs-progs'
  
# for copmiling helpers and such
package 'libatomic_ops-devel'
 
# used by workunits
package 'git-all'
package 'attr'
package 'valgrind'
package 'python-nose'
package 'mpich2'
package 'mpich2-devel'
package 'ant'
package 'dbench'
package 'bonnie++'
package 'tiobench'
  
# used by the xfstests tasks
package 'libtool'
package 'automake'
package 'gettext'
package 'uuid-devel'
package 'libacl-devel'
package 'bc'
package 'xfsdump'
  
# for blktrace and seekwatcher
package 'blktrace'
package 'numpy'
package 'python-matplotlib'
  
# for qemu:
package 'qemu-kvm'
package 'qemu-kvm-tools'
package 'genisoimage'

# for json_xs to investigate JSON by hand
package 'perl-JSON'
  
# for pretty-printing xml
package 'perl-XML-Twig'
  
# for java bindings, hadoop, etc.
package 'java-1.7.0-openjdk-devel'
package 'junit4'
  
# for disk/etc monitoring
package 'smartmontools'
package 'ntp'

cookbook_file '/etc/ntp.conf' do
  source "ntp.conf"
  mode 0644
  owner "root"
  group "root"
  notifies :restart, "service[ntpd]"
end
  
service "ntpd" do
  action [:enable,:start]
end

service "iptables" do
  action [:disable,:stop]
end

cookbook_file '/etc/security/limits.d/remote.conf' do
  source "remote.conf"
  mode 0644
  owner "root"
  group "root"
end


file '/etc/fuse.conf' do
  mode "0644"
end

execute "add user ubuntu to group kvm" do
  command "gpasswd -a ubuntu kvm"
end

execute "Make raid/smart scripts work on centos/fedora" do
  command "if [ ! -e /usr/bin/lspci ]; then ln -s /sbin/lspci /usr/bin/lspci; fi"
end

directory '/home/ubuntu/.ssh' do
  owner "ubuntu"
  group "ubuntu"
  mode "0755"
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

#NFS servers uport per David Z.
package 'nfs-utils'

# Remove requiretty, not visiblepw and set unlimited security/limits.conf soft core value. Allow authorized_keys2
execute "Sudoers and security/lmits.conf changes" do
  command <<-'EOH'
    sed -i 's/ requiretty/ !requiretty/g' /etc/sudoers
    sed -i 's/ !visiblepw/ visiblepw/g' /etc/sudoers
    sed -i 's/^#\*.*soft.*core.*0/\*                soft    core            unlimited/g' /etc/security/limits.conf
    sed -i 's/^AuthorizedKeysFile/#AuthorizedKeysFile/g' /etc/ssh/sshd_config
  EOH
end

service "sshd" do
  action [:restart]
end

file '/ceph-qa-ready' do
  content "ok\n"
end
