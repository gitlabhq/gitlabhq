# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::RestoreService, feature_category: :groups_and_projects do
  let(:user) { create(:user) }
  let(:group) do
    create(:group_with_deletion_schedule,
      marked_for_deletion_on: 1.day.ago,
      deleting_user: user)
  end

  subject(:execute) { described_class.new(group, user, {}).execute }

  context 'when restoring the group' do
    context 'with a user that can admin the group' do
      before do
        group.add_owner(user)
      end

      context 'for a group that has been marked for deletion' do
        it 'removes the mark for deletion' do
          execute

          expect(group.marked_for_deletion_on).to be_nil
          expect(group.deleting_user).to be_nil
        end

        it 'returns success' do
          result = execute

          expect(result).to eq({ status: :success })
        end

        context 'when restoring fails' do
          it 'returns error' do
            allow(group.deletion_schedule).to receive(:destroy).and_return(false)

            result = execute

            expect(result).to eq({ status: :error, message: 'Could not restore the group' })
          end
        end
      end

      context 'for a group that has not been marked for deletion' do
        let(:group) { create(:group) }

        it 'does not change the attributes associated with delayed deletion' do
          execute

          expect(group.marked_for_deletion_on).to be_nil
          expect(group.deleting_user).to be_nil
        end

        it 'returns error' do
          result = execute

          expect(result).to eq({ status: :error, message: 'Group has not been marked for deletion' })
        end
      end

      it 'logs the restore' do
        allow(Gitlab::AppLogger).to receive(:info)

        expect(::Gitlab::AppLogger).to receive(:info).with("User #{user.id} restored group #{group.full_path}")

        execute
      end

      context 'when the group is deletion is in progress' do
        before do
          group.namespace_details.update!(deleted_at: Time.current)
        end

        it { is_expected.to eq({ status: :error, message: 'Group deletion is in progress' }) }
      end
    end

    context 'with a user that cannot admin the group' do
      it 'does not restore the group' do
        execute

        expect(group.marked_for_deletion?).to be_truthy
      end

      it 'returns error' do
        result = execute

        expect(result).to eq({ status: :error, message: 'You are not authorized to perform this action' })
      end
    end
  end
end
