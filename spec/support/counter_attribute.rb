# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each, :counter_attribute) do
    stub_const('CounterAttributeModel', Class.new(ProjectStatistics))

    CounterAttributeModel.class_eval do
      include CounterAttribute

      after_initialize { self.allow_package_size_counter = true }

      counter_attribute :build_artifacts_size
      counter_attribute :commit_count
      counter_attribute :packages_size, if: ->(instance) { instance.allow_package_size_counter }

      attr_accessor :flushed, :allow_package_size_counter

      counter_attribute_after_commit do |subject|
        subject.flushed = true
      end
    end
  end
end
