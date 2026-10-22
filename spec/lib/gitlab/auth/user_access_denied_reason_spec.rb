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

      it { is_expected.to match(/blocked/) }
    end

    context 'a user did not accept the enforced terms' do
      before do
        enforce_terms
      end

      it { is_expected.to match(/must accept the Terms of Service/) }
      it { is_expected.to include(user.username) }
      it { is_expected.to include(Gitlab.config.gitlab.url) }
    end

    context 'when the user is internal' do
      let(:organization) { create(:common_organization) }
      let(:user) { Users::Internal.in_organization(organization).ghost }

      it { is_expected.to match(/This action cannot be performed by internal users/) }
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

      it { is_expected.to match(/Your primary email address is not confirmed/) }
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

    context 'when the actor is a deploy token' do
      context 'when the token has been revoked' do
        let(:user) { build_stubbed(:deploy_token, :revoked) }

        it { is_expected.to eq('This deploy token has been revoked.') }
      end

      context 'when the token has expired' do
        let(:user) { build_stubbed(:deploy_token, :expired) }

        it { is_expected.to eq('This deploy token has expired.') }
      end

      context 'when the token is active' do
        let(:user) { build_stubbed(:deploy_token) }

        it { is_expected.to start_with('Your request has been rejected for an unknown reason.') }
      end

      context 'when the token is inactive but has neither been revoked nor expired' do
        let(:user) { build_stubbed(:deploy_token) }

        before do
          allow(user).to receive(:active?).and_return(false)
        end

        it { is_expected.to start_with('Your request has been rejected for an unknown reason.') }
      end
    end
  end
end
