# Check if burnupi/plana
if !node['hostname'].match(/^(plana|burnupi|mira|vpm|tala)/)
 raise "This recipe is only intended for plana/burnupi/mira/vpm/tala hosts"
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

