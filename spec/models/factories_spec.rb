# frozen_string_literal: true

require 'spec_helper'

# `:saas` is used to test `gitlab_subscription` factory.
# It's not available on FOSS but also this very factory is not.
RSpec.describe 'factories', :saas, :with_license, feature_category: :tooling do
  include Database::DatabaseHelpers

  # Used in `skipped` and indicates whether to skip any traits including the
  # plain factory.
  any = Object.new

  # https://gitlab.com/groups/gitlab-org/-/epics/5464 tracks the remaining
  # skipped factories or traits.
  #
  # Consider adding a code comment if a trait cannot produce a valid object.
  skipped = [
    [:audit_event, :unauthenticated],
    [:ci_build_trace_chunk, :fog_with_data],
    [:ci_job_artifact, :remote_store],
    [:ci_job_artifact, :raw],
    [:ci_job_artifact, :gzip],
    [:ci_job_artifact, :correct_checksum],
    [:dependency_proxy_blob, :remote_store],
    [:environment, :non_playable],
    [:composer_cache_file, :object_storage],
    [:debian_project_component_file, :object_storage],
    [:debian_project_distribution, :object_storage],
    [:debian_file_metadatum, :unknown],
    [:issue_customer_relations_contact, :for_contact],
    [:issue_customer_relations_contact, :for_issue],
    [:package_file, :object_storage],
    [:rpm_repository_file, :object_storage],
    [:pages_domain, :without_certificate],
    [:pages_domain, :without_key],
    [:pages_domain, :with_missing_chain],
    [:pages_domain, :with_trusted_chain],
    [:pages_domain, :with_trusted_expired_chain],
    [:pages_domain, :explicit_ecdsa],
    [:project_member, :blocked],
    [:remote_mirror, :ssh],
    [:user_preference, :only_comments],
    [:ci_pipeline_artifact, :remote_store],
    # EE
    [:dast_profile, :with_dast_site_validation],
    [:dependency_proxy_manifest, :remote_store],
    [:geo_dependency_proxy_manifest_state, any],
    [:ee_ci_build, :dependency_scanning_report],
    [:ee_ci_build, :license_scan_v1],
    [:ee_ci_job_artifact, :v1],
    [:ee_ci_job_artifact, :v1_1],
    [:ee_ci_job_artifact, :v2],
    [:ee_ci_job_artifact, :v2_1],
    [:geo_ci_secure_file_state, any],
    [:geo_dependency_proxy_blob_state, any],
    [:geo_event_log, :geo_event],
    [:geo_job_artifact_state, any],
    [:geo_lfs_object_state, any],
    [:geo_pages_deployment_state, any],
    [:geo_upload_state, any],
    [:geo_ci_secure_file_state, any],
    [:lfs_object, :checksum_failure],
    [:lfs_object, :checksummed],
    [:merge_request, :blocked],
    [:merge_request_diff, :verification_failed],
    [:merge_request_diff, :verification_succeeded],
    [:package_file, :verification_failed],
    [:package_file, :verification_succeeded],
    [:project, :with_vulnerabilities],
    [:scan_execution_policy, :with_schedule_and_agent],
    [:vulnerability, :with_cluster_image_scanning_finding],
    [:vulnerability, :with_findings],
    [:vulnerability_export, :finished]
  ].freeze

  shared_examples 'factory' do |factory|
    skip_any = skipped.include?([factory.name, any])

    describe "#{factory.name} factory" do
      it 'does not raise error when built' do
        # We use `skip` here because using `build` mostly work even if
        # factories break when creating them.
        skip 'Factory skipped linting due to legacy error' if skip_any

        expect { build(factory.name) }.not_to raise_error
      end

      it 'does not raise error when created' do
        pending 'Factory skipped linting due to legacy error' if skip_any

        expect { create(factory.name) }.not_to raise_error # rubocop:disable Rails/SaveBang
      end

      factory.definition.defined_traits.map(&:name).each do |trait_name|
        skip_trait = skip_any || skipped.include?([factory.name, trait_name.to_sym])

        describe "linting :#{trait_name} trait" do
          it 'does not raise error when created' do
            pending 'Trait skipped linting due to legacy error' if skip_trait

            expect { create(factory.name, trait_name) }.not_to raise_error
          end
        end
      end
    end
  end

  # FactoryDefault speed up specs by creating associations only once
  # and reuse them in other factories.
  #
  # However, for some factories we cannot use FactoryDefault because the
  # associations must be unique and cannot be reused, or the factory default
  # is being mutated.
  skip_factory_defaults = %i[
    ci_job_token_project_scope_link
    ci_subscriptions_project
    evidence
    exported_protected_branch
    fork_network_member
    group_member
    import_state
    issue_customer_relations_contact
    member_task
    merge_request_block
    milestone_release
    namespace
    project_namespace
    project_repository
    project_security_setting
    prometheus_alert
    prometheus_alert_event
    prometheus_metric
    protected_branch
    protected_branch_merge_access_level
    protected_branch_push_access_level
    protected_branch_unprotect_access_level
    protected_tag
    protected_tag_create_access_level
    release
    release_link
    self_managed_prometheus_alert_event
    shard
    users_star_project
    vulnerabilities_finding_identifier
    wiki_page
    wiki_page_meta
  ].to_set.freeze

  # Some factories and their corresponding models are based on
  # database views. In order to use those, we have to swap the
  # view out with a table of the same structure.
  factories_based_on_view = %i[
    postgres_index
    postgres_index_bloat_estimate
    postgres_autovacuum_activity
  ].to_set.freeze

  without_fd, with_fd = FactoryBot.factories
    .partition { |factory| skip_factory_defaults.include?(factory.name) }

  # Some EE models check licensed features so stub them.
  shared_context 'with licensed features' do
    licensed_features = %i[
      board_milestone_lists
      board_assignee_lists
    ].index_with(true)

    if Gitlab.jh?
      licensed_features.merge! %i[
        dingtalk_integration
        feishu_bot_integration
      ].index_with(true)
    end

    before do
      stub_licensed_features(licensed_features)
    end
  end

  include_context 'with licensed features' if Gitlab.ee?

  context 'with factory defaults', factory_default: :keep do
    let_it_be(:namespace) { create_default(:namespace).freeze }
    let_it_be(:project) { create_default(:project, :repository).freeze }
    let_it_be(:user) { create_default(:user).freeze }

    before do
      factories_based_on_view.each do |factory|
        view = build(factory).class.table_name
        view_gitlab_schema = Gitlab::Database::GitlabSchema.table_schema(view)
        Gitlab::Database.database_base_models.each_value.select do |base_model|
          connection = base_model.connection
          next unless Gitlab::Database.gitlab_schemas_for_connection(connection).include?(view_gitlab_schema)

          swapout_view_for_table(view, connection: connection)
        end
      end
    end

    with_fd.each do |factory|
      it_behaves_like 'factory', factory
    end
  end

  context 'without factory defaults' do
    without_fd.each do |factory|
      it_behaves_like 'factory', factory
    end
  end
end
