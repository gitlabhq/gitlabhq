# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Tracing::Trace do
  it "has all its methods in the development cop" do
    trace_source = File.read("cop/development/trace_methods_cop.rb")
    superable_methods = GraphQL::Tracing::Trace.instance_methods(false).sort
    superable_methods_source = superable_methods.map { |m| "        #{m.inspect},\n" }.join
    assert_includes trace_source, superable_methods_source
  end
end
