# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Every Sidekiq worker' do
  let(:workers_without_defaults) do
    Gitlab::SidekiqConfig.workers - Gitlab::SidekiqConfig::DEFAULT_WORKERS.values
  end

  it 'does not use the default queue' do
    expect(workers_without_defaults.map(&:queue)).not_to include('default')
  end

  it 'uses the cronjob queue when the worker runs as a cronjob' do
    expect(Gitlab::SidekiqConfig.cron_workers.map(&:queue)).to all(start_with('cronjob:'))
  end

  it 'has its queue in Gitlab::SidekiqConfig::QUEUE_CONFIG_PATHS', :aggregate_failures do
    file_worker_queues = Gitlab::SidekiqConfig.worker_queues.to_set

    worker_queues = Gitlab::SidekiqConfig.workers.map(&:queue).to_set
    worker_queues << ActionMailer::MailDeliveryJob.new.queue_name
    worker_queues << 'default'

    missing_from_file = worker_queues - file_worker_queues
    expect(missing_from_file).to be_empty, "expected #{missing_from_file.to_a.inspect} to be in Gitlab::SidekiqConfig::QUEUE_CONFIG_PATHS"

    unnecessarily_in_file = file_worker_queues - worker_queues
    expect(unnecessarily_in_file).to be_empty, "expected #{unnecessarily_in_file.to_a.inspect} not to be in Gitlab::SidekiqConfig::QUEUE_CONFIG_PATHS"
  end

  it 'has its queue or namespace in config/sidekiq_queues.yml', :aggregate_failures do
    config_queues = Gitlab::SidekiqConfig.config_queues.to_set

    Gitlab::SidekiqConfig.workers.each do |worker|
      queue = worker.queue
      queue_namespace = queue.split(':').first

      expect(config_queues).to include(queue).or(include(queue_namespace))
    end
  end

  it 'has a value for loggable_arguments' do
    workers_without_defaults.each do |worker|
      expect(worker.klass.loggable_arguments).to be_an(Array)
    end
  end

  describe "feature category declarations" do
    let(:feature_categories) do
      YAML.load_file(Rails.root.join('config', 'feature_categories.yml')).map(&:to_sym).to_set
    end

    # All Sidekiq worker classes should declare a valid `feature_category`
    # or explicitly be excluded with the `feature_category_not_owned!` annotation.
    # Please see doc/development/sidekiq_style_guide.md#feature-categorization for more details.
    it 'has a feature_category or feature_category_not_owned! attribute', :aggregate_failures do
      workers_without_defaults.each do |worker|
        expect(worker.get_feature_category).to be_a(Symbol), "expected #{worker.inspect} to declare a feature_category or feature_category_not_owned!"
      end
    end

    # All Sidekiq worker classes should declare a valid `feature_category`.
    # The category should match a value in `config/feature_categories.yml`.
    # Please see doc/development/sidekiq_style_guide.md#feature-categorization for more details.
    it 'has a feature_category that maps to a value in feature_categories.yml', :aggregate_failures do
      workers_with_feature_categories = workers_without_defaults
                  .select(&:get_feature_category)
                  .reject(&:feature_category_not_owned?)

      workers_with_feature_categories.each do |worker|
        expect(feature_categories).to include(worker.get_feature_category), "expected #{worker.inspect} to declare a valid feature_category, but got #{worker.get_feature_category}"
      end
    end

    # Memory-bound workers are very expensive to run, since they need to run on nodes with very low
    # concurrency, so that each job can consume a large amounts of memory. For this reason, on
    # GitLab.com, when a large number of memory-bound jobs arrive at once, we let them queue up
    # rather than scaling the hardware to meet the SLO. For this reason, memory-bound,
    # high urgency jobs are explicitly discouraged and disabled.
    it 'is (exclusively) memory-bound or high urgency, not both', :aggregate_failures do
      high_urgency_workers = workers_without_defaults
                               .select { |worker| worker.get_urgency == :high }

      high_urgency_workers.each do |worker|
        expect(worker.get_worker_resource_boundary).not_to eq(:memory), "#{worker.inspect} cannot be both memory-bound and high urgency"
      end
    end

    # In high traffic installations, such as GitLab.com, `urgency :high` workers run in a
    # dedicated fleet. In order to ensure short queue times, `urgency :high` jobs have strict
    # SLOs in order to ensure throughput. However, when a worker depends on an external service,
    # such as a user's k8s cluster or a third-party internet service, we cannot guarantee latency,
    # and therefore throughput. An outage to an 3rd party service could therefore impact throughput
    # on other high urgency jobs, leading to degradation through the GitLab application.
    # Please see doc/development/sidekiq_style_guide.md#jobs-with-external-dependencies for more
    # details.
    it 'has (exclusively) external dependencies or is high urgency, not both', :aggregate_failures do
      high_urgency_workers = workers_without_defaults
                               .select { |worker| worker.get_urgency == :high }

      high_urgency_workers.each do |worker|
        expect(worker.worker_has_external_dependencies?).to be_falsey, "#{worker.inspect} cannot have both external dependencies and be high urgency"
      end
    end
  end

  context 'retries' do
    let(:cronjobs)  do
      workers_without_defaults.select { |worker| worker.klass < CronjobQueue }
    end

    let(:retry_exception_workers) do
      workers_without_defaults.select { |worker| retry_exceptions.has_key?(worker.klass.to_s) }
    end

    let(:retry_exceptions) do
      {
        'AdjournedProjectDeletionWorker' => 3,
        'AdminEmailsWorker' => 3,
        'Analytics::CodeReviewMetricsWorker' => 3,
        'Analytics::DevopsAdoption::CreateSnapshotWorker' => 3,
        'Analytics::InstanceStatistics::CounterJobWorker' => 3,
        'Analytics::UsageTrends::CounterJobWorker' => 3,
        'ApprovalRules::ExternalApprovalRulePayloadWorker' => 3,
        'ApproveBlockedPendingApprovalUsersWorker' => 3,
        'ArchiveTraceWorker' => 3,
        'AuthorizedKeysWorker' => 3,
        'AuthorizedProjectUpdate::ProjectCreateWorker' => 3,
        'AuthorizedProjectUpdate::ProjectGroupLinkCreateWorker' => 3,
        'AuthorizedProjectUpdate::UserRefreshOverUserRangeWorker' => 3,
        'AuthorizedProjectUpdate::UserRefreshWithLowUrgencyWorker' => 3,
        'AuthorizedProjectUpdate::UserRefreshFromReplicaWorker' => 3,
        'AuthorizedProjectsWorker' => 3,
        'AutoDevops::DisableWorker' => 3,
        'AutoMergeProcessWorker' => 3,
        'BackgroundMigrationWorker' => 3,
        'BuildFinishedWorker' => 3,
        'BuildHooksWorker' => 3,
        'BuildQueueWorker' => 3,
        'BuildSuccessWorker' => 3,
        'BulkImportWorker' => false,
        'BulkImports::EntityWorker' => false,
        'BulkImports::PipelineWorker' => false,
        'Chaos::CpuSpinWorker' => 3,
        'Chaos::DbSpinWorker' => 3,
        'Chaos::KillWorker' => false,
        'Chaos::LeakMemWorker' => 3,
        'Chaos::SleepWorker' => 3,
        'ChatNotificationWorker' => false,
        'Ci::BatchResetMinutesWorker' => 10,
        'Ci::BuildPrepareWorker' => 3,
        'Ci::BuildScheduleWorker' => 3,
        'Ci::BuildTraceChunkFlushWorker' => 3,
        'Ci::CreateCrossProjectPipelineWorker' => 3,
        'Ci::DailyBuildGroupReportResultsWorker' => 3,
        'Ci::DeleteObjectsWorker' => 0,
        'Ci::DropPipelineWorker' => 3,
        'Ci::InitialPipelineProcessWorker' => 3,
        'Ci::MergeRequests::AddTodoWhenBuildFailsWorker' => 3,
        'Ci::PipelineArtifacts::CoverageReportWorker' => 3,
        'Ci::PipelineArtifacts::CreateQualityReportWorker' => 3,
        'Ci::PipelineBridgeStatusWorker' => 3,
        'Ci::PipelineSuccessUnlockArtifactsWorker' => 3,
        'Ci::RefDeleteUnlockArtifactsWorker' => 3,
        'Ci::ResourceGroups::AssignResourceFromResourceGroupWorker' => 3,
        'Ci::TestFailureHistoryWorker' => 3,
        'Ci::TriggerDownstreamSubscriptionsWorker' => 3,
        'Ci::SyncReportsToReportApprovalRulesWorker' => 3,
        'CleanupContainerRepositoryWorker' => 3,
        'ClusterConfigureIstioWorker' => 3,
        'ClusterInstallAppWorker' => 3,
        'ClusterPatchAppWorker' => 3,
        'ClusterProvisionWorker' => 3,
        'ClusterUpdateAppWorker' => 3,
        'ClusterUpgradeAppWorker' => 3,
        'ClusterWaitForAppInstallationWorker' => 3,
        'ClusterWaitForAppUpdateWorker' => 3,
        'ClusterWaitForIngressIpAddressWorker' => 3,
        'Clusters::Applications::ActivateServiceWorker' => 3,
        'Clusters::Applications::DeactivateServiceWorker' => 3,
        'Clusters::Applications::UninstallWorker' => 3,
        'Clusters::Applications::WaitForUninstallAppWorker' => 3,
        'Clusters::Cleanup::AppWorker' => 3,
        'Clusters::Cleanup::ProjectNamespaceWorker' => 3,
        'Clusters::Cleanup::ServiceAccountWorker' => 3,
        'ContainerExpirationPolicies::CleanupContainerRepositoryWorker' => 0,
        'CreateCommitSignatureWorker' => 3,
        'CreateGithubWebhookWorker' => 3,
        'CreateNoteDiffFileWorker' => 3,
        'CreatePipelineWorker' => 3,
        'DastSiteValidationWorker' => 3,
        'DeleteContainerRepositoryWorker' => 3,
        'DeleteDiffFilesWorker' => 3,
        'DeleteMergedBranchesWorker' => 3,
        'DeleteStoredFilesWorker' => 3,
        'DeleteUserWorker' => 3,
        'Deployments::AutoRollbackWorker' => 3,
        'Deployments::DropOlderDeploymentsWorker' => 3,
        'Deployments::FinishedWorker' => 3,
        'Deployments::ForwardDeploymentWorker' => 3,
        'Deployments::LinkMergeRequestWorker' => 3,
        'Deployments::SuccessWorker' => 3,
        'Deployments::UpdateEnvironmentWorker' => 3,
        'DesignManagement::CopyDesignCollectionWorker' => 3,
        'DesignManagement::NewVersionWorker' => 3,
        'DestroyPagesDeploymentsWorker' => 3,
        'DetectRepositoryLanguagesWorker' => 1,
        'DisallowTwoFactorForGroupWorker' => 3,
        'DisallowTwoFactorForSubgroupsWorker' => 3,
        'Dora::DailyMetrics::RefreshWorker' => 3,
        'ElasticAssociationIndexerWorker' => 3,
        'ElasticCommitIndexerWorker' => 2,
        'ElasticDeleteProjectWorker' => 2,
        'ElasticFullIndexWorker' => 2,
        'ElasticIndexingControlWorker' => 3,
        'ElasticNamespaceIndexerWorker' => 2,
        'ElasticNamespaceRolloutWorker' => 2,
        'EmailReceiverWorker' => 3,
        'EmailsOnPushWorker' => 3,
        'Environments::CanaryIngress::UpdateWorker' => false,
        'Epics::UpdateEpicsDatesWorker' => 3,
        'ErrorTrackingIssueLinkWorker' => 3,
        'Experiments::RecordConversionEventWorker' => 3,
        'ExpireBuildInstanceArtifactsWorker' => 3,
        'ExpireJobCacheWorker' => 3,
        'ExpirePipelineCacheWorker' => 3,
        'ExportCsvWorker' => 3,
        'ExternalServiceReactiveCachingWorker' => 3,
        'FileHookWorker' => false,
        'FlushCounterIncrementsWorker' => 3,
        'Geo::Batch::ProjectRegistrySchedulerWorker' => 3,
        'Geo::Batch::ProjectRegistryWorker' => 3,
        'Geo::ContainerRepositorySyncWorker' => 3,
        'Geo::DesignRepositoryShardSyncWorker' => false,
        'Geo::DesignRepositorySyncWorker' => 3,
        'Geo::DestroyWorker' => 3,
        'Geo::EventWorker' => 3,
        'Geo::FileDownloadWorker' => 3,
        'Geo::FileRegistryRemovalWorker' => 3,
        'Geo::FileRemovalWorker' => 3,
        'Geo::HashedStorageAttachmentsMigrationWorker' => 3,
        'Geo::HashedStorageMigrationWorker' => 3,
        'Geo::ProjectSyncWorker' => 3,
        'Geo::RenameRepositoryWorker' => 3,
        'Geo::RepositoriesCleanUpWorker' => 3,
        'Geo::RepositoryCleanupWorker' => 3,
        'Geo::RepositoryShardSyncWorker' => false,
        'Geo::RepositoryVerification::Primary::ShardWorker' => false,
        'Geo::RepositoryVerification::Primary::SingleWorker' => false,
        'Geo::RepositoryVerification::Secondary::SingleWorker' => false,
        'Geo::ReverificationBatchWorker' => 0,
        'Geo::Scheduler::Primary::SchedulerWorker' => 3,
        'Geo::Scheduler::SchedulerWorker' => 3,
        'Geo::Scheduler::Secondary::SchedulerWorker' => 3,
        'Geo::VerificationBatchWorker' => 0,
        'Geo::VerificationTimeoutWorker' => false,
        'Geo::VerificationWorker' => 3,
        'GeoRepositoryDestroyWorker' => 3,
        'GitGarbageCollectWorker' => false,
        'Gitlab::GithubImport::AdvanceStageWorker' => 3,
        'Gitlab::GithubImport::ImportDiffNoteWorker' => 5,
        'Gitlab::GithubImport::ImportIssueWorker' => 5,
        'Gitlab::GithubImport::ImportLfsObjectWorker' => 5,
        'Gitlab::GithubImport::ImportNoteWorker' => 5,
        'Gitlab::GithubImport::ImportPullRequestMergedByWorker' => 5,
        'Gitlab::GithubImport::ImportPullRequestReviewWorker' => 5,
        'Gitlab::GithubImport::ImportPullRequestWorker' => 5,
        'Gitlab::GithubImport::RefreshImportJidWorker' => 5,
        'Gitlab::GithubImport::Stage::FinishImportWorker' => 5,
        'Gitlab::GithubImport::Stage::ImportBaseDataWorker' => 5,
        'Gitlab::GithubImport::Stage::ImportIssuesAndDiffNotesWorker' => 5,
        'Gitlab::GithubImport::Stage::ImportLfsObjectsWorker' => 5,
        'Gitlab::GithubImport::Stage::ImportNotesWorker' => 5,
        'Gitlab::GithubImport::Stage::ImportPullRequestsMergedByWorker' => 5,
        'Gitlab::GithubImport::Stage::ImportPullRequestsReviewsWorker' => 5,
        'Gitlab::GithubImport::Stage::ImportPullRequestsWorker' => 5,
        'Gitlab::GithubImport::Stage::ImportRepositoryWorker' => 5,
        'Gitlab::JiraImport::AdvanceStageWorker' => 5,
        'Gitlab::JiraImport::ImportIssueWorker' => 5,
        'Gitlab::JiraImport::Stage::FinishImportWorker' => 5,
        'Gitlab::JiraImport::Stage::ImportAttachmentsWorker' => 5,
        'Gitlab::JiraImport::Stage::ImportIssuesWorker' => 5,
        'Gitlab::JiraImport::Stage::ImportLabelsWorker' => 5,
        'Gitlab::JiraImport::Stage::ImportNotesWorker' => 5,
        'Gitlab::JiraImport::Stage::StartImportWorker' => 5,
        'Gitlab::PhabricatorImport::ImportTasksWorker' => 5,
        'GitlabPerformanceBarStatsWorker' => 3,
        'GitlabShellWorker' => 3,
        'GitlabServicePingWorker' => 3,
        'GitlabUsagePingWorker' => 3,
        'GroupDestroyWorker' => 3,
        'GroupExportWorker' => false,
        'GroupImportWorker' => false,
        'GroupSamlGroupSyncWorker' => 3,
        'GroupWikis::GitGarbageCollectWorker' => false,
        'Groups::ScheduleBulkRepositoryShardMovesWorker' => 3,
        'Groups::UpdateRepositoryStorageWorker' => 3,
        'Groups::UpdateStatisticsWorker' => 3,
        'HashedStorage::MigratorWorker' => 3,
        'HashedStorage::ProjectMigrateWorker' => 3,
        'HashedStorage::ProjectRollbackWorker' => 3,
        'HashedStorage::RollbackerWorker' => 3,
        'ImportIssuesCsvWorker' => 3,
        'ImportSoftwareLicensesWorker' => 3,
        'IncidentManagement::AddSeveritySystemNoteWorker' => 3,
        'IncidentManagement::ApplyIncidentSlaExceededLabelWorker' => 3,
        'IncidentManagement::OncallRotations::PersistAllRotationsShiftsJob' => 3,
        'IncidentManagement::OncallRotations::PersistShiftsJob' => 3,
        'IncidentManagement::PagerDuty::ProcessIncidentWorker' => 3,
        'InvalidGpgSignatureUpdateWorker' => 3,
        'IrkerWorker' => 3,
        'IssuableExportCsvWorker' => 3,
        'IssuePlacementWorker' => 3,
        'IssueRebalancingWorker' => 3,
        'IterationsUpdateStatusWorker' => 3,
        'JiraConnect::SyncBranchWorker' => 3,
        'JiraConnect::SyncBuildsWorker' => 3,
        'JiraConnect::SyncDeploymentsWorker' => 3,
        'JiraConnect::SyncFeatureFlagsWorker' => 3,
        'JiraConnect::SyncMergeRequestWorker' => 3,
        'JiraConnect::SyncProjectWorker' => 3,
        'LdapGroupSyncWorker' => 3,
        'MailScheduler::IssueDueWorker' => 3,
        'MailScheduler::NotificationServiceWorker' => 3,
        'MembersDestroyer::UnassignIssuablesWorker' => 3,
        'MergeRequestCleanupRefsWorker' => 3,
        'MergeRequestMergeabilityCheckWorker' => 3,
        'MergeRequestResetApprovalsWorker' => 3,
        'MergeRequests::AssigneesChangeWorker' => 3,
        'MergeRequests::CreatePipelineWorker' => 3,
        'MergeRequests::DeleteSourceBranchWorker' => 3,
        'MergeRequests::HandleAssigneesChangeWorker' => 3,
        'MergeRequests::ResolveTodosWorker' => 3,
        'MergeRequests::SyncCodeOwnerApprovalRulesWorker' => 3,
        'MergeTrains::RefreshWorker' => 3,
        'MergeWorker' => 3,
        'Metrics::Dashboard::PruneOldAnnotationsWorker' => 3,
        'Metrics::Dashboard::SyncDashboardsWorker' => 3,
        'MigrateExternalDiffsWorker' => 3,
        'NamespacelessProjectDestroyWorker' => 3,
        'Namespaces::OnboardingIssueCreatedWorker' => 3,
        'Namespaces::OnboardingPipelineCreatedWorker' => 3,
        'Namespaces::OnboardingProgressWorker' => 3,
        'Namespaces::OnboardingUserAddedWorker' => 3,
        'Namespaces::RootStatisticsWorker' => 3,
        'Namespaces::ScheduleAggregationWorker' => 3,
        'NetworkPolicyMetricsWorker' => 3,
        'NewEpicWorker' => 3,
        'NewIssueWorker' => 3,
        'NewMergeRequestWorker' => 3,
        'NewNoteWorker' => 3,
        'ObjectPool::CreateWorker' => 3,
        'ObjectPool::DestroyWorker' => 3,
        'ObjectPool::JoinWorker' => 3,
        'ObjectPool::ScheduleJoinWorker' => 3,
        'ObjectStorage::BackgroundMoveWorker' => 5,
        'ObjectStorage::MigrateUploadsWorker' => 3,
        'Packages::Composer::CacheUpdateWorker' => 3,
        'Packages::Go::SyncPackagesWorker' => 3,
        'Packages::Maven::Metadata::SyncWorker' => 3,
        'Packages::Nuget::ExtractionWorker' => 3,
        'Packages::Rubygems::ExtractionWorker' => 3,
        'PagesDomainSslRenewalWorker' => 3,
        'PagesDomainVerificationWorker' => 3,
        'PagesRemoveWorker' => 3,
        'PagesTransferWorker' => 3,
        'PagesUpdateConfigurationWorker' => 3,
        'PagesWorker' => 3,
        'PersonalAccessTokens::Groups::PolicyWorker' => 3,
        'PersonalAccessTokens::Instance::PolicyWorker' => 3,
        'PipelineHooksWorker' => 3,
        'PipelineMetricsWorker' => 3,
        'PipelineNotificationWorker' => 3,
        'PipelineProcessWorker' => 3,
        'PostReceive' => 3,
        'ProcessCommitWorker' => 3,
        'ProjectCacheWorker' => 3,
        'ProjectDailyStatisticsWorker' => 3,
        'ProjectDestroyWorker' => 3,
        'ProjectExportWorker' => false,
        'ProjectImportScheduleWorker' => false,
        'ProjectScheduleBulkRepositoryShardMovesWorker' => 3,
        'ProjectServiceWorker' => 3,
        'ProjectTemplateExportWorker' => false,
        'ProjectUpdateRepositoryStorageWorker' => 3,
        'Projects::GitGarbageCollectWorker' => false,
        'Projects::PostCreationWorker' => 3,
        'Projects::ScheduleBulkRepositoryShardMovesWorker' => 3,
        'Projects::UpdateRepositoryStorageWorker' => 3,
        'Prometheus::CreateDefaultAlertsWorker' => 3,
        'PropagateIntegrationGroupWorker' => 3,
        'PropagateIntegrationInheritDescendantWorker' => 3,
        'PropagateIntegrationInheritWorker' => 3,
        'PropagateIntegrationProjectWorker' => 3,
        'PropagateIntegrationWorker' => 3,
        'PropagateServiceTemplateWorker' => 3,
        'PurgeDependencyProxyCacheWorker' => 3,
        'ReactiveCachingWorker' => 3,
        'RebaseWorker' => 3,
        'RefreshLicenseComplianceChecksWorker' => 3,
        'Releases::CreateEvidenceWorker' => 3,
        'RemoteMirrorNotificationWorker' => 3,
        'RepositoryCheck::BatchWorker' => false,
        'RepositoryCheck::ClearWorker' => false,
        'RepositoryCheck::SingleRepositoryWorker' => false,
        'RepositoryCleanupWorker' => 3,
        'RepositoryForkWorker' => 5,
        'RepositoryImportWorker' => false,
        'RepositoryPushAuditEventWorker' => 3,
        'RepositoryRemoveRemoteWorker' => 3,
        'RepositoryUpdateMirrorWorker' => false,
        'RepositoryUpdateRemoteMirrorWorker' => 3,
        'RequirementsManagement::ImportRequirementsCsvWorker' => 3,
        'RequirementsManagement::ProcessRequirementsReportsWorker' => 3,
        'RunPipelineScheduleWorker' => 3,
        'ScanSecurityReportSecretsWorker' => 17,
        'Security::AutoFixWorker' => 3,
        'Security::StoreScansWorker' => 3,
        'SelfMonitoringProjectCreateWorker' => 3,
        'SelfMonitoringProjectDeleteWorker' => 3,
        'ServiceDeskEmailReceiverWorker' => 3,
        'SetUserStatusBasedOnUserCapSettingWorker' => 3,
        'SnippetScheduleBulkRepositoryShardMovesWorker' => 3,
        'SnippetUpdateRepositoryStorageWorker' => 3,
        'Snippets::ScheduleBulkRepositoryShardMovesWorker' => 3,
        'Snippets::UpdateRepositoryStorageWorker' => 3,
        'StageUpdateWorker' => 3,
        'StatusPage::PublishWorker' => 5,
        'StoreSecurityReportsWorker' => 3,
        'StoreSecurityScansWorker' => 3,
        'SyncSeatLinkRequestWorker' => 20,
        'SyncSeatLinkWorker' => 12,
        'SystemHookPushWorker' => 3,
        'TodosDestroyer::ConfidentialEpicWorker' => 3,
        'TodosDestroyer::ConfidentialIssueWorker' => 3,
        'TodosDestroyer::DestroyedIssuableWorker' => 3,
        'TodosDestroyer::EntityLeaveWorker' => 3,
        'TodosDestroyer::GroupPrivateWorker' => 3,
        'TodosDestroyer::PrivateFeaturesWorker' => 3,
        'TodosDestroyer::ProjectPrivateWorker' => 3,
        'UpdateExternalPullRequestsWorker' => 3,
        'UpdateHeadPipelineForMergeRequestWorker' => 3,
        'UpdateHighestRoleWorker' => 3,
        'UpdateMergeRequestsWorker' => 3,
        'UpdateProjectStatisticsWorker' => 3,
        'UploadChecksumWorker' => 3,
        'Vulnerabilities::Statistics::AdjustmentWorker' => 3,
        'VulnerabilityExports::ExportDeletionWorker' => 3,
        'VulnerabilityExports::ExportWorker' => 3,
        'WaitForClusterCreationWorker' => 3,
        'WebHookWorker' => 4,
        'WebHooks::DestroyWorker' => 3,
        'Wikis::GitGarbageCollectWorker' => false,
        'X509CertificateRevokeWorker' => 3
      }
    end

    it 'uses the default number of retries for new jobs' do
      expect(workers_without_defaults - cronjobs - retry_exception_workers).to all(have_attributes(retries: true))
    end

    it 'uses zero retries for cronjobs' do
      expect(cronjobs - retry_exception_workers).to all(have_attributes(retries: false))
    end

    it 'uses specified numbers of retries for workers with exceptions encoded here', :aggregate_failures do
      retry_exception_workers.each do |worker|
        expect(worker.retries).to eq(retry_exceptions[worker.klass.to_s]),
                                  "#{worker.klass} has #{worker.retries} retries, expected #{retry_exceptions[worker.klass]}"
      end
    end
  end
end
