# run a test task
require 'spec_helper_acceptance'

describe 'package task' do
  describe 'install' do
    before(:all) do
      hosts.each do |h|
        plugindir = if h.platform =~ %r{windows}
                      'C:/ProgramData/PuppetLabs/mcollective/etc/plugins/mcollective/agent'
                    else
                      '/opt/puppetlabs/mcollective/plugins/mcollective'
                    end

        specdir = File.absolute_path(File.join(File.dirname(__FILE__), '..'))
        moduledir = "#{specdir}/fixtures/modules/package_agent/"

        on(h, "mkdir -p #{plugindir}")
        Dir.glob("#{moduledir}/*").each do |fh|
          scp_to(h, fh, plugindir)
        end
      end
    end

    before(:each) do
      apply_manifest('package { "nano": ensure => absent, }')
    end

    it 'errors for uninstalled agents' do
      result = run_task(task_name: 'mco_rpc', params: 'agent=nonexistent_agent')
      expect_multiple_regexes(result: result, regexes: [%r{puppetlabs.mco_rpc/unknown-agent}])
    end

    it 'runs the package agent without data' do
      result = run_task(task_name: 'mco_rpc', params: 'agent=package action=count')
      expect_multiple_regexes(result: result, regexes: [%r{output}, %r{exitcode[\w:"].0}])
    end

    it 'errors with missing params' do
      result = run_task(task_name: 'mco_rpc', params: 'agent=package action=install')
      expect_multiple_regexes(result: result, regexes: [/puppetlabs.mco_rpc\/mco_error/, %r{Action install needs a package argument}])
    end

    it 'runs the package agent with data' do
      params = { agent: 'package',
                 action: 'install',
                 data: { package: 'nano' } }
      result = run_task(task_name: 'mco_rpc', params: params)
      expect_multiple_regexes(result: result, regexes: [%r{output}, %r{release}])
    end

    it 'runs the package agent with arguments' do
      params = { agent: 'package',
                 action: 'install',
                 arguments: 'package=nano' }
      result = run_task(task_name: 'mco_rpc', params: params)
      expect_multiple_regexes(result: result, regexes: [%r{output}, %r{release}])
    end
  end
end
