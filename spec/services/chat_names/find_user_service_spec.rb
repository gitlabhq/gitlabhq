# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ChatNames::FindUserService, :clean_gitlab_redis_shared_state do
  describe '#execute' do
    let(:integration) { create(:service) }

    subject { described_class.new(integration, params).execute }

    context 'find user mapping' do
      let(:user) { create(:user) }
      let!(:chat_name) { create(:chat_name, user: user, integration: integration) }

      context 'when existing user is requested' do
        let(:params) { { team_id: chat_name.team_id, user_id: chat_name.chat_id } }

        it 'returns the existing chat_name' do
          is_expected.to eq(chat_name)
        end

        it 'updates the last used timestamp if one is not already set' do
          expect(chat_name.last_used_at).to be_nil

          subject

          expect(chat_name.reload.last_used_at).to be_present
        end

        it 'only updates an existing timestamp once within a certain time frame' do
          service = described_class.new(integration, params)

          expect(chat_name.last_used_at).to be_nil

          service.execute

          time = chat_name.reload.last_used_at

          service.execute

          expect(chat_name.reload.last_used_at).to eq(time)
        end
      end

      context 'when different user is requested' do
        let(:params) { { team_id: chat_name.team_id, user_id: 'non-existing-user' } }

        it 'returns existing user' do
          is_expected.to be_nil
        end
      end
    end
  end
end
