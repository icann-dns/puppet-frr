# frozen_string_literal: true

require 'spec_helper'

describe 'frr::bgpd::peer' do
  let(:node) { 'foo.example.com' }
  let(:title) { '64498' }
  let(:params) do
    {
      addr4: ['192.0.2.2'],
      # addr6: [],
      desc: 'TEST Network',
      # inbound_routes: "none",
      # communities: [],
      # multihop: undef,
      # password: undef,
      # prepend: undef,
    }
  end
  let(:pre_condition) do
    "class {'::frr::bgpd': my_asn => 64496, router_id => '192.0.2.1', networks4 => ['192.0.2.0/24'] }"
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      describe 'check default config' do
        # add these two lines in a single test block to enable puppet and hiera debug mode
        # Puppet::Util::Log.level = :debug
        # Puppet::Util::Log.newdestination(:console)
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('Frr::Bgpd') }

        it do
          is_expected.to contain_concat__fragment('bgpd_peer_64498').with(
            order: '30',
            target: '/etc/frr/frr.conf'
          ).with_content(
            %r{neighbor 192.0.2.2 remote-as 64498}
          ).with_content(
            %r{neighbor 192.0.2.2 description TEST Network}
          ).with_content(
            %r{neighbor 192.0.2.2 soft-reconfiguration inbound}
          ).with_content(
            %r{neighbor 192.0.2.2 prefix-list prefix-v4 out}
          ).with_content(
            %r{neighbor 192.0.2.2 prefix-list deny in}
          ).without_content(
            %r{neighbor 192.0.2.2 prefix-list deny-default-route in}
          ).without_content(
            %r{neighbor 192.0.2.2 route-map outbound-64498 out}
          )
        end

        it { is_expected.not_to contain_concat__fragment('bgpd_v6peer_64498') }

        it do
          is_expected.to contain_concat__fragment('frr_bgpd_routemap_64498').with(
            order: '90',
            target: '/etc/frr/frr.conf'
          ).without_content(
            %r{route-map outbound-64498}
          ).without_content(
            %r{route-map outbound-64498-v6}
          ).without_content(
            %r{set community}
          )
        end
      end
    end
  end
end
