# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::DeactivateDormantUsersWorker, feature_category: :seat_cost_management do
  using RSpec::Parameterized::TableSyntax

  describe '#perform' do
    let_it_be(:dormant) { create(:user, last_activity_on: Gitlab::CurrentSettings.deactivate_dormant_users_period.days.ago.to_date) }
    let_it_be(:inactive) { create(:user, last_activity_on: nil, created_at: User::MINIMUM_DAYS_CREATED.days.ago.to_date) }
    let_it_be(:inactive_recently_created) { create(:user, last_activity_on: nil, created_at: (User::MINIMUM_DAYS_CREATED - 1).days.ago.to_date) }

    subject(:worker) { described_class.new }

    it 'does not run for SaaS', :saas do
      # Now makes a call to current settings to determine period of dormancy

      worker.perform

      expect(User.dormant.count).to eq(1)
      expect(User.with_no_activity.count).to eq(1)
    end

    context 'when automatic deactivation of dormant users is enabled' do
      before do
        stub_application_setting(deactivate_dormant_users: true)
      end

      it 'deactivates dormant users' do
        worker.perform

        expect(User.dormant.count).to eq(0)
        expect(User.with_no_activity.count).to eq(0)
      end

      where(:user_type, :expected_state) do
        :human             | 'deactivated'
        :human_deprecated  | 'deactivated'
        :support_bot       | 'active'
        :alert_bot         | 'active'
        :visual_review_bot | 'active'
        :service_user      | 'deactivated'
        :ghost             | 'active'
        :project_bot       | 'active'
        :migration_bot     | 'active'
        :security_bot      | 'active'
        :automation_bot    | 'active'
      end
      with_them do
        it 'deactivates certain user types' do
          user = create(:user, user_type: user_type, state: :active, last_activity_on: Gitlab::CurrentSettings.deactivate_dormant_users_period.days.ago.to_date)

          worker.perform

          expect(user.reload.state).to eq(expected_state)
        end
      end

      it 'does not deactivate non-active users' do
        human_user = create(:user, user_type: :human, state: :blocked, last_activity_on: Gitlab::CurrentSettings.deactivate_dormant_users_period.days.ago.to_date)
        human_user2 = create(:user, user_type: :human_deprecated, state: :blocked, last_activity_on: Gitlab::CurrentSettings.deactivate_dormant_users_period.days.ago.to_date)
        service_user = create(:user, user_type: :service_user, state: :blocked, last_activity_on: Gitlab::CurrentSettings.deactivate_dormant_users_period.days.ago.to_date)

        worker.perform

        expect(human_user.reload.state).to eq('blocked')
        expect(human_user2.reload.state).to eq('blocked')
        expect(service_user.reload.state).to eq('blocked')
      end

      it 'does not deactivate recently created users' do
        worker.perform

        expect(inactive_recently_created.reload.state).to eq('active')
      end

      it 'triggers update of highest user role for deactivated users', :clean_gitlab_redis_shared_state do
        [dormant, inactive].each do |user|
          expect(UpdateHighestRoleWorker).to receive(:perform_in).with(anything, user.id)
        end

        worker.perform
      end
    end

    context 'when automatic deactivation of dormant users is disabled' do
      before do
        stub_application_setting(deactivate_dormant_users: false)
      end

      it 'does nothing' do
        worker.perform

        expect(User.dormant.count).to eq(1)
        expect(User.with_no_activity.count).to eq(1)
      end
    end
  end
end
