# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::API::Entities::Project, feature_category: :groups_and_projects do
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:current_user) { create(:user) }

  let(:options) { { current_user: current_user, statistics: true } }
  let(:entity) { described_class.new(project, options) }

  subject(:json) { entity.as_json }

  before do
    allow(Gitlab.config.registry).to receive(:enabled).and_return(true)
  end

  context 'as a guest' do
    before_all do
      project.add_guest(current_user)
    end

    it 'exposes the correct attributes' do
      expect(json.keys).to contain_exactly(
        :id, :description, :name, :name_with_namespace, :path, :path_with_namespace,
        :created_at, :tag_list, :topics, :ssh_url_to_repo, :http_url_to_repo, :web_url,
        :avatar_url, :star_count, :last_activity_at, :namespace, :container_registry_image_prefix,
        :_links, :empty_repo, :archived, :visibility, :owner, :open_issues_count,
        :description_html, :updated_at, :can_create_merge_request_in, :shared_with_groups
      )
    end
  end

  context 'as a reporter' do
    before_all do
      project.add_reporter(current_user)
    end

    it 'exposes the correct attributes' do
      expect(json.keys).to contain_exactly(
        :id, :description, :name, :name_with_namespace, :path, :path_with_namespace,
        :created_at, :default_branch, :tag_list, :topics, :ssh_url_to_repo, :http_url_to_repo,
        :web_url, :readme_url, :forks_count, :avatar_url, :star_count, :last_activity_at,
        :namespace, :container_registry_image_prefix, :_links, :empty_repo, :archived,
        :visibility, :owner, :open_issues_count, :description_html, :updated_at,
        :can_create_merge_request_in, :statistics, :ci_config_path, :shared_with_groups, :service_desk_address
      )
    end
  end

  context 'as a developer' do
    before_all do
      project.add_developer(current_user)
    end

    it 'exposes the correct attributes' do
      expect(json.keys).to contain_exactly(
        :id, :description, :name, :name_with_namespace, :path, :path_with_namespace,
        :created_at, :default_branch, :tag_list, :topics, :ssh_url_to_repo, :http_url_to_repo,
        :web_url, :readme_url, :forks_count, :avatar_url, :star_count, :last_activity_at,
        :namespace, :container_registry_image_prefix, :_links, :empty_repo, :archived,
        :visibility, :owner, :open_issues_count, :description_html, :updated_at,
        :can_create_merge_request_in, :statistics, :ci_config_path, :shared_with_groups, :service_desk_address
      )
    end
  end

  context 'as a maintainer' do
    before_all do
      project.add_maintainer(current_user)
    end

    it 'exposes the correct attributes' do
      expected_fields = [
        :id, :description, :name, :name_with_namespace, :path, :path_with_namespace,
        :created_at, :default_branch, :tag_list, :topics, :ssh_url_to_repo, :http_url_to_repo,
        :web_url, :readme_url, :forks_count, :avatar_url, :star_count, :last_activity_at,
        :namespace, :container_registry_image_prefix, :_links, :empty_repo, :archived,
        :visibility, :owner, :open_issues_count, :description_html, :updated_at,
        :can_create_merge_request_in, :statistics, :ci_config_path, :shared_with_groups, :service_desk_address,
        :emails_disabled, :emails_enabled, :resolve_outdated_diff_discussions,
        :container_expiration_policy, :repository_object_format, :shared_runners_enabled,
        :lfs_enabled, :creator_id, :import_url, :import_type, :import_status,
        :import_error, :ci_default_git_depth, :ci_forward_deployment_enabled,
        :ci_forward_deployment_rollback_allowed, :ci_job_token_scope_enabled,
        :ci_separated_caches, :ci_allow_fork_pipelines_to_run_in_parent_project, :build_git_strategy,
        :keep_latest_artifact, :restrict_user_defined_variables, :runners_token,
        :runner_token_expiration_interval, :group_runners_enabled, :auto_cancel_pending_pipelines,
        :build_timeout, :auto_devops_enabled, :auto_devops_deploy_strategy, :public_jobs,
        :only_allow_merge_if_pipeline_succeeds, :allow_merge_on_skipped_pipeline,
        :request_access_enabled, :only_allow_merge_if_all_discussions_are_resolved,
        :remove_source_branch_after_merge, :printing_merge_request_link_enabled,
        :merge_method, :squash_option, :enforce_auth_checks_on_uploads,
        :suggestion_commit_message, :merge_commit_template, :squash_commit_template,
        :issue_branch_template, :warn_about_potentially_unwanted_characters,
        :autoclose_referenced_issues, :packages_enabled, :service_desk_enabled, :issues_enabled,
        :merge_requests_enabled, :wiki_enabled, :jobs_enabled, :snippets_enabled,
        :container_registry_enabled, :issues_access_level, :repository_access_level,
        :merge_requests_access_level, :forking_access_level, :wiki_access_level,
        :builds_access_level, :snippets_access_level, :pages_access_level, :analytics_access_level,
        :container_registry_access_level, :security_and_compliance_access_level,
        :releases_access_level, :environments_access_level, :feature_flags_access_level,
        :infrastructure_access_level, :monitor_access_level, :model_experiments_access_level,
        :model_registry_access_level
      ]

      if Gitlab.ee?
        expected_fields += [
          :requirements_enabled, :security_and_compliance_enabled,
          :requirements_access_level, :compliance_frameworks
        ]
      end

      expect(json.keys).to match(expected_fields)
    end

    context 'without project feature' do
      before do
        project.project_feature.destroy!
        project.reload
      end

      it 'returns nil for all features' do
        expect(json[:issues_access_level]).to be_nil
        expect(json[:repository_access_level]).to be_nil
        expect(json[:merge_requests_access_level]).to be_nil
        expect(json[:forking_access_level]).to be_nil
        expect(json[:wiki_access_level]).to be_nil
        expect(json[:builds_access_level]).to be_nil
        expect(json[:snippets_access_level]).to be_nil
        expect(json[:pages_access_level]).to be_nil
        expect(json[:analytics_access_level]).to be_nil
        expect(json[:container_registry_access_level]).to be_nil
        expect(json[:security_and_compliance_access_level]).to be_nil
        expect(json[:releases_access_level]).to be_nil
        expect(json[:environments_access_level]).to be_nil
        expect(json[:feature_flags_access_level]).to be_nil
        expect(json[:infrastructure_access_level]).to be_nil
        expect(json[:monitor_access_level]).to be_nil
        expect(json[:model_experiments_access_level]).to be_nil
        expect(json[:model_registry_access_level]).to be_nil
      end
    end
  end

  describe 'shared_with_groups' do
    let_it_be(:group) { create(:group, :private) }

    subject(:shared_with_groups) { json[:shared_with_groups].as_json }

    before do
      project.project_group_links.create!(group: group)
    end

    context 'when the current user does not have access to the group' do
      it 'is empty' do
        expect(shared_with_groups).to be_empty
      end
    end

    context 'when the current user has access to the group' do
      before_all do
        group.add_guest(current_user)
      end

      it 'contains information about the shared group' do
        expect(shared_with_groups[0]['group_id']).to eq(group.id)
      end
    end
  end
end
