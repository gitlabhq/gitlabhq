# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::ResetFeedTokenService, feature_category: :system_access do
  shared_examples_for 'a successfully reset token' do
    it { expect(reset.success?).to be true }
    it { expect { reset }.to change { user.feed_token } }

    it 'logs the event' do
      expect(Gitlab::AppLogger).to receive(:info).with(
        class: described_class.to_s,
        message: 'User Feed Token Reset',
        source: :self,
        reset_by: reset_by,
        reset_for: user.username,
        user_id: user.id)

      reset
    end
  end

  shared_examples_for 'an unsuccessfully reset token' do
    it { expect(reset.success?).to be false }
    it { expect { reset }.not_to change { user.feed_token } }
  end

  describe '#execute' do
    subject(:reset) { service.execute }

    let(:service) { described_class.new(current_user, user: user) }
    let_it_be(:admin) { create(:admin) }
    let_it_be(:alex) { create(:user) }

    context 'when current_user is an administrator' do
      context 'when admin mode is enabled', :enable_admin_mode do
        let(:current_user) { admin }
        let(:user) { alex }

        it_behaves_like 'a successfully reset token' do
          let(:reset_by) { current_user.username }
        end
      end

      context 'when admin mode is disabled' do
        let(:current_user) { admin }
        let(:user) { alex }

        it_behaves_like 'an unsuccessfully reset token'
      end
    end

    context 'when current_user is not an administrator' do
      let(:current_user) { alex }

      context 'when user is a different user' do
        let(:user) { admin }

        it_behaves_like 'an unsuccessfully reset token'
      end

      context 'when user is current_user' do
        let(:user) { alex }

        it_behaves_like 'a successfully reset token' do
          let(:reset_by) { current_user.username }
        end
      end
    end
  end
end
