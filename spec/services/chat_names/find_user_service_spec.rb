# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ChatNames::FindUserService, :clean_gitlab_redis_shared_state, feature_category: :user_profile do
  describe '#execute' do
    subject { described_class.new(team_id, user_id).execute }

    context 'find user mapping' do
      let_it_be(:user) { create(:user) }
      let(:chat_name) { create(:chat_name, user: user) }

      let(:team_id) { chat_name.team_id }
      let(:user_id) { chat_name.chat_id }

      context 'when existing user is requested' do
        it 'returns the existing chat_name' do
          is_expected.to eq(chat_name)
        end

        it 'updates the last used timestamp if one is not already set' do
          expect { subject }.to change { chat_name.reload.last_used_at }.from(nil)
        end

        it 'only updates an existing timestamp once within a certain time frame' do
          expect { described_class.new(team_id, user_id).execute }.to change { chat_name.reload.last_used_at }.from(nil)
          expect { described_class.new(team_id, user_id).execute }.not_to change { chat_name.reload.last_used_at }
        end

        it 'records activity for the related user' do
          expect_next_instance_of(Users::ActivityService, author: user) do |activity_service|
            expect(activity_service).to receive(:execute)
          end

          subject
        end
      end

      context 'when different user is requested' do
        let(:user_id) { 'non-existing-user' }

        it 'returns nil' do
          is_expected.to be_nil
        end
      end
    end
  end
end
