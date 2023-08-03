# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::DeactivateDormantUsersWorker, feature_category: :seat_cost_management do
  using RSpec::Parameterized::TableSyntax

  describe '#perform' do
    let_it_be(:dormant) { create(:user, last_activity_on: Gitlab::CurrentSettings.deactivate_dormant_users_period.days.ago.to_date) }
    let_it_be(:inactive) { create(:user, last_activity_on: nil, created_at: User::MINIMUM_DAYS_CREATED.days.ago.to_date) }
    let_it_be(:inactive_recently_created) { create(:user, last_activity_on: nil, created_at: (User::MINIMUM_DAYS_CREATED - 1).days.ago.to_date) }

    let(:admin_bot) { create(:user, :admin_bot) }
    let(:deactivation_service) { instance_spy(Users::DeactivateService) }

    before do
      allow(Users::DeactivateService).to receive(:new).and_return(deactivation_service)
    end

    subject(:worker) { described_class.new }

    it 'does not run for SaaS', :saas do
      # Now makes a call to current settings to determine period of dormancy

      worker.perform

      expect(deactivation_service).not_to have_received(:execute)
    end

    context 'when automatic deactivation of dormant users is enabled' do
      before do
        stub_application_setting(deactivate_dormant_users: true)
      end

      it 'deactivates dormant users' do
        worker.perform

        expect(deactivation_service).to have_received(:execute).twice
      end

      where(:user_type, :expected_state) do
        :human | 'deactivated'
        :support_bot | 'active'
        :alert_bot | 'active'
        :visual_review_bot | 'active'
        :service_user | 'deactivated'
        :ghost | 'active'
        :project_bot | 'active'
        :migration_bot | 'active'
        :security_bot | 'active'
        :automation_bot | 'active'
      end

      with_them do
        it 'deactivates certain user types' do
          user = create(:user, user_type: user_type, state: :active, last_activity_on: Gitlab::CurrentSettings.deactivate_dormant_users_period.days.ago.to_date)

          worker.perform

          if expected_state == 'deactivated'
            expect(deactivation_service).to have_received(:execute).with(user)
          else
            expect(deactivation_service).not_to have_received(:execute).with(user)
          end
        end
      end

      it 'does not deactivate non-active users' do
        human_user = create(:user, user_type: :human, state: :blocked, last_activity_on: Gitlab::CurrentSettings.deactivate_dormant_users_period.days.ago.to_date)
        service_user = create(:user, user_type: :service_user, state: :blocked, last_activity_on: Gitlab::CurrentSettings.deactivate_dormant_users_period.days.ago.to_date)

        worker.perform

        expect(deactivation_service).not_to have_received(:execute).with(human_user)
        expect(deactivation_service).not_to have_received(:execute).with(service_user)
      end

      it 'does not deactivate recently created users' do
        worker.perform

        expect(deactivation_service).not_to have_received(:execute).with(inactive_recently_created)
      end
    end

    context 'when automatic deactivation of dormant users is disabled' do
      before do
        stub_application_setting(deactivate_dormant_users: false)
      end

      it 'does nothing' do
        worker.perform

        expect(deactivation_service).not_to have_received(:execute)
      end
    end
  end
end
