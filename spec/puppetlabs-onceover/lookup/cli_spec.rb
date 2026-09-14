# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'PuppetlabsOnceover::CLI::Lookup' do
  describe 'the lookup command' do
    it 'is registered under the core run command' do
      run_command = PuppetlabsOnceover::CLI::Run.command
      lookup_command = run_command.subcommands.find { |c| c.name == 'lookup' }

      expect(lookup_command).not_to be_nil
      expect(lookup_command).to eq(PuppetlabsOnceover::CLI::Lookup.command)
    end

    it 'delegates to PuppetlabsOnceover::Lookup::Lookup.run with the passthru and factset options' do
      allow(PuppetlabsOnceover::Lookup::Lookup).to receive(:run)

      PuppetlabsOnceover::CLI::Lookup.command.run(['--passthru', 'profile::foo --explain', '--factset',
                                                   'CentOS-7.0-64'])

      expect(PuppetlabsOnceover::Lookup::Lookup).to have_received(:run).with('profile::foo --explain', 'CentOS-7.0-64')
    end

    it 'registers the setup subcommand' do
      setup_command = PuppetlabsOnceover::CLI::Lookup.command.subcommands.find { |c| c.name == 'setup' }

      expect(setup_command).to eq(PuppetlabsOnceover::CLI::Setup.command)
    end
  end

  describe 'the setup subcommand' do
    it 'delegates to PuppetlabsOnceover::Lookup::Lookup.setup' do
      allow(PuppetlabsOnceover::Lookup::Lookup).to receive(:setup)

      PuppetlabsOnceover::CLI::Setup.command.run([])

      expect(PuppetlabsOnceover::Lookup::Lookup).to have_received(:setup)
    end
  end
end
