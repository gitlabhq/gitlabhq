# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::ActiveRecord::FilterDefinition, feature_category: :database do
  it 'requires #apply definition' do
    expect(described_class.new(:foo, :bar)).to require_method_definition(:apply, nil, nil)
  end
end
