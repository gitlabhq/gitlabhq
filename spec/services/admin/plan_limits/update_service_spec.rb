# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::PlanLimits::UpdateService, feature_category: :shared do
  let_it_be(:user) { create(:admin) }
  let_it_be(:plan) { create(:plan, name: 'free') }
  let_it_be(:limits) { plan.actual_limits }
  let_it_be(:params) do
    {
      ci_pipeline_size: 101,
      ci_active_jobs: 102,
      ci_project_subscriptions: 104,
      ci_pipeline_schedules: 105,
      ci_needs_size_limit: 106,
      ci_registered_group_runners: 107,
      ci_registered_project_runners: 108,
      conan_max_file_size: 10,
      enforcement_limit: 100,
      generic_packages_max_file_size: 20,
      helm_max_file_size: 25,
      notification_limit: 95,
      maven_max_file_size: 40,
      npm_max_file_size: 60,
      nuget_max_file_size: 60,
      pypi_max_file_size: 70,
      terraform_module_max_file_size: 80,
      storage_size_limit: 90,
      pipeline_hierarchy_size: 250
    }
  end

  subject(:update_plan_limits) { described_class.new(params, current_user: user, plan: plan).execute }

  context 'when current_user is an admin', :enable_admin_mode do
    context 'when the update is successful', :freeze_time do
      let(:current_timestamp) { Time.current.utc.to_i }

      it 'updates all attributes' do
        update_plan_limits

        params.each do |key, value|
          expect(limits.send(key)).to eq value
        end
      end

      it 'logs the allowed attributes only', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/436572' do
        update_plan_limits

        expect(limits.limits_history).to eq(
          { "enforcement_limit" =>
                                [{ "user_id" => user.id, "username" => user.username,
                                   "timestamp" => current_timestamp, "value" => 100 }],
            "notification_limit" =>
                                [{ "user_id" => user.id, "username" => user.username,
                                   "timestamp" => current_timestamp, "value" => 95 }],
            "storage_size_limit" =>
                                [{ "user_id" => user.id, "username" => user.username,
                                   "timestamp" => current_timestamp, "value" => 90 }] }
        )
      end

      it 'returns success' do
        response = update_plan_limits

        expect(response[:status]).to eq :success
      end
    end

    context 'when the update is unsuccessful' do
      context 'when notification_limit is less than storage_size_limit' do
        let(:params) { { notification_limit: 2 } }

        before do
          limits.update!(
            storage_size_limit: 5,
            enforcement_limit: 10
          )
        end

        it 'returns an error' do
          response = update_plan_limits

          expect(response[:status]).to eq :error
          expect(response[:message]).to eq [
            "Notification limit must be greater than or equal to the dashboard limit (5)"
          ]
        end
      end

      context 'when notification_limit is greater than enforcement_limit' do
        let(:params) { { notification_limit: 11 } }

        before do
          limits.update!(
            storage_size_limit: 5,
            enforcement_limit: 10
          )
        end

        it 'returns an error' do
          response = update_plan_limits

          expect(response[:status]).to eq :error
          expect(response[:message]).to eq [
            "Notification limit must be less than or equal to the enforcement limit (10)"
          ]
        end
      end

      context 'when enforcement_limit is less than storage_size_limit' do
        let(:params) { { enforcement_limit: 9 } }

        before do
          limits.update!(
            storage_size_limit: 10,
            notification_limit: 9
          )
        end

        it 'returns an error' do
          response = update_plan_limits

          expect(response[:status]).to eq :error
          expect(response[:message]).to eq [
            "Enforcement limit must be greater than or equal to the dashboard limit (10)"
          ]
        end
      end

      context 'when enforcement_limit is less than notification_limit' do
        let(:params) { { enforcement_limit: 9 } }

        before do
          limits.update!(
            storage_size_limit: 9,
            notification_limit: 10
          )
        end

        it 'returns an error' do
          response = update_plan_limits

          expect(response[:status]).to eq :error
          expect(response[:message]).to eq [
            "Enforcement limit must be greater than or equal to the notification limit (10)"
          ]
        end
      end

      context 'when storage_size_limit is greater than notification_limit' do
        let(:params) { { storage_size_limit: 11 } }

        before do
          limits.update!(
            enforcement_limit: 12,
            notification_limit: 10
          )
        end

        it 'returns an error' do
          response = update_plan_limits

          expect(response[:status]).to eq :error
          expect(response[:message]).to eq [
            "Dashboard limit must be less than or equal to the notification limit (10)"
          ]
        end
      end

      context 'when storage_size_limit is greater than enforcement_limit' do
        let(:params) { { storage_size_limit: 11 } }

        before do
          limits.update!(
            enforcement_limit: 10,
            notification_limit: 11
          )
        end

        it 'returns an error' do
          response = update_plan_limits

          expect(response[:status]).to eq :error
          expect(response[:message]).to eq [
            "Dashboard limit must be less than or equal to the enforcement limit (10)"
          ]
        end

        context 'when enforcement_limit is 0' do
          before do
            limits.update!(
              enforcement_limit: 0
            )
          end

          it 'does not return an error' do
            response = update_plan_limits

            expect(response[:status]).to eq :success
          end
        end
      end
    end

    context 'when setting limit to unlimited' do
      before do
        limits.update!(
          notification_limit: 10,
          storage_size_limit: 10,
          enforcement_limit: 10
        )
      end

      [:notification_limit, :enforcement_limit, :storage_size_limit].each do |limit|
        context "for #{limit}" do
          let(:params) { { limit => 0 } }

          it 'is successful' do
            response = update_plan_limits

            expect(response[:status]).to eq :success
          end
        end
      end
    end
  end

  context 'when the user is not an admin' do
    let(:user) { create(:user) }

    it 'returns an error' do
      response = update_plan_limits

      expect(response[:status]).to eq :error
      expect(response[:message]).to eq 'Access denied'
    end
  end
end
