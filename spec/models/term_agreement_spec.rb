# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TermAgreement do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:term) }
    it { is_expected.to validate_presence_of(:user) }
  end

  describe '.accepted' do
    it 'only includes accepted terms' do
      accepted = create(:term_agreement, :accepted)
      create(:term_agreement, :declined)

      expect(described_class.accepted).to contain_exactly(accepted)
    end
  end
end
