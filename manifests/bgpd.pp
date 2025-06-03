# @summary bgpd class
# @param my_asn The local ASN number
# @param router_id The router_id
# @param enable if to enable bgpd
# @param networks4 List of v4 networks to advertise
# @param failsafe_networks4 List of v4 failsafe networks to advertise
# @param networks6 List of v6 networks to advertise
# @param failsafe_networks6 List of v6 failsafe networks to advertise
# @param rejected_v4 list of v4 networks to reject
# @param rejected_v6 list of v6 networks to reject
# @param reject_bogons_v4 list of v4 bogons to reject
# @param reject_bogons_v6 list of v6 bogons to reject
# @param failover_server If this is a failover server
# @param inject_static_routes frr needs routes to exist in the routing table to redistribute.  if they don't we need to add some Null0 routes
# @param enable_advertisements weather we should advertise bgp networks
# @param enable_advertisements_v4 weather we should advertise bgp v4networks
# @param enable_advertisements_v6 weather we should advertise bgp v6networks
# @param bgpd_cmd location of bgp config comand
# @param debug_bgp Debug options

# @param fib_update update the local fib
# @param peers A hash of peers
class frr::bgpd (
  Integer[1,4294967295]                $my_asn                   = undef,
  Stdlib::IP::Address::V4              $router_id                = undef,
  Boolean                              $enable                   = true,
  Array[Stdlib::IP::Address::V4::CIDR] $networks4                = [],
  Array[Stdlib::IP::Address::V4::CIDR] $failsafe_networks4       = [],
  Array[Stdlib::IP::Address::V6::CIDR] $networks6                = [],
  Array[Stdlib::IP::Address::V6::CIDR] $failsafe_networks6       = [],
  Array[Stdlib::IP::Address::V4::CIDR] $rejected_v4              = [],
  Array[Stdlib::IP::Address::V6::CIDR] $rejected_v6              = [],
  Boolean                              $reject_bogons_v4         = true,
  Boolean                              $reject_bogons_v6         = true,
  Boolean                              $failover_server          = false,
  Boolean                              $inject_static_routes     = true,
  Boolean                              $enable_advertisements    = true,
  Boolean                              $enable_advertisements_v4 = true,
  Boolean                              $enable_advertisements_v6 = true,
  Stdlib::Absolutepath                 $bgpd_cmd                 = '/usr/lib/frr/bgpd',
  Array                                $debug_bgp                = [],
  Boolean                              $fib_update               = true,
  Hash                                 $peers                    = {},
) {
  include frr
  $conf_file = $frr::conf_file

  ini_setting {
    default:
      path    => '/etc/frr/daemons',
      section => '',
      notify  => Service[$frr::service],
      require => Package[$frr::package];
    'bgpd':
      setting => 'bgpd',
      value   => $enable.bool2str('yes','no');
  }
  if $inject_static_routes {
    $static_null_routes = (
      ($networks4 + $failsafe_networks4).map |$net| {
        "ip route ${net} Null0"
      } + ($networks6 + $failsafe_networks6).map |$net| {
        "ipv6 route ${net} Null0"
      }
    ).unique.join("\n")
    concat::fragment { 'frr_bgpd_static_routes':
      target  => $conf_file,
      order   => '10',
      content => $static_null_routes,
    }
  }
  concat::fragment { 'frr_bgpd_head':
    target  => $conf_file,
    content => template('frr/bgpd.conf.head.erb'),
    order   => '20',
  }
  concat::fragment { 'frr_bgpd_v6head':
    target  => $conf_file,
    content => "!\n address-family ipv6\n",
    order   => '40',
  }
  concat::fragment { 'frr_bgpd_v6foot':
    target  => $conf_file,
    content => template('frr/bgpd.conf.v6foot.erb'),
    order   => '60',
  }
  concat::fragment { 'frr_bgpd_acl':
    target  => $conf_file,
    content => template('frr/bgpd.conf.acl.erb'),
    order   => '80',
  }
  concat::fragment { 'frr_bgpd_foot':
    target  => $conf_file,
    content => "line vty\n!\n",
    order   => '99',
  }
  $peers.each |$peer_title, $peer_config| {
    frr::bgpd::peer { String($peer_title):
      * => $peer_config,
    }
  }
}
