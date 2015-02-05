execute "Over-ride DNS to use RH" do
  command <<-'EOH'
    grep -q apt-mirror /etc/hosts || echo 64.90.32.37 apt-mirror.front.sepia.ceph.com | sudo tee -a /etc/hosts
    sed 's;^nameserver .*;nameserver 10.10.160.1;g' -i /etc/resolv.conf || true
    sed 's;\(^DNS[0-9]=\).*;\110.10.160.1;g' -i /etc/sysconfig/network-scripts/ifcfg-eth0 || true
  EOH
end


