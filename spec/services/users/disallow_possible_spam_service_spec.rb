# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::DisallowPossibleSpamService, feature_category: :user_management do
  let_it_be(:current_user) { create(:admin) }

  subject(:service) { described_class.new(current_user) }

  describe '#execute' do
    let(:user) { create(:user) }

    subject(:operation) { service.execute(user) }

    before do
      UserCustomAttribute.upsert_custom_attributes(
        [{
          user_id: user.id,
          key: :allow_possible_spam,
          value: 'not important'
        }]
      )
    end

    it 'updates the custom attributes', :aggregate_failures do
      expect(user.custom_attributes.by_key(UserCustomAttribute::ALLOW_POSSIBLE_SPAM)).to be_present

      operation
      user.reload

      expect(user.custom_attributes).to be_empty
    end
  end
end
