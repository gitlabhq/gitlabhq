# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::AggregationResult, feature_category: :database do
  subject { described_class.new(nil, nil, nil) }

  it { is_expected.to require_method_definition(:load_data) }
end
