# frozen_string_literal: true

require_relative "lib/webfunction/version"

Gem::Specification.new do |spec|
  spec.name = "webfunction"
  spec.version = WebFunction::VERSION
  spec.authors = ["Robin Clart"]
  spec.email = ["robin@clart.be"]

  spec.summary = "A Web Function Client for Ruby"
  spec.description = "A lightweight Web Function client for Ruby. Web Function is a radical rethinking of API design: no verbs, no nested URLs, no bloat. Just function calls over HTTP. This gem lets you invoke endpoints defined in a package, with full support for argument validations, error triples, and bearer auth."
  spec.homepage = "https://github.com/webfunction-protocol/webfunction-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "irb"
  spec.add_dependency "logger"
  spec.add_dependency "excon", "~> 1.2"
  spec.add_dependency "json", "~> 2.10"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/webfunction-protocol/webfunction-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/webfunction-protocol/webfunction-ruby/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"
end
