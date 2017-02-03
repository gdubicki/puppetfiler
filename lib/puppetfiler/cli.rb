require 'thor'
require 'yaml'
require 'puppetfiler/puppetfile'
require 'puppetfiler/version'

module Puppetfiler
    class CLI < Thor
        desc 'check [puppetfile]', 'Check forge for newer versions of used forge modules'
        def check(puppetfile = 'Puppetfile')
            pf = Puppetfiler::Puppetfile.new(puppetfile)
            format = "% -#{pf.maxlen_name}s  % -#{pf.maxlen_ver}s  %s"

            puts sprintf(format, 'module', 'current', 'newest')

            pf.updates.each do |name, hash|
                puts sprintf(format, name, hash[:current], hash[:newest])
            end
        end

        desc 'fixture [puppetfile]', 'Create puppetlabs_spec_helper compatible .fixtures.yml from puppetfile'
        method_option :stdout, :aliases => '-o'
        def fixture(puppetfile = 'Puppetfile')
            f = Puppetfiler::Puppetfile.new(puppetfile).fixture.to_yaml

            if options[:stdout]
                puts f
            else
                File.write('.fixtures.yml', f)
            end
        end

        desc 'version', 'Output version'
        def version
            puts "puppetfiler v#{Puppetfiler::VERSION}"
        end
    end
end
