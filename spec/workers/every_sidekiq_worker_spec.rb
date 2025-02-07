# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Every Sidekiq worker', feature_category: :shared do
  include EverySidekiqWorkerTestHelper

  let(:workers_without_defaults) do
    Gitlab::SidekiqConfig.workers - Gitlab::SidekiqConfig::DEFAULT_WORKERS.values
  end

  it 'does not use the default queue' do
    expect(workers_without_defaults.map(&:generated_queue_name)).not_to include('default')
  end

  it 'uses the cronjob queue when the worker runs as a cronjob' do
    expect(Gitlab::SidekiqConfig.cron_workers.map(&:generated_queue_name)).to all(start_with('cronjob:'))
  end

  it 'has its queue in Gitlab::SidekiqConfig::QUEUE_CONFIG_PATHS', :aggregate_failures do
    file_worker_queues = Gitlab::SidekiqConfig.worker_queues.to_set

    worker_queues = Gitlab::SidekiqConfig.workers.map(&:generated_queue_name).to_set
    worker_queues << ActionMailer::MailDeliveryJob.new('Notify').queue_name
    worker_queues << 'default'

    missing_from_file = worker_queues - file_worker_queues
    expect(missing_from_file).to be_empty, "expected #{missing_from_file.to_a.inspect} to be in Gitlab::SidekiqConfig::QUEUE_CONFIG_PATHS"

    unnecessarily_in_file = file_worker_queues - worker_queues
    expect(unnecessarily_in_file).to be_empty, "expected #{unnecessarily_in_file.to_a.inspect} not to be in Gitlab::SidekiqConfig::QUEUE_CONFIG_PATHS"
  end

  it 'has its queue or namespace in config/sidekiq_queues.yml', :aggregate_failures do
    config_queues = Gitlab::SidekiqConfig.config_queues.to_set

    Gitlab::SidekiqConfig.workers.each do |worker|
      queue = worker.generated_queue_name
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
      Gitlab::FeatureCategories.default.categories.map(&:to_sym).to_set
    end

    # All Sidekiq worker classes should declare a valid `feature_category`
    # or explicitly be excluded with the `feature_category_not_owned!` annotation.
    # Please see doc/development/sidekiq_style_guide.md#feature-categorization for more details.
    it 'has a feature_category attribute', :aggregate_failures do
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
        'Analytics::UsageTrends::CounterJobWorker' => 3,
        'ApprovalRules::ExternalApprovalRulePayloadWorker' => 3,
        'ApproveBlockedPendingApprovalUsersWorker' => 3,
        'AuthorizedKeysWorker' => 3,
        'AuthorizedProjectUpdate::UserRefreshOverUserRangeWorker' => 3,
        'AuthorizedProjectUpdate::UserRefreshWithLowUrgencyWorker' => 3,
        'AuthorizedProjectUpdate::UserRefreshFromReplicaWorker' => 3,
        'AuthorizedProjectsWorker' => 3,
        'AutoDevops::DisableWorker' => 3,
        'AutoMergeProcessWorker' => 3,
        'BackgroundMigrationWorker' => 3,
        'BackgroundMigration::CiDatabaseWorker' => 3,
        'BuildQueueWorker' => 3,
        'BulkImportWorker' => 3,
        'BulkImports::ExportRequestWorker' => 5,
        'BulkImports::EntityWorker' => 3,
        'BulkImports::PipelineWorker' => 6,
        'BulkImports::PipelineBatchWorker' => 6,
        'BulkImports::FinishProjectImportWorker' => 3,
        'BulkImports::TransformReferencesWorker' => 3,
        'Chaos::CpuSpinWorker' => 3,
        'Chaos::DbSpinWorker' => 3,
        'Chaos::KillWorker' => false,
        'Chaos::LeakMemWorker' => 3,
        'Chaos::SleepWorker' => 3,
        'ChatNotificationWorker' => false,
        'Ci::ArchiveTraceWorker' => 3,
        'Ci::BuildFinishedWorker' => 3,
        'Ci::BuildPrepareWorker' => 3,
        'Ci::BuildScheduleWorker' => 3,
        'Ci::BuildTraceChunkFlushWorker' => 3,
        'Ci::CreateDownstreamPipelineWorker' => 3,
        'Ci::DailyBuildGroupReportResultsWorker' => 3,
        'Ci::DeleteObjectsWorker' => 0,
        'Ci::DropPipelineWorker' => 3,
        'Ci::InitialPipelineProcessWorker' => 3,
        'Ci::UpdateBuildNamesWorker' => 3,
        'Ci::MergeRequests::AddTodoWhenBuildFailsWorker' => 3,
        'Ci::Minutes::UpdateProjectAndNamespaceUsageWorker' => 3,
        'Ci::PipelineArtifacts::CoverageReportWorker' => 3,
        'Ci::PipelineArtifacts::CreateQualityReportWorker' => 3,
        'Ci::PipelineCleanupRefWorker' => 3,
        'Ci::PipelineBridgeStatusWorker' => 3,
        'Ci::RefDeleteUnlockArtifactsWorker' => 3,
        'Ci::Refs::UnlockPreviousPipelinesWorker' => 3,
        'Ci::ResourceGroups::AssignResourceFromResourceGroupWorker' => 3,
        'Ci::ResourceGroups::AssignResourceFromResourceGroupWorkerV2' => 3,
        'Ci::TestFailureHistoryWorker' => 3,
        'Ci::TriggerDownstreamSubscriptionsWorker' => 3,
        'Ci::UnlockPipelinesInQueueWorker' => 0,
        'Ci::SyncReportsToReportApprovalRulesWorker' => 3,
        'CleanupContainerRepositoryWorker' => 3,
        'CloudConnector::SyncServiceTokenWorker' => 3,
        'ClusterConfigureIstioWorker' => 3,
        'ClusterInstallAppWorker' => 3,
        'ClusterPatchAppWorker' => 3,
        'ClusterProvisionWorker' => 3,
        'ClusterUpdateAppWorker' => 3,
        'ClusterUpgradeAppWorker' => 3,
        'ClusterWaitForAppInstallationWorker' => 3,
        'ClusterWaitForAppUpdateWorker' => 3,
        'ClusterWaitForIngressIpAddressWorker' => 3,
        'Clusters::Applications::ActivateIntegrationWorker' => 3,
        'Clusters::Applications::DeactivateIntegrationWorker' => 3,
        'Clusters::Applications::UninstallWorker' => 3,
        'Clusters::Applications::WaitForUninstallAppWorker' => 3,
        'Clusters::Cleanup::ProjectNamespaceWorker' => 3,
        'Clusters::Cleanup::ServiceAccountWorker' => 3,
        'ContainerExpirationPolicies::CleanupContainerRepositoryWorker' => 0,
        'ContainerRegistry::DeleteContainerRepositoryWorker' => 0,
        'ContainerRegistry::RecordDataRepairDetailWorker' => 0,
        'CreateCommitSignatureWorker' => 3,
        'CreateGithubWebhookWorker' => 3,
        'CreateNoteDiffFileWorker' => 3,
        'CreatePipelineWorker' => 3,
        'Database::LockTablesWorker' => false,
        'Database::BatchedBackgroundMigration::CiExecutionWorker' => 0,
        'Database::BatchedBackgroundMigration::MainExecutionWorker' => 0,
        'DeleteDiffFilesWorker' => 3,
        'DeleteMergedBranchesWorker' => 3,
        'DeleteStoredFilesWorker' => 3,
        'DeleteUserWorker' => 3,
        'DependencyProxy::CleanupBlobWorker' => 0,
        'DependencyProxy::CleanupManifestWorker' => 0,
        'Deployments::AutoRollbackWorker' => 3,
        'Deployments::LinkMergeRequestWorker' => 3,
        'Deployments::UpdateEnvironmentWorker' => 3,
        'Deployments::ApprovalWorker' => 3,
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
        'ExportCsvWorker' => 3,
        'ExternalServiceReactiveCachingWorker' => 3,
        'FileHookWorker' => false,
        'FlushCounterIncrementsWorker' => 3,
        'Geo::ContainerRepositorySyncWorker' => 1,
        'Geo::DestroyWorker' => 3,
        'Geo::EventWorker' => 3,
        'Geo::ReverificationBatchWorker' => 0,
        'Geo::BulkMarkPendingBatchWorker' => 0,
        'Geo::BulkMarkVerificationPendingBatchWorker' => 0,
        'Geo::Scheduler::SchedulerWorker' => false,
        'Geo::Scheduler::Secondary::SchedulerWorker' => false,
        'Geo::SyncWorker' => false,
        'Geo::VerificationBatchWorker' => 0,
        'Geo::VerificationStateBackfillWorker' => false,
        'Geo::VerificationTimeoutWorker' => false,
        'Geo::VerificationWorker' => 3,
        'Gitlab::BitbucketImport::AdvanceStageWorker' => 6,
        'Gitlab::BitbucketImport::Stage::FinishImportWorker' => 6,
        'Gitlab::BitbucketImport::Stage::ImportIssuesWorker' => 6,
        'Gitlab::BitbucketImport::Stage::ImportIssuesNotesWorker' => 6,
        'Gitlab::BitbucketImport::Stage::ImportLfsObjectsWorker' => 6,
        'Gitlab::BitbucketImport::Stage::ImportPullRequestsWorker' => 6,
        'Gitlab::BitbucketImport::Stage::ImportPullRequestsNotesWorker' => 6,
        'Gitlab::BitbucketImport::Stage::ImportRepositoryWorker' => 6,
        'Gitlab::BitbucketImport::Stage::ImportUsersWorker' => 6,
        'Gitlab::BitbucketServerImport::AdvanceStageWorker' => 6,
        'Gitlab::BitbucketServerImport::Stage::FinishImportWorker' => 6,
        'Gitlab::BitbucketServerImport::Stage::ImportLfsObjectsWorker' => 6,
        'Gitlab::BitbucketServerImport::Stage::ImportNotesWorker' => 6,
        'Gitlab::BitbucketServerImport::Stage::ImportPullRequestsWorker' => 6,
        'Gitlab::BitbucketServerImport::Stage::ImportRepositoryWorker' => 6,
        'Gitlab::BitbucketServerImport::Stage::ImportUsersWorker' => 6,
        'Gitlab::GithubImport::AdvanceStageWorker' => 6,
        'Gitlab::GithubImport::Attachments::ImportReleaseWorker' => 5,
        'Gitlab::GithubImport::Attachments::ImportNoteWorker' => 5,
        'Gitlab::GithubImport::Attachments::ImportIssueWorker' => 5,
        'Gitlab::GithubImport::Attachments::ImportMergeRequestWorker' => 5,
        'Gitlab::GithubImport::ImportDiffNoteWorker' => 5,
        'Gitlab::GithubImport::ImportIssueWorker' => 5,
        'Gitlab::GithubImport::ImportIssueEventWorker' => 5,
        'Gitlab::GithubImport::ImportLfsObjectWorker' => 5,
        'Gitlab::GithubImport::ImportNoteWorker' => 5,
        'Gitlab::GithubImport::ImportProtectedBranchWorker' => 5,
        'Gitlab::GithubImport::ImportCollaboratorWorker' => 5,
        'Gitlab::GithubImport::PullRequests::ImportReviewRequestWorker' => 5,
        'Gitlab::GithubImport::PullRequests::ImportReviewWorker' => 5,
        'Gitlab::GithubImport::PullRequests::ImportMergedByWorker' => 5,
        'Gitlab::GithubImport::ImportPullRequestWorker' => 5,
        'Gitlab::GithubImport::ReplayEventsWorker' => 5,
        'Gitlab::GithubImport::Stage::FinishImportWorker' => 6,
        'Gitlab::GithubImport::Stage::ImportBaseDataWorker' => 6,
        'Gitlab::GithubImport::Stage::ImportIssuesAndDiffNotesWorker' => 6,
        'Gitlab::GithubImport::Stage::ImportIssueEventsWorker' => 6,
        'Gitlab::GithubImport::Stage::ImportLfsObjectsWorker' => 6,
        'Gitlab::GithubImport::Stage::ImportAttachmentsWorker' => 6,
        'Gitlab::GithubImport::Stage::ImportProtectedBranchesWorker' => 6,
        'Gitlab::GithubImport::Stage::ImportNotesWorker' => 6,
        'Gitlab::GithubImport::Stage::ImportCollaboratorsWorker' => 6,
        'Gitlab::GithubImport::Stage::ImportPullRequestsMergedByWorker' => 6,
        'Gitlab::GithubImport::Stage::ImportPullRequestsReviewRequestsWorker' => 6,
        'Gitlab::GithubImport::Stage::ImportPullRequestsReviewsWorker' => 6,
        'Gitlab::GithubImport::Stage::ImportPullRequestsWorker' => 6,
        'Gitlab::GithubImport::Stage::ImportRepositoryWorker' => 6,
        'Gitlab::GithubGistsImport::ImportGistWorker' => 5,
        'Gitlab::GithubGistsImport::StartImportWorker' => 5,
        'Gitlab::GithubGistsImport::FinishImportWorker' => 5,
        'Gitlab::Import::RefreshImportJidWorker' => 5,
        'Gitlab::JiraImport::AdvanceStageWorker' => 6,
        'Gitlab::JiraImport::ImportIssueWorker' => 5,
        'Gitlab::JiraImport::Stage::FinishImportWorker' => 6,
        'Gitlab::JiraImport::Stage::ImportAttachmentsWorker' => 6,
        'Gitlab::JiraImport::Stage::ImportIssuesWorker' => 6,
        'Gitlab::JiraImport::Stage::ImportLabelsWorker' => 6,
        'Gitlab::JiraImport::Stage::ImportNotesWorker' => 6,
        'Gitlab::JiraImport::Stage::StartImportWorker' => 6,
        'GitlabPerformanceBarStatsWorker' => 3,
        'GitlabSubscriptions::RefreshSeatsWorker' => 0,
        'GitlabSubscriptions::AddOnPurchases::BulkRefreshUserAssignmentsWorker' => 0,
        'GitlabSubscriptions::AddOnPurchases::CleanupWorker' => false,
        'GitlabServicePingWorker' => 3,
        'GroupDestroyWorker' => 3,
        'GroupExportWorker' => false,
        'GroupImportWorker' => false,
        'GroupSamlGroupSyncWorker' => 3,
        'GroupWikis::GitGarbageCollectWorker' => false,
        'Groups::ScheduleBulkRepositoryShardMovesWorker' => 3,
        'Groups::UpdateRepositoryStorageWorker' => 3,
        'Groups::UpdateStatisticsWorker' => 3,
        'Import::BulkImports::SourceUsersAttributesWorker' => 6,
        'Import::LoadPlaceholderReferencesWorker' => 6,
        'ImportIssuesCsvWorker' => 3,
        'ImportSoftwareLicensesWorker' => 3,
        'IncidentManagement::AddSeveritySystemNoteWorker' => 3,
        'IncidentManagement::ApplyIncidentSlaExceededLabelWorker' => 3,
        'IncidentManagement::OncallRotations::PersistAllRotationsShiftsJob' => 3,
        'IncidentManagement::OncallRotations::PersistShiftsJob' => 3,
        'IncidentManagement::PagerDuty::ProcessIncidentWorker' => 3,
        'Integrations::ExecuteWorker' => 3,
        'Integrations::IrkerWorker' => 3,
        'InvalidGpgSignatureUpdateWorker' => 3,
        'IssuableExportCsvWorker' => 3,
        'Issues::CloseWorker' => 3,
        'Issues::PlacementWorker' => 3,
        'Issues::RebalancingWorker' => 3,
        'IterationsUpdateStatusWorker' => 3,
        'Integrations::JiraConnect::RemoveBranchWorker' => 3,
        'JiraConnect::SyncBranchWorker' => 3,
        'JiraConnect::SyncBuildsWorker' => 3,
        'JiraConnect::SyncDeploymentsWorker' => 3,
        'JiraConnect::SyncFeatureFlagsWorker' => 3,
        'JiraConnect::SyncMergeRequestWorker' => 3,
        'JiraConnect::SyncProjectWorker' => 3,
        'LdapGroupSyncWorker' => 3,
        'Licenses::ResetSubmitLicenseUsageDataBannerWorker' => 13,
        'Llm::CompletionWorker' => 3,
        'MailScheduler::IssueDueWorker' => 3,
        'MailScheduler::NotificationServiceWorker' => 3,
        'MembersDestroyer::UnassignIssuablesWorker' => 3,
        'Members::PruneDeletionsWorker' => 0,
        'MergeRequestCleanupRefsWorker' => 3,
        'MergeRequestMergeabilityCheckWorker' => 3,
        'MergeRequestResetApprovalsWorker' => 3,
        'MergeRequests::CaptureSuggestedReviewersAcceptedWorker' => 3,
        'MergeRequests::CleanupRefWorker' => 3,
        'MergeRequests::CreatePipelineWorker' => 3,
        'MergeRequests::DeleteSourceBranchWorker' => 3,
        'MergeRequests::DuoCodeReviewChatWorker' => 3,
        'MergeRequests::FetchSuggestedReviewersWorker' => 3,
        'MergeRequests::HandleAssigneesChangeWorker' => 3,
        'MergeRequests::MergeabilityCheckBatchWorker' => 3,
        'MergeRequests::ResolveTodosWorker' => 3,
        'MergeRequests::SyncCodeOwnerApprovalRulesWorker' => 3,
        'MergeTrains::RefreshWorker' => 3,
        'MergeWorker' => 3,
        'MigrateExternalDiffsWorker' => 3,
        'Onboarding::ProgressTrackingWorker' => 3,
        'Namespaces::RootStatisticsWorker' => 3,
        'Namespaces::ScheduleAggregationWorker' => 3,
        'Namespaces::RemoveDormantMembersWorker' => 0,
        'NewEpicWorker' => 3,
        'NewIssueWorker' => 3,
        'NewMergeRequestWorker' => 3,
        'NewNoteWorker' => 3,
        'ObjectPool::CreateWorker' => 3,
        'ObjectPool::DestroyWorker' => 3,
        'ObjectPool::JoinWorker' => 3,
        'ObjectPool::ScheduleJoinWorker' => 3,
        'ObjectStorage::MigrateUploadsWorker' => 3,
        'Packages::CleanupPackageFileWorker' => 0,
        'Packages::Cleanup::ExecutePolicyWorker' => 0,
        'Packages::Go::SyncPackagesWorker' => 3,
        'Packages::MarkPackageFilesForDestructionWorker' => 3,
        'Packages::Maven::Metadata::SyncWorker' => 3,
        'Packages::Npm::CleanupStaleMetadataCacheWorker' => 0,
        'Packages::Nuget::CleanupStaleSymbolsWorker' => 0,
        'Packages::Nuget::ExtractionWorker' => 3,
        'Packages::Rubygems::ExtractionWorker' => 3,
        'PagesDomainSslRenewalWorker' => 3,
        'PagesDomainVerificationWorker' => 3,
        'PagesWorker' => 3,
        'PersonalAccessTokens::Groups::PolicyWorker' => 3,
        'PersonalAccessTokens::Instance::PolicyWorker' => 3,
        'PipelineHooksWorker' => 3,
        'PipelineMetricsWorker' => 3,
        'PipelineNotificationWorker' => 3,
        'PipelineProcessWorker' => 3,
        'PostReceive' => 3,
        'ProcessCommitWorker' => 3,
        'ProductAnalytics::InitializeSnowplowProductAnalyticsWorker' => 1,
        'ProjectCacheWorker' => 3,
        'ProjectDestroyWorker' => 3,
        'ProjectExportWorker' => false,
        'ProjectImportScheduleWorker' => 1,
        'ProjectTemplateExportWorker' => false,
        'Projects::DeregisterSuggestedReviewersProjectWorker' => 3,
        'Projects::DisableLegacyOpenSourceLicenseForInactiveProjectsWorker' => 3,
        'Projects::GitGarbageCollectWorker' => false,
        'Projects::ImportExport::RelationExportWorker' => 6,
        'Projects::ImportExport::RelationImportWorker' => 6,
        'Projects::InactiveProjectsDeletionNotificationWorker' => 3,
        'Projects::PostCreationWorker' => 3,
        'Projects::ScheduleBulkRepositoryShardMovesWorker' => 3,
        'Projects::UpdateRepositoryStorageWorker' => 3,
        'Projects::RefreshBuildArtifactsSizeStatisticsWorker' => 0,
        'Projects::RegisterSuggestedReviewersProjectWorker' => 3,
        'PropagateIntegrationGroupWorker' => 3,
        'PropagateIntegrationInheritDescendantWorker' => 3,
        'PropagateIntegrationInheritWorker' => 3,
        'PropagateIntegrationProjectWorker' => 3,
        'PropagateIntegrationWorker' => 3,
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
        'RepositoryUpdateMirrorWorker' => false,
        'RepositoryUpdateRemoteMirrorWorker' => 3,
        'RequirementsManagement::ImportRequirementsCsvWorker' => 3,
        'RequirementsManagement::ProcessRequirementsReportsWorker' => 3,
        'RunPipelineScheduleWorker' => 3,
        'ScanSecurityReportSecretsWorker' => 17,
        'Search::ElasticGroupAssociationDeletionWorker' => 3,
        'Search::Elastic::DeleteWorker' => 3,
        'Search::Zoekt::AdjustIndicesReservedStorageBytesEventWorker' => 1,
        'Search::Zoekt::DeleteProjectEventWorker' => 1,
        'Search::Zoekt::IndexMarkedAsReadyEventWorker' => 1,
        'Search::Zoekt::IndexMarkAsPendingEvictionEventWorker' => 1,
        'Search::Zoekt::IndexMarkedAsToDeleteEventWorker' => 1,
        'Search::Zoekt::IndexOverWatermarkEventWorker' => 1,
        'Search::Zoekt::IndexToEvictEventWorker' => 1,
        'Search::Zoekt::IndexWatermarkChangedEventWorker' => 1,
        'Search::Zoekt::InitialIndexingEventWorker' => 1,
        'Search::Zoekt::LostNodeEventWorker' => 1,
        'Search::Zoekt::NodeWithNegativeUnclaimedStorageEventWorker' => 1,
        'Search::Zoekt::OrphanedIndexEventWorker' => 1,
        'Search::Zoekt::OrphanedRepoEventWorker' => 1,
        'Search::Zoekt::RepoMarkedAsToDeleteEventWorker' => 1,
        'Search::Zoekt::RepoToIndexEventWorker' => 1,
        'Search::Zoekt::TaskFailedEventWorker' => 1,
        'Search::Zoekt::UpdateIndexUsedStorageBytesEventWorker' => 1,
        'Search::Zoekt::SaasRolloutEventWorker' => 1,
        'Security::StoreScansWorker' => 3,
        'Security::TrackSecureScansWorker' => 1,
        'ServiceDeskEmailReceiverWorker' => 3,
        'SetUserStatusBasedOnUserCapSettingWorker' => 3,
        'Snippets::ScheduleBulkRepositoryShardMovesWorker' => 3,
        'Snippets::UpdateRepositoryStorageWorker' => 3,
        'StageUpdateWorker' => 3,
        'StatusPage::PublishWorker' => 5,
        'Security::StoreSecurityReportsByProjectWorker' => 3,
        'SyncSeatLinkRequestWorker' => 20,
        'SyncSeatLinkWorker' => 12,
        'SystemHookPushWorker' => 3,
        'TodosDestroyer::ConfidentialEpicWorker' => 3,
        'TodosDestroyer::ConfidentialIssueWorker' => 3,
        'TodosDestroyer::DestroyedIssuableWorker' => 3,
        'TodosDestroyer::DestroyedDesignsWorker' => 3,
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
        'Import::ReassignPlaceholderUserRecordsWorker' => 5,
        'Vulnerabilities::Statistics::AdjustmentWorker' => 3,
        'VulnerabilityExports::ExportDeletionWorker' => 3,
        'VulnerabilityExports::ExportWorker' => 3,
        'VirtualRegistries::Packages::DestroyOrphanCachedResponsesWorker' => 0,
        'VirtualRegistries::Packages::Cache::DestroyOrphanEntriesWorker' => 0,
        'WaitForClusterCreationWorker' => 3,
        'WebHookWorker' => 4,
        'WebHooks::LogExecutionWorker' => 3,
        'Wikis::GitGarbageCollectWorker' => false,
        'WorkItems::ImportWorkItemsCsvWorker' => 3,
        'X509CertificateRevokeWorker' => 3,
        'ComplianceManagement::MergeRequests::ComplianceViolationsWorker' => 3,
        'Issuable::RelatedLinksCreateWorker' => 3,
        'BulkImports::RelationBatchExportWorker' => 6,
        'BulkImports::RelationExportWorker' => 6,
        'Ci::Runners::ExportUsageCsvWorker' => 3,
        'AppSec::ContainerScanning::ScanImageWorker' => 3,
        'Ci::DestroyOldPipelinesWorker' => 0
      }.merge(extra_retry_exceptions)
    end

    it 'defines `retry_exceptions` only for existing workers', if: Gitlab.ee? do
      removed_workers = retry_exceptions.keys - retry_exception_workers.map { |worker| worker.klass.to_s }
      message = -> do
        list = removed_workers.map { |name| "- #{name}" }

        <<~MESSAGE
          The following workers no longer exist but are defined in `retry_exceptions`:

          #{list.join("\n")}

          Make sure to remove them from `retry_exceptions` because their definition is unnecessary.
        MESSAGE
      end

      expect(removed_workers).to be_empty, message
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
