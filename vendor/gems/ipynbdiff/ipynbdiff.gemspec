# frozen_string_literal: true

lib = File.expand_path('lib/..', __dir__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'lib/version'

Gem::Specification.new do |s|
  s.name        = 'ipynbdiff'
  s.version     = IpynbDiff::VERSION
  s.summary     = 'Human Readable diffs for Jupyter Notebooks'
  s.description = 'Better diff for Jupyter Notebooks by first preprocessing them and removing clutter'
  s.authors     = ['Eduardo Bonet']
  s.email       = 'ebonet@gitlab.com'
  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  s.files = Dir.glob("lib/**/*.*")
  s.test_files = Dir.glob("spec/**/*.*")
  s.homepage =
    'https://gitlab.com/gitlab-org/incubation-engineering/mlops/rb-ipynbdiff'
  s.license       = 'MIT'

  s.require_paths = ['lib']

  s.add_runtime_dependency 'diffy', '~> 3.4'
  s.add_runtime_dependency 'oj', '~> 3.13.16'

  s.add_development_dependency 'bundler', '~> 2.2'
  s.add_development_dependency 'pry', '~> 0.14'
  s.add_development_dependency 'rake', '~> 13.0'
  s.add_development_dependency 'rspec', '~> 3.10'
  s.add_development_dependency 'rspec-parameterized', '~> 0.5.1'
  s.add_development_dependency 'benchmark-memory', '~>0.2.0'
end
