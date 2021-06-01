# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::UserAccessDeniedReason do
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

    context 'when the user is deactivated' do
      before do
        user.deactivate!
      end

      it { is_expected.to eq "Your account has been deactivated by your administrator. Please log back in from a web browser to reactivate your account at #{Gitlab.config.gitlab.url}" }
    end

    context 'when the user is unconfirmed' do
      before do
        user.update!(confirmed_at: nil)
      end

      it { is_expected.to match /Your primary email address is not confirmed/ }
    end

    context 'when the user is blocked pending approval' do
      before do
        user.block_pending_approval!
      end

      it { is_expected.to eq('Your account is pending approval from your administrator and hence blocked.') }
    end

    context 'when the user has expired password' do
      before do
        user.update!(password_expires_at: 2.days.ago)
      end

      it { is_expected.to eq('Your password expired. Please access GitLab from a web browser to update your password.') }
    end
  end
end
