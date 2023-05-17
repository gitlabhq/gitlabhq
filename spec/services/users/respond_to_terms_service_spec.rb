# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::RespondToTermsService, feature_category: :user_profile do
  let(:user) { create(:user) }
  let(:term) { create(:term) }

  subject(:service) { described_class.new(user, term) }

  describe '#execute' do
    it 'creates a new agreement if it did not exist' do
      expect { service.execute(accepted: true) }
        .to change { user.term_agreements.size }.by(1)
    end

    it 'updates an agreement if it existed' do
      agreement = create(:term_agreement, user: user, term: term, accepted: true)

      service.execute(accepted: true)

      expect(agreement.reload.accepted).to be_truthy
    end

    it 'adds the accepted terms to the user' do
      service.execute(accepted: true)

      expect(user.reload.accepted_term).to eq(term)
    end

    it 'removes accepted terms when declining' do
      user.update!(accepted_term: term)

      service.execute(accepted: false)

      expect(user.reload.accepted_term).to be_nil
    end
  end
end
