# Check if burnupi/plana
if !node['hostname'].match(/^(plana|burnupi|mira|vpm|tala|saya|dubia|apama|rhoda|magna|typica)/)
 raise "This recipe is only intended for plana/burnupi/mira/vpm/tala/saya/dubia/apama/magna/typica hosts"
end


# high max open files
file '/etc/security/limits.d/ubuntu.conf' do
  owner 'root'
  group 'root'
  mode '0755'
  content <<-EOH
    ubuntu hard nofile 16384
  EOH
end


if node[:platform] == "ubuntu"
  include_recipe "ceph-qa::ubuntu"
end

if node[:platform] == "centos"
  if node[:platform_version] >= "6.0" and node[:platform_version] < "7.0"
    include_recipe "ceph-qa::centos6"
  end
  if node[:platform_version] >= "7.0" and node[:platform_version] < "8.0"
    include_recipe "ceph-qa::centos7"
  end
end

if node[:platform] == "redhat"
  if node[:platform_version] >= "6.0" and node[:platform_version] < "7.0"
    include_recipe "ceph-qa::redhat6"
  end
  if node[:platform_version] >= "7.0" and node[:platform_version] < "8.0"
    include_recipe "ceph-qa::redhat7"
  end
end

if node[:platform] == "debian"
  include_recipe "ceph-qa::debian"
end

if node[:platform] == "fedora"
  include_recipe "ceph-qa::fedora"
end

