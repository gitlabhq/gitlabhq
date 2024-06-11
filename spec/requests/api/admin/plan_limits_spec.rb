# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Admin::PlanLimits, 'PlanLimits', feature_category: :shared do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:plan) { create(:plan, name: 'default') }
  let_it_be(:path) { '/application/plan_limits' }

  describe 'GET /application/plan_limits' do
    it_behaves_like 'GET request permissions for admin mode'

    context 'as an admin user' do
      context 'no params' do
        it 'returns plan limits', :aggregate_failures do
          get api(path, admin, admin_mode: true)

          expect(json_response).to be_an Hash
          expect(json_response['ci_instance_level_variables']).to eq(Plan.default.actual_limits.ci_instance_level_variables)
          expect(json_response['ci_pipeline_size']).to eq(Plan.default.actual_limits.ci_pipeline_size)
          expect(json_response['ci_active_jobs']).to eq(Plan.default.actual_limits.ci_active_jobs)
          expect(json_response['ci_project_subscriptions']).to eq(Plan.default.actual_limits.ci_project_subscriptions)
          expect(json_response['ci_pipeline_schedules']).to eq(Plan.default.actual_limits.ci_pipeline_schedules)
          expect(json_response['ci_needs_size_limit']).to eq(Plan.default.actual_limits.ci_needs_size_limit)
          expect(json_response['ci_registered_group_runners']).to eq(Plan.default.actual_limits.ci_registered_group_runners)
          expect(json_response['ci_registered_project_runners']).to eq(Plan.default.actual_limits.ci_registered_project_runners)
          expect(json_response['dotenv_size']).to eq(Plan.default.actual_limits.dotenv_size)
          expect(json_response['dotenv_variables']).to eq(Plan.default.actual_limits.dotenv_variables)
          expect(json_response['conan_max_file_size']).to eq(Plan.default.actual_limits.conan_max_file_size)
          expect(json_response['generic_packages_max_file_size']).to eq(Plan.default.actual_limits.generic_packages_max_file_size)
          expect(json_response['helm_max_file_size']).to eq(Plan.default.actual_limits.helm_max_file_size)
          expect(json_response['limits_history']).to eq(Plan.default.actual_limits.limits_history)
          expect(json_response['maven_max_file_size']).to eq(Plan.default.actual_limits.maven_max_file_size)
          expect(json_response['npm_max_file_size']).to eq(Plan.default.actual_limits.npm_max_file_size)
          expect(json_response['nuget_max_file_size']).to eq(Plan.default.actual_limits.nuget_max_file_size)
          expect(json_response['pypi_max_file_size']).to eq(Plan.default.actual_limits.pypi_max_file_size)
          expect(json_response['terraform_module_max_file_size']).to eq(Plan.default.actual_limits.terraform_module_max_file_size)
          expect(json_response['storage_size_limit']).to eq(Plan.default.actual_limits.storage_size_limit)
          expect(json_response['pipeline_hierarchy_size']).to eq(Plan.default.actual_limits.pipeline_hierarchy_size)
        end
      end

      context 'correct plan name in params' do
        before do
          @params = { plan_name: 'default' }
        end

        it 'returns plan limits', :aggregate_failures do
          get api(path, admin, admin_mode: true), params: @params

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_an Hash
          expect(json_response['ci_instance_level_variables']).to eq(Plan.default.actual_limits.ci_instance_level_variables)
          expect(json_response['ci_pipeline_size']).to eq(Plan.default.actual_limits.ci_pipeline_size)
          expect(json_response['ci_active_jobs']).to eq(Plan.default.actual_limits.ci_active_jobs)
          expect(json_response['ci_project_subscriptions']).to eq(Plan.default.actual_limits.ci_project_subscriptions)
          expect(json_response['ci_pipeline_schedules']).to eq(Plan.default.actual_limits.ci_pipeline_schedules)
          expect(json_response['ci_needs_size_limit']).to eq(Plan.default.actual_limits.ci_needs_size_limit)
          expect(json_response['ci_registered_group_runners']).to eq(Plan.default.actual_limits.ci_registered_group_runners)
          expect(json_response['ci_registered_project_runners']).to eq(Plan.default.actual_limits.ci_registered_project_runners)
          expect(json_response['conan_max_file_size']).to eq(Plan.default.actual_limits.conan_max_file_size)
          expect(json_response['generic_packages_max_file_size']).to eq(Plan.default.actual_limits.generic_packages_max_file_size)
          expect(json_response['helm_max_file_size']).to eq(Plan.default.actual_limits.helm_max_file_size)
          expect(json_response['maven_max_file_size']).to eq(Plan.default.actual_limits.maven_max_file_size)
          expect(json_response['npm_max_file_size']).to eq(Plan.default.actual_limits.npm_max_file_size)
          expect(json_response['nuget_max_file_size']).to eq(Plan.default.actual_limits.nuget_max_file_size)
          expect(json_response['pypi_max_file_size']).to eq(Plan.default.actual_limits.pypi_max_file_size)
          expect(json_response['terraform_module_max_file_size']).to eq(Plan.default.actual_limits.terraform_module_max_file_size)
          expect(json_response['storage_size_limit']).to eq(Plan.default.actual_limits.storage_size_limit)
          expect(json_response['pipeline_hierarchy_size']).to eq(Plan.default.actual_limits.pipeline_hierarchy_size)
        end
      end

      context 'invalid plan name in params' do
        before do
          @params = { plan_name: 'my-plan' }
        end

        it 'returns validation error', :aggregate_failures do
          get api(path, admin, admin_mode: true), params: @params

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']).to eq('plan_name does not have a valid value')
        end
      end
    end
  end

  describe 'PUT /application/plan_limits' do
    it_behaves_like 'PUT request permissions for admin mode' do
      let(:params) { { plan_name: 'default' } }
    end

    context 'as an admin user', :freeze_time do
      let(:current_timestamp) { Time.current.utc.to_i }

      context 'correct params' do
        it 'updates multiple plan limits', :aggregate_failures do
          put api(path, admin, admin_mode: true), params: {
            plan_name: 'default',
            ci_instance_level_variables: 103,
            ci_pipeline_size: 101,
            ci_active_jobs: 102,
            ci_project_subscriptions: 104,
            ci_pipeline_schedules: 105,
            ci_needs_size_limit: 106,
            ci_registered_group_runners: 107,
            ci_registered_project_runners: 108,
            dotenv_size: 109,
            dotenv_variables: 110,
            conan_max_file_size: 10,
            enforcement_limit: 100,
            generic_packages_max_file_size: 20,
            helm_max_file_size: 25,
            maven_max_file_size: 30,
            notification_limit: 90,
            npm_max_file_size: 40,
            nuget_max_file_size: 50,
            pypi_max_file_size: 60,
            terraform_module_max_file_size: 70,
            storage_size_limit: 80,
            pipeline_hierarchy_size: 250
          }

          expect(json_response).to be_an Hash
          expect(json_response['ci_instance_level_variables']).to eq(103)
          expect(json_response['ci_pipeline_size']).to eq(101)
          expect(json_response['ci_active_jobs']).to eq(102)
          expect(json_response['ci_project_subscriptions']).to eq(104)
          expect(json_response['ci_pipeline_schedules']).to eq(105)
          expect(json_response['ci_needs_size_limit']).to eq(106)
          expect(json_response['ci_registered_group_runners']).to eq(107)
          expect(json_response['ci_registered_project_runners']).to eq(108)
          expect(json_response['dotenv_size']).to eq(109)
          expect(json_response['dotenv_variables']).to eq(110)
          expect(json_response['conan_max_file_size']).to eq(10)
          expect(json_response['enforcement_limit']).to eq(100)
          expect(json_response['generic_packages_max_file_size']).to eq(20)
          expect(json_response['helm_max_file_size']).to eq(25)
          expect(json_response['limits_history']).to eq(
            { "enforcement_limit" => [{ "user_id" => admin.id, "username" => admin.username, "timestamp" => current_timestamp, "value" => 100 }],
              "notification_limit" => [{ "user_id" => admin.id, "username" => admin.username, "timestamp" => current_timestamp, "value" => 90 }],
              "storage_size_limit" => [{ "user_id" => admin.id, "username" => admin.username, "timestamp" => current_timestamp, "value" => 80 }] }
          )
          expect(json_response['maven_max_file_size']).to eq(30)
          expect(json_response['notification_limit']).to eq(90)
          expect(json_response['npm_max_file_size']).to eq(40)
          expect(json_response['nuget_max_file_size']).to eq(50)
          expect(json_response['pypi_max_file_size']).to eq(60)
          expect(json_response['terraform_module_max_file_size']).to eq(70)
          expect(json_response['storage_size_limit']).to eq(80)
          expect(json_response['pipeline_hierarchy_size']).to eq(250)
        end

        it 'updates single plan limits', :aggregate_failures do
          put api(path, admin, admin_mode: true), params: {
            plan_name: 'default',
            maven_max_file_size: 100
          }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_an Hash
          expect(json_response['maven_max_file_size']).to eq(100)
        end
      end

      context 'empty params' do
        it 'fails to update plan limits', :aggregate_failures do
          put api(path, admin, admin_mode: true), params: {}

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']).to match('plan_name is missing')
        end
      end

      context 'params with wrong type' do
        it 'fails to update plan limits', :aggregate_failures do
          put api(path, admin, admin_mode: true), params: {
            plan_name: 'default',
            ci_instance_level_variables: 'a',
            ci_pipeline_size: 'z',
            ci_active_jobs: 'y',
            ci_project_subscriptions: 'w',
            ci_pipeline_schedules: 'v',
            ci_needs_size_limit: 'u',
            ci_registered_group_runners: 't',
            ci_registered_project_runners: 's',
            dotenv_size: 'r',
            dotenv_variables: 'q',
            conan_max_file_size: 'a',
            enforcement_limit: 'e',
            generic_packages_max_file_size: 'b',
            helm_max_file_size: 'h',
            maven_max_file_size: 'c',
            notification_limit: 'n',
            npm_max_file_size: 'd',
            nuget_max_file_size: 'e',
            pypi_max_file_size: 'f',
            terraform_module_max_file_size: 'g',
            storage_size_limit: 'j',
            pipeline_hierarchy_size: 'r'
          }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']).to include(
            'ci_instance_level_variables is invalid',
            'ci_pipeline_size is invalid',
            'ci_active_jobs is invalid',
            'ci_project_subscriptions is invalid',
            'ci_pipeline_schedules is invalid',
            'ci_needs_size_limit is invalid',
            'ci_registered_group_runners is invalid',
            'ci_registered_project_runners is invalid',
            'dotenv_size is invalid',
            'dotenv_variables is invalid',
            'conan_max_file_size is invalid',
            'enforcement_limit is invalid',
            'generic_packages_max_file_size is invalid',
            'helm_max_file_size is invalid',
            'maven_max_file_size is invalid',
            'notification_limit is invalid',
            'npm_max_file_size is invalid',
            'nuget_max_file_size is invalid',
            'pypi_max_file_size is invalid',
            'terraform_module_max_file_size is invalid',
            'storage_size_limit is invalid',
            'pipeline_hierarchy_size is invalid'
          )
        end
      end

      context 'missing plan_name in params' do
        it 'fails to update plan limits', :aggregate_failures do
          put api(path, admin, admin_mode: true), params: { conan_max_file_size: 0 }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']).to match('plan_name is missing')
        end
      end

      context 'additional undeclared params' do
        before do
          Plan.default.actual_limits.update!({ golang_max_file_size: 1000 })
        end

        it 'updates only declared plan limits', :aggregate_failures do
          put api(path, admin, admin_mode: true), params: {
            plan_name: 'default',
            pypi_max_file_size: 200,
            golang_max_file_size: 999
          }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_an Hash
          expect(json_response['pypi_max_file_size']).to eq(200)
          expect(json_response['golang_max_file_size']).to be_nil
          expect(Plan.default.actual_limits.golang_max_file_size).to eq(1000)
        end
      end
    end
  end
end
