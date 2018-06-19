require 'spec_helper'

describe ApplicationSetting::Term do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:terms) }
  end

  describe '.latest' do
    it 'finds the latest terms' do
      terms = create(:term)

      expect(described_class.latest).to eq(terms)
    end
  end

  describe '#accepted_by_user?' do
    let(:user) { create(:user) }
    let(:term) { create(:term) }

    it 'is true when the user accepted the terms' do
      accept_terms(term, user)

      expect(term.accepted_by_user?(user)).to be(true)
    end

    it 'is false when the user declined the terms' do
      decline_terms(term, user)

      expect(term.accepted_by_user?(user)).to be(false)
    end

    it 'does not cause a query when the user accepted the current terms' do
      accept_terms(term, user)

      expect { term.accepted_by_user?(user) }.not_to exceed_query_limit(0)
    end

    it 'returns false if the currently accepted terms are different' do
      accept_terms(create(:term), user)

      expect(term.accepted_by_user?(user)).to be(false)
    end

    def accept_terms(term, user)
      Users::RespondToTermsService.new(user, term).execute(accepted: true)
    end

    def decline_terms(term, user)
      Users::RespondToTermsService.new(user, term).execute(accepted: false)
    end
  end
end
