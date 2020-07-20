# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserCanonicalEmail do
  it { is_expected.to belong_to(:user) }

  describe 'validations' do
    describe 'canonical_email' do
      it { is_expected.to validate_presence_of(:canonical_email) }

      it 'validates email address', :aggregate_failures do
        expect(build(:user_canonical_email, canonical_email: 'nonsense')).not_to be_valid
        expect(build(:user_canonical_email, canonical_email: '@nonsense')).not_to be_valid
        expect(build(:user_canonical_email, canonical_email: '@nonsense@')).not_to be_valid
        expect(build(:user_canonical_email, canonical_email: 'nonsense@')).not_to be_valid
      end
    end
  end
end
