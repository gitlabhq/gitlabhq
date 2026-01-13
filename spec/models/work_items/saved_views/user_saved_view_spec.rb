# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::SavedViews::UserSavedView, feature_category: :portfolio_management do
  describe '.user_saved_view_limit' do
    let(:namespace) { build(:namespace) }

    it 'returns the correct value' do
      expect(described_class.user_saved_view_limit(namespace)).to eq(5)
    end
  end
end
