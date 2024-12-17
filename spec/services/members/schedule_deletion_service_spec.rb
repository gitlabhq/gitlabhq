# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::ScheduleDeletionService, feature_category: :seat_cost_management do
  let_it_be(:namespace) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:scheduled_by) { create(:user) }
  let_it_be(:user_id) { user.id }

  subject(:service) { described_class.new(namespace, user_id, scheduled_by) }

  describe '#execute' do
    context 'when the namespace is not root' do
      let(:namespace) { create(:group, :nested) }

      it 'returns an error' do
        result = service.execute

        expect(result[:status]).to eq :error
        expect(result[:message]).to eq('Must be a root namespace')
      end
    end

    context 'when the user is an owner' do
      before_all do
        namespace.add_owner(scheduled_by)
      end

      it 'creates a deletion schedule' do
        expect { service.execute }.to change { Members::DeletionSchedule.count }.by(1)
      end

      it 'returns a success result' do
        result = service.execute

        expect(result[:status]).to eq :success
      end

      it 'sets the correct attributes on the deletion schedule' do
        result = service.execute
        deletion_schedule = result[:deletion_schedule]

        expect(deletion_schedule.namespace).to eq(namespace)
        expect(deletion_schedule.user).to eq(user)
        expect(deletion_schedule.scheduled_by).to eq(scheduled_by)
      end

      context 'when a deletion schedule is not unique' do
        it 'returns an error' do
          create(:members_deletion_schedules, namespace: namespace, user: user, scheduled_by: scheduled_by)

          result = service.execute

          expect(result[:status]).to eq :error
          expect(result[:message]).to eq(['User already scheduled for deletion'])
        end
      end

      context 'when the target user does not exist' do
        let(:user_id) { non_existing_record_id }

        it 'returns an error' do
          result = service.execute

          expect(result[:status]).to eq :error
          expect(result[:message]).to eq(['User must exist'])
        end
      end

      context 'when the user_id is nil' do
        let(:user_id) { nil }

        it 'returns an error' do
          result = service.execute

          expect(result[:status]).to eq :error
          expect(result[:message]).to eq(['User must exist'])
        end
      end
    end

    context 'when the user is an admin bot', :enable_admin_mode do
      let_it_be(:scheduled_by) { Users::Internal.admin_bot }

      it 'creates a deletion schedule' do
        result = service.execute

        expect(result[:status]).to eq :success
        expect(::Members::DeletionSchedule.count).to eq(1)
      end
    end

    context 'when the user is not authorized' do
      it 'returns an error' do
        result = service.execute

        expect(result[:status]).to eq :error
        expect(result[:message]).to eq('User not authorized')
      end
    end
  end
end
