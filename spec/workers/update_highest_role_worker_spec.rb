# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UpdateHighestRoleWorker, :clean_gitlab_redis_shared_state, feature_category: :seat_cost_management do
  include ExclusiveLeaseHelpers

  let(:worker) { described_class.new }

  describe '#perform' do
    context 'when user is not found' do
      it 'does not update or deletes any highest role', :aggregate_failures do
        expect { worker.perform(-1) }.not_to change { UserHighestRole.count }
      end
    end

    context 'when user is found' do
      let(:active_attributes) do
        {
          state: 'active',
          user_type: :human
        }
      end

      let(:user) { create(:user, active_attributes) }

      subject { worker.perform(user.id) }

      context 'when user is active and not internal' do
        context 'when user highest role exists' do
          it 'updates the highest role for the user' do
            user_highest_role = create(:user_highest_role, user: user)
            create(:group_member, :developer, user: user)

            expect { subject }
              .to change { user_highest_role.reload.highest_access_level }
              .from(nil)
              .to(Gitlab::Access::DEVELOPER)
          end
        end

        context 'when user highest role does not exist' do
          it 'creates the highest role for the user' do
            create(:group_member, :developer, user: user)

            expect { subject }.to change { UserHighestRole.count }.by(1)
          end
        end
      end

      context 'when user is either inactive or internal' do
        using RSpec::Parameterized::TableSyntax

        where(:additional_attributes) do
          [
            { state: 'blocked' },
            { user_type: :alert_bot }
          ]
        end

        with_them do
          it 'deletes highest role' do
            user = create(:user, active_attributes.merge(additional_attributes))
            create(:user_highest_role, user: user)

            expect { worker.perform(user.id) }.to change { UserHighestRole.count }.from(1).to(0)
          end
        end

        context 'when user highest role does not exist' do
          it 'does not delete a highest role' do
            user = create(:user, state: 'blocked')

            expect { worker.perform(user.id) }.not_to change { UserHighestRole.count }
          end
        end
      end
    end
  end
end
