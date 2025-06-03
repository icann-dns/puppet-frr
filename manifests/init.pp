# @summary Frr routing server.
# @param owner The owner of the frr configuration files.
# @param group The group of the frr configuration files.
# @param mode The mode of the frr configuration files.
# @param package The package to install.
# @param service The service to manage.
# @param enable Whether to enable the zebra daemon.
# @param zebra_content The content of the zebra configuration file.
# @param conf_file The path to the frr configuration file.
# @param log_stdout Log to stdout
# @param log_stdout_level Logging level
# @param log_file Log to file
# @param log_file_path The log file to use
# @param log_file_level The log level to use
# @param log_syslog log to syslog
# @param log_syslog_level syslog level
# @param log_syslog_facility syslog facility
# @param log_monitor log to monitor
# @param log_monitor_level log to level
# @param log_record_priority
# @param log_timestamp_precision logging precission
# @param bgp_listenon The IP address to listen on for BGP.
class frr (
  String                        $owner                    = 'frr',
  String                        $group                    = 'frr',
  Stdlib::Filemode              $mode                     = '0664',
  String                        $package                  = 'frr',
  String                        $service                  = 'frr',
  Boolean                       $enable                   = true,
  String                        $zebra_content            = "hostname ${facts['networking']['fqdn']}",
  Boolean                       $log_syslog               = false,
  Frr::Log_level                $log_syslog_level         = 'debugging',
  Stdlib::Syslogfacility        $log_syslog_facility      = 'daemon',
  Boolean                       $log_monitor              = false,
  Frr::Log_level                $log_monitor_level        = 'debugging',
  Boolean                       $log_record_priority      = false,
  Integer[0,6]                  $log_timestamp_precision  = 1,
  Boolean                       $log_stdout               = false,
  Frr::Log_level                $log_stdout_level         = 'debugging',
  Boolean                       $log_file                 = false,
  Stdlib::Absolutepath          $log_file_path            = '/var/log/frr/bgpd.log',
  Frr::Log_level                $log_file_level           = 'debugging',
  Stdlib::Unixpath              $conf_file                = '/etc/frr/frr.conf',
  Optional[Stdlib::IP::Address] $bgp_listenon             = undef
) {
  ensure_packages([$package])
  file {
    default:
      ensure  => file,
      owner   => $owner,
      group   => $group,
      mode    => $mode,
      require => Package[$package],
      notify  => Service[$service];
    '/etc/frr':
      ensure  => directory;
    '/etc/frr/zebra.conf':
      content => $zebra_content;
  }
  file { '/etc/frr/vtysh.conf':
    ensure => file,
    mode   => $mode,
    source => 'puppet:///modules/frr/vtysh.conf',
  }
  file { '/etc/profile.d/vtysh.sh':
    ensure => file,
    source => 'puppet:///modules/frr/vtysh.sh',
  }
  # TODO: check if we still need this
  # the frr validate command runs without CAP_DAC_OVERRIDE
  # this means that even if running the command as root it cant
  # read files owned by !root
  # further to this the validate command is indeterminate. if the
  # file allready exists then the temp file created for the validate_cmd
  # has the permissions of the original user.  if the file does not exits
  # then the temp file is created with root user permissions.
  # As such we need this hack
  exec { "/usr/bin/touch ${conf_file}":
    creates => $conf_file,
    user    => $owner,
    before  => Concat[$conf_file],
  }
  concat { $conf_file:
    owner        => $owner,
    group        => $group,
    mode         => $mode,
    validate_cmd => '/usr/bin/vtysh -f %',
    require      => Package[$package],
    notify       => Service[$service],
  }
  concat::fragment { 'frr_head':
    target  => $conf_file,
    content => template('frr/frr.conf.head.erb'),
    order   => '01',
  }
  ini_setting { 'zebra':
    ensure  => present,
    path    => '/etc/frr/daemons',
    section => '',
    setting => 'zebra',
    value   => $enable.bool2str('yes','no'),
    require => Package[$package],
    notify  => Service[$service],
  }
  service { $service:
    ensure => running,
    enable => true,
  }
}
