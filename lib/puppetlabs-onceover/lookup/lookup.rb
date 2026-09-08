require "erb"
require "tempfile"
require "json"

class PuppetlabsOnceover
  module Lookup
    module Lookup
      PUPPET_CONF       = ".puppet.conf.onceover"
      LOOKUP_TMP_DIR    = ".onceover/tmp"
      ENVIRONMENT_CONF  = ".onceover/etc/puppetlabs/code/environments/production/environment.conf"

      # Figure out what hiera.yaml we should be using. If there isn't a custom
      # one, then fallback to the per-environment one. We don't care if this
      # exists or not because it really should...
      def self.resolve_hiera_yaml
        hiera_yaml = File.exist?("spec/hiera.yaml") ? "spec/hiera.yaml" : "hiera.yaml"
      end

      def self.setup
        puppet_conf_template = File.join(File.dirname(File.expand_path(__FILE__)), "../../../res/puppet.conf.erb")
        ssl_readme = File.join(File.dirname(File.expand_path(__FILE__)), "../../../res/ssl_readme.md")

        template = File.read(puppet_conf_template)

        # used by the template
        hiera_yaml = resolve_hiera_yaml
        lookup_tmp_dir = LOOKUP_TMP_DIR

        content = ERB.new(template, nil, '-').result(binding)

        # We can't use a ruby block here - file handle needs to be synced and
        # closed before puppet runs or it will read and empty file and not tell
        # us
        f = File.open(PUPPET_CONF, "w")
        f.puts content
        f.close

        logger.info "wrote #{PUPPET_CONF}"
        logger.info "puppet will store state in #{lookup_tmp_dir}, we suggest you add this to .gitignore"

        if ! Dir.exist? "spec/ssl"
          Dir.mkdir "spec/ssl"
        end

        if ! File.exist? "spec/ssl/README.md"
          FileUtils.cp(ssl_readme, "spec/ssl/README.md")
        end
      end

      def self.fix_environment_conf
        environment_conf = File.readlines(ENVIRONMENT_CONF)
        environment_conf_clean = environment_conf.reject { |e| e =~ /^config_version/ }

        if environment_conf != environment_conf_clean
          File.open(ENVIRONMENT_CONF, "w") do |f|
            f.puts(environment_conf_clean)
          end
        end
      end

      def self.check_setup
        status = true
        if ! File.exist? PUPPET_CONF
          logger.error "#{PUPPET_CONF} does not exist, please run `puppetlabs-onceover run lookup setup` to create it"
          status = false
        end

        if ! File.exist? ENVIRONMENT_CONF
          logger.error "#{ENVIRONMENT_CONF} does not exist, please run `puppetlabs-onceover run spec ...` to create it"
          status = false
        end

        status
      end

      def self.run(passthru, factset)
        if check_setup
          if factset
            if factset.include? "/"
              # relative path - use this
              input_factset = factset
            else
              # resolve factset from Onceover's built-in facts
              # https://stackoverflow.com/a/10083594/3441106
              spec = Gem::Specification.find_by_name("puppetlabs-onceover")
              gem_root = spec.gem_dir

              input_factset = File.join(gem_root, "factsets", "#{factset}.json")
            end

            logger.info "Extracting factset #{factset}..."
            begin
              data_hash = JSON.parse(File.read(input_factset))

              # must give file extension or puppet will:
              # Error: Could not parse application options: undefined method `[]' for nil:NilClass
              factset_tempfile = Tempfile.new(["facts", ".json"])
              factset_tempfile.write(data_hash["values"].to_json)
              factset_tempfile.close
            rescue Errno::ENOENT => e
              raise("File not found reading: #{input_factset}: #{e.message}")
            end
          else
            input_factset = nil
          end

          # Fix environment.conf on windows by removing any `config_version`
          # since the script cant run on windows it errors the whole run. Do this
          # on all platforms since it does nothing useful on Linux either
          fix_environment_conf

          cmd = "bundle exec puppet lookup --config #{PUPPET_CONF} #{passthru}"
          if input_factset
            if passthru =~ /--facts/
              raise "You cannot specify both `--facts` and `--factsets`"
            end
            cmd += " --facts #{factset_tempfile.path}"
          end

          if ! Dir.exist? LOOKUP_TMP_DIR
            logger.info "creating #{LOOKUP_TMP_DIR}"
            FileUtils.mkdir_p LOOKUP_TMP_DIR
          end

          logger.info "running command: #{cmd}"
          system(cmd)
        end
      end
    end
  end
end
