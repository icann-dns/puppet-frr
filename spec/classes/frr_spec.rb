# frozen_string_literal: true

require 'spec_helper'

describe 'frr' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  # include_context :hiera

  # below is the facts hash that gives you the ability to mock
  # facts on a per describe/context block.  If you use a fact in your
  # manifest you should mock the facts below.
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end
      # below is a list of the resource parameters that you can override.
      # By default all non-required parameters are commented out,
      # while all required parameters will require you to add a value
      let(:params) do
        {
          # :owner => "frr",
          # :group => "frr",
          # :mode => "0664",
          # :package => "frr",
          # :enable => true,
          zebra_content: 'hostname test',
        }
      end

      describe 'check default parameters' do
        # add these two lines in a single test block to enable puppet and hiera debug mode
        # Puppet::Util::Log.level = :debug
        # Puppet::Util::Log.newdestination(:console)
        it do
          is_expected.to compile.with_all_deps
        end

        it { is_expected.to contain_package('frr') }
        it { is_expected.to contain_class('Frr') }

        it do
          is_expected.to contain_file('/etc/frr/zebra.conf').with(
            content: 'hostname test',
            ensure: 'file',
            group: 'frr',
            mode: '0664',
            notify: 'Service[frr]',
            owner: 'frr'
          )
        end

        it do
          is_expected.to contain_concat__fragment('frr_head').with(
            order: '01',
            target: '/etc/frr/frr.conf'
          ).with_content(
            %r{no log stdout}
          ).with_content(
            %r{no log file}
          ).with_content(
            %r{no log syslog}
          ).with_content(
            %r{no log monitor}
          ).with_content(
            %r{no log record-priority}
          ).with_content(
            %r{log timestamp precision 1}
          )
        end

        it do
          is_expected.to contain_file('/etc/profile.d/vtysh.sh').with(
            ensure: 'file',
            source: 'puppet:///modules/frr/vtysh.sh'
          )
        end

        it do
          is_expected.to contain_service('frr').with(
            enable: 'true',
            ensure: 'running'
          )
        end

        it do
          is_expected.to contain_ini_setting('zebra').with(
            setting: 'zebra',
            value: 'yes'
          )
        end
      end

      describe 'check changin default parameters' do
        context 'owner' do
          before { params.merge!(owner: 'foo') }

          it { is_expected.to contain_file('/etc/frr/zebra.conf').with_owner('foo') }
        end

        context 'group' do
          before { params.merge!(group: 'foo') }

          it { is_expected.to contain_file('/etc/frr/zebra.conf').with_group('foo') }
        end

        context 'mode' do
          before { params.merge!(mode: '0600') }

          it { is_expected.to contain_file('/etc/frr/zebra.conf').with_mode('0600') }
        end

        context 'package' do
          before { params.merge!(package: 'foo') }

          it { is_expected.to contain_package('foo') }
        end

        context 'enable' do
          before { params.merge!(enable: false) }

          it do
            is_expected.to contain_ini_setting('zebra').with(
              setting: 'zebra',
              value:   'no'
            )
          end
        end

        context 'log_syslog' do
          before { params.merge!(log_syslog: true) }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment('frr_head').with(
              order: '01',
              target: '/etc/frr/frr.conf'
            ).with_content(
              %r{^log syslog debugging}
            ).with_content(
              %r{^log facility daemon}
            )
          end
        end

        context 'log_syslog_level' do
          before { params.merge!(log_syslog: true, log_syslog_level: 'alerts') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment('frr_head').with(
              order: '01',
              target: '/etc/frr/frr.conf'
            ).with_content(
              %r{^log syslog alerts}
            ).with_content(
              %r{^log facility daemon}
            )
          end
        end

        context 'log_syslog_facility' do
          before { params.merge!(log_syslog: true, log_syslog_facility: 'local7') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment('frr_head').with(
              order: '01',
              target: '/etc/frr/frr.conf'
            ).with_content(
              %r{^log syslog debugging}
            ).with_content(
              %r{^log facility local7}
            )
          end
        end

        context 'log_monitor' do
          before { params.merge!(log_monitor: true) }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment('frr_head').with(
              order: '01',
              target: '/etc/frr/frr.conf'
            ).with_content(
              %r{^log monitor debugging}
            )
          end
        end

        context 'log_monitor_level' do
          before { params.merge!(log_monitor: true, log_monitor_level: 'alerts') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment('frr_head').with(
              order: '01',
              target: '/etc/frr/frr.conf'
            ).with_content(
              %r{^log monitor alerts}
            )
          end
        end

        context 'log_record_priority' do
          before { params.merge!(log_record_priority: true) }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment('frr_head').with(
              order: '01',
              target: '/etc/frr/frr.conf'
            ).with_content(
              %r{^log record-priority}
            )
          end
        end

        context 'log_timestamp_precision' do
          before { params.merge!(log_timestamp_precision: 3) }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment('frr_head').with(
              order: '01',
              target: '/etc/frr/frr.conf'
            ).with_content(
              %r{^log timestamp precision 3}
            )
          end
        end

        context 'log_stdout' do
          before { params.merge!(log_stdout: true) }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment('frr_head').with(
              order: '01',
              target: '/etc/frr/frr.conf'
            ).with_content(
              %r{^log stdout debugging}
            )
          end
        end

        context 'log_stdout_level' do
          before { params.merge!(log_stdout: true, log_stdout_level: 'alerts') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment('frr_head').with(
              order: '01',
              target: '/etc/frr/frr.conf'
            ).with_content(
              %r{^log stdout alerts}
            )
          end
        end

        context 'log_file' do
          before { params.merge!(log_file: true) }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment('frr_head').with(
              order: '01',
              target: '/etc/frr/frr.conf'
            ).with_content(
              %r{^log file /var/log/frr/bgpd.log debugging}
            )
          end
        end

        context 'log_file_level' do
          before { params.merge!(log_file: true, log_file_level: 'alerts') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment('frr_head').with(
              order: '01',
              target: '/etc/frr/frr.conf'
            ).with_content(
              %r{^log file /var/log/frr/bgpd.log alerts}
            )
          end
        end

        context 'log_file_path' do
          before { params.merge!(log_file: true, log_file_path: '/bgpd.log') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment('frr_head').with(
              order: '01',
              target: '/etc/frr/frr.conf'
            ).with_content(
              %r{^log file /bgpd.log debugging}
            )
          end
        end

        context 'zebra_content' do
          before { params.merge!(zebra_content: 'foo') }

          it do
            is_expected.to contain_file('/etc/frr/zebra.conf').with_content(
              %r{foo}
            )
          end
        end
      end

      describe 'check bad parameters' do
        context 'owner' do
          before { params.merge!(owner: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'group' do
          before { params.merge!(group: []) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'mode' do
          before { params.merge!(mode: 'foo') }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'package' do
          before { params.merge!(package: {}) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'enable' do
          before { params.merge!(enable: 'false') }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'zebra_content' do
          before { params.merge!(zebra_content: []) }

          it { is_expected.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
