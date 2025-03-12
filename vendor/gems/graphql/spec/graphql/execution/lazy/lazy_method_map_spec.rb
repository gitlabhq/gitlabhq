# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Execution::Lazy::LazyMethodMap do
  def self.test_lazy_method_map
    it "handles multithreaded access" do
      a = Class.new
      b = Class.new(a)
      c = Class.new(b)
      lazy_method_map.set(a, :a)
      threads = 1000.times.map do |i|
        Thread.new {
          d = Class.new(c)
          assert_equal :a, lazy_method_map.get(d.new)
        }
      end
      threads.map(&:join)
    end

    it "dups" do
      a = Class.new
      b = Class.new(a)
      c = Class.new(b)
      lazy_method_map.set(a, :a)
      lazy_method_map.get(b.new)
      lazy_method_map.get(c.new)

      dup_map = lazy_method_map.dup
      assert_equal 3, dup_map.instance_variable_get(:@storage).size
      assert_equal :a, dup_map.get(a.new)
      assert_equal :a, dup_map.get(b.new)
      assert_equal :a, dup_map.get(c.new)
    end
  end

  describe "with a plain hash" do
    let(:lazy_method_map) { GraphQL::Execution::Lazy::LazyMethodMap.new(use_concurrent: false) }
    test_lazy_method_map

    it "has a Ruby Hash inside" do
      storage = lazy_method_map
        .instance_variable_get(:@storage)
        .instance_variable_get(:@storage)
      assert_instance_of Hash, storage
    end
  end

  describe "with a Concurrent::Map" do
    let(:lazy_method_map) { GraphQL::Execution::Lazy::LazyMethodMap.new(use_concurrent: true) }
    test_lazy_method_map

    it "has a Concurrent::Map inside" do
      storage = lazy_method_map.instance_variable_get(:@storage)
      assert_instance_of Concurrent::Map, storage
    end
  end
end
