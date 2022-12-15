# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Admin::PlanLimits, 'PlanLimits', feature_category: :not_owned do
  let_it_be(:user) { create(:user) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:plan) { create(:plan, name: 'default') }

  describe 'GET /application/plan_limits' do
    context 'as a non-admin user' do
      it 'returns 403' do
        get api('/application/plan_limits', user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'as an admin user' do
      context 'no params' do
        it 'returns plan limits' do
          get api('/application/plan_limits', admin)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_an Hash
          expect(json_response['ci_pipeline_size']).to eq(Plan.default.actual_limits.ci_pipeline_size)
          expect(json_response['ci_active_jobs']).to eq(Plan.default.actual_limits.ci_active_jobs)
          expect(json_response['ci_active_pipelines']).to eq(Plan.default.actual_limits.ci_active_pipelines)
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

      context 'correct plan name in params' do
        before do
          @params = { plan_name: 'default' }
        end

        it 'returns plan limits' do
          get api('/application/plan_limits', admin), params: @params

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_an Hash
          expect(json_response['ci_pipeline_size']).to eq(Plan.default.actual_limits.ci_pipeline_size)
          expect(json_response['ci_active_jobs']).to eq(Plan.default.actual_limits.ci_active_jobs)
          expect(json_response['ci_active_pipelines']).to eq(Plan.default.actual_limits.ci_active_pipelines)
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

        it 'returns validation error' do
          get api('/application/plan_limits', admin), params: @params

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']).to eq('plan_name does not have a valid value')
        end
      end
    end
  end

  describe 'PUT /application/plan_limits' do
    context 'as a non-admin user' do
      it 'returns 403' do
        put api('/application/plan_limits', user), params: { plan_name: 'default' }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'as an admin user' do
      context 'correct params' do
        it 'updates multiple plan limits' do
          put api('/application/plan_limits', admin), params: {
            'plan_name': 'default',
            'ci_pipeline_size': 101,
            'ci_active_jobs': 102,
            'ci_active_pipelines': 103,
            'ci_project_subscriptions': 104,
            'ci_pipeline_schedules': 105,
            'ci_needs_size_limit': 106,
            'ci_registered_group_runners': 107,
            'ci_registered_project_runners': 108,
            'conan_max_file_size': 10,
            'generic_packages_max_file_size': 20,
            'helm_max_file_size': 25,
            'maven_max_file_size': 30,
            'npm_max_file_size': 40,
            'nuget_max_file_size': 50,
            'pypi_max_file_size': 60,
            'terraform_module_max_file_size': 70,
            'storage_size_limit': 80,
            'pipeline_hierarchy_size': 250
          }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_an Hash
          expect(json_response['ci_pipeline_size']).to eq(101)
          expect(json_response['ci_active_jobs']).to eq(102)
          expect(json_response['ci_active_pipelines']).to eq(103)
          expect(json_response['ci_project_subscriptions']).to eq(104)
          expect(json_response['ci_pipeline_schedules']).to eq(105)
          expect(json_response['ci_needs_size_limit']).to eq(106)
          expect(json_response['ci_registered_group_runners']).to eq(107)
          expect(json_response['ci_registered_project_runners']).to eq(108)
          expect(json_response['conan_max_file_size']).to eq(10)
          expect(json_response['generic_packages_max_file_size']).to eq(20)
          expect(json_response['helm_max_file_size']).to eq(25)
          expect(json_response['maven_max_file_size']).to eq(30)
          expect(json_response['npm_max_file_size']).to eq(40)
          expect(json_response['nuget_max_file_size']).to eq(50)
          expect(json_response['pypi_max_file_size']).to eq(60)
          expect(json_response['terraform_module_max_file_size']).to eq(70)
          expect(json_response['storage_size_limit']).to eq(80)
          expect(json_response['pipeline_hierarchy_size']).to eq(250)
        end

        it 'updates single plan limits' do
          put api('/application/plan_limits', admin), params: {
            'plan_name': 'default',
            'maven_max_file_size': 100
          }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_an Hash
          expect(json_response['maven_max_file_size']).to eq(100)
        end
      end

      context 'empty params' do
        it 'fails to update plan limits' do
          put api('/application/plan_limits', admin), params: {}

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']).to match('plan_name is missing')
        end
      end

      context 'params with wrong type' do
        it 'fails to update plan limits' do
          put api('/application/plan_limits', admin), params: {
            'plan_name': 'default',
            'ci_pipeline_size': 'z',
            'ci_active_jobs': 'y',
            'ci_active_pipelines': 'x',
            'ci_project_subscriptions': 'w',
            'ci_pipeline_schedules': 'v',
            'ci_needs_size_limit': 'u',
            'ci_registered_group_runners': 't',
            'ci_registered_project_runners': 's',
            'conan_max_file_size': 'a',
            'generic_packages_max_file_size': 'b',
            'helm_max_file_size': 'h',
            'maven_max_file_size': 'c',
            'npm_max_file_size': 'd',
            'nuget_max_file_size': 'e',
            'pypi_max_file_size': 'f',
            'terraform_module_max_file_size': 'g',
            'storage_size_limit': 'j',
            'pipeline_hierarchy_size': 'r'
          }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']).to include(
            'ci_pipeline_size is invalid',
            'ci_active_jobs is invalid',
            'ci_active_pipelines is invalid',
            'ci_project_subscriptions is invalid',
            'ci_pipeline_schedules is invalid',
            'ci_needs_size_limit is invalid',
            'ci_registered_group_runners is invalid',
            'ci_registered_project_runners is invalid',
            'conan_max_file_size is invalid',
            'generic_packages_max_file_size is invalid',
            'helm_max_file_size is invalid',
            'maven_max_file_size is invalid',
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
        it 'fails to update plan limits' do
          put api('/application/plan_limits', admin), params: { 'conan_max_file_size': 0 }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']).to match('plan_name is missing')
        end
      end

      context 'additional undeclared params' do
        before do
          Plan.default.actual_limits.update!({ 'golang_max_file_size': 1000 })
        end

        it 'updates only declared plan limits' do
          put api('/application/plan_limits', admin), params: {
            'plan_name': 'default',
            'pypi_max_file_size': 200,
            'golang_max_file_size': 999
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
