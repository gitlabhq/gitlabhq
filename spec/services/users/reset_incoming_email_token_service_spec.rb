# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::ResetIncomingEmailTokenService, feature_category: :system_access do
  shared_examples_for 'a successfully reset token' do
    it { expect(execute.success?).to be true }
    it { expect { execute }.to change { user.incoming_email_token } }
  end

  shared_examples_for 'an unsuccessfully reset token' do
    it { expect(execute.success?).to be false }
    it { expect { execute }.not_to change { user.incoming_email_token } }
  end

  describe '#execute!' do
    let(:service) { described_class.new(current_user: current_user, user: user) }

    let_it_be(:existing_user) { create(:user) }

    subject(:execute) { service.execute! }

    context 'when current_user is an admin', :enable_admin_mode do
      let(:current_user) { create(:admin) }
      let(:user) { existing_user }

      it_behaves_like 'a successfully reset token'
    end

    context 'when current_user is not an administrator' do
      let(:current_user) { existing_user }

      context 'when user is a different user' do
        let(:user) { create(:user) }

        it_behaves_like 'an unsuccessfully reset token'
      end

      context 'when user is current_user' do
        let(:user) { current_user }

        it_behaves_like 'a successfully reset token'
      end
    end
  end
end
