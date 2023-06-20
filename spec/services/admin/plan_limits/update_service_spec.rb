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
      enforcement_limit: 15,
      generic_packages_max_file_size: 20,
      helm_max_file_size: 25,
      notification_limit: 30,
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
    context 'when the update is successful' do
      it 'updates all attributes' do
        expect_next_instance_of(described_class) do |instance|
          expect(instance).to receive(:parsed_params).and_call_original
        end

        update_plan_limits

        params.each do |key, value|
          expect(limits.send(key)).to eq value
        end
      end

      it 'returns success' do
        response = update_plan_limits

        expect(response[:status]).to eq :success
      end
    end

    context 'when the update is unsuccessful' do
      let(:params) { { notification_limit: 'abc' } }

      it 'returns an error' do
        response = update_plan_limits

        expect(response[:status]).to eq :error
        expect(response[:message]).to include 'Notification limit is not a number'
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
