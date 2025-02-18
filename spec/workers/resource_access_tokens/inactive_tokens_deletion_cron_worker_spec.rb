# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceAccessTokens::InactiveTokensDeletionCronWorker, feature_category: :system_access do
  subject(:worker) { described_class.new }

  it_behaves_like 'an idempotent worker'

  it_behaves_like 'worker with data consistency', described_class, data_consistency: :sticky

  describe '#perform' do
    it(
      'initiates deletion for project_bot users whose all tokens became inactive before cut_off date or without tokens',
      :aggregate_failures,
      :freeze_time,
      :sidekiq_inline
    ) do
      cut_off = ApplicationSetting::INACTIVE_RESOURCE_ACCESS_TOKENS_DELETE_AFTER_DAYS.days.ago
      admin_bot = Users::Internal.admin_bot

      active_personal_access_token =
        create(:personal_access_token)
      personal_access_token_expired_before_cut_off =
        create(:personal_access_token, expires_at: cut_off - 1.day)
      personal_access_token_expired_at_cut_off =
        create(:personal_access_token, expires_at: cut_off)
      personal_access_token_expired_after_cut_off =
        create(:personal_access_token, expires_at: cut_off + 1.day)
      personal_access_token_revoked_before_cut_off =
        create(:personal_access_token, :revoked, updated_at: cut_off - 1.second)
      personal_access_token_revoked_at_cut_off =
        create(:personal_access_token, :revoked, updated_at: cut_off)
      personal_access_token_revoked_after_cut_off =
        create(:personal_access_token, :revoked, updated_at: cut_off + 1.second)
      non_revoked_personal_access_token_updated_before_cut_off =
        create(:personal_access_token, updated_at: cut_off - 1.second)
      non_revoked_personal_access_token_updated_at_cut_off =
        create(:personal_access_token, updated_at: cut_off)
      non_revoked_personal_access_token_updated_after_cut_off =
        create(:personal_access_token, updated_at: cut_off + 1.second)

      active_resource_access_token =
        create(:resource_access_token)
      resource_access_token_expired_before_cut_off =
        create(:resource_access_token, expires_at: cut_off - 1.day)
      resource_access_token_expired_at_cut_off =
        create(:resource_access_token, expires_at: cut_off)
      resource_access_token_expired_after_cut_off =
        create(:resource_access_token, expires_at: cut_off + 1.day)
      resource_access_token_revoked_before_cut_off =
        create(:resource_access_token, :revoked, updated_at: cut_off - 1.second)
      resource_access_token_revoked_at_cut_off =
        create(:resource_access_token, :revoked, updated_at: cut_off)
      resource_access_token_revoked_after_cut_off =
        create(:resource_access_token, :revoked, updated_at: cut_off + 1.second)
      non_revoked_resource_access_token_updated_before_cut_off =
        create(:resource_access_token, updated_at: cut_off - 1.second)
      non_revoked_resource_access_token_updated_at_cut_off =
        create(:resource_access_token, updated_at: cut_off)
      non_revoked_resource_access_token_updated_after_cut_off =
        create(:personal_access_token, updated_at: cut_off + 1.second)
      resource_access_token_with_rotated_token_before_cut_off =
        create(:resource_access_token, :with_rotated_token, rotated_at: cut_off - 1.second)
      resource_access_token_with_rotated_token_at_cut_off =
        create(:resource_access_token, :with_rotated_token, rotated_at: cut_off)
      resource_access_token_with_rotated_token_after_cut_off =
        create(:resource_access_token, :with_rotated_token, rotated_at: cut_off + 1.second)

      user_1_without_any_tokens = create(:user)
      user_2_without_any_tokens = create(:user)

      project_bot_user_1_without_any_tokens = create(:user, :project_bot)
      project_bot_user_2_without_any_tokens = create(:user, :project_bot)

      tokens_to_keep = [
        active_personal_access_token,
        personal_access_token_expired_before_cut_off,
        personal_access_token_expired_at_cut_off,
        personal_access_token_expired_after_cut_off,
        personal_access_token_revoked_before_cut_off,
        personal_access_token_revoked_at_cut_off,
        personal_access_token_revoked_after_cut_off,
        non_revoked_personal_access_token_updated_before_cut_off,
        non_revoked_personal_access_token_updated_at_cut_off,
        non_revoked_personal_access_token_updated_after_cut_off,

        active_resource_access_token,
        resource_access_token_expired_at_cut_off,
        resource_access_token_expired_after_cut_off,
        resource_access_token_revoked_at_cut_off,
        resource_access_token_revoked_after_cut_off,
        non_revoked_resource_access_token_updated_before_cut_off,
        non_revoked_resource_access_token_updated_at_cut_off,
        non_revoked_resource_access_token_updated_after_cut_off,
        resource_access_token_with_rotated_token_before_cut_off,
        resource_access_token_with_rotated_token_at_cut_off,
        resource_access_token_with_rotated_token_after_cut_off
      ]
      users_to_keep = tokens_to_keep.map(&:user)
      users_to_keep.push(
        user_1_without_any_tokens,
        user_2_without_any_tokens
      )

      tokens_to_delete = [
        resource_access_token_expired_before_cut_off,
        resource_access_token_revoked_before_cut_off
      ]
      users_to_delete = tokens_to_delete.map(&:user)
      users_to_delete.push(
        project_bot_user_1_without_any_tokens,
        project_bot_user_2_without_any_tokens
      )

      worker.perform

      users_to_keep.each do |user|
        expect(
          Users::GhostUserMigration.find_by(
            user: user,
            initiator_user: admin_bot
          )
        ).not_to be_present
      end

      users_to_delete.each do |user|
        expect(
          Users::GhostUserMigration.find_by(
            user: user,
            initiator_user: admin_bot
          )
        ).to be_present
      end
    end

    context 'for runtime limit' do
      before do
        stub_const("#{described_class}::BATCH_SIZE", 1)
      end

      let_it_be(:resource_access_tokens) { create_list(:resource_access_token, 3) }

      context 'when runtime limit is reached' do
        before do
          allow_next_instance_of(Gitlab::Metrics::RuntimeLimiter) do |runtime_limiter|
            allow(runtime_limiter).to receive(:over_time?).and_return(false, true)
          end
        end

        it 'schedules the worker in 2 minutes with the last processed user id value as the cursor', :freeze_time do
          expect(described_class).to receive(:perform_in).with(2.minutes, resource_access_tokens.second.user.id)

          worker.perform
        end
      end

      context 'when runtime limit is not reached' do
        it 'does not schedule the worker' do
          expect(described_class).not_to receive(:perform_in)

          worker.perform
        end
      end
    end
  end
end
