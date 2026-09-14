# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'tmpdir'

RSpec.describe PuppetlabsOnceover::Lookup::Lookup do
  # Run every example inside a throwaway working directory since the code
  # under test operates on paths relative to Dir.pwd (PUPPET_CONF,
  # LOOKUP_TMP_DIR, ENVIRONMENT_CONF).
  around do |example|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) { example.run }
    end
  end

  let(:environment_conf_dir) { File.dirname(described_class::ENVIRONMENT_CONF) }

  def write_environment_conf(lines)
    FileUtils.mkdir_p(environment_conf_dir)
    File.open(described_class::ENVIRONMENT_CONF, 'w') { |f| f.puts(lines) }
  end

  describe '.resolve_hiera_yaml' do
    it 'prefers spec/hiera.yaml when it exists' do
      FileUtils.mkdir_p('spec')
      File.write('spec/hiera.yaml', "---\n")

      expect(described_class.resolve_hiera_yaml).to eq('spec/hiera.yaml')
    end

    it 'falls back to the top-level hiera.yaml otherwise' do
      expect(described_class.resolve_hiera_yaml).to eq('hiera.yaml')
    end
  end

  describe '.setup' do
    before do
      FileUtils.mkdir_p('spec')
    end

    it 'writes the puppet.conf.onceover file' do
      described_class.setup

      expect(File.exist?(described_class::PUPPET_CONF)).to be true
      content = File.read(described_class::PUPPET_CONF)
      expect(content).to include(described_class::LOOKUP_TMP_DIR)
    end

    it 'creates spec/ssl with a README if missing' do
      described_class.setup

      expect(Dir.exist?('spec/ssl')).to be true
      expect(File.exist?('spec/ssl/README.md')).to be true
    end

    it 'does not clobber an existing spec/ssl/README.md' do
      FileUtils.mkdir_p('spec/ssl')
      File.write('spec/ssl/README.md', 'custom content')

      described_class.setup

      expect(File.read('spec/ssl/README.md')).to eq('custom content')
    end
  end

  describe '.fix_environment_conf' do
    it 'strips config_version lines' do
      write_environment_conf(['environment_timeout = 0', 'config_version = /some/script.sh'])

      described_class.fix_environment_conf

      content = File.readlines(described_class::ENVIRONMENT_CONF)
      expect(content.grep(/^config_version/)).to be_empty
      expect(content.join).to include('environment_timeout')
    end

    it 'leaves the file untouched when there is nothing to strip' do
      write_environment_conf(['environment_timeout = 0'])
      original = File.read(described_class::ENVIRONMENT_CONF)

      described_class.fix_environment_conf

      expect(File.read(described_class::ENVIRONMENT_CONF)).to eq(original)
    end
  end

  describe '.check_setup' do
    it 'returns false and logs when PUPPET_CONF is missing' do
      write_environment_conf(['environment_timeout = 0'])

      expect(described_class.check_setup).to be false
    end

    it 'returns false and logs when ENVIRONMENT_CONF is missing' do
      File.write(described_class::PUPPET_CONF, "[main]\n")

      expect(described_class.check_setup).to be false
    end

    it 'returns true when both files exist' do
      File.write(described_class::PUPPET_CONF, "[main]\n")
      write_environment_conf(['environment_timeout = 0'])

      expect(described_class.check_setup).to be true
    end
  end

  describe '.run' do
    before do
      File.write(described_class::PUPPET_CONF, "[main]\n")
      write_environment_conf(['environment_timeout = 0'])
      allow(described_class).to receive(:system)
    end

    it 'does nothing if setup has not been run' do
      FileUtils.rm(described_class::PUPPET_CONF)

      described_class.run(nil, nil)

      expect(described_class).not_to have_received(:system)
    end

    it 'runs puppet lookup without --facts when no factset is given' do
      described_class.run('profile::foo --explain', nil)

      expect(described_class).to have_received(:system) do |cmd|
        expect(cmd).to include('puppet lookup')
        expect(cmd).to include('profile::foo --explain')
        expect(cmd).not_to include('--facts')
      end
    end

    it 'creates the lookup tmp dir if missing' do
      described_class.run(nil, nil)

      expect(Dir.exist?(described_class::LOOKUP_TMP_DIR)).to be true
    end

    it 'accepts a relative-path factset directly' do
      FileUtils.mkdir_p('spec/factsets')
      factset_path = 'spec/factsets/custom.json'
      File.write(factset_path, { 'values' => { 'os' => 'CentOS' } }.to_json)

      described_class.run(nil, factset_path)

      expect(described_class).to have_received(:system) do |cmd|
        expect(cmd).to include('--facts')
      end
    end

    it 'raises a clear error when the factset file does not exist' do
      expect do
        described_class.run(nil, 'spec/factsets/does-not-exist.json')
      end.to raise_error(/File not found reading/)
    end

    it "resolves a bare factset name against the puppetlabs-onceover gem's bundled factsets" do
      described_class.run(nil, 'CentOS-7.0-64')

      expect(described_class).to have_received(:system) do |cmd|
        expect(cmd).to include('--facts')
      end
    end

    it 'raises when both --facts and --factset are specified' do
      expect do
        described_class.run('--facts /tmp/foo.json', 'CentOS-7.0-64')
      end.to raise_error(/cannot specify both/)
    end
  end
end
