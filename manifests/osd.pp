define cephdeploy::osd(
){

  include cephdeploy
  $user = $::ceph_deploy_user
  $disk = $name

  $mon0 = "`/bin/grep mon_initial_members /etc/ceph/ceph.conf  | /usr/bin/awk '{print \$3}' | /bin/sed '\$s/.$//'`"

  exec { "gatherkeys_$disk":
    cwd     => '/etc/ceph/bootstrap',
    user    => $user,
    provider => shell,
    command => "/bin/rm -f /etc/ceph/bootstrap/ceph.log && /usr/local/bin/ceph-deploy gatherkeys $mon0",
    require => [ Exec['install ceph'], File["/etc/sudoers.d/$user"], File['/etc/ceph/bootstrap/ceph.log'], Exec['hack pushy'] ],
    unless  => '/usr/bin/test -e /etc/ceph/bootstrap/ceph.bootstrap-osd.keyring',
  }

  exec { "zap $disk":
    cwd     => '/etc/ceph/bootstrap',
    command => "/usr/local/bin/ceph-deploy disk zap $::hostname:$disk",
    require => [ Exec['install ceph'], Exec["gatherkeys_$disk"] ],
    unless  => "/usr/bin/test -e /home/$user/zapped/$disk",
  }

  exec { "create osd $disk":
    cwd     => '/etc/ceph/bootstrap',
    command => "/usr/local/bin/ceph-deploy osd create $::hostname:$disk",
    require => Exec["zap $disk"],
    unless  => "/usr/bin/test -e /home/$user/zapped/$disk",
  }
  
  file { "/home/$user/zapped/$disk":
    ensure  => present,
    require => [ Exec["zap $disk"], Exec["create osd $disk"], File["/home/$user/zapped"] ],
  }



}
