# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Admin::PlanLimits, 'PlanLimits', feature_category: :shared do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:plan) { create(:plan, name: 'default') }
  let_it_be(:path) { '/application/plan_limits' }

  describe 'GET /application/plan_limits' do
    it_behaves_like 'GET request permissions for admin mode'

    it_behaves_like 'authorizing granular token permissions', :read_plan_limit do
      let(:user) { admin }
      let(:boundary_object) { :instance }
      let(:request) { get api(path, personal_access_token: pat) }
    end

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
          expect(json_response['web_hook_calls']).to eq(Plan.default.actual_limits.web_hook_calls)
          expect(json_response['web_hook_calls_mid']).to eq(Plan.default.actual_limits.web_hook_calls_mid)
          expect(json_response['web_hook_calls_low']).to eq(Plan.default.actual_limits.web_hook_calls_low)
          expect(json_response['max_pipelines_per_merge_train']).to eq(Plan.default.actual_limits.max_pipelines_per_merge_train)
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
          expect(json_response['web_hook_calls']).to eq(Plan.default.actual_limits.web_hook_calls)
          expect(json_response['web_hook_calls_mid']).to eq(Plan.default.actual_limits.web_hook_calls_mid)
          expect(json_response['web_hook_calls_low']).to eq(Plan.default.actual_limits.web_hook_calls_low)
          expect(json_response['max_pipelines_per_merge_train']).to eq(Plan.default.actual_limits.max_pipelines_per_merge_train)
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

    it_behaves_like 'authorizing granular token permissions', :update_plan_limit do
      let(:user) { admin }
      let(:boundary_object) { :instance }
      let(:request) { put api(path, personal_access_token: pat), params: { plan_name: 'default' } }
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
            pipeline_hierarchy_size: 250,
            web_hook_calls: 300,
            web_hook_calls_mid: 200,
            web_hook_calls_low: 100,
            max_pipelines_per_merge_train: 10
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
          expect(json_response['web_hook_calls']).to eq(300)
          expect(json_response['web_hook_calls_mid']).to eq(200)
          expect(json_response['web_hook_calls_low']).to eq(100)
          expect(json_response['max_pipelines_per_merge_train']).to eq(10)
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
            pipeline_hierarchy_size: 'r',
            web_hook_calls: 's',
            web_hook_calls_mid: 't',
            web_hook_calls_low: 'u',
            max_pipelines_per_merge_train: 'x'
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
            'pipeline_hierarchy_size is invalid',
            'web_hook_calls is invalid',
            'web_hook_calls_mid is invalid',
            'web_hook_calls_low is invalid',
            'max_pipelines_per_merge_train is invalid'
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

  describe 'column parity' do
    let_it_be(:non_limit_columns) do
      %w[
        id
        plan_id
        plan_name_uid
        updated_at
      ].freeze
    end

    # Backlog of plan_limits columns that are not yet exposed through the admin
    # Plan Limits API.
    #
    # Do not add to this list. Every new column on plan_limits must be exposed
    # through the admin Plan Limits API. plan_limits is cell-scoped configuration
    # and cells need a way to tune each limit independently.
    #
    # See:
    #   - doc/development/application_limits.md
    #   - https://gitlab.com/gitlab-org/gitlab/-/work_items/600205
    let_it_be(:unexposed_columns) do
      %w[
        active_versioned_pages_deployments_limit_by_namespace
        audit_events_amazon_s3_configurations
        cargo_max_file_size
        ci_daily_pipeline_schedule_triggers
        ci_job_annotations_num
        ci_job_annotations_size
        ci_jobs_trace_size_limit
        ci_max_artifact_size_accessibility
        ci_max_artifact_size_annotations
        ci_max_artifact_size_api_fuzzing
        ci_max_artifact_size_archive
        ci_max_artifact_size_browser_performance
        ci_max_artifact_size_cluster_applications
        ci_max_artifact_size_cluster_image_scanning
        ci_max_artifact_size_cobertura
        ci_max_artifact_size_codequality
        ci_max_artifact_size_container_scanning
        ci_max_artifact_size_coverage_fuzzing
        ci_max_artifact_size_cyclonedx
        ci_max_artifact_size_dast
        ci_max_artifact_size_dependency_scanning
        ci_max_artifact_size_dotenv
        ci_max_artifact_size_jacoco
        ci_max_artifact_size_junit
        ci_max_artifact_size_license_management
        ci_max_artifact_size_license_scanning
        ci_max_artifact_size_load_performance
        ci_max_artifact_size_lsif
        ci_max_artifact_size_metadata
        ci_max_artifact_size_metrics
        ci_max_artifact_size_metrics_referee
        ci_max_artifact_size_network_referee
        ci_max_artifact_size_performance
        ci_max_artifact_size_repository_xray
        ci_max_artifact_size_requirements
        ci_max_artifact_size_requirements_v2
        ci_max_artifact_size_sarif
        ci_max_artifact_size_sast
        ci_max_artifact_size_secret_detection
        ci_max_artifact_size_slsa_provenance_statement
        ci_max_artifact_size_terraform
        ci_max_artifact_size_trace
        ci_pipeline_deployments
        daily_invites
        dashboard_limit_enabled_at
        dast_profile_schedules
        debian_max_file_size
        external_audit_event_destinations
        file_size_limit_mb
        golang_max_file_size
        google_cloud_logging_configurations
        group_ci_variables
        group_hooks
        import_placeholder_user_limit_tier_1
        import_placeholder_user_limit_tier_2
        import_placeholder_user_limit_tier_3
        import_placeholder_user_limit_tier_4
        ml_model_max_file_size
        offset_pagination_limit
        pages_file_entries
        pipeline_triggers
        project_access_token_limit
        project_ci_secure_files
        project_ci_variables
        project_feature_flags
        project_hooks
        pull_mirror_interval_seconds
        repository_size
        rpm_max_file_size
        rubygems_max_file_size
        security_policy_scan_execution_schedules
      ].freeze
    end

    let_it_be(:put_params) do
      route = API::Admin::PlanLimits.routes.find { |r| r.request_method == 'PUT' }
      route.params.keys.map(&:to_s) - %w[plan_name]
    end

    let(:entity_attributes) { API::Entities::PlanLimit.root_exposures.map { |e| e.attribute.to_s } }
    let(:api_exposed_columns) { (entity_attributes + put_params).uniq }
    let(:limit_columns) { PlanLimits.column_names - non_limit_columns }

    it 'exposes every plan_limits column in the admin Plan Limits API' do
      missing = limit_columns - api_exposed_columns - unexposed_columns

      expect(missing).to be_empty, <<~MSG
        The following plan_limits columns are not exposed via the admin Plan Limits API:

          #{missing.join("\n  ")}

        plan_limits is cell-scoped configuration. Every column must be settable
        per cell via the admin Plan Limits API. Either:

          1. Expose the column in lib/api/admin/plan_limits.rb (PUT params) and
             lib/api/entities/plan_limit.rb (GET response), OR
          2. (Discouraged) Add the column to `unexposed_columns` with a comment
             explaining the deferral.

        See doc/development/application_limits.md and
        https://gitlab.com/gitlab-org/gitlab/-/work_items/600205.
      MSG
    end

    it 'keeps the unexposed columns allowlist tight' do
      redundant = unexposed_columns & api_exposed_columns

      expect(redundant).to be_empty,
        "Remove from `unexposed_columns` (now exposed via the API): #{redundant.join(', ')}"
    end

    it 'has no stale columns in the allowlist' do
      stale = unexposed_columns - PlanLimits.column_names

      expect(stale).to be_empty,
        "`unexposed_columns` references nonexistent plan_limits columns: #{stale.join(', ')}"
    end
  end
end
