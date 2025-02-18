# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Environments::FeatureFlags::ResetClientTokenService, :aggregate_failures, feature_category: :feature_flags do
  let_it_be(:authorized_user) { create(:user) }
  let_it_be(:project) { create(:project, maintainers: [authorized_user]) }

  let_it_be(:client) { create(:operations_feature_flags_client, project: project) }

  subject(:execute) { described_class.new(current_user: current_user, feature_flags_client: client).execute! }

  context 'with an authorized user' do
    let(:current_user) { authorized_user }

    it 'does reset feature flag client token and returns success' do
      expect { execute }.to change { client.reload.token }
      expect(execute.success?).to be_truthy
    end
  end

  context 'with an unauthorized user' do
    where(:current_user) do
      [
        build(:user),
        nil
      ]
    end

    with_them do
      it 'does not reset feature flags client token and returns error response' do
        expect(execute.error?).to be_truthy
        expect(execute.message).to eq('Not permitted to reset token')
      end
    end
  end
end
