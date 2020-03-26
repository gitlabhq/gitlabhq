# frozen_string_literal: true

require 'spec_helper'

describe UpdateHighestRoleWorker, :clean_gitlab_redis_shared_state do
  include ExclusiveLeaseHelpers

  let(:worker) { described_class.new }

  describe '#perform' do
    let(:active_scope_attributes) do
      {
        state: 'active',
        ghost: false,
        user_type: nil
      }
    end
    let(:user) { create(:user, attributes) }

    subject { worker.perform(user.id) }

    context 'when user is found' do
      let(:attributes) { active_scope_attributes }

      it 'updates the highest role for the user' do
        user_highest_role = create(:user_highest_role, user: user)
        create(:group_member, :developer, user: user)

        expect { subject }
          .to change { user_highest_role.reload.highest_access_level }
          .from(nil)
          .to(Gitlab::Access::DEVELOPER)
      end
    end

    context 'when user is not found' do
      shared_examples 'no update' do
        it 'does not update any highest role' do
          expect(Users::UpdateHighestMemberRoleService).not_to receive(:new)

          worker.perform(user.id)
        end
      end

      context 'when user is blocked' do
        let(:attributes) { active_scope_attributes.merge(state: 'blocked') }

        it_behaves_like 'no update'
      end

      context 'when user is a ghost' do
        let(:attributes) { active_scope_attributes.merge(ghost: true) }

        it_behaves_like 'no update'
      end

      context 'when user has a user type' do
        let(:attributes) { active_scope_attributes.merge(user_type: :alert_bot) }

        it_behaves_like 'no update'
      end
    end
  end
end
