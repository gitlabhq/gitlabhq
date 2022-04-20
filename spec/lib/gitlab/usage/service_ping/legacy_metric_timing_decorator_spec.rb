# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::ServicePing::LegacyMetricTimingDecorator do
  using RSpec::Parameterized::TableSyntax

  let(:duration) { 123 }

  where(:metric_value, :metric_class) do
    1       | Integer
    "value" | String
    true    | TrueClass
    false   | FalseClass
    nil     | NilClass
  end

  with_them do
    let(:decorated_object) { described_class.new(metric_value, duration) }

    it 'exposes a duration with the correct value' do
      expect(decorated_object.duration).to eq(duration)
    end

    it 'imitates wrapped class', :aggregate_failures do
      expect(decorated_object).to eq metric_value
      expect(decorated_object.class).to eq metric_class
      expect(decorated_object.is_a?(metric_class)).to be_truthy
      # rubocop:disable Style/ClassCheck
      expect(decorated_object.kind_of?(metric_class)).to be_truthy
      # rubocop:enable Style/ClassCheck
      expect({ metric: decorated_object }.to_json).to eql({ metric: metric_value }.to_json)
    end
  end
end
