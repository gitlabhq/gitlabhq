# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::ServicePing::LegacyMetricMetadataDecorator, feature_category: :service_ping do
  using RSpec::Parameterized::TableSyntax

  let(:duration) { 123 }

  where(:metric_value, :error, :metric_class) do
    1       | nil | Integer
    "value" | nil | String
    true    | nil | TrueClass
    false   | nil | FalseClass
    nil     | nil | NilClass
    nil     | StandardError.new | NilClass
  end

  with_them do
    let(:decorated_object) { described_class.new(metric_value, duration, error: error) }

    it 'exposes a duration with the correct value' do
      expect(decorated_object.duration).to eq(duration)
    end

    it 'exposes error with the correct value' do
      expect(decorated_object.error).to eq(error)
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
