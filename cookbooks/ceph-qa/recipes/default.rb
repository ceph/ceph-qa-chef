# Check if burnupi/plana
if !node['hostname'].match(/^(plana|burnupi|mira|vpm|tala|saya)/)
 raise "This recipe is only intended for plana/burnupi/mira/vpm/tala/saya hosts"
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
  include_recipe "ceph-qa::centos"
end

if node[:platform] == "redhat"
  include_recipe "ceph-qa::redhat"
end

if node[:platform] == "debian"
  include_recipe "ceph-qa::debian"
end

if node[:platform] == "fedora"
  include_recipe "ceph-qa::fedora"
end

