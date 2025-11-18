# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::Engine, feature_category: :database do
  describe '.mapping' do
    it 'raises NotImplementedError' do
      expect { described_class.mapping }.to raise_error(NotImplementedError)
    end
  end

  describe '#execute_query' do
    it 'raises NotImplementedError' do
      expect { described_class.new(context: nil).execute_query(nil) }.to raise_error(NotImplementedError)
    end
  end
end
