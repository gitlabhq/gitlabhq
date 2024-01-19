# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ClickHouse, feature_category: :database do
  context 'when ClickHouse is not configured' do
    it 'returns false' do
      expect(described_class).not_to be_configured
    end
  end

  context 'when ClickHouse is configured', :click_house do
    it 'returns false' do
      expect(described_class).to be_configured
    end
  end
end
