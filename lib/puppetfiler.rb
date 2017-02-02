require "puppetfiler/version"
require 'puppet_forge'
require 'semantic_puppet'
require 'thor'
require 'thor/group'
require 'erb'

# parsing
module Puppetfiler
    class Puppetfile < Thor
        @@modules = {}
        @@repos = {}
        @@maxlen = 0
        @@puppetfile = 'Puppetfile'
        @@fixture_template = <<-EOT
---
fixtures:
  forge_modules:
<% @@modules.each do |name, version| -%>
    <%= name.split('/')[1] %>:
      repo: <%= name %>
      ref: <%= version %>
<% end -%>
  repositories:
<% @@repos.each do |name, hash| -%>
    <%= name %>:
      repo: <%= hash[:uri] %>
      ref: <%= hash[:ref] %>
<% end -%>
EOT

        desc 'check', 'Check forge for newer versions of used forge modules'
        def check
            evaluate
            puts "#{'module'.ljust(@@maxlen)}\tinstalled\tnewest"
            @@modules.each do |name, version|
                current = SemanticPuppet::Version.parse(version)
                newest = newest(name)

                if not newest.eql?(current)
                    puts "#{name.ljust(@@maxlen)}\t#{current}\t\t#{newest}"
                end
            end
        end

        desc 'fixture [puppetfile]', 'Create puppetlabs_spec_helper compatible .fixtures.yml from puppetfile'
        def fixture
            evaluate
            puts ERB.new(@@fixture_template, 3, '-').result(binding)
        end

        private
        def evaluate
            content = File.read(@@puppetfile)
            self.instance_eval(content)
        end

        # returns a Version object of the newest release
        def newest(name)
            mod = PuppetForge::Module.find(name.gsub('/', '-'))
            version = mod.current_release.version
            return SemanticPuppet::Version.parse(version)
        end

        # puppetfile functions
        def moduledir(*args)
        end

        def mod(name, *args)
            arg = args[0]

            if arg.is_a?(String)
                return if arg == 'latest'
                @@modules[name] = arg
                @@maxlen = name.length if name.length > @@maxlen
            else args.is_a?(Hash)

                @@repos[name] = {}

                %i{git svn}.each do |vcs|
                    @@repos[name][:uri] = arg[vcs] if arg.keys.member?(vcs)
                end

                %i{fallback branch tag commit}.each do |ref|
                    @@repos[name][:ref] = arg[ref] if arg.keys.member?(ref)
                end

            end
        end
    end

end
