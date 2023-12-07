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
      worker.perform

      expect_any_instance_of(::Users::DeactivateService) do |deactivation_service|
        expect(deactivation_service).not_to have_received(:execute)
      end
    end

    shared_examples 'deactivates dormant users' do
      specify do
        expect { worker.perform }
          .to change { dormant.reload.state }
          .to('deactivated')
          .and change { inactive.reload.state }
          .to('deactivated')
      end
    end

    shared_examples 'deactivates certain user types' do
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
        specify do
          user = create(:user, user_type: user_type, state: :active, last_activity_on: Gitlab::CurrentSettings.deactivate_dormant_users_period.days.ago.to_date)

          worker.perform

          expect_any_instance_of(::Users::DeactivateService) do |deactivation_service|
            if expected_state == 'deactivated'
              expect(deactivation_service).to receive(:execute).with(user).and_call_original
            else
              expect(deactivation_service).not_to have_received(:execute).with(user)
            end
          end

          expect(user.reload.state).to eq expected_state
        end
      end
    end

    shared_examples 'does not deactivate non-active users' do
      specify do
        human_user = create(:user, user_type: :human, state: :blocked, last_activity_on: Gitlab::CurrentSettings.deactivate_dormant_users_period.days.ago.to_date)
        service_user = create(:user, user_type: :service_user, state: :blocked, last_activity_on: Gitlab::CurrentSettings.deactivate_dormant_users_period.days.ago.to_date)

        worker.perform

        expect_any_instance_of(::Users::DeactivateService) do |deactivation_service|
          expect(deactivation_service).not_to have_received(:execute).with(human_user)
          expect(deactivation_service).not_to have_received(:execute).with(service_user)
        end
      end
    end

    shared_examples 'does not deactivate recently created users' do
      specify do
        worker.perform

        expect_any_instance_of(::Users::DeactivateService) do |deactivation_service|
          expect(deactivation_service).not_to have_received(:execute).with(inactive_recently_created)
        end
      end
    end

    context 'when automatic deactivation of dormant users is enabled' do
      before do
        stub_application_setting(deactivate_dormant_users: true)
      end

      context 'when admin mode is not enabled', :do_not_mock_admin_mode_setting do
        include_examples 'deactivates dormant users'
        include_examples 'deactivates certain user types'
        include_examples 'does not deactivate non-active users'
        include_examples 'does not deactivate recently created users'
      end

      context 'when admin mode is enabled', :request_store do
        before do
          stub_application_setting(admin_mode: true)
        end

        include_examples 'deactivates dormant users'
        include_examples 'deactivates certain user types'
        include_examples 'does not deactivate non-active users'
        include_examples 'does not deactivate recently created users'
      end
    end

    context 'when automatic deactivation of dormant users is disabled' do
      before do
        stub_application_setting(deactivate_dormant_users: false)
      end

      it 'does nothing' do
        worker.perform

        expect_any_instance_of(::Users::DeactivateService) do |deactivation_service|
          expect(deactivation_service).not_to have_received(:execute)
        end
      end
    end
  end
end
