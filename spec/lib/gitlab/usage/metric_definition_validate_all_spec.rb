# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::MetricDefinition, feature_category: :product_analytics do
  # rubocop:disable Rails/FindEach -- The all method invoked here is unrelated to the ActiveRecord scope all
  it 'only has valid metric definitions', :aggregate_failures do
    described_class.all.each do |definition|
      validation_errors = definition.validation_errors
      expect(validation_errors).to be_empty, validation_errors.join
    end
  end
  # rubocop:enable Rails/FindEach
end
