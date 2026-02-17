# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::DismissCalloutService, feature_category: :user_management do
  describe '#execute' do
    let_it_be(:user) { create(:user) }

    let(:params) { { feature_name: feature_name } }
    let(:feature_name) { Users::Callout.feature_names.each_key.first }

    subject(:execute) do
      described_class.new(
        container: nil, current_user: user, params: params
      ).execute
    end

    context 'when callout is not dissmissed yet' do
      before do
        allow(user).to receive(:dismissed_callout?).and_return(false)
      end

      it_behaves_like 'dismissing user callout', Users::Callout
    end

    context 'when callout is already dismissed - no database operations' do
      before do
        freeze_time do
          create(:callout, user: user, feature_name: feature_name, dismissed_at: Time.current)
        end
      end

      it 'does not perform database UPDATE queries' do
        # Reload user to ensure callouts are loaded
        user.reload

        queries = ActiveRecord::QueryRecorder.new do
          execute
        end

        update_queries = queries.log.select { |q| q.match?(/UPDATE/i) }
        expect(update_queries).to be_empty
      end
    end
  end
end
