#!/usr/bin/env ruby
# frozen_string_literal: true

require 'prime'
require 'stackprof'

StackProf.run(mode: :cpu, raw: true, interval: 100, out: 'spec/cloud_profiler_agent/cpu.stackprof') do
  (1..1000).each { |i| Prime.prime_division(i) }
end

StackProf.run(mode: :wall, raw: true, interval: 100, out: 'spec/cloud_profiler_agent/wall.stackprof') do
  sleep(1)
end

StackProf.run(mode: :object, raw: true, interval: 100, out: 'spec/cloud_profiler_agent/object.stackprof') do
  (1..1000).each { |i| Prime.prime_division(i) }
end
