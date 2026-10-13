# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Search::AdvancedFinders::GroupsFinder, feature_category: :global_search do
  let_it_be(:user) { create(:user) }

  describe '#use_elasticsearch_finder?' do
    it 'is false without the EE implementation' do
      expect(described_class.new(user, search: 'foo').use_elasticsearch_finder?).to be(false)
    end
  end
end
