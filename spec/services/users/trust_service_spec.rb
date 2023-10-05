# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::TrustService, feature_category: :user_management do
  let_it_be(:current_user) { create(:admin) }

  subject(:service) { described_class.new(current_user) }

  describe '#execute' do
    let(:user) { create(:user) }

    subject(:operation) { service.execute(user) }

    it 'updates the custom attributes', :aggregate_failures do
      expect(user.custom_attributes).to be_empty

      operation
      user.reload

      expect(user.custom_attributes.by_key(UserCustomAttribute::TRUSTED_BY)).to be_present
    end
  end
end
