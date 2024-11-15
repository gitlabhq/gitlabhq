# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::ScheduleDeletionService, feature_category: :seat_cost_management do
  let_it_be(:namespace) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:scheduled_by) { create(:user) }

  subject(:service) { described_class.new(namespace, user, scheduled_by) }

  describe '#execute' do
    context 'when the namespace is not root' do
      let(:namespace) { create(:group, :nested) }

      it 'returns an error' do
        result = service.execute

        expect(result[:status]).to eq :error
        expect(result[:message]).to eq('Must be a root namespace')
      end
    end

    context 'when the user is not authorized' do
      it 'returns an error' do
        result = service.execute

        expect(result[:status]).to eq :error
        expect(result[:message]).to eq('User not authorized')
      end
    end

    context 'when the user is authorized' do
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
    end
  end
end
