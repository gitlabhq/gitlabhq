# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::Runners::ResetAuthenticationTokenService, :aggregate_failures, feature_category: :runner do
  let_it_be(:user) { build(:user) }
  let_it_be(:admin) { build(:admin) }

  let(:runner) { create(:ci_runner) }

  subject(:service) { described_class.new(runner: runner, current_user: current_user) }

  context 'with unauthorized user' do
    where(:current_user) do
      [
        ref(:user),
        nil
      ]
    end

    with_them do
      it 'does not reset authentication token and returns error response' do
        expect(service.execute.error?).to be_truthy
        expect(service.execute.message).to eq('user is not allowed to reset runner authentication token')
      end
    end
  end

  context 'with admin', :enable_admin_mode do
    let(:current_user) { admin }

    it 'does reset authentication token and returns success' do
      expect(service.execute.success?).to be_truthy
      expect { service.execute }.to change { runner.reload.token }
    end

    context 'with service unable to reset token' do
      before do
        allow(runner).to receive(:reset_token!).and_return(false)
      end

      it 'returns error response' do
        expect(service.execute.error?).to be_truthy
        expect(service.execute.message).to eq("Couldn't reset token")
      end
    end
  end
end
