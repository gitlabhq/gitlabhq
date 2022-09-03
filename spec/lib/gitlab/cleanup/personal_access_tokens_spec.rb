# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Cleanup::PersonalAccessTokens do
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project_bot) { create(:user, :project_bot) }

  let(:group_full_path) { group.full_path }
  let(:logger) { instance_double(Gitlab::AppJsonLogger, info: nil, warn: nil) }
  let(:last_used_at) { 1.month.ago.beginning_of_hour }
  let!(:unused_token)  { create(:personal_access_token) }

  let!(:old_unused_token) do
    create(:personal_access_token, created_at: last_used_at - 1.minute)
  end

  let!(:old_actively_used_token) do
    create(:personal_access_token, created_at: last_used_at - 1.minute, last_used_at: 1.day.ago)
  end

  let!(:old_unused_token_for_non_group_member) do
    create(:personal_access_token, created_at: last_used_at - 1.minute)
  end

  let!(:old_unused_token_for_subgroup_member) do
    create(:personal_access_token, created_at: last_used_at - 1.minute)
  end

  let!(:old_unused_project_access_token) do
    create(:personal_access_token, user: project_bot, created_at: last_used_at - 1.minute)
  end

  let!(:old_formerly_used_token) do
    create(:personal_access_token,
      created_at: last_used_at - 1.minute,
      last_used_at: last_used_at - 1.minute
    )
  end

  before do
    group.add_member(old_formerly_used_token.user, Gitlab::Access::DEVELOPER)
    group.add_member(old_actively_used_token.user, Gitlab::Access::DEVELOPER)
    group.add_member(unused_token.user, Gitlab::Access::DEVELOPER)
    group.add_member(old_unused_token.user, Gitlab::Access::DEVELOPER)
    group.add_member(project_bot, Gitlab::Access::MAINTAINER)

    subgroup.add_member(old_unused_token_for_subgroup_member.user, Gitlab::Access::DEVELOPER)
  end

  subject do
    described_class.new(
      logger: logger,
      cut_off_date: last_used_at,
      group_full_path: group_full_path
    )
  end

  context 'when initialized with an invalid logger' do
    let(:logger) { "not a logger" }

    it 'raises error' do
      expect do
        subject.run!
      end.to raise_error('Invalid logger: not a logger')
    end
  end

  describe '#run!' do
    context 'when invalid group path passed' do
      let(:group_full_path) { 'notagroup' }

      it 'raises error' do
        expect do
          subject.run!
        end.to raise_error("Group with full_path notagroup not found")
      end
    end

    context 'in a real run' do
      let(:args) { { dry_run: false } }

      context 'when revoking unused tokens' do
        it 'revokes human-owned tokens created and last used over 1 year ago' do
          subject.run!(**args)

          expect(PersonalAccessToken.active).to contain_exactly(
            unused_token,
            old_actively_used_token,
            old_unused_project_access_token,
            old_unused_token_for_non_group_member,
            old_unused_token_for_subgroup_member
          )
          expect(PersonalAccessToken.revoked).to contain_exactly(
            old_unused_token,
            old_formerly_used_token
          )
        end
      end

      context 'when revoking used and unused tokens' do
        let(:args) { { dry_run: false, revoke_active_tokens: true } }

        it 'revokes human-owned tokens created over 1 year ago' do
          subject.run!(**args)

          expect(PersonalAccessToken.active).to contain_exactly(
            unused_token,
            old_unused_project_access_token,
            old_unused_token_for_non_group_member,
            old_unused_token_for_subgroup_member
          )
          expect(PersonalAccessToken.revoked).to contain_exactly(
            old_unused_token,
            old_actively_used_token,
            old_formerly_used_token
          )
        end
      end

      it 'updates updated_at' do
        expect do
          subject.run!(**args)
        end.to change {
          old_unused_token.reload.updated_at
        }
      end

      it 'logs action as done' do
        message = {
          dry_run: false,
          token_count: 2,
          updated_count: 2,
          tokens: instance_of(Array),
          group_full_path: group_full_path
        }
        expect(logger).to receive(:info).with(include(message))
        subject.run!(**args)
      end
    end

    context 'in a dry run' do
      # Dry run is the default
      let(:args) { {} }

      it 'does not revoke any tokens' do
        expect do
          subject.run!(**args)
        end.to not_change {
          PersonalAccessToken.active.count
        }
      end

      it 'logs what could be revoked' do
        message = {
          dry_run: true,
          token_count: 2,
          updated_count: 0,
          tokens: instance_of(Array),
          group_full_path: group_full_path
        }
        expect(logger).to receive(:info).with(include(message))
        subject.run!(**args)
      end
    end
  end
end
