# frozen_string_literal: true

module CloudProfilerAgent
  VERSION = '0.0.1.pre'
  autoload :Agent, 'cloud_profiler_agent/agent'
  autoload :PprofBuilder, 'cloud_profiler_agent/pprof_builder'
  autoload :Looper, 'cloud_profiler_agent/looper'
end

module Perftools
  autoload :Profiles, 'profile_pb'
end
