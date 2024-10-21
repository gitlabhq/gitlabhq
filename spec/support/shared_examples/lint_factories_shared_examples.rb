# frozen_string_literal: true

module Support
  # Lint factories based on example group's `described_class`.
  module LintFactories
    Any = Object.new

    # To avoid factories from being linted multiple times
    # we ignore the following example group paths.
    IGNORE_EXAMPLE_GROUP_PATHS = [
      # Don't run factory lints in frontend fixtures
      'spec/frontend/fixtures/',
      # Skip EE extensions specs as FOSS+EE factories are tested by corresponding models
      '/ee/',
      # Skip concerns specs
      '/concerns/'
    ].freeze

    def self.skip_example_group?(example_group)
      # ./ee/foo/ee/bar_spec.rb -> ee/foo/ee/bar_spec.rb
      file_path = example_group.file_path.delete_prefix('./')

      example_group.described_class.nil? ||
        IGNORE_EXAMPLE_GROUP_PATHS.any? { |ignore| file_path.include?(ignore) }
    end

    def self.lint_factories_for(example_group)
      return if skip_example_group?(example_group)

      described_class = example_group.described_class

      without_factory_defaults, with_factory_defaults = factories_for(described_class)
        .partition { |factory| skip_factory_defaults?(factory.name) }

      return if without_factory_defaults.empty? && with_factory_defaults.empty?

      # Pass model spec location as a caller to top-level example group.
      # This enables the use of the correct model spec location as opposed to
      # this very shared examples file path when specs are retry.
      model_location = example_group.metadata.values_at(:absolute_file_path, :line_number).join(':')

      RSpec.describe "Lint factories for #{described_class}", feature_category: :shared, caller: [model_location] do
        include_examples 'Lint factories', with_factory_defaults, without_factory_defaults
      end
    end

    def self.factories_for(model)
      factories_by_model[model] || []
    end

    def self.factories_by_model
      @factories_by_model ||=
        begin
          group = FactoryBot.factories.group_by do |factory|
            class_name = factory.send(:class_name)
            class_name = class_name.to_s.camelize if class_name.is_a?(Symbol)
            class_name.constantize if class_name.is_a?(String)
          end
          group.delete(nil)
          group
        end
    end

    def self.skip?(factory_name, trait_name = nil)
      return true if skipped.include?([factory_name, Any])
      return false unless trait_name

      skipped.include?([factory_name, trait_name.to_sym])
    end

    # https://gitlab.com/groups/gitlab-org/-/epics/5464 tracks the remaining
    # skipped factories or traits.
    #
    # Consider adding a code comment if a trait cannot produce a valid object.
    def self.skipped
      @skipped ||= [
        [:audit_event, :unauthenticated],
        [:ci_build_trace_chunk, :fog_with_data],
        [:ci_job_artifact, :remote_store],
        [:ci_job_artifact, :raw],
        [:ci_job_artifact, :gzip],
        [:ci_job_artifact, :correct_checksum],
        [:dependency_proxy_blob, :remote_store],
        [:environment, :non_playable],
        [:issue_customer_relations_contact, :for_contact],
        [:issue_customer_relations_contact, :for_issue],
        [:pages_domain, :without_certificate],
        [:pages_domain, :without_key],
        [:pages_domain, :with_missing_chain],
        [:pages_domain, :with_trusted_chain],
        [:pages_domain, :with_trusted_expired_chain],
        [:pages_domain, :with_untrusted_root_ca_in_chain],
        [:pages_domain, :explicit_ecdsa],
        [:pages_domain, :extra_long_key], # used to test key length validation
        [:project_member, :blocked],
        [:remote_mirror, :ssh],
        [:user_preference, :only_comments],
        [:ci_pipeline_artifact, :remote_store],
        # EE
        [:ci_secure_file, :verification_failed],
        [:ci_secure_file, :verification_succeeded],
        [:container_repository, :remote_store],
        [:container_repository, :verification_failed],
        [:container_repository, :verification_succeeded],
        [:dast_profile, :with_dast_site_validation],
        [:dependency_proxy_manifest, :remote_store],
        [:dependency_proxy_manifest, :verification_failed],
        [:dependency_proxy_manifest, :verification_succeeded],
        [:dependency_proxy_blob, :verification_failed],
        [:dependency_proxy_blob, :verification_succeeded],
        [:ee_ci_build, :dependency_scanning_report],
        [:ee_ci_build, :license_scan_v1],
        [:ee_ci_job_artifact, :v1],
        [:ee_ci_job_artifact, :v1_1],
        [:ee_ci_job_artifact, :v2],
        [:ee_ci_job_artifact, :v2_1],
        [:ee_ci_job_artifact, :verification_failed],
        [:ee_ci_job_artifact, :verification_succeeded],
        [:lfs_object, :checksum_failure],
        [:lfs_object, :checksummed],
        [:lfs_object, :verification_failed],
        [:lfs_object, :verification_succeeded],
        [:merge_request, :blocked],
        [:external_merge_request_diff, :verification_failed],
        [:external_merge_request_diff, :verification_succeeded],
        [:package_file, :verification_failed],
        [:package_file, :verification_succeeded],
        [:pages_deployment, :verification_failed],
        [:pages_deployment, :verification_succeeded],
        [:project, :with_vulnerabilities],
        [:project, :fork_repository],
        [:scan_execution_policy, :with_schedule_and_agent],
        [:vulnerability, :with_cluster_image_scanning_finding],
        [:vulnerability, :with_findings],
        [:vulnerability_export, :finished],
        [:vulnerabilities_finding_signature, :finding], # https://gitlab.com/gitlab-org/gitlab/-/issues/473014
        [:member_role, :instance] # this trait is not available for saas
      ].freeze
    end

    def self.skip_factory_defaults?(factory_name)
      skip_factory_defaults.include?(factory_name)
    end

    # FactoryDefault speed up specs by creating associations only once
    # and reuse them in other factories.
    #
    # However, for some factories we cannot use FactoryDefault because the
    # associations must be unique and cannot be reused, or the factory default
    # is being mutated.
    def self.skip_factory_defaults
      @skip_factory_defaults ||= %i[
        ci_catalog_resource_component
        ci_catalog_resource_component_usage
        ci_catalog_resource_version
        ci_job_token_project_scope_link
        ci_subscriptions_project
        compliance_standards_adherence
        evidence
        exported_protected_branch
        fork_network_member
        group_member
        import_state
        issue_customer_relations_contact
        merge_request_block
        milestone_release
        namespace
        project_namespace
        project_repository
        project_security_setting
        protected_branch
        protected_branch_merge_access_level
        protected_branch_push_access_level
        protected_branch_unprotect_access_level
        approval_project_rules_protected_branch
        approval_group_rules_protected_branch
        protected_tag
        protected_tag_create_access_level
        release
        release_link
        shard
        users_star_project
        vulnerabilities_finding_identifier
        wiki_page
        wiki_page_meta
        workspace
        workspace_variable
        member_approval
        external_status_checks_protected_branch
      ].to_set.freeze
    end

    # Some EE models check licensed features so stub them.
    def self.licensed_features
      @licensed_features ||=
        begin
          features = %i[
            board_milestone_lists
            board_assignee_lists
          ]

          if Gitlab.jh?
            features += %i[
              dingtalk_integration
              feishu_bot_integration
            ]
          end

          features.index_with(true).freeze
        end
    end

    # Some factories and their corresponding models are based on
    # database views. In order to use those, we have to swap the
    # view out with a table of the same structure.
    def self.database_views
      @database_views ||= %w[
        postgres_indexes
        postgres_index_bloat_estimates
        postgres_autovacuum_activity
      ].freeze
    end
  end
end

RSpec.shared_examples 'Lint factories' do |with_factory_defaults, without_factory_defaults|
  shared_context 'with licensed features' do
    before do
      stub_licensed_features(Support::LintFactories.licensed_features)
    end
  end

  shared_context 'with database views' do
    include Database::DatabaseHelpers

    before do
      Support::LintFactories.database_views.each do |view|
        view_gitlab_schema = Gitlab::Database::GitlabSchema.table_schema(view)
        Gitlab::Database::EachDatabase.each_connection(include_shared: false) do |connection|
          next unless Gitlab::Database.gitlab_schemas_for_connection(connection).include?(view_gitlab_schema)

          swapout_view_for_table(view, connection: connection)
        end
      end
    end
  end

  shared_context 'with factory defaults' do
    let_it_be(:namespace) { create_default(:namespace).freeze }
    let_it_be(:project) { create_default(:project, :repository).freeze }
    let_it_be(:user) { create_default(:user).freeze }
  end

  shared_context 'with stubbed storage' do
    before do
      stub_package_file_object_storage # [:package_file, :object_storage]
      debian_component_file_object_storage # [:debian_project_component_file, :object_storage]
      debian_distribution_release_file_object_storage # [:debian_project_distribution, :object_storage]
      stub_rpm_repository_file_object_storage # [:rpm_repository_file, :object_storage]
    end
  end

  shared_examples 'factory' do |factory|
    include_context 'with stubbed storage'
    include_context 'with licensed features' if Gitlab.ee?

    describe "#{factory.name} factory" do
      it 'does not raise error when built' do
        # We use `skip` here because using `build` mostly work even if
        # factories break when creating them.
        skip 'Factory skipped linting due to legacy error' if Support::LintFactories.skip?(factory.name)

        expect { build(factory.name) }.not_to raise_error
      end

      it 'does not raise error when created' do
        pending 'Factory skipped linting due to legacy error' if Support::LintFactories.skip?(factory.name)

        expect { create(factory.name) }.not_to raise_error # rubocop:disable Rails/SaveBang -- It's not Rails
      end

      factory.definition.defined_traits.map(&:name).each do |trait_name|
        describe "linting :#{trait_name} trait" do
          it 'does not raise error when created' do
            skip 'Trait skipped linting due to legacy error' if Support::LintFactories.skip?(factory.name, trait_name)

            expect { create(factory.name, trait_name) }.not_to raise_error
          end
        end
      end
    end
  end

  if with_factory_defaults.any?
    context 'with saas, license, and factory defaults', :saas, :with_license, factory_default: :keep do
      include_context 'with database views'
      include_context 'with factory defaults'

      with_factory_defaults.each do |factory|
        it_behaves_like 'factory', factory
      end
    end
  end

  if without_factory_defaults.any?
    context 'with saas, license, and no factory defaults', :saas, :with_license do
      without_factory_defaults.each do |factory|
        it_behaves_like 'factory', factory
      end
    end
  end
end

# TODO: disable factory linting for now.  There are several flaky specs and some
# ~master:broken jobs.
# See https://gitlab.com/gitlab-org/gitlab/-/issues/478114
# and https://gitlab.com/gitlab-org/gitlab/-/issues/478381
# RSpec.configure do |config|
#   config.on_example_group_definition do |example_group|
#     # Hook into every top-level example group definition.
#     #
#     # Define a new isolated context `Lint factories for <described_class>` for
#     # associated factories.
#     #
#     # Creating this context triggers this callback again with <described_class>
#     # being `nil` so recursive definitions are prevented.
#     Support::LintFactories.lint_factories_for(example_group)
#   end
# end
