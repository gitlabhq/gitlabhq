require 'spec_helper'

describe Gitlab::Auth::UserAccessDeniedReason do
  include TermsHelper
  let(:user) { build(:user) }

  let(:reason) { described_class.new(user) }

  describe '#rejection_message' do
    subject { reason.rejection_message }

    context 'when a user is blocked' do
      before do
        user.block!
      end

      it { is_expected.to match /blocked/ }
    end

    context 'a user did not accept the enforced terms' do
      before do
        enforce_terms
      end

      it { is_expected.to match /must accept the Terms of Service/ }
      it { is_expected.to include(user.username) }
    end

    context 'when the user is internal' do
      let(:user) { User.ghost }

      it { is_expected.to match /This action cannot be performed by internal users/ }
    end
  end
end
