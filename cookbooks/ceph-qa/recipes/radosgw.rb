# TODO once we're building more than squeeze, parameterize distro name

#Apt priority
file '/etc/apt/preferences.d/ceph.pref' do
  owner 'root'
  group 'root'
  mode '0644'
    content <<-EOH
Package: *
Pin: origin gitbuilder.ceph.com
Pin-Priority: 999
EOH
end
file '/etc/apt/preferences.d/ceph-redhat.pref' do
  owner 'root'
  group 'root'
  mode '0644'
    content <<-EOH
Package: *
Pin: origin gitbuilder.ceph.redhat.com
Pin-Priority: 998
EOH
end


file '/etc/apt/sources.list.d/radosgw.list' do
  owner 'root'
  group 'root'
  mode '0644'

  if node[:platform_version] == "12.04"
    # pull from precise gitbuilder
    content <<-EOH
deb http://gitbuilder.ceph.com/libapache-mod-fastcgi-deb-precise-x86_64-basic/ref/master/ precise main
deb http://gitbuilder.ceph.com/apache2-deb-precise-x86_64-basic/ref/master/ precise main
EOH
  elsif node[:platform_version] == "11.10"
    # pull from oneiric gitbuilder
    content <<-EOH
deb http://gitbuilder.ceph.com/apache2-deb-oneiric-x86_64-basic/ref/master/ oneiric main
deb http://gitbuilder.ceph.com/libapache-mod-fastcgi-deb-oneiric-x86_64-basic/ref/master/ oneiric main
EOH
  elsif node[:platform_version] == "12.10"
    if node[:languages][:ruby][:host_cpu] == "arm"
      # pull from arm repo
      content <<-EOH
deb http://gitbuilder.ceph.com/apache2-deb-quantal-armv7l-basic/ref/master/ quantal main
deb http://gitbuilder.ceph.com/libapache-mod-fastcgi-deb-quantal-armv7l-basic/ref/master/ quantal main
EOH
    end
  elsif node[:platform_version] == "14.04"
    # pull from oneiric gitbuilder
    content <<-EOH
deb http://gitbuilder.ceph.com/apache2-deb-trusty-x86_64-basic/ref/master/ trusty main
deb http://gitbuilder.ceph.com/libapache-mod-fastcgi-deb-trusty-x86_64-basic/ref/master/ trusty main
EOH
  else
    # hrm!
  end
end

# TODO do this only once, after all sources.list manipulation is done,
# but before first package directive (that uses non-default sources)
execute 'apt-get update' do
  command <<-'EOH'
    apt-get update || apt-get update || true
  EOH
end

package 'apache2' do
  action :upgrade
end
package 'libapache2-mod-fastcgi' do
  action :upgrade
end
package 'libfcgi0ldbl'

service "apache2" do
  action [ :disable, :stop ]
end
