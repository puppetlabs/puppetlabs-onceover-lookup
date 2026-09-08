# Create a class to hold the new command definition.  The class defined should
# match the file we are contained in.
require "puppetlabs-onceover/lookup/lookup"
class PuppetlabsOnceover
  class CLI
    class Lookup

      def self.command
        @cmd ||= Cri::Command.define do
          name 'lookup'
          usage 'lookup [--name NAME]'
          summary "Do a hiera lookup"
          description <<-DESCRIPTION
Run the `puppet lookup` command to use onceover configuration
          DESCRIPTION

          option nil, :passthru, 'Arguments to passthrough to puppet lookup', argument: :required
          option nil, :factset, 'Extract and use this factset with `puppet lookup`', argument: :optional

          run do |opts, args, cmd|
            PuppetlabsOnceover::Lookup::Lookup.run(opts[:passthru], opts[:factset])
          end
        end
      end
    end

    class Setup

      def self.command
        @cmd ||= Cri::Command.define do
          name 'setup'
          usage 'setup'
          summary "Setup the onceover to work with `puppet lookup`"
          description <<-DESCRIPTION
Setup puppetlabs-onceover-lookup by creating .puppet.conf.onceover
          DESCRIPTION

          run do |opts, args, cmd|
            PuppetlabsOnceover::Lookup::Lookup.setup
          end
        end
      end
    end
  end
end

PuppetlabsOnceover::CLI::Run.command.add_command(PuppetlabsOnceover::CLI::Lookup.command)
# sub-sub command
PuppetlabsOnceover::CLI::Lookup.command.add_command(PuppetlabsOnceover::CLI::Setup.command)
