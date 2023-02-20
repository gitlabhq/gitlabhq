# frozen_string_literal: true

require_relative "lib/gitlab_active_record/version"

Gem::Specification.new do |spec|
  spec.name = "gitlab_active_record"
  spec.version = GitlabActiveRecord::VERSION
  spec.authors = ["GitLab"]
  spec.email = [""]

  spec.summary = "ActiveRecord patches for CI partitioning"
  spec.description = "ActiveRecord patches for CI partitioning"
  spec.homepage = "https://gitlab.com/gitlab-org/gitlab"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://gitlab.com/gitlab-org/gitlab"

  spec.files = Dir.glob("lib/**/*")
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'activerecord', '~> 6.1'
  spec.add_dependency 'activesupport', '~> 6.1'

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
