execute "Fix broken old broken cloud-init" do
  command <<-'EOH'
  hostname=$(cat /etc/hostname | cut -d'.' -f1 || true)
  hostcheck=$(grep -c HOSTNAME= /etc/sysconfig/network || true)
  good=$(grep -ic $hostname /etc/sysconfig/network || true)
  if [ $good -lt 1 ]
  then
     if [ $hostcheck -gt 0 ]
     then
      sed -i "s/HOSTNAME=.*/HOSTNAME=$hostname/g" /etc/sysconfig/network || true
     else
      echo HOSTNAME=$hostname >> /etc/sysconfig/network
     fi
  fi
  EOH
end


