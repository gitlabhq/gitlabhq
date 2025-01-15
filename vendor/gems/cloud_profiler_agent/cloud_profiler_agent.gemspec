# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cloud_profiler_agent'

Gem::Specification.new do |spec|
  spec.name          = 'cloud_profiler_agent'
  spec.version       = CloudProfilerAgent::VERSION
  spec.authors       = ['Remind']

  spec.summary       = 'Profiling agent for Google Cloud Profiler'
  spec.homepage      = 'https://github.com/remind101/ruby-cloud-profiler'
  spec.license       = 'BSD-2-Clause'

  spec.files = ['lib/profile_pb.rb',
    'lib/cloud_profiler_agent.rb',
    'lib/cloud_profiler_agent/agent.rb',
    'lib/cloud_profiler_agent/looper.rb',
    'lib/cloud_profiler_agent/pprof_builder.rb']

  spec.add_runtime_dependency 'googleauth', '>= 0.14'
  spec.add_runtime_dependency 'google-cloud-profiler-v2', '~> 0.3'
  spec.add_runtime_dependency 'google-protobuf', '~> 3.25'
  spec.add_runtime_dependency 'stackprof', '~> 0.2'

  spec.add_development_dependency 'rspec', '>= 3.10'
  spec.add_development_dependency 'rubocop', '>= 1.2'
end
