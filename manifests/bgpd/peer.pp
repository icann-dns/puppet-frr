# @summary set up bgpd peer
# @param addr4 The IPv4 address of the peer.
# @param addr6 The IPv6 address of the peer.
# @param desc The description of the peer.
# @param inbound_routes The inbound routes to accept.
# @param communities The communities to accept.
# @param multihop The multihop value.
# @param password The password to use.
# @param prepend The prepend value.
# @param default_originate Whether to default originate.
define frr::bgpd::peer (
  Boolean                        $default_originate = false,
  Frr::Routes_acl             $inbound_routes    = 'none',
  String                         $desc              = undef,
  Array                          $communities       = [],
  Array[Stdlib::IP::Address::V4] $addr4             = [],
  Array[Stdlib::IP::Address::V6] $addr6             = [],
  Optional[Integer[1,254]]       $multihop          = undef,
  Optional[String]               $password          = undef,
  Optional[Integer[1,32]]        $prepend           = undef,
) {
  include frr::bgpd

  $my_asn = $frr::bgpd::my_asn

  unless ($addr4 + $addr6).empty {
    concat::fragment { "bgpd_peer_${name}":
      target  => $frr::bgpd::conf_file,
      content => template('frr/bgpd.conf.peer.erb'),
      order   => '30',
    }
  }
  unless $addr6.empty {
    concat::fragment { "bgpd_v6peer_${name}":
      target  => $frr::bgpd::conf_file,
      content => template('frr/bgpd.conf.v6peer.erb'),
      order   => '50',
    }
  }
  concat::fragment { "frr_bgpd_routemap_${name}":
    target  => $frr::bgpd::conf_file,
    content => template('frr/bgpd.conf.routemap.erb'),
    order   => '90',
  }
}
