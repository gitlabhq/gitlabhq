# frozen_string_literal: true

require 'spec_helper'

RSpec.describe '1_settings', feature_category: :shared do
  include_context 'when loading 1_settings initializer'

  it 'settings do not change after reload', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/501317' do
    original_settings = Settings.to_h

    load_settings

    new_settings = Settings.to_h

    # Gitlab::Pages::Settings is a SimpleDelegator, so each time the settings
    # are reloaded a new SimpleDelegator wraps the original object. Convert
    # the settings to a Hash to ensure the comparison works.
    [new_settings, original_settings].each do |settings|
      settings['pages'] = settings['pages'].to_h
    end
    expect(new_settings).to eq(original_settings)
  end

  describe 'DNS rebinding protection' do
    subject(:dns_rebinding_protection_enabled) { Settings.gitlab.dns_rebinding_protection_enabled }

    let(:http_proxy) { nil }

    before do
      # Reset it, because otherwise we might memoize the value across tests.
      Settings.gitlab['dns_rebinding_protection_enabled'] = nil
      stub_env('http_proxy', http_proxy)
      load_settings
    end

    it { is_expected.to be(true) }

    context 'when an HTTP proxy environment variable is set' do
      let(:http_proxy) { 'http://myproxy.com:8080' }

      it { is_expected.to be(false) }
    end
  end

  describe 'log_decompressed_response_bytesize' do
    it { expect(Settings.gitlab.log_decompressed_response_bytesize).to eq(0) }

    context 'when GITLAB_LOG_DECOMPRESSED_RESPONSE_BYTESIZE is set' do
      before do
        stub_env('GITLAB_LOG_DECOMPRESSED_RESPONSE_BYTESIZE', '10')
        load_settings
      end

      it { expect(Settings.gitlab.log_decompressed_response_bytesize).to eq(10) }
    end
  end

  describe 'initial_gitlab_product_usage_data' do
    it 'is enabled by default' do
      Settings.gitlab['initial_gitlab_product_usage_data'] = nil
      load_settings

      expect(Settings.gitlab.initial_gitlab_product_usage_data).to be(true)
    end

    context 'when explicitly set' do
      before do
        Settings.gitlab['initial_gitlab_product_usage_data'] = false
        load_settings
      end

      it 'uses the configured value' do
        expect(Settings.gitlab.initial_gitlab_product_usage_data).to be(false)
      end
    end
  end

  describe 'cell configuration' do
    let(:config) do
      {
        address: 'test-topology-service-host:8080',
        ca_file: '/test/topology-service-ca.pem',
        certificate_file: '/test/topology-service-cert.pem',
        private_key_file: '/test/topology-service-key.pem',
        metadata: {
          'key1' => 'val1'
        }
      }
    end

    context 'when legacy topology service client config is provided as a top-level key' do
      before do
        stub_config({ cell: { enabled: true, id: 1 }, topology_service: config })
        load_settings
      end

      it { expect(Settings.cell.topology_service_client.address).to eq(config[:address]) }
      it { expect(Settings.cell.topology_service_client.ca_file).to eq(config[:ca_file]) }
      it { expect(Settings.cell.topology_service_client.certificate_file).to eq(config[:certificate_file]) }
      it { expect(Settings.cell.topology_service_client.private_key_file).to eq(config[:private_key_file]) }
      it { expect(Settings.cell.topology_service_client.metadata.to_h).to eq(config[:metadata]) }
    end

    context 'when topology service client config is provided as a key nested' do
      before do
        stub_config({ cell: { enabled: true, id: 1, topology_service_client: config } })
        load_settings
      end

      it { expect(Settings.cell.topology_service_client.address).to eq(config[:address]) }
      it { expect(Settings.cell.topology_service_client.ca_file).to eq(config[:ca_file]) }
      it { expect(Settings.cell.topology_service_client.certificate_file).to eq(config[:certificate_file]) }
      it { expect(Settings.cell.topology_service_client.private_key_file).to eq(config[:private_key_file]) }
      it { expect(Settings.cell.topology_service_client.metadata.to_h).to eq(config[:metadata]) }
    end

    context 'when topology service client config does not include metadata' do
      let(:config_without_metadata) { config.delete(:metadata) }

      before do
        stub_config({ cell: { enabled: true, id: 1, topology_service_client: config_without_metadata } })
        load_settings
      end

      it { expect(Settings.cell.topology_service_client.metadata.to_h).to eq({}) }
    end
  end

  describe 'Pages custom domains settings' do
    using RSpec::Parameterized::TableSyntax

    where(:external_http, :external_https, :initial_custom_domain_mode, :expected_custom_domain_mode) do
      nil   | true  | nil     | 'https'
      true  | nil   | nil     | 'http'
      true  | true  | nil     | 'https'
      nil   | nil   | 'https' | 'https'
      false | false | 'http'  | 'http'
      nil   | true  | 'http'  | 'https'
      nil   | nil   | nil     | nil
    end

    with_them do
      before do
        stub_config(pages: {
          enabled: true,
          external_http: external_http,
          external_https: external_https,
          custom_domain_mode: initial_custom_domain_mode
        })

        allow(Settings.pages).to receive(:__getobj__).and_return(Settings.pages)
      end

      it 'sets the expected custom_domain_mode value' do
        load_settings

        expect(Settings.pages['custom_domain_mode']).to eq(expected_custom_domain_mode)
      end
    end
  end

  describe 'ci_id_tokens_issuer_url' do
    after do
      Settings.ci_id_tokens['issuer_url'] = nil
      load_settings
    end

    it 'is set as Settings.gitlab.url by default' do
      Settings.ci_id_tokens['issuer_url'] = nil
      load_settings

      expect(Settings.ci_id_tokens.issuer_url).to eq Settings.gitlab.url
    end

    it 'uses the configured value' do
      Settings.ci_id_tokens['issuer_url'] = 'https://example.com'
      load_settings

      expect(Settings.ci_id_tokens.issuer_url).to eq('https://example.com')
    end
  end

  describe 'openbao_authentication_token_secret_file_path' do
    after do
      Settings.openbao['authentication_token_secret_file_path'] = nil
      load_settings
    end

    it 'is set the correct default path' do
      Settings.openbao['authentication_token_secret_file_path'] = nil
      load_settings

      expect(Settings.openbao.authentication_token_secret_file_path)
      .to eq(Rails.root.join('.gitlab_openbao_authentication_token_secret'))
    end

    it 'uses the configured value' do
      Settings.openbao['authentication_token_secret_file_path'] = '/custom/path'
      load_settings

      expect(Settings.openbao.authentication_token_secret_file_path).to eq('/custom/path')
    end
  end

  describe 'cron jobs', unless: Gitlab.ee? do
    let(:expected_jobs) do
      %w[
        adjourned_group_deletion_worker
        adjourned_projects_deletion_cron_worker
        admin_email_worker
        analytics_usage_trends_count_job_trigger_worker
        authn_data_retention_authentication_event_archive_worker
        authn_data_retention_oauth_access_grant_archive_worker
        authn_data_retention_oauth_access_token_archive_worker
        authorized_project_update_periodic_recalculate_worker
        batched_background_migrations_worker
        batched_background_migration_worker_ci_database
        batched_background_migration_worker_sec_database
        batched_git_ref_updates_cleanup_scheduler_worker
        bulk_imports_stale_import_worker
        ci_archive_traces_cron_worker
        ci_catalog_resources_aggregate_last30_day_usage_worker
        ci_catalog_resources_cleanup_last_usages_worker
        ci_catalog_resources_process_sync_events_worker
        ci_click_house_finished_pipelines_sync_worker
        ci_delete_unit_tests_worker
        ci_partitioning_worker
        ci_pipelines_expire_artifacts_worker
        ci_runners_stale_machines_cleanup_worker
        ci_runner_versions_reconciliation_worker
        ci_schedule_delete_objects_worker
        ci_schedule_old_pipelines_removal_cron_worker
        ci_schedule_unlock_pipelines_in_queue_worker
        cleanup_container_registry_worker
        cleanup_dangling_debian_package_files_worker
        cleanup_dependency_proxy_worker
        cleanup_package_registry_worker
        container_expiration_policy_worker
        database_monitor_locked_tables_cron_worker
        deactivated_pages_deployments_delete_cron_worker
        deactivate_expired_deployments_cron_worker
        delete_expired_trigger_token_worker
        deploy_tokens_expiring_worker
        environments_auto_delete_cron_worker
        environments_auto_stop_cron_worker
        expire_build_artifacts_worker
        gitlab_export_prune_project_export_jobs_worker
        gitlab_import_import_file_cleanup_worker
        gitlab_service_ping_worker
        image_ttl_group_policy_worker
        import_export_project_cleanup_worker
        import_placeholder_user_cleanup_worker
        import_stuck_project_import_jobs
        inactive_projects_deletion_cron_worker
        issue_due_scheduler_worker
        issues_reschedule_stuck_issue_rebalances
        jira_import_stuck_jira_import_jobs
        loose_foreign_keys_cleanup_worker
        loose_foreign_keys_merge_request_diff_commit_cleanup_worker
        manage_evidence_worker
        member_invitation_reminder_emails_worker
        members_expiring_worker
        merge_requests_process_scheduled_merge
        namespaces_process_outdated_namespace_descendants_cron_worker
        namespaces_prune_aggregation_schedules_worker
        object_storage_delete_stale_direct_uploads_worker
        packages_cleanup_delete_orphaned_dependencies_worker
        pages_domain_removal_cron_worker
        pages_domain_ssl_renewal_cron_worker
        pages_domain_verification_cron_worker
        performance_bar_stats
        personal_access_tokens_expired_notification_worker
        personal_access_tokens_expiring_worker
        pipeline_schedule_worker
        poll_interval
        postgres_dynamic_partitions_dropper
        postgres_dynamic_partitions_manager
        projects_schedule_refresh_build_artifacts_size_statistics_worker
        prune_old_events_worker
        publish_release_worker
        remove_expired_group_links_worker
        remove_expired_members_worker
        remove_unaccepted_member_invites_worker
        remove_unreferenced_lfs_objects_worker
        repository_archive_cache_worker
        repository_check_worker
        resource_access_tokens_inactive_tokens_deletion_cron_worker
        schedule_merge_request_cleanup_refs_worker
        schedule_migrate_external_diffs_worker
        service_desk_custom_email_verification_cleanup
        ssh_keys_expired_notification_worker
        ssh_keys_expiring_soon_notification_worker
        stuck_ci_jobs_worker
        stuck_export_jobs_worker
        stuck_merge_jobs_worker
        trending_projects_worker
        update_container_registry_info_worker
        update_locked_unknown_artifacts_worker
        users_create_statistics_worker
        users_deactivate_dormant_users_worker
        users_migrate_records_to_ghost_user_in_batches_worker
        user_status_cleanup_batch_worker
        version_version_check_cron
        x509_issuer_crl_check_worker
      ]
    end

    it 'configures the expected jobs' do
      expect(Settings.cron_jobs.keys).to match_array(expected_jobs)
    end
  end
end
