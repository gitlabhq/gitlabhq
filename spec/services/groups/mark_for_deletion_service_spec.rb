# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::MarkForDeletionService, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let(:licensed) { false }

  subject(:result) { described_class.new(group, user, {}).execute(licensed: licensed) }

  context 'when marking the group for deletion' do
    context 'with user that can admin the group' do
      let_it_be_with_reload(:group) { create(:group, owners: user) }

      context 'for a group that has not been marked for deletion' do
        it 'marks the group for deletion', :freeze_time do
          result

          expect(group.marked_for_deletion_on).to eq(Time.zone.today)
          expect(group.deleting_user).to eq(user)
        end

        it 'returns success' do
          expect(result).to eq({ status: :success })
        end

        it 'logs the event' do
          allow(Gitlab::AppLogger).to receive(:info).and_call_original
          expect(Gitlab::AppLogger).to receive(:info).with(
            "User #{user.id} marked group #{group.full_path} for deletion"
          )

          result
        end

        context 'when marking for deletion fails' do
          before do
            expect_next_instance_of(GroupDeletionSchedule) do |group_deletion_schedule|
              allow(group_deletion_schedule).to receive_message_chain(:errors, :full_messages)
                .and_return(['error message'])

              allow(group_deletion_schedule).to receive(:save).and_return(false)
            end
          end

          it 'returns error' do
            expect(result).to eq({ status: :error, message: 'error message' })
          end
        end

        context 'when the downtier_delayed_deletion feature flag is disabled' do
          before do
            stub_feature_flags(downtier_delayed_deletion: false)
          end

          it 'returns error' do
            expect(result).to eq({ status: :error, message: 'Cannot mark group for deletion: feature not supported' })
          end

          context 'when the feature is licensed', unless: Gitlab.ee? do
            let(:licensed) { true }

            it 'is successful' do
              expect(result[:status]).to eq(:success)
            end
          end
        end
      end

      context 'for a group that has been marked for deletion' do
        let(:deletion_date) { 3.days.ago }
        let(:group) do
          create(:group_with_deletion_schedule,
            marked_for_deletion_on: deletion_date,
            owners: user,
            deleting_user: user)
        end

        it 'does not change the attributes associated with delayed deletion' do
          result

          expect(group.marked_for_deletion_on).to eq(deletion_date.to_date)
          expect(group.deleting_user).to eq(user)
        end

        it 'returns error' do
          expect(result).to eq({ status: :error, message: 'Group has been already marked for deletion' })
        end
      end
    end

    context 'with a user that cannot admin the group' do
      let(:group) { build(:group) }

      it 'does not mark the group for deletion' do
        result

        expect(group.marked_for_deletion?).to be_falsey
      end

      it 'returns error' do
        expect(result).to eq({ status: :error, message: 'You are not authorized to perform this action' })
      end
    end
  end
end
