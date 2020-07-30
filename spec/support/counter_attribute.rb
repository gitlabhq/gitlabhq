# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each, :counter_attribute) do
    stub_const('CounterAttributeModel', Class.new(ProjectStatistics))

    CounterAttributeModel.class_eval do
      include CounterAttribute

      counter_attribute :build_artifacts_size
      counter_attribute :commit_count
    end
  end
end
