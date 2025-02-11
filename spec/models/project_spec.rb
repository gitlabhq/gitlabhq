# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Project, factory_default: :keep, feature_category: :groups_and_projects do
  include ContainerRegistryHelpers
  include ProjectForksHelper
  include ExternalAuthorizationServiceHelpers
  include ReloadHelpers
  include StubGitlabCalls
  include ProjectHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:namespace) { create_default(:namespace).freeze }

  it_behaves_like 'having unique enum values'

  context 'when runner registration is allowed' do
    let_it_be(:project) { create(:project, :allow_runner_registration_token) }

    it_behaves_like 'ensures runners_token is prefixed' do
      subject(:record) { project }
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:organization) }
    it { is_expected.to belong_to(:group) }
    it { is_expected.to belong_to(:namespace) }
    it { is_expected.to belong_to(:project_namespace).class_name('Namespaces::ProjectNamespace').with_foreign_key('project_namespace_id').inverse_of(:project) }
    it { is_expected.to belong_to(:creator).class_name('User') }
    it { is_expected.to belong_to(:pool_repository) }
    it { is_expected.to have_many(:users) }
    it { is_expected.to have_many(:maintainers).through(:project_members).source(:user).conditions(members: { access_level: Gitlab::Access::MAINTAINER }) }
    it { is_expected.to have_many(:owners_and_maintainers).through(:project_members).source(:user).conditions(members: { access_level: Gitlab::Access::MAINTAINER }) }
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:merge_requests) }
    it { is_expected.to have_many(:merge_request_metrics).class_name('MergeRequest::Metrics') }
    it { is_expected.to have_many(:issues) }
    it { is_expected.to have_many(:work_items) }
    it { is_expected.to have_many(:incident_management_issuable_escalation_statuses).through(:issues).inverse_of(:project).class_name('IncidentManagement::IssuableEscalationStatus') }
    it { is_expected.to have_many(:milestones) }
    it { is_expected.to have_many(:project_members).dependent(:delete_all) }
    it { is_expected.to have_many(:namespace_members) }
    it { is_expected.to have_many(:users).through(:project_members) }
    it { is_expected.to have_many(:requesters).dependent(:delete_all) }
    it { is_expected.to have_many(:namespace_requesters) }
    it { is_expected.to have_many(:notes).dependent(:destroy) }
    it { is_expected.to have_many(:snippets).class_name('ProjectSnippet') }
    it { is_expected.to have_many(:deploy_keys_projects) }
    it { is_expected.to have_many(:deploy_keys) }
    it { is_expected.to have_many(:hooks) }
    it { is_expected.to have_many(:protected_branches) }
    it { is_expected.to have_many(:exported_protected_branches) }
    it { is_expected.to have_one(:wiki_repository).class_name('Projects::WikiRepository').inverse_of(:project) }
    it { is_expected.to have_one(:design_management_repository).class_name('DesignManagement::Repository').inverse_of(:project) }
    it { is_expected.to have_one(:slack_integration) }
    it { is_expected.to have_one(:catalog_resource) }
    it { is_expected.to have_many(:ci_components).class_name('Ci::Catalog::Resources::Component') }
    it { is_expected.to have_many(:ci_component_usages).class_name('Ci::Catalog::Resources::Components::Usage') }
    it { is_expected.to have_many(:ci_component_last_usages).class_name('Ci::Catalog::Resources::Components::LastUsage').inverse_of(:component_project) }
    it { is_expected.to have_many(:catalog_resource_versions).class_name('Ci::Catalog::Resources::Version') }
    it { is_expected.to have_many(:catalog_resource_sync_events).class_name('Ci::Catalog::Resources::SyncEvent') }
    it { is_expected.to have_one(:microsoft_teams_integration) }
    it { is_expected.to have_one(:mattermost_integration) }
    it { is_expected.to have_one(:matrix_integration) }
    it { is_expected.to have_one(:hangouts_chat_integration) }
    it { is_expected.to have_one(:telegram_integration) }
    it { is_expected.to have_one(:unify_circuit_integration) }
    it { is_expected.to have_one(:pumble_integration) }
    it { is_expected.to have_one(:webex_teams_integration) }
    it { is_expected.to have_one(:packagist_integration) }
    it { is_expected.to have_one(:phorge_integration) }
    it { is_expected.to have_one(:pushover_integration) }
    it { is_expected.to have_one(:apple_app_store_integration) }
    it { is_expected.to have_one(:google_play_integration) }
    it { is_expected.to have_one(:asana_integration) }
    it { is_expected.to have_many(:boards) }
    it { is_expected.to have_one(:campfire_integration) }
    it { is_expected.to have_one(:datadog_integration) }
    it { is_expected.to have_one(:discord_integration) }
    it { is_expected.to have_one(:drone_ci_integration) }
    it { is_expected.to have_one(:emails_on_push_integration) }
    it { is_expected.to have_one(:pipelines_email_integration) }
    it { is_expected.to have_one(:irker_integration) }
    it { is_expected.to have_one(:pivotaltracker_integration) }
    it { is_expected.to have_one(:assembla_integration) }
    it { is_expected.to have_one(:slack_slash_commands_integration) }
    it { is_expected.to have_one(:mattermost_slash_commands_integration) }
    it { is_expected.to have_one(:buildkite_integration) }
    it { is_expected.to have_one(:bamboo_integration) }
    it { is_expected.to have_one(:teamcity_integration) }
    it { is_expected.to have_one(:jira_integration) }
    it { is_expected.to have_one(:jira_cloud_app_integration) }
    it { is_expected.to have_one(:harbor_integration) }
    it { is_expected.to have_one(:redmine_integration) }
    it { is_expected.to have_one(:youtrack_integration) }
    it { is_expected.to have_one(:clickup_integration) }
    it { is_expected.to have_one(:custom_issue_tracker_integration) }
    it { is_expected.to have_one(:bugzilla_integration) }
    it { is_expected.to have_one(:ewm_integration) }
    it { is_expected.to have_one(:external_wiki_integration) }
    it { is_expected.to have_one(:confluence_integration) }
    it { is_expected.to have_one(:gitlab_slack_application_integration) }
    it { is_expected.to have_one(:beyond_identity_integration) }
    it { is_expected.to have_one(:project_feature) }
    it { is_expected.to have_one(:project_repository) }
    it { is_expected.to have_one(:container_expiration_policy) }
    it { is_expected.to have_one(:statistics).class_name('ProjectStatistics') }
    it { is_expected.to have_one(:import_data).class_name('ProjectImportData') }
    it { is_expected.to have_one(:last_event).class_name('Event') }
    it { is_expected.to have_one(:forked_from_project).through(:fork_network_member) }
    it { is_expected.to have_one(:auto_devops).class_name('ProjectAutoDevops') }
    it { is_expected.to have_one(:error_tracking_setting).class_name('ErrorTracking::ProjectErrorTrackingSetting') }
    it { is_expected.to have_one(:project_setting) }
    it { is_expected.to have_one(:alerting_setting).class_name('Alerting::ProjectAlertingSetting') }
    it { is_expected.to have_one(:mock_ci_integration) }
    it { is_expected.to have_one(:mock_monitoring_integration) }
    it { is_expected.to have_one(:service_desk_custom_email_verification).class_name('ServiceDesk::CustomEmailVerification') }
    it { is_expected.to have_one(:container_registry_data_repair_detail).class_name('ContainerRegistry::DataRepairDetail') }
    it { is_expected.to have_many(:container_registry_protection_rules).class_name('ContainerRegistry::Protection::Rule') }
    it { is_expected.to have_many(:container_registry_protection_tag_rules).class_name('ContainerRegistry::Protection::TagRule') }
    it { is_expected.to have_many(:commit_statuses) }
    it { is_expected.to have_many(:ci_pipelines) }
    it { is_expected.to have_many(:ci_refs) }
    it { is_expected.to have_many(:builds) }
    it { is_expected.to have_many(:build_report_results) }
    it { is_expected.to have_many(:runner_projects) }
    it { is_expected.to have_many(:runners) }
    it { is_expected.to have_many(:variables) }
    it { is_expected.to have_many(:triggers) }
    it { is_expected.to have_many(:labels).class_name('ProjectLabel') }
    it { is_expected.to have_many(:users_star_projects) }
    it { is_expected.to have_many(:repository_languages) }
    it { is_expected.to have_many(:environments) }
    it { is_expected.to have_many(:deployments) }
    it { is_expected.to have_many(:todos) }
    it { is_expected.to have_many(:releases) }
    it { is_expected.to have_many(:lfs_objects_projects) }
    it { is_expected.to have_many(:project_group_links) }
    it { is_expected.to have_many(:notification_settings).dependent(:delete_all) }
    it { is_expected.to have_many(:forked_to_members).class_name('ForkNetworkMember') }
    it { is_expected.to have_many(:forks).through(:forked_to_members) }
    it { is_expected.to have_many(:uploads) }
    it { is_expected.to have_many(:pipeline_schedules) }
    it { is_expected.to have_many(:members_and_requesters) }
    it { is_expected.to have_many(:namespace_members_and_requesters) }
    it { is_expected.to have_many(:clusters) }
    it { is_expected.to have_many(:management_clusters).class_name('Clusters::Cluster') }
    it { is_expected.to have_many(:kubernetes_namespaces) }
    it { is_expected.to have_many(:cluster_agents).class_name('Clusters::Agent') }
    it { is_expected.to have_many(:custom_attributes).class_name('ProjectCustomAttribute') }
    it { is_expected.to have_many(:project_badges).class_name('ProjectBadge') }
    it { is_expected.to have_many(:lfs_file_locks) }
    it { is_expected.to have_many(:project_deploy_tokens) }
    it { is_expected.to have_many(:deploy_tokens).through(:project_deploy_tokens) }
    it { is_expected.to have_many(:external_pull_requests) }
    it { is_expected.to have_many(:sourced_pipelines) }
    it { is_expected.to have_many(:source_pipelines) }
    it { is_expected.to have_many(:alert_management_alerts) }
    it { is_expected.to have_many(:alert_management_http_integrations) }
    it { is_expected.to have_many(:jira_imports) }
    it { is_expected.to have_many(:repository_storage_moves) }
    it { is_expected.to have_many(:reviews).inverse_of(:project) }
    it { is_expected.to have_many(:packages).class_name('Packages::Package') }
    it { is_expected.to have_many(:package_files).class_name('Packages::PackageFile') }
    it { is_expected.to have_many(:rpm_repository_files).class_name('Packages::Rpm::RepositoryFile').inverse_of(:project).dependent(:destroy) }
    it { is_expected.to have_many(:debian_distributions).class_name('Packages::Debian::ProjectDistribution').dependent(:destroy) }
    it { is_expected.to have_many(:npm_metadata_caches).class_name('Packages::Npm::MetadataCache') }
    it { is_expected.to have_one(:packages_cleanup_policy).class_name('Packages::Cleanup::Policy').inverse_of(:project) }
    it { is_expected.to have_many(:package_protection_rules).class_name('Packages::Protection::Rule').inverse_of(:project) }
    it { is_expected.to have_many(:pipeline_artifacts).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:terraform_states).class_name('Terraform::State').inverse_of(:project) }
    it { is_expected.to have_many(:timelogs) }
    it { is_expected.to have_many(:error_tracking_client_keys).class_name('ErrorTracking::ClientKey') }
    it { is_expected.to have_many(:pending_builds).class_name('Ci::PendingBuild') }
    it { is_expected.to have_many(:ci_feature_usages).class_name('Projects::CiFeatureUsage') }
    it { is_expected.to have_many(:bulk_import_exports).class_name('BulkImports::Export') }
    it { is_expected.to have_many(:job_artifacts).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:build_trace_chunks).through(:builds).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:secure_files).class_name('Ci::SecureFile').dependent(:restrict_with_error) }
    it { is_expected.to have_one(:build_artifacts_size_refresh).class_name('Projects::BuildArtifactsSizeRefresh') }
    it { is_expected.to have_many(:project_callouts).class_name('Users::ProjectCallout').with_foreign_key(:project_id) }
    it { is_expected.to have_many(:pipeline_metadata).class_name('Ci::PipelineMetadata') }
    it { is_expected.to have_many(:incident_management_timeline_event_tags).class_name('IncidentManagement::TimelineEventTag') }
    it { is_expected.to have_many(:integrations) }
    it { is_expected.to have_many(:push_hooks_integrations).class_name('Integration') }
    it { is_expected.to have_many(:tag_push_hooks_integrations).class_name('Integration') }
    it { is_expected.to have_many(:issue_hooks_integrations).class_name('Integration') }
    it { is_expected.to have_many(:confidential_issue_hooks_integrations).class_name('Integration') }
    it { is_expected.to have_many(:merge_request_hooks_integrations).class_name('Integration') }
    it { is_expected.to have_many(:note_hooks_integrations).class_name('Integration') }
    it { is_expected.to have_many(:confidential_note_hooks_integrations).class_name('Integration') }
    it { is_expected.to have_many(:job_hooks_integrations).class_name('Integration') }
    it { is_expected.to have_many(:archive_trace_hooks_integrations).class_name('Integration') }
    it { is_expected.to have_many(:pipeline_hooks_integrations).class_name('Integration') }
    it { is_expected.to have_many(:wiki_page_hooks_integrations).class_name('Integration') }
    it { is_expected.to have_many(:deployment_hooks_integrations).class_name('Integration') }
    it { is_expected.to have_many(:alert_hooks_integrations).class_name('Integration') }
    it { is_expected.to have_many(:incident_hooks_integrations).class_name('Integration') }
    it { is_expected.to have_many(:relation_import_trackers).class_name('Projects::ImportExport::RelationImportTracker') }
    it { is_expected.to have_many(:all_protected_branches).class_name('ProtectedBranch') }
    it { is_expected.to have_many(:import_export_uploads).dependent(:destroy) }

    # GitLab Pages
    it { is_expected.to have_many(:pages_domains) }
    it { is_expected.to have_one(:pages_metadatum) }
    it { is_expected.to have_many(:pages_deployments) }

    it_behaves_like 'model with repository' do
      let_it_be(:container) { create(:project, :repository, path: 'somewhere') }
      let(:stubbed_container) { build_stubbed(:project) }
      let(:expected_full_path) { "#{container.namespace.full_path}/somewhere" }
      let(:expected_lfs_enabled) { true }
    end

    it_behaves_like 'model with wiki' do
      let_it_be(:container) { create(:project, :wiki_repo, namespace: create(:group)) }
      let(:container_without_wiki) { create(:project) }
    end

    it_behaves_like 'can move repository storage' do
      let_it_be(:container) { create(:project, :repository) }
    end

    it 'has an inverse relationship with merge requests' do
      expect(described_class.reflect_on_association(:merge_requests).has_inverse?).to eq(:target_project)
    end

    it 'has a distinct has_many :lfs_objects relation through lfs_objects_projects' do
      project = create(:project)
      lfs_object = create(:lfs_object)
      [:project, :design].each do |repository_type|
        create(
          :lfs_objects_project,
          project: project,
          lfs_object: lfs_object,
          repository_type: repository_type
        )
      end

      expect(project.lfs_objects_projects.size).to eq(2)
      expect(project.lfs_objects.size).to eq(1)
      expect(project.lfs_objects.to_a).to eql([lfs_object])
    end

    describe 'maintainers association' do
      let_it_be(:project) { create(:project) }
      let_it_be(:maintainer1) { create(:user) }
      let_it_be(:maintainer2) { create(:user) }
      let_it_be(:reporter) { create(:user) }

      before do
        project.add_maintainer(maintainer1)
        project.add_maintainer(maintainer2)
        project.add_reporter(reporter)
      end

      it 'returns only maintainers' do
        expect(project.maintainers).to match_array([maintainer1, maintainer2])
      end
    end

    context 'after initialized' do
      it "has a project_feature" do
        expect(described_class.new.project_feature).to be_present
      end
    end

    describe 'owners_and_maintainers association' do
      let_it_be(:project) { create(:project) }
      let_it_be(:maintainer) { create(:user) }
      let_it_be(:reporter) { create(:user) }
      let_it_be(:developer) { create(:user) }

      before do
        project.add_maintainer(maintainer)
        project.add_developer(developer)
        project.add_reporter(reporter)
      end

      it 'returns only maintainers and owners' do
        expect(project.owners_and_maintainers).to match_array([maintainer, project.owner])
      end
    end

    context 'when deleting project' do
      # using delete rather than destroy due to `delete` skipping AR hooks/callbacks
      # so it's ensured to work at the DB level. Uses AFTER DELETE trigger.
      let_it_be(:project) { create(:project) }
      let_it_be(:project_namespace) { project.project_namespace }

      it 'also deletes the associated ProjectNamespace' do
        project.delete

        expect { project.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { project_namespace.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when project has object storage attached to it' do
      let_it_be(:project) { create(:project) }

      before do
        create(:ci_job_artifact, project: project)
      end

      context 'when associated object storage object is not deleted before the project' do
        it 'adds an error to project', :aggregate_failures do
          expect { project.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)

          expect(project.errors).not_to be_empty
          expect(project.errors.first.message).to eq("Cannot delete record because dependent job artifacts exist")
        end
      end

      context 'when associated object storage object is deleted before the project' do
        before do
          project.job_artifacts.first.destroy!
        end

        it 'deletes the project' do
          project.destroy!

          expect { project.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    context 'when creating a new project' do
      let_it_be(:project) { create(:project) }

      it 'automatically creates a CI/CD settings row' do
        expect(project.ci_cd_settings).to be_an_instance_of(ProjectCiCdSetting)
        expect(project.ci_cd_settings).to be_persisted
      end

      it 'automatically creates a container expiration policy row' do
        expect(project.container_expiration_policy).to be_an_instance_of(ContainerExpirationPolicy)
        expect(project.container_expiration_policy).to be_persisted
      end

      it 'does not create another container expiration policy if there is already one' do
        project = build(:project)

        expect do
          container_expiration_policy = create(:container_expiration_policy, project: project)

          expect(project.container_expiration_policy).to eq(container_expiration_policy)
        end.to change { ContainerExpirationPolicy.count }.by(1)
      end

      it 'automatically creates a Pages metadata row' do
        expect(project.pages_metadatum).to be_an_instance_of(ProjectPagesMetadatum)
        expect(project.pages_metadatum).to be_persisted
      end

      it 'automatically builds a project setting row' do
        expect(project.project_setting).to be_an_instance_of(ProjectSetting)
        expect(project.project_setting).to be_new_record
      end

      context 'with project namespaces' do
        shared_examples 'creates project namespace' do
          it 'automatically creates a project namespace' do
            project = build(:project, path: 'hopefully-valid-path1')
            project.save!

            expect(project).to be_persisted
            expect(project.project_namespace).to be_persisted
            expect(project.project_namespace).to be_in_sync_with_project(project)
            expect(project.reload.project_namespace.traversal_ids).to eq([project.namespace.traversal_ids, project.project_namespace.id].flatten.compact)
          end
        end

        it_behaves_like 'creates project namespace'
      end
    end

    context 'updating a project' do
      let_it_be(:project_namespace) { create(:project_namespace) }
      let_it_be(:project) { project_namespace.project }

      context 'when project has an associated project namespace' do
        # when FF is disabled creating a project does not create a project_namespace, so we create one
        it 'project is INVALID when trying to remove project namespace' do
          project.reload
          # check that project actually has an associated project namespace
          expect(project.project_namespace_id).to eq(project_namespace.id)

          expect do
            project.update!(project_namespace_id: nil, path: 'hopefully-valid-path1')
          end.to raise_error(ActiveRecord::RecordInvalid)
          expect(project).to be_invalid
          expect(project.errors.full_messages).to include("Project namespace can't be blank")
          expect(project.reload.project_namespace).to be_in_sync_with_project(project)
        end

        context 'when same project is being updated in 2 instances' do
          it 'syncs only changed attributes' do
            project1 = described_class.last
            project2 = described_class.last

            project_name = project1.name
            project_path = project1.path

            project1.update!(name: project_name + "-1")
            project2.update!(path: project_path + "-1")

            expect(project.reload.project_namespace).to be_in_sync_with_project(project)
          end
        end
      end
    end

    context 'updating cd_cd_settings' do
      it 'does not raise an error' do
        project = create(:project)

        expect { project.update!(ci_cd_settings: nil) }.not_to raise_exception
      end
    end

    describe '#namespace_members' do
      let_it_be(:project) { create(:project, :public) }
      let_it_be(:requester) { create(:user) }
      let_it_be(:developer) { create(:user) }

      before_all do
        project.request_access(requester)
        project.add_developer(developer)
      end

      it 'includes the correct users' do
        expect(project.namespace_members).to include Member.find_by(user: developer)
        expect(project.namespace_members).not_to include Member.find_by(user: requester)
      end

      it 'is equivalent to #project_members' do
        expect(project.namespace_members).to match_array(project.project_members)
      end

      it_behaves_like 'query without source filters' do
        subject { project.namespace_members }
      end
    end

    describe '#namespace_requesters' do
      let_it_be(:project) { create(:project, :public) }
      let_it_be(:requester) { create(:user) }
      let_it_be(:developer) { create(:user) }

      before_all do
        project.request_access(requester)
        project.add_developer(developer)
      end

      it 'includes the correct users' do
        expect(project.namespace_requesters).to include Member.find_by(user: requester)
        expect(project.namespace_requesters).not_to include Member.find_by(user: developer)
      end

      it 'is equivalent to #project_members' do
        expect(project.namespace_requesters).to eq project.requesters
      end

      it_behaves_like 'query without source filters' do
        subject { project.namespace_requesters }
      end
    end

    describe '#namespace_members_and_requesters' do
      let_it_be(:project) { create(:project, :public) }
      let_it_be(:requester) { create(:user) }
      let_it_be(:developer) { create(:user) }
      let_it_be(:invited_member) { create(:project_member, :invited, :owner, project: project) }

      before_all do
        project.request_access(requester)
        project.add_developer(developer)
      end

      it 'includes the correct users' do
        expect(project.namespace_members_and_requesters).to include(
          Member.find_by(user: requester),
          Member.find_by(user: developer),
          Member.find(invited_member.id)
        )
      end

      it 'is equivalent to #project_members' do
        expect(project.namespace_members_and_requesters).to match_array(project.members_and_requesters)
      end

      it_behaves_like 'query without source filters' do
        subject { project.namespace_members_and_requesters }
      end
    end

    shared_examples 'polymorphic membership relationship' do
      it do
        expect(membership.attributes).to include(
          'source_type' => 'Project',
          'source_id' => project.id
        )
      end
    end

    shared_examples 'member_namespace membership relationship' do
      it do
        expect(membership.attributes).to include(
          'member_namespace_id' => project.project_namespace_id
        )
      end
    end

    describe '#namespace_members setters' do
      let_it_be(:project) { create(:project) }
      let_it_be(:user) { create(:user) }
      let_it_be(:membership) { project.namespace_members.create!(user: user, access_level: Gitlab::Access::DEVELOPER) }

      it { expect(membership).to be_instance_of(ProjectMember) }
      it { expect(membership.user).to eq user }
      it { expect(membership.project).to eq project }
      it { expect(membership.requested_at).to be_nil }

      it_behaves_like 'polymorphic membership relationship'
      it_behaves_like 'member_namespace membership relationship'
    end

    describe '#namespace_requesters setters' do
      let_it_be(:requested_at) { Time.current }
      let_it_be(:project) { create(:project) }
      let_it_be(:user) { create(:user) }
      let_it_be(:membership) do
        project.namespace_requesters.create!(user: user, requested_at: requested_at, access_level: Gitlab::Access::DEVELOPER)
      end

      it { expect(membership).to be_instance_of(ProjectMember) }
      it { expect(membership.user).to eq user }
      it { expect(membership.project).to eq project }
      it { expect(membership.requested_at).to eq requested_at }

      it_behaves_like 'polymorphic membership relationship'
      it_behaves_like 'member_namespace membership relationship'
    end

    shared_examples 'share with group lock' do
      let_it_be(:group) { create(:group) }
      let_it_be_with_reload(:project) { create(:project, group: group) }

      context 'without share with group lock' do
        it { is_expected.to be_truthy }
      end

      context 'with share with group lock' do
        before do
          group.update!(share_with_group_lock: true)
        end

        it { is_expected.to be_falsey }
      end
    end

    describe '#allowed_to_share_with_group?' do
      subject { project.allowed_to_share_with_group? }

      it_behaves_like 'share with group lock'
    end

    describe '#share_with_group_enabled?' do
      subject { project.share_with_group_enabled? }

      it_behaves_like 'share with group lock'
    end

    describe '#namespace_members_and_requesters setters' do
      let_it_be(:requested_at) { Time.current }
      let_it_be(:project) { create(:project) }
      let_it_be(:user) { create(:user) }
      let_it_be(:membership) do
        project.namespace_members_and_requesters.create!(
          user: user, requested_at: requested_at, access_level: Gitlab::Access::DEVELOPER
        )
      end

      it { expect(membership).to be_instance_of(ProjectMember) }
      it { expect(membership.user).to eq user }
      it { expect(membership.project).to eq project }
      it { expect(membership.requested_at).to eq requested_at }

      it_behaves_like 'polymorphic membership relationship'
      it_behaves_like 'member_namespace membership relationship'
    end

    describe '#members & #requesters' do
      let_it_be(:project) { create(:project, :public) }
      let_it_be(:requester) { create(:user) }
      let_it_be(:developer) { create(:user) }

      before_all do
        project.request_access(requester)
        project.add_developer(developer)
      end

      it_behaves_like 'members and requesters associations' do
        let(:namespace) { project }
      end
    end

    describe 'ci_pipelines association' do
      it 'returns only pipelines from ci_sources' do
        expect(Ci::Pipeline).to receive(:ci_sources).and_call_original

        subject.ci_pipelines
      end
    end

    context 'order of the `has_many :notes` association' do
      let(:associations_having_dependent_destroy) do
        described_class.reflect_on_all_associations(:has_many).select do |assoc|
          assoc.options[:dependent] == :destroy
        end
      end

      let(:associations_having_dependent_destroy_with_issuable_included) do
        associations_having_dependent_destroy.select do |association|
          association.klass.include?(Issuable)
        end
      end

      it 'has `has_many :notes` as the first association among all the other associations that'\
         'includes the `Issuable` module' do
        names_of_associations_having_dependent_destroy = associations_having_dependent_destroy.map(&:name)
        index_of_has_many_notes_association = names_of_associations_having_dependent_destroy.find_index(:notes)

        associations_having_dependent_destroy_with_issuable_included.each do |issuable_included_association|
          index_of_issuable_included_association =
            names_of_associations_having_dependent_destroy.find_index(issuable_included_association.name)

          expect(index_of_has_many_notes_association).to be < index_of_issuable_included_association
        end
      end
    end
  end

  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(Gitlab::ConfigHelper) }
    it { is_expected.to include_module(Gitlab::ShellAdapter) }
    it { is_expected.to include_module(Gitlab::VisibilityLevel) }
    it { is_expected.to include_module(Referable) }
    it { is_expected.to include_module(Sortable) }
  end

  describe 'before_validation' do
    context 'with removal of leading spaces' do
      subject(:project) { build(:project, name: ' space first', path: 'some_path') }

      it 'removes the leading space' do
        expect(project.name).to eq ' space first'

        expect(project).to be_valid # triggers before_validation and assures we automatically handle the bad format

        expect(project.name).to eq 'space first'
      end

      context 'when name is nil' do
        it 'falls through to the presence validation' do
          project.name = nil

          expect(project).not_to be_valid
        end
      end
    end

    context 'when last_activity_at is being set' do
      let(:last_activity_at) { 1.day.ago }
      let(:project) { build(:project, last_activity_at: last_activity_at) }

      it 'will use supplied timestamp' do
        expect { project.valid? }.not_to change(project, :last_activity_at)
      end
    end

    context 'when last_activity_at is not being set' do
      context 'and one of PROJECT_ACTIVITY_ATTRIBUTES is updated' do
        let(:project) { build(:project) }

        before do
          project.name = "Name Changed"
        end

        it 'sets last_activity_at to the current time' do
          freeze_time do
            expect { project.valid? }.to change(project, :last_activity_at).to(Time.current)
          end
        end
      end

      context 'and the record is new' do
        let(:project) { build(:project) }

        it 'sets last_activity_at to the current time' do
          freeze_time do
            expect { project.valid? }.to change(project, :last_activity_at).from(nil).to(Time.current)
          end
        end
      end

      context 'and the last_activity_at is nil' do
        let_it_be(:project) { create(:project) }

        before do
          project.update_column(:last_activity_at, nil)
        end

        it 'sets last_activity_at to created_at' do
          expect { project.valid? }.to change(project, :last_activity_at).from(nil).to(project.created_at)
        end
      end
    end
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to allow_value('space last ').for(:name) }
    it { is_expected.not_to allow_value('colon:in:path').for(:path) } # This is to validate that a specially crafted name cannot bypass a pattern match. See !72555
    it { is_expected.to validate_presence_of(:path) }
    it { is_expected.to validate_length_of(:path).is_at_most(255) }
    it { is_expected.to validate_length_of(:description).is_at_most(2000) }
    it { is_expected.to validate_length_of(:ci_config_path).is_at_most(255) }
    it { is_expected.to allow_value('').for(:ci_config_path) }
    it { is_expected.not_to allow_value('test/../foo').for(:ci_config_path) }
    it { is_expected.not_to allow_value('/test/foo').for(:ci_config_path) }
    it { is_expected.to validate_presence_of(:creator) }
    it { is_expected.to validate_presence_of(:namespace) }
    it { is_expected.to validate_presence_of(:organization) }
    it { is_expected.to validate_presence_of(:repository_storage) }
    it { is_expected.to validate_numericality_of(:max_artifacts_size).only_integer.is_greater_than(0) }
    it { is_expected.to validate_length_of(:suggestion_commit_message).is_at_most(255) }

    it 'validates name is case-sensitively unique within the scope of namespace_id' do
      project = create(:project)

      expect(project).to validate_uniqueness_of(:name).scoped_to(:namespace_id)
    end

    it 'validates build timeout constraints' do
      is_expected.to validate_numericality_of(:build_timeout)
        .only_integer
        .is_greater_than_or_equal_to(10.minutes)
        .is_less_than(1.month)
        .with_message('needs to be between 10 minutes and 1 month')
    end

    it 'does not allow new projects beyond user limits' do
      project2 = build(:project)

      allow(project2)
        .to receive(:creator)
        .and_return(
          double(can_create_project?: false, projects_limit: 0).as_null_object
        )

      expect(project2).not_to be_valid
    end

    it 'validates the visibility' do
      expect_any_instance_of(described_class).to receive(:visibility_level_allowed_as_fork).twice.and_call_original
      expect_any_instance_of(described_class).to receive(:visibility_level_allowed_by_group).twice.and_call_original

      create(:project)
    end

    context 'validates project namespace creation' do
      it 'does not create project namespace if project is not created' do
        project = build(:project, path: 'tree')

        project.valid?

        expect(project).not_to be_valid
        expect(project).to be_new_record
        expect(project.project_namespace).to be_new_record
      end
    end

    context 'repository storages inclusion' do
      let(:project2) { build(:project, repository_storage: 'missing') }

      before do
        storages = { 'custom' => { 'path' => 'tmp/tests/custom_repositories' } }
        allow(Gitlab.config.repositories).to receive(:storages).and_return(storages)
      end

      it "does not allow repository storages that don't match a label in the configuration" do
        expect(project2).not_to be_valid
        expect(project2.errors[:repository_storage].first).to match(/is not included in the list/)
      end
    end

    it 'validates presence of project_feature' do
      project = build(:project)
      project.project_feature = nil

      expect(project).not_to be_valid
    end

    describe 'import_url' do
      it 'does not allow an invalid URI as import_url' do
        project = build(:project, import_url: 'invalid://')

        expect(project).not_to be_valid
      end

      it 'does allow a SSH URI as import_url for persisted projects' do
        project = create(:project)
        project.import_url = 'ssh://test@gitlab.com/project.git'

        expect(project).to be_valid
      end

      it 'does not allow a SSH URI as import_url for new projects' do
        project = build(:project, import_url: 'ssh://test@gitlab.com/project.git')

        expect(project).not_to be_valid
      end

      it 'does allow a valid URI as import_url' do
        project = build(:project, import_url: 'http://gitlab.com/project.git')

        expect(project).to be_valid
      end

      it 'allows an empty URI' do
        project = build(:project, import_url: '')

        expect(project).to be_valid
      end

      it 'does not produce import data on an empty URI' do
        project = build(:project, import_url: '')

        expect(project.import_data).to be_nil
      end

      it 'does not produce import data on an invalid URI' do
        project = build(:project, import_url: 'test://')

        expect(project.import_data).to be_nil
      end

      it "does not allow import_url pointing to localhost" do
        project = build(:project, import_url: 'http://localhost:9000/t.git')

        expect(project).to be_invalid
        expect(project.errors[:import_url].first).to include('Requests to localhost are not allowed')
      end

      it 'does not allow import_url pointing to the local network' do
        project = build(:project, import_url: 'https://192.168.1.1')

        expect(project).to be_invalid
        expect(project.errors[:import_url].first).to include('Requests to the local network are not allowed')
      end

      it "does not allow import_url with invalid ports for new projects" do
        project = build(:project, import_url: 'http://github.com:25/t.git')

        expect(project).to be_invalid
        expect(project.errors[:import_url].first).to include('Only allowed ports are 80, 443')
      end

      it "does not allow import_url with invalid ports for persisted projects" do
        project = create(:project)
        project.import_url = 'http://github.com:25/t.git'

        expect(project).to be_invalid
        expect(project.errors[:import_url].first).to include('Only allowed ports are 22, 80, 443')
      end

      it "does not allow import_url with invalid user" do
        project = build(:project, import_url: 'http://$user:password@github.com/t.git')

        expect(project).to be_invalid
        expect(project.errors[:import_url].first).to include('Username needs to start with an alphanumeric character')
      end

      include_context 'invalid urls'
      include_context 'valid urls with CRLF'

      it 'does not allow URLs with unencoded CR or LF characters' do
        project = build(:project)

        aggregate_failures do
          urls_with_crlf.each do |url|
            project.import_url = url

            expect(project).not_to be_valid
            expect(project.errors.full_messages.first).to match(/is blocked: URI is invalid/)
          end
        end
      end

      it 'allow URLs with CR or LF characters' do
        project = build(:project)

        aggregate_failures do
          valid_urls_with_crlf.each do |url|
            project.import_url = url

            expect(project).to be_valid
            expect(project.errors).to be_empty
          end
        end
      end
    end

    describe 'project pending deletion' do
      let!(:project_pending_deletion) do
        create(:project, pending_delete: true)
      end

      let(:new_project) do
        build(:project, path: project_pending_deletion.path, namespace: project_pending_deletion.namespace)
      end

      before do
        new_project.validate
      end

      it 'contains errors related to the project being deleted' do
        expect(new_project.errors.full_messages).to include(_('The project is still being deleted. Please try again later.'))
      end
    end

    describe 'name format validation' do
      context 'name is unchanged' do
        let_it_be(:invalid_path_project) do
          project = create(:project)
          project.update_attribute(:name, '.invalid_name')
          project
        end

        it 'does not raise validation error for name for existing project' do
          expect { invalid_path_project.update!(description: 'Foo') }.not_to raise_error
        end
      end

      %w[. - $].each do |special_character|
        it "rejects a name starting with '#{special_character}'" do
          project = build(:project, name: "#{special_character}foo")

          expect(project).not_to be_valid
        end
      end
    end

    describe 'path validation' do
      it 'allows paths reserved on the root namespace' do
        project = build(:project, path: 'api')

        expect(project).to be_valid
      end

      it 'rejects paths reserved on another level' do
        project = build(:project, path: 'tree')

        expect(project).not_to be_valid
      end

      it 'rejects nested paths' do
        parent = create(:group, :nested, path: 'environments')
        project = build(:project, path: 'folders', namespace: parent)

        expect(project).not_to be_valid
      end

      it 'allows a reserved group name' do
        parent = create(:group)
        project = build(:project, path: 'avatar', namespace: parent)

        expect(project).to be_valid
      end

      context 'when validating if path already exist as pages unique domain' do
        before do
          stub_pages_setting(host: 'example.com')
        end

        it 'rejects paths that match pages unique domain' do
          create(:project_setting, pages_unique_domain: 'some-unique-domain')

          project = build(:project, path: 'some-unique-domain.example.com')

          expect(project).not_to be_valid
          expect(project.errors.full_messages_for(:path)).to match(['Path already in use'])
        end

        it 'accepts path when the host does not match' do
          create(:project_setting, pages_unique_domain: 'some-unique-domain')

          project = build(:project, path: 'some-unique-domain.another-example.com')

          expect(project).to be_valid
        end

        it 'accepts path when the domain does not match' do
          create(:project_setting, pages_unique_domain: 'another-unique-domain')

          project = build(:project, path: 'some-unique-domain.example.com')

          expect(project).to be_valid
        end
      end

      context 'path is unchanged' do
        let_it_be(:invalid_path_project) do
          project = create(:project, :repository, :public)
          project.update_attribute(:path, 'foo.')
          project
        end

        it 'does not raise validation error for path for existing project' do
          expect { invalid_path_project.update!(name: 'Foo') }.not_to raise_error
        end
      end

      %w[. - _].each do |special_character|
        it "rejects a path ending in '#{special_character}'" do
          project = build(:project, path: "foo#{special_character}")

          expect(project).not_to be_valid
        end

        it "rejects a path starting with '#{special_character}'" do
          project = build(:project, path: "#{special_character}foo")

          expect(project).not_to be_valid
        end
      end
    end
  end

  it_behaves_like 'a BulkUsersByEmailLoad model'

  describe '#notification_group' do
    it 'is expected to be an alias' do
      expect(build(:project).method(:notification_group).original_name).to eq(:group)
    end
  end

  describe '#all_pipelines' do
    let_it_be(:project) { create(:project) }

    before_all do
      create(:ci_pipeline, project: project, ref: 'master', source: :web)
      create(:ci_pipeline, project: project, ref: 'master', source: :external)
    end

    it 'has all pipelines' do
      expect(project.all_pipelines.size).to eq(2)
    end

    context 'when builds are disabled' do
      before do
        project.project_feature.update_attribute(:builds_access_level, ProjectFeature::DISABLED)
      end

      it 'returns .external pipelines' do
        expect(project.all_pipelines).to all(have_attributes(source: 'external'))
        expect(project.all_pipelines.size).to eq(1)
      end
    end
  end

  describe '#ci_pipelines' do
    let_it_be(:project) { create(:project) }

    before_all do
      create(:ci_pipeline, project: project, ref: 'master', source: :web)
      create(:ci_pipeline, project: project, ref: 'master', source: :external)
      create(:ci_pipeline, project: project, ref: 'master', source: :webide)
    end

    it 'excludes dangling pipelines such as :webide' do
      expect(project.ci_pipelines.size).to eq(2)
    end

    context 'when builds are disabled' do
      before do
        project.project_feature.update_attribute(:builds_access_level, ProjectFeature::DISABLED)
      end

      it 'returns .external pipelines' do
        expect(project.ci_pipelines).to all(have_attributes(source: 'external'))
        expect(project.ci_pipelines.size).to eq(1)
      end
    end
  end

  describe '#commit_notes' do
    let_it_be(:project) { create(:project) }

    it "returns project's commit notes" do
      note_1 = create(:note_on_commit, project: project, commit_id: 'commit_id_1')
      note_2 = create(:note_on_commit, project: project, commit_id: 'commit_id_2')

      expect(project.commit_notes).to match_array([note_1, note_2])
    end
  end

  describe '#personal_namespace_holder?' do
    let_it_be(:group) { create(:group) }
    let_it_be(:namespace_user) { create(:user) }
    let_it_be(:admin_user) { create(:user, :admin) }
    let_it_be(:personal_project) { create(:project, namespace: namespace_user.namespace) }
    let_it_be(:group_project) { create(:project, group: group) }
    let_it_be(:another_user) { create(:user) }
    let_it_be(:group_owner_user) { create(:user, owner_of: group) }

    where(:project, :user, :result) do
      ref(:personal_project)      | ref(:namespace_user)   | true
      ref(:personal_project)      | ref(:admin_user)       | false
      ref(:personal_project)      | ref(:another_user)     | false
      ref(:personal_project)      | nil                    | false
      ref(:group_project)         | ref(:namespace_user)   | false
      ref(:group_project)         | ref(:group_owner_user) | false
      ref(:group_project)         | ref(:another_user)     | false
      ref(:group_project)         | nil                    | false
      ref(:group_project)         | nil                    | false
      ref(:group_project)         | ref(:admin_user)       | false
    end

    with_them do
      it { expect(project.personal_namespace_holder?(user)).to eq(result) }
    end
  end

  describe '#invalidate_personal_projects_count_of_owner' do
    context 'for personal projects' do
      let_it_be(:namespace_user) { create(:user) }
      let_it_be(:project) { create(:project, namespace: namespace_user.namespace) }

      it 'invalidates personal_project_count cache of the the owner of the personal namespace' do
        expect(Rails.cache).to receive(:delete).with(['users', namespace_user.id, 'personal_projects_count'])

        project.invalidate_personal_projects_count_of_owner
      end
    end

    context 'for projects in groups' do
      let_it_be(:project) { create(:project, namespace: create(:group)) }

      it 'does not invalidates any cache' do
        expect(Rails.cache).not_to receive(:delete)

        project.invalidate_personal_projects_count_of_owner
      end
    end
  end

  describe '#default_pipeline_lock' do
    let(:project) { build_stubbed(:project) }

    subject { project.default_pipeline_lock }

    where(:keep_latest_artifact_enabled, :result_pipeline_locked) do
      false        | :unlocked
      true         | :artifacts_locked
    end

    before do
      allow(project).to receive(:keep_latest_artifacts_available?).and_return(keep_latest_artifact_enabled)
    end

    with_them do
      it { expect(subject).to eq(result_pipeline_locked) }
    end
  end

  describe '#membership_locked?' do
    it 'returns false' do
      expect(build(:project)).not_to be_membership_locked
    end
  end

  describe '#autoclose_referenced_issues' do
    context 'when DB entry is nil' do
      let(:project) { build(:project, autoclose_referenced_issues: nil) }

      it 'returns true' do
        expect(project.autoclose_referenced_issues).to be_truthy
      end
    end

    context 'when DB entry is true' do
      let(:project) { build(:project, autoclose_referenced_issues: true) }

      it 'returns true' do
        expect(project.autoclose_referenced_issues).to be_truthy
      end
    end

    context 'when DB entry is false' do
      let(:project) { build(:project, autoclose_referenced_issues: false) }

      it 'returns false' do
        expect(project.autoclose_referenced_issues).to be_falsey
      end
    end
  end

  describe 'runner registration token' do
    let(:project) { create(:project, :allow_runner_registration_token, runners_token: initial_token) }

    context 'when no token provided' do
      let(:initial_token) { '' }

      it 'sets a random token as the project runners_token' do
        expect(project.runners_token).to be_present
        expect(project.runners_token).not_to eq(initial_token)
      end
    end

    context 'when initial token exists' do
      let(:initial_token) { "#{RunnersTokenPrefixable::RUNNERS_TOKEN_PREFIX}my-token" }

      it 'assigns the provided token value as the project runners_token' do
        expect(project.runners_token).to eq(initial_token)
      end
    end
  end

  describe 'Respond to' do
    it { is_expected.to respond_to(:url_to_repo) }
    it { is_expected.to respond_to(:execute_hooks) }
    it { is_expected.to respond_to(:owner) }
    it { is_expected.to respond_to(:path_with_namespace) }
    it { is_expected.to respond_to(:full_path) }
  end

  describe 'delegation' do
    let_it_be(:project) { create(:project) }

    [:add_guest, :add_planner, :add_reporter, :add_developer, :add_maintainer, :add_member, :add_members].each do |method|
      it { is_expected.to delegate_method(method).to(:team) }
    end

    it { is_expected.to delegate_method(:members).to(:team).with_prefix(true) }
    it { is_expected.to delegate_method(:has_user?).to(:team) }
    it { is_expected.to delegate_method(:member?).to(:team) }
    it { is_expected.to delegate_method(:name).to(:owner).with_prefix(true).allow_nil }
    it { is_expected.to delegate_method(:root_ancestor).to(:namespace).allow_nil }
    it { is_expected.to delegate_method(:certificate_based_clusters_enabled?).to(:namespace).allow_nil }
    it { is_expected.to delegate_method(:last_pipeline).to(:commit).allow_nil }
    it { is_expected.to delegate_method(:container_registry_enabled?).to(:project_feature) }
    it { is_expected.to delegate_method(:container_registry_access_level).to(:project_feature) }
    it { is_expected.to delegate_method(:environments_access_level).to(:project_feature) }
    it { is_expected.to delegate_method(:model_experiments_access_level).to(:project_feature) }
    it { is_expected.to delegate_method(:model_registry_access_level).to(:project_feature) }
    it { is_expected.to delegate_method(:feature_flags_access_level).to(:project_feature) }
    it { is_expected.to delegate_method(:releases_access_level).to(:project_feature) }
    it { is_expected.to delegate_method(:infrastructure_access_level).to(:project_feature) }
    it { is_expected.to delegate_method(:maven_package_requests_forwarding).to(:namespace) }
    it { is_expected.to delegate_method(:pypi_package_requests_forwarding).to(:namespace) }
    it { is_expected.to delegate_method(:npm_package_requests_forwarding).to(:namespace) }

    describe 'read project settings' do
      %i[
        show_default_award_emojis
        show_default_award_emojis?
        warn_about_potentially_unwanted_characters
        warn_about_potentially_unwanted_characters?
        enforce_auth_checks_on_uploads
        enforce_auth_checks_on_uploads?
      ].each do |method|
        it { is_expected.to delegate_method(method).to(:project_setting).allow_nil }
      end
    end

    describe 'write project settings' do
      %i[
        show_default_award_emojis=
        warn_about_potentially_unwanted_characters=
        enforce_auth_checks_on_uploads=
      ].each do |method|
        it { is_expected.to delegate_method(method).to(:project_setting).with_arguments(:args).allow_nil }
      end
    end

    include_examples 'ci_cd_settings delegation' do
      let(:attributes_with_prefix) do
        {
          'group_runners_enabled' => '',
          'default_git_depth' => 'ci_',
          'forward_deployment_enabled' => 'ci_',
          'forward_deployment_rollback_allowed' => 'ci_',
          'keep_latest_artifact' => '',
          'restrict_user_defined_variables' => '',
          'pipeline_variables_minimum_override_role' => 'ci_',
          'runner_token_expiration_interval' => '',
          'separated_caches' => 'ci_',
          'allow_fork_pipelines_to_run_in_parent_project' => 'ci_',
          'inbound_job_token_scope_enabled' => 'ci_',
          'push_repository_for_job_token_allowed' => 'ci_',
          'job_token_scope_enabled' => 'ci_outbound_',
          'id_token_sub_claim_components' => 'ci_',
          'delete_pipelines_in_seconds' => 'ci_'
        }
      end

      let(:exclude_attributes) do
        # Skip attributes defined in EE code
        %w[
          merge_pipelines_enabled
          merge_trains_enabled
          auto_rollback_enabled
          merge_trains_skip_train_allowed
          restrict_pipeline_cancellation_role
        ]
      end
    end

    describe '#ci_forward_deployment_enabled?' do
      it_behaves_like 'a ci_cd_settings predicate method', prefix: 'ci_' do
        let(:delegated_method) { :forward_deployment_enabled? }
      end
    end

    describe '#ci_forward_deployment_rollback_allowed?' do
      it_behaves_like 'a ci_cd_settings predicate method', prefix: 'ci_' do
        let(:delegated_method) { :forward_deployment_rollback_allowed? }
      end
    end

    describe '#ci_allow_fork_pipelines_to_run_in_parent_project?' do
      it_behaves_like 'a ci_cd_settings predicate method', prefix: 'ci_' do
        let(:delegated_method) { :allow_fork_pipelines_to_run_in_parent_project? }
      end
    end

    describe '#ci_outbound_job_token_scope_enabled?' do
      it_behaves_like 'a ci_cd_settings predicate method', prefix: 'ci_outbound_' do
        let(:delegated_method) { :job_token_scope_enabled? }
      end
    end

    describe '#ci_inbound_job_token_scope_enabled?' do
      it_behaves_like 'a ci_cd_settings predicate method', prefix: 'ci_', default: true do
        let(:delegated_method) { :inbound_job_token_scope_enabled? }
      end

      where(:ci_cd_settings_attrs, :instance_enabled, :expectation) do
        nil | true | true
        nil | false | true
        { inbound_job_token_scope_enabled: true } | true | true
        { inbound_job_token_scope_enabled: true } | false | true
        { inbound_job_token_scope_enabled: false } | true | true
        { inbound_job_token_scope_enabled: false } | false | false
      end

      with_them do
        let_it_be(:project) { create(:project) }

        before do
          if ci_cd_settings_attrs.nil?
            allow(project).to receive(:ci_cd_settings).and_return(nil)
          else
            project.ci_cd_settings.update_attribute(:inbound_job_token_scope_enabled, ci_cd_settings_attrs[:inbound_job_token_scope_enabled])
          end

          allow(::Gitlab::CurrentSettings).to receive(:enforce_ci_inbound_job_token_scope_enabled?).and_return(instance_enabled)
        end

        it { expect(project.ci_inbound_job_token_scope_enabled?).to be(expectation) }
      end
    end

    describe '#restrict_user_defined_variables?' do
      it_behaves_like 'a ci_cd_settings predicate method' do
        let(:delegated_method) { :restrict_user_defined_variables? }
      end
    end

    describe '#ci_push_repository_for_job_token_allowed?' do
      it_behaves_like 'a ci_cd_settings predicate method', prefix: 'ci_' do
        let(:delegated_method) { :push_repository_for_job_token_allowed? }
      end
    end

    describe '#keep_latest_artifacts_available?' do
      it_behaves_like 'a ci_cd_settings predicate method' do
        let(:delegated_method) { :keep_latest_artifacts_available? }
      end
    end

    describe '#keep_latest_artifact?' do
      it_behaves_like 'a ci_cd_settings predicate method' do
        let(:delegated_method) { :keep_latest_artifact? }
      end
    end

    describe '#group_runners_enabled?' do
      it_behaves_like 'a ci_cd_settings predicate method' do
        let(:delegated_method) { :group_runners_enabled? }
      end
    end
  end

  describe '#merge_commit_template_or_default' do
    let_it_be(:project) { create(:project) }

    it 'returns default merge commit template' do
      expect(project.merge_commit_template_or_default).to eq(Project::DEFAULT_MERGE_COMMIT_TEMPLATE)
    end

    context 'when merge commit template is set and not nil' do
      before do
        project.merge_commit_template = '%{description}'
      end

      it 'returns current value' do
        expect(project.merge_commit_template_or_default).to eq('%{description}')
      end
    end
  end

  describe '#merge_commit_template_or_default=' do
    let_it_be(:project) { create(:project) }

    it 'sets template to nil when set to default value' do
      project.merge_commit_template_or_default = Project::DEFAULT_MERGE_COMMIT_TEMPLATE
      expect(project.merge_commit_template).to be_nil
    end

    it 'sets template to nil when set to default value but with CRLF line endings' do
      project.merge_commit_template_or_default = "Merge branch '%{source_branch}' into '%{target_branch}'\r\n\r\n%{title}\r\n\r\n%{issues}\r\n\r\nSee merge request %{reference}"
      expect(project.merge_commit_template).to be_nil
    end

    it 'allows changing template' do
      project.merge_commit_template_or_default = '%{description}'
      expect(project.merge_commit_template).to eq('%{description}')
    end

    it 'allows setting template to nil' do
      project.merge_commit_template_or_default = nil
      expect(project.merge_commit_template).to be_nil
    end
  end

  describe '#squash_commit_template_or_default' do
    let_it_be(:project) { create(:project) }

    it 'returns default squash commit template' do
      expect(project.squash_commit_template_or_default).to eq(Project::DEFAULT_SQUASH_COMMIT_TEMPLATE)
    end

    context 'when squash commit template is set and not nil' do
      before do
        project.squash_commit_template = '%{description}'
      end

      it 'returns current value' do
        expect(project.squash_commit_template_or_default).to eq('%{description}')
      end
    end
  end

  describe '#squash_commit_template_or_default=' do
    let_it_be(:project) { create(:project) }

    it 'sets template to nil when set to default value' do
      project.squash_commit_template_or_default = Project::DEFAULT_SQUASH_COMMIT_TEMPLATE
      expect(project.squash_commit_template).to be_nil
    end

    it 'allows changing template' do
      project.squash_commit_template_or_default = '%{description}'
      expect(project.squash_commit_template).to eq('%{description}')
    end

    it 'allows setting template to nil' do
      project.squash_commit_template_or_default = nil
      expect(project.squash_commit_template).to be_nil
    end
  end

  describe 'reference methods' do
    # TODO update when we have multiple owners of a project
    # https://gitlab.com/gitlab-org/gitlab/-/issues/350605
    let_it_be(:owner)     { create(:user, name: 'Gitlab') }
    let_it_be(:namespace) { create(:namespace, name: 'Sample namespace', path: 'sample-namespace', owner: owner) }
    let_it_be(:project)   { create(:project, name: 'Sample project', path: 'sample-project', namespace: namespace) }
    let_it_be(:group)     { create(:group, name: 'Group', path: 'sample-group') }
    let_it_be(:another_project) { create(:project, namespace: namespace) }
    let_it_be(:another_namespace_project) { create(:project, name: 'another-project') }

    describe '#to_reference' do
      it 'returns the path with reference_postfix' do
        expect(project.to_reference).to eq("#{project.full_path}>")
      end

      it 'returns the path with reference_postfix when arg is self' do
        expect(project.to_reference(project)).to eq("#{project.full_path}>")
      end

      it 'returns the full_path with reference_postfix when full' do
        expect(project.to_reference(full: true)).to eq("#{project.full_path}>")
      end

      it 'returns the full_path with reference_postfix when cross-project' do
        expect(project.to_reference(build_stubbed(:project))).to eq("#{project.full_path}>")
      end
    end

    describe '#to_reference_base' do
      context 'when nil argument' do
        it 'returns nil' do
          expect(project.to_reference_base).to be_nil
        end
      end

      context 'when full is true' do
        it 'returns complete path to the project', :aggregate_failures do
          be_full_path = eq('sample-namespace/sample-project')

          expect(project.to_reference_base(full: true)).to be_full_path
          expect(project.to_reference_base(project, full: true)).to be_full_path
          expect(project.to_reference_base(group, full: true)).to be_full_path
        end
      end

      context 'when absolute_path is true' do
        it 'returns complete path to the project with leading slash', :aggregate_failures do
          be_full_path = eq('/sample-namespace/sample-project')

          expect(project.to_reference_base(full: true, absolute_path: true)).to be_full_path
        end
      end

      context 'when same project argument' do
        it 'returns nil' do
          expect(project.to_reference_base(project)).to be_nil
        end
      end

      context 'when cross namespace project argument' do
        it 'returns complete path to the project' do
          expect(project.to_reference_base(another_namespace_project)).to eq 'sample-namespace/sample-project'
        end
      end

      context 'when same namespace / cross-project argument' do
        it 'returns path to the project' do
          expect(project.to_reference_base(another_project)).to eq 'sample-project'
        end
      end

      context 'when different namespace / cross-project argument with same owner' do
        let(:another_namespace_same_owner) { create(:namespace, path: 'another-namespace', owner: owner) }
        let(:another_project_same_owner)   { create(:project, path: 'another-project', namespace: another_namespace_same_owner) }

        it 'returns full path to the project' do
          expect(project.to_reference_base(another_project_same_owner)).to eq 'sample-namespace/sample-project'
        end
      end

      context 'when argument is a namespace' do
        context 'with same project path' do
          it 'returns path to the project' do
            expect(project.to_reference_base(namespace)).to eq 'sample-project'
          end
        end

        context 'with different project path' do
          it 'returns full path to the project' do
            expect(project.to_reference_base(group)).to eq 'sample-namespace/sample-project'
          end
        end
      end

      context 'when argument is a user' do
        it 'returns full path to the project' do
          expect(project.to_reference_base(owner)).to eq 'sample-namespace/sample-project'
        end
      end
    end

    describe '#to_human_reference' do
      context 'when nil argument' do
        it 'returns nil' do
          expect(project.to_human_reference).to be_nil
        end
      end

      context 'when same project argument' do
        it 'returns nil' do
          expect(project.to_human_reference(project)).to be_nil
        end
      end

      context 'when cross namespace project argument' do
        it 'returns complete name with namespace of the project' do
          expect(project.to_human_reference(another_namespace_project)).to eq 'Gitlab / Sample project'
        end
      end

      context 'when same namespace / cross-project argument' do
        it 'returns name of the project' do
          expect(project.to_human_reference(another_project)).to eq 'Sample project'
        end
      end
    end

    describe '#reference_pattern' do
      it 'matches a normal reference' do
        reference = project.to_reference
        match = reference.match(described_class.reference_pattern)

        expect(match[:namespace]).to eq project.namespace.full_path
        expect(match[:project]).to eq project.path
        expect(match[:absolute_path]).to eq nil
      end

      it 'matches an absolute reference' do
        reference = "/#{project.to_reference}"
        match = reference.match(described_class.reference_pattern)

        expect(match[:namespace]).to eq project.namespace.full_path
        expect(match[:project]).to eq project.path
        expect(match[:absolute_path]).to eq '/'
      end
    end
  end

  describe '#to_reference_base' do
    let_it_be(:user) { create(:user) }
    let_it_be(:user_namespace) { user.namespace }

    let_it_be(:parent) { create(:group) }
    let_it_be(:group) { create(:group, parent: parent) }
    let_it_be(:another_group) { create(:group) }

    let_it_be(:project1) { create(:project, namespace: group) }
    let_it_be(:project_namespace) { project1.project_namespace }

    # different project same group
    let_it_be(:project2) { create(:project, namespace: group) }
    let_it_be(:project_namespace2) { project2.project_namespace }

    # different project from different group
    let_it_be(:project3) { create(:project) }
    let_it_be(:project_namespace3) { project3.project_namespace }

    # testing references with namespace being: group, project namespace and user namespace
    where(:project, :full, :from, :result) do
      ref(:project1) | false | nil                       | nil
      ref(:project1) | true  | nil                       | lazy { project.full_path }
      ref(:project1) | false | ref(:group)               | lazy { project.path }
      ref(:project1) | true  | ref(:group)               | lazy { project.full_path }
      ref(:project1) | false | ref(:parent)              | lazy { project.full_path }
      ref(:project1) | true  | ref(:parent)              | lazy { project.full_path }
      ref(:project1) | false | ref(:project1)            | nil
      ref(:project1) | true  | ref(:project1)            | lazy { project.full_path }
      ref(:project1) | false | ref(:project_namespace)   | nil
      ref(:project1) | true  | ref(:project_namespace)   | lazy { project.full_path }
      ref(:project1) | false | ref(:project2)            | lazy { project.path }
      ref(:project1) | true  | ref(:project2)            | lazy { project.full_path }
      ref(:project1) | false | ref(:project_namespace2)  | lazy { project.path }
      ref(:project1) | true  | ref(:project_namespace2)  | lazy { project.full_path }
      ref(:project1) | false | ref(:another_group)       | lazy { project.full_path }
      ref(:project1) | true  | ref(:another_group)       | lazy { project.full_path }
      ref(:project1) | false | ref(:project3)            | lazy { project.full_path }
      ref(:project1) | true  | ref(:project3)            | lazy { project.full_path }
      ref(:project1) | false | ref(:project_namespace3)  | lazy { project.full_path }
      ref(:project1) | true  | ref(:project_namespace3)  | lazy { project.full_path }
      ref(:project1) | false | ref(:user_namespace)      | lazy { project.full_path }
      ref(:project1) | true  | ref(:user_namespace)      | lazy { project.full_path }
    end

    with_them do
      it 'returns correct path' do
        expect(project.to_reference_base(from, full: full)).to eq(result)
      end
    end
  end

  describe '#merge_method' do
    where(:ff, :rebase, :method) do
      true  | true  | :ff
      true  | false | :ff
      false | true  | :rebase_merge
      false | false | :merge
    end

    with_them do
      let(:project) { build(:project, merge_requests_rebase_enabled: rebase, merge_requests_ff_only_enabled: ff) }

      subject { project.merge_method }

      it { is_expected.to eq(method) }
    end
  end

  describe '#merge_method=' do
    where(:merge_method, :ff_only_enabled, :rebase_enabled) do
      :ff           | true | true
      :rebase_merge | false | true
      :merge        | false | false
    end

    with_them do
      let(:project) { build :project }

      subject { project.merge_method = merge_method }

      it 'sets merge_requests_ff_only_enabled and merge_requests_rebase_enabled' do
        subject
        expect(project.merge_requests_ff_only_enabled).to eq(ff_only_enabled)
        expect(project.merge_requests_rebase_enabled).to eq(rebase_enabled)
      end
    end
  end

  it 'returns valid url to repo' do
    project = described_class.new(path: 'somewhere')
    expect(project.url_to_repo).to eq(Gitlab.config.gitlab_shell.ssh_path_prefix + 'somewhere.git')
  end

  describe "#readme_url" do
    context 'with a non-existing repository' do
      let(:project) { create(:project) }

      it 'returns nil' do
        expect(project.readme_url).to be_nil
      end
    end

    context 'with an existing repository' do
      context 'when no README exists' do
        let(:project) { create(:project, :empty_repo) }

        it 'returns nil' do
          expect(project.readme_url).to be_nil
        end
      end

      context 'when a README exists' do
        let(:project) { create(:project, :repository) }

        it 'returns the README' do
          expect(project.readme_url).to eq("#{project.web_url}/-/blob/master/README.md")
        end
      end
    end
  end

  describe "#new_issuable_address" do
    let_it_be(:project) { create(:project, path: "somewhere") }
    let_it_be(:user) { create(:user) }

    context 'incoming email enabled' do
      before do
        stub_incoming_email_setting(enabled: true, address: "p+%{key}@gl.ab")
      end

      it 'returns the address to create a new issue' do
        address = "p+#{project.full_path_slug}-#{project.project_id}-#{user.incoming_email_token}-issue@gl.ab"

        expect(project.new_issuable_address(user, 'issue')).to eq(address)
      end

      it 'returns the address to create a new merge request' do
        address = "p+#{project.full_path_slug}-#{project.project_id}-#{user.incoming_email_token}-merge-request@gl.ab"

        expect(project.new_issuable_address(user, 'merge_request')).to eq(address)
      end

      it 'returns nil with invalid address type' do
        expect(project.new_issuable_address(user, 'invalid_param')).to be_nil
      end
    end

    context 'incoming email disabled' do
      before do
        stub_incoming_email_setting(enabled: false)
      end

      it 'returns nil' do
        expect(project.new_issuable_address(user, 'issue')).to be_nil
      end

      it 'returns nil' do
        expect(project.new_issuable_address(user, 'merge_request')).to be_nil
      end
    end
  end

  describe 'last_activity methods' do
    let(:timestamp) { 2.hours.ago }
    # last_activity_at gets set to created_at upon creation
    let(:project) { create(:project, created_at: timestamp, updated_at: timestamp) }

    describe 'last_activity' do
      it 'alias last_activity to last_event' do
        last_event = create(:event, :closed, project: project)

        expect(project.last_activity).to eq(last_event)
      end
    end
  end

  describe '#get_issue' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }

    let!(:issue) { create(:issue, project: project) }

    before_all do
      project.add_developer(user)
    end

    context 'with default issues tracker' do
      it 'returns an issue' do
        expect(project.get_issue(issue.iid, user)).to eq issue
      end

      it 'returns count of open issues' do
        expect(project.open_issues_count).to eq(1)
      end

      it 'returns nil when no issue found' do
        expect(project.get_issue(non_existing_record_id, user)).to be_nil
      end

      it "returns nil when user doesn't have access" do
        user = create(:user)
        expect(project.get_issue(issue.iid, user)).to eq nil
      end
    end

    context 'with external issues tracker' do
      let!(:internal_issue) { create(:issue, project: project) }

      before do
        allow(project).to receive(:external_issue_tracker).and_return(true)
      end

      context 'when internal issues are enabled' do
        it 'returns interlan issue' do
          issue = project.get_issue(internal_issue.iid, user)

          expect(issue).to be_kind_of(Issue)
          expect(issue.iid).to eq(internal_issue.iid)
          expect(issue.project).to eq(project)
        end

        it 'returns an ExternalIssue when internal issue does not exists' do
          issue = project.get_issue('FOO-1234', user)

          expect(issue).to be_kind_of(ExternalIssue)
          expect(issue.iid).to eq('FOO-1234')
          expect(issue.project).to eq(project)
        end
      end

      context 'when internal issues are disabled' do
        before do
          project.issues_enabled = false
          project.save!
        end

        it 'returns always an External issues' do
          issue = project.get_issue(internal_issue.iid, user)
          expect(issue).to be_kind_of(ExternalIssue)
          expect(issue.iid).to eq(internal_issue.iid.to_s)
          expect(issue.project).to eq(project)
        end

        it 'returns an ExternalIssue when internal issue does not exists' do
          issue = project.get_issue('FOO-1234', user)
          expect(issue).to be_kind_of(ExternalIssue)
          expect(issue.iid).to eq('FOO-1234')
          expect(issue.project).to eq(project)
        end
      end
    end
  end

  describe '#open_issues_count' do
    let(:project) { build(:project) }

    it 'provides the issue count' do
      expect(project.open_issues_count).to eq 0
    end

    it 'invokes the count service with current_user' do
      user = build(:user)
      count_service = instance_double(Projects::OpenIssuesCountService)
      expect(Projects::OpenIssuesCountService).to receive(:new).with(project, user).and_return(count_service)
      expect(count_service).to receive(:count)

      project.open_issues_count(user)
    end

    it 'invokes the batch count service with no current_user' do
      count_service = instance_double(Projects::BatchOpenIssuesCountService)
      expect(Projects::BatchOpenIssuesCountService).to receive(:new).with([project]).and_return(count_service)
      expect(count_service).to receive(:refresh_cache_and_retrieve_data).and_return({})

      project.open_issues_count.to_s
    end
  end

  describe '#open_merge_requests_count' do
    it 'provides the merge request count' do
      project = build(:project)

      expect(project.open_merge_requests_count).to eq 0
    end
  end

  describe '#issue_exists?' do
    let_it_be(:project) { create(:project) }

    it 'is truthy when issue exists' do
      expect(project).to receive(:get_issue).and_return(double)
      expect(project.issue_exists?(1)).to be_truthy
    end

    it 'is falsey when issue does not exist' do
      expect(project).to receive(:get_issue).and_return(nil)
      expect(project.issue_exists?(1)).to be_falsey
    end
  end

  describe '#to_param' do
    context 'with namespace' do
      before do
        @group = create(:group, name: 'gitlab')
        @project = create(:project, path: 'gitlabhq', namespace: @group)
      end

      it { expect(@project.to_param).to eq('gitlabhq') }
    end

    context 'with invalid path' do
      it 'returns previous path to keep project suitable for use in URLs when persisted' do
        project = create(:project, path: 'gitlab')
        project.path = 'foo&bar'

        expect(project).not_to be_valid
        expect(project.to_param).to eq 'gitlab'
      end

      it 'returns current path when new record' do
        project = build(:project, path: 'gitlab')
        project.path = 'foo&bar'

        expect(project).not_to be_valid
        expect(project.to_param).to eq 'foo&bar'
      end
    end
  end

  describe '#default_issues_tracker?' do
    it "is true if used internal tracker" do
      project = build(:project)

      expect(project.default_issues_tracker?).to be_truthy
    end

    it "is false if used other tracker" do
      # NOTE: The current nature of this factory requires persistence
      project = create(:project, :with_redmine_integration)

      expect(project.default_issues_tracker?).to be_falsey
    end
  end

  describe '#has_wiki?' do
    let(:no_wiki_project)       { create(:project, :wiki_disabled, has_external_wiki: false) }
    let(:wiki_enabled_project)  { create(:project) }
    let(:external_wiki_project) { create(:project, has_external_wiki: true) }

    it 'returns true if project is wiki enabled or has external wiki' do
      expect(wiki_enabled_project).to have_wiki
      expect(external_wiki_project).to have_wiki
      expect(no_wiki_project).not_to have_wiki
    end
  end

  describe '#first_owner' do
    let_it_be(:owner)     { create(:user) }
    let_it_be(:namespace) { create(:namespace, owner: owner) }

    context 'the project does not have a group' do
      let(:project) { build(:project, namespace: namespace) }

      it 'is the namespace owner' do
        expect(project.first_owner).to eq(owner)
      end
    end

    context 'the project is in a group' do
      let(:group)   { build(:group) }
      let(:project) { build(:project, group: group, namespace: namespace) }

      it 'is the group owner' do
        allow(group).to receive(:first_owner).and_return(Object.new)

        expect(project.first_owner).to eq(group.first_owner)
      end
    end
  end

  describe '#external_issue_tracker' do
    it 'sets Project#has_external_issue_tracker when it is nil' do
      project_with_no_tracker = create(:project, has_external_issue_tracker: nil)
      project_with_tracker = create(:project, :with_redmine_integration, has_external_issue_tracker: nil)

      expect do
        project_with_no_tracker.external_issue_tracker
      end.to change { project_with_no_tracker.reload.has_external_issue_tracker }.from(nil).to(false)

      expect do
        project_with_tracker.external_issue_tracker
      end.to change { project_with_tracker.reload.has_external_issue_tracker }.from(nil).to(true)
    end

    it 'returns nil and does not query services when there is no external issue tracker' do
      project = create(:project)

      expect(project).not_to receive(:integrations)
      expect(project.external_issue_tracker).to eq(nil)
    end

    it 'retrieves external_issue_tracker querying services and cache it when there is external issue tracker' do
      project = create(:project, :with_redmine_integration)

      expect(project).to receive(:integrations).once.and_call_original
      2.times { expect(project.external_issue_tracker).to be_a_kind_of(Integrations::Redmine) }
    end
  end

  describe '#has_external_issue_tracker' do
    let_it_be(:project) { create(:project) }

    def subject
      project.reload.has_external_issue_tracker
    end

    it 'is false when external issue tracker integration is not active' do
      create(:integration, project: project, category: 'issue_tracker', active: false)

      is_expected.to eq(false)
    end

    it 'is false when other integration is active' do
      create(:integration, project: project, category: 'not_issue_tracker', active: true)

      is_expected.to eq(false)
    end

    context 'when there is an active external issue tracker integration' do
      let!(:integration) do
        create(:jira_integration, project: project, category: 'issue_tracker')
      end

      it { is_expected.to eq(true) }

      it 'becomes false when external issue tracker integration is destroyed' do
        expect do
          Integration.find(integration.id).delete
        end.to change { subject }.to(false)
      end

      it 'becomes false when external issue tracker integration becomes inactive' do
        expect do
          integration.update_column(:active, false)
        end.to change { subject }.to(false)
      end

      context 'when there are two active external issue tracker integrations' do
        let_it_be(:second_integration) do
          create(:custom_issue_tracker_integration, project: project, category: 'issue_tracker')
        end

        it 'does not become false when external issue tracker integration is destroyed' do
          expect do
            Integration.find(integration.id).delete
          end.not_to change { subject }
        end

        it 'does not become false when external issue tracker integration becomes inactive' do
          expect do
            integration.update_column(:active, false)
          end.not_to change { subject }
        end
      end
    end
  end

  describe '#external_wiki' do
    let_it_be(:project) { create(:project) }

    def subject
      project.reload.external_wiki
    end

    it 'returns an active external wiki' do
      create(:external_wiki_integration, project: project, active: true)

      is_expected.to be_kind_of(Integrations::ExternalWiki)
    end

    it 'does not return an inactive external wiki' do
      create(:external_wiki_integration, project: project, active: false)

      is_expected.to eq(nil)
    end

    it 'sets Project#has_external_wiki when it is nil' do
      create(:external_wiki_integration, project: project, active: true)
      project.update_column(:has_external_wiki, nil)

      expect { subject }.to change { project.has_external_wiki }.from(nil).to(true)
    end
  end

  describe '#has_external_wiki' do
    let_it_be(:project) { create(:project) }

    def has_external_wiki
      project.reload.has_external_wiki
    end

    specify { expect(has_external_wiki).to eq(false) }

    context 'when there is an active external wiki integration' do
      let(:active) { true }

      let!(:integration) do
        create(:external_wiki_integration, project: project, active: active)
      end

      specify { expect(has_external_wiki).to eq(true) }

      it 'becomes false if the external wiki integration is destroyed' do
        expect do
          Integration.find(integration.id).delete
        end.to change { has_external_wiki }.to(false)
      end

      it 'becomes false if the external wiki integration becomes inactive' do
        expect do
          integration.update_column(:active, false)
        end.to change { has_external_wiki }.to(false)
      end

      context 'when created as inactive' do
        let(:active) { false }

        it 'is false' do
          expect(has_external_wiki).to eq(false)
        end
      end
    end
  end

  describe '#star_count' do
    it 'counts stars from multiple users' do
      user1 = create(:user)
      user2 = create(:user)
      project = create(:project, :public)

      expect(project.star_count).to eq(0)

      user1.toggle_star(project)
      expect(project.reload.star_count).to eq(1)

      user2.toggle_star(project)
      project.reload
      expect(project.reload.star_count).to eq(2)

      user1.toggle_star(project)
      project.reload
      expect(project.reload.star_count).to eq(1)

      user2.toggle_star(project)
      project.reload
      expect(project.reload.star_count).to eq(0)
    end

    it 'does not count stars from blocked users' do
      user1 = create(:user)
      user2 = create(:user)
      project = create(:project, :public)

      expect(project.star_count).to eq(0)

      user1.toggle_star(project)
      expect(project.reload.star_count).to eq(1)

      user2.toggle_star(project)
      project.reload
      expect(project.reload.star_count).to eq(2)

      user1.block
      project.reload
      expect(project.reload.star_count).to eq(1)

      user2.block
      project.reload
      expect(project.reload.star_count).to eq(0)

      user1.activate
      project.reload
      expect(project.reload.star_count).to eq(1)
    end

    it 'counts stars on the right project' do
      user = create(:user)
      project1 = create(:project, :public)
      project2 = create(:project, :public)

      expect(project1.star_count).to eq(0)
      expect(project2.star_count).to eq(0)

      user.toggle_star(project1)
      project1.reload
      project2.reload
      expect(project1.star_count).to eq(1)
      expect(project2.star_count).to eq(0)

      user.toggle_star(project1)
      project1.reload
      project2.reload
      expect(project1.star_count).to eq(0)
      expect(project2.star_count).to eq(0)

      user.toggle_star(project2)
      project1.reload
      project2.reload
      expect(project1.star_count).to eq(0)
      expect(project2.star_count).to eq(1)

      user.toggle_star(project2)
      project1.reload
      project2.reload
      expect(project1.star_count).to eq(0)
      expect(project2.star_count).to eq(0)
    end
  end

  context 'with avatar' do
    it_behaves_like Avatarable do
      let(:model) { create(:project, :with_avatar) }
    end

    describe '#avatar_url' do
      subject { project.avatar_url }

      let(:project) { create(:project) }

      context 'when avatar file in git' do
        before do
          allow(project).to receive(:avatar_in_git) { true }
        end

        let(:avatar_path) { "/#{project.full_path}/-/avatar" }

        it { is_expected.to eq "http://#{Gitlab.config.gitlab.host}#{avatar_path}" }
      end

      context 'when git repo is empty' do
        let(:project) { create(:project) }

        it { is_expected.to eq nil }
      end
    end
  end

  describe '#builds_enabled' do
    let(:project) { create(:project) }

    subject { project.builds_enabled }

    it { expect(project.builds_enabled?).to be_truthy }
  end

  describe '.sort_by_attribute' do
    let_it_be(:project1) { create(:project, star_count: 2, last_activity_at: 1.minute.ago) }
    let_it_be(:project2) { create(:project, star_count: 1) }
    let_it_be(:project3) { create(:project, last_activity_at: 2.minutes.ago) }

    before_all do
      create(:project_statistics, project: project1, repository_size: 1)
      create(:project_statistics, project: project2, repository_size: 3)
      create(:project_statistics, project: project3, repository_size: 2)
    end

    it 'reorders the input relation by start count desc' do
      projects = described_class.sort_by_attribute(:stars_desc)

      expect(projects).to eq([project1, project2, project3])
    end

    it 'reorders the input relation by last activity desc' do
      projects = described_class.sort_by_attribute(:latest_activity_desc)

      expect(projects).to eq([project2, project1, project3])
    end

    it 'reorders the input relation by last activity asc' do
      projects = described_class.sort_by_attribute(:latest_activity_asc)

      expect(projects).to eq([project3, project1, project2])
    end

    it 'reorders the input relation by path asc' do
      projects = described_class.sort_by_attribute(:path_asc)

      expect(projects).to eq([project1, project2, project3].sort_by(&:path))
    end

    it 'reorders the input relation by path desc' do
      projects = described_class.sort_by_attribute(:path_desc)

      expect(projects).to eq([project1, project2, project3].sort_by(&:path).reverse)
    end

    it 'reorders the input relation by storage size asc' do
      projects = described_class.sort_by_attribute(:storage_size_asc)

      expect(projects).to eq([project1, project3, project2])
    end

    it 'reorders the input relation by storage size desc' do
      projects = described_class.sort_by_attribute(:storage_size_desc)

      expect(projects).to eq([project2, project3, project1])
    end
  end

  describe '.by_not_in_root_id' do
    let_it_be(:group1) { create(:group) }
    let_it_be(:group2) { create(:group) }
    let_it_be(:group1_project) { create(:project, namespace: group1) }
    let_it_be(:group2_project) { create(:project, namespace: group2) }
    let_it_be(:subgroup_project) { create(:project, namespace: create(:group, parent: group1)) }

    it 'returns correct namespaces' do
      expect(described_class.by_not_in_root_id(group1.id)).to contain_exactly(group2_project)
      expect(described_class.by_not_in_root_id(group2.id)).to contain_exactly(group1_project, subgroup_project)
    end
  end

  describe '.order_by_storage_size' do
    let_it_be(:project_1) { create(:project_statistics, repository_size: 1).project }
    let_it_be(:project_2) { create(:project_statistics, repository_size: 3).project }
    let_it_be(:project_3) { create(:project_statistics, repository_size: 2).project }

    context 'ascending' do
      it { expect(described_class.sorted_by_storage_size_asc).to eq([project_1, project_3, project_2]) }
    end

    context 'descending' do
      it { expect(described_class.sorted_by_storage_size_desc).to eq([project_2, project_3, project_1]) }
    end
  end

  describe '.sorted_by_similarity_desc' do
    let_it_be(:project_a) { create(:project, path: 'similar-1', name: 'similar-1', description: 'A similar project') }
    let_it_be_with_reload(:project_b) { create(:project, path: 'similar-2', name: 'similar-2', description: 'A related project') }
    let_it_be(:project_c) { create(:project, path: 'different-path', name: 'different-name', description: 'A different project') }

    let(:search_term) { 'similar' }

    subject(:relation) { described_class.sorted_by_similarity_desc(search_term) }

    context 'when sorting with full similarity' do
      it 'sorts projects based on path, name, and description similarity' do
        expect(relation).to eq([project_a, project_b, project_c])
      end
    end

    context 'when sorting with path-only similarity' do
      let(:search_term) { 'diff' }

      subject(:relation) { described_class.sorted_by_similarity_desc(search_term, full_path_only: true) }

      it 'sorts projects based on path similarity only' do
        expect(relation).to eq([project_c, project_b, project_a])
      end
    end
  end

  describe '.with_shared_runners_enabled' do
    subject { described_class.with_shared_runners_enabled }

    context 'when shared runners are enabled for project' do
      let!(:project) { create(:project, shared_runners_enabled: true) }

      it "returns a project" do
        is_expected.to eq([project])
      end
    end

    context 'when shared runners are disabled for project' do
      let!(:project) { create(:project, shared_runners_enabled: false) }

      it "returns an empty array" do
        is_expected.to be_empty
      end
    end
  end

  describe '.with_remote_mirrors' do
    let_it_be(:project) { create(:project, :repository) }

    subject { described_class.with_remote_mirrors }

    context 'when some remote mirrors are enabled for the project' do
      let!(:remote_mirror) { create(:remote_mirror, project: project, enabled: true) }

      it "returns a project" do
        is_expected.to eq([project])
      end
    end

    context 'when some remote mirrors exists but disabled for the project' do
      let!(:remote_mirror) { create(:remote_mirror, project: project, enabled: false) }

      it "returns a project" do
        is_expected.to be_empty
      end
    end

    context 'when no remote mirrors exist for the project' do
      it "returns an empty list" do
        is_expected.to be_empty
      end
    end
  end

  describe '.with_jira_dvcs_server' do
    it 'returns the correct project' do
      jira_dvcs_server_project = create(:project, :jira_dvcs_server)

      expect(described_class.with_jira_dvcs_server).to contain_exactly(jira_dvcs_server_project)
    end
  end

  describe '.by_name' do
    let_it_be(:project1) { create(:project, :small_repo, name: 'Project 1') }
    let_it_be(:project2) { create(:project, :small_repo, name: 'Project 2') }

    it 'includes correct projects' do
      expect(described_class.by_name(project1.name)).to eq([project1])
      expect(described_class.by_name(project2.name.chop)).to match_array([project1, project2])
    end
  end

  describe '.with_slack_application_disabled' do
    let_it_be(:project1) { create(:project) }
    let_it_be(:project2) { create(:project) }
    let_it_be(:project3) { create(:project) }

    before_all do
      create(:gitlab_slack_application_integration, project: project2)
      create(:gitlab_slack_application_integration, project: project3).update!(active: false)
    end

    context 'when the Slack app setting is enabled' do
      before do
        stub_application_setting(slack_app_enabled: true)
      end

      it 'includes only projects where Slack app is disabled or absent' do
        projects = described_class.with_slack_application_disabled

        expect(projects).to include(project1, project3)
        expect(projects).not_to include(project2)
      end
    end

    context 'when the Slack app setting is not enabled' do
      before do
        stub_application_setting(slack_app_enabled: false)
        allow(Rails.env).to receive(:test?).and_return(false)
      end

      it 'includes all projects' do
        projects = described_class.with_slack_application_disabled

        expect(projects).to include(project1, project2, project3)
      end
    end
  end

  describe '.with_slack_integration' do
    it 'returns projects with both active and inactive slack integrations' do
      create(:project)
      with_active_slack = create(:integrations_slack).project
      with_disabled_slack = create(:integrations_slack, active: false).project

      expect(described_class.with_slack_integration).to contain_exactly(
        with_active_slack,
        with_disabled_slack
      )
    end
  end

  describe '.with_slack_slash_commands_integration' do
    it 'returns projects with both active and inactive slack slash commands integrations' do
      create(:project)
      with_active_slash_commands = create(:slack_slash_commands_integration).project
      with_disabled_slash_commands = create(:slack_slash_commands_integration, active: false).project

      expect(described_class.with_slack_slash_commands_integration).to contain_exactly(
        with_active_slash_commands,
        with_disabled_slash_commands
      )
    end
  end

  describe '.cached_count', :use_clean_rails_memory_store_caching do
    let(:group)     { create(:group, :public) }
    let!(:project1) { create(:project, :public, group: group) }
    let!(:project2) { create(:project, :public, group: group) }

    it 'returns total project count' do
      expect(described_class).to receive(:count).once.and_call_original

      3.times do
        expect(described_class.cached_count).to eq(2)
      end
    end
  end

  describe '.trending' do
    let(:group)    { create(:group, :public) }
    let(:project1) { create(:project, :public, :repository, group: group) }
    let(:project2) { create(:project, :public, :repository, group: group) }

    before do
      create_list(:note_on_commit, 2, project: project1)

      create(:note_on_commit, project: project2)

      TrendingProject.refresh!
    end

    subject { described_class.trending.to_a }

    it 'sorts projects by the amount of notes in descending order' do
      expect(subject).to eq([project1, project2])
    end

    it 'does not take system notes into account' do
      create_list(:note_on_commit, 10, project: project2, system: true)

      expect(described_class.trending.to_a).to eq([project1, project2])
    end
  end

  describe '.starred_by' do
    it 'returns only projects starred by the given user' do
      user1 = create(:user)
      user2 = create(:user)
      project1 = create(:project)
      project2 = create(:project)
      create(:project)
      user1.toggle_star(project1)
      user2.toggle_star(project2)

      expect(described_class.starred_by(user1)).to contain_exactly(project1)
    end
  end

  describe '.with_limit' do
    it 'limits the number of projects returned' do
      create_list(:project, 3)

      expect(described_class.with_limit(1).count).to eq(1)
    end
  end

  describe '.visible_to_user' do
    let!(:project) { create(:project, :private) }
    let!(:user)    { create(:user) }

    subject { described_class.visible_to_user(user) }

    describe 'when a user has access to a project' do
      before do
        project.add_member(user, Gitlab::Access::MAINTAINER)
      end

      it { is_expected.to eq([project]) }
    end

    describe 'when a user does not have access to any projects' do
      it { is_expected.to eq([]) }
    end
  end

  describe '.with_integration' do
    it 'returns the correct projects' do
      active_confluence_integration = create(:confluence_integration)
      inactive_confluence_integration = create(:confluence_integration, active: false)
      create(:bugzilla_integration)

      expect(described_class.with_integration(::Integrations::Confluence)).to contain_exactly(
        active_confluence_integration.project,
        inactive_confluence_integration.project
      )
    end
  end

  describe '.with_active_integration' do
    it 'returns the correct projects' do
      active_confluence_integration = create(:confluence_integration)
      create(:confluence_integration, active: false)
      create(:bugzilla_integration, active: true)

      expect(described_class.with_active_integration(::Integrations::Confluence)).to contain_exactly(
        active_confluence_integration.project
      )
    end
  end

  describe '.include_integration' do
    it 'avoids n + 1', :aggregate_failures do
      create(:prometheus_integration)
      run_test = -> { described_class.include_integration(:prometheus_integration).map(&:prometheus_integration) }
      control = ActiveRecord::QueryRecorder.new { run_test.call }
      create(:prometheus_integration)

      expect(run_test.call.count).to eq(2)
      expect { run_test.call }.not_to exceed_query_limit(control)
    end
  end

  describe '.service_desk_enabled' do
    it 'returns the correct project' do
      project_with_service_desk_enabled = create(:project)
      project_with_service_desk_disabled = create(:project, :service_desk_disabled)

      expect(described_class.service_desk_enabled).to include(project_with_service_desk_enabled)
      expect(described_class.service_desk_enabled).not_to include(project_with_service_desk_disabled)
    end
  end

  describe '.with_service_desk_key' do
    it 'returns projects with given key' do
      project1 = create(:project)
      project2 = create(:project)
      create(:service_desk_setting, project: project1, project_key: 'key1')
      create(:service_desk_setting, project: project2, project_key: 'key1')
      create(:service_desk_setting, project_key: 'key2')
      create(:service_desk_setting)

      expect(described_class.with_service_desk_key('key1')).to contain_exactly(project1, project2)
    end

    it 'returns empty if there is no project with the key' do
      expect(described_class.with_service_desk_key('key1')).to be_empty
    end
  end

  describe '.find_by_url' do
    subject { described_class.find_by_url(url) }

    let_it_be(:project) { create(:project) }

    before do
      stub_config_setting(host: 'gitlab.com')
    end

    context 'url is internal' do
      let(:url) { "https://#{Gitlab.config.gitlab.host}/#{path}" }

      context 'path is recognised as a project path' do
        let(:path) { project.full_path }

        it { is_expected.to eq(project) }

        it 'returns nil if the path detection throws an error' do
          expect(Rails.application.routes).to receive(:recognize_path).with(url) { raise ActionController::RoutingError, 'test' }

          expect { subject }.not_to raise_error
          expect(subject).to be_nil
        end
      end

      context 'path is not a project path' do
        let(:path) { 'probably/missing.git' }

        it { is_expected.to be_nil }
      end
    end

    context 'url is external' do
      let(:url) { "https://foo.com/bar/baz.git" }

      it { is_expected.to be_nil }
    end
  end

  describe '.without_integration' do
    it 'returns projects without the integration' do
      project_1, project_2, project_3, project_4 = create_list(:project, 4)
      instance_integration = create(:jira_integration, :instance)
      create(:jira_integration, project: project_1, inherit_from_id: instance_integration.id)
      create(:jira_integration, project: project_2, inherit_from_id: nil)
      create(:jira_integration, group: create(:group), project: nil, inherit_from_id: nil)
      create(:jira_integration, project: project_3, inherit_from_id: nil)
      create(:integrations_slack, project: project_4, inherit_from_id: nil)

      expect(described_class.without_integration(instance_integration)).to contain_exactly(project_4)
    end
  end

  context 'repository storage by default' do
    let(:project) { build(:project) }

    it 'picks storage from ApplicationSetting' do
      expect(Repository).to receive(:pick_storage_shard).and_return('picked')

      expect(project.repository_storage).to eq('picked')
    end
  end

  context 'shared runners by default' do
    let(:project) { create(:project) }

    subject { project.shared_runners_enabled }

    context 'are enabled' do
      before do
        stub_application_setting(shared_runners_enabled: true)
      end

      it { is_expected.to be_truthy }
    end

    context 'are disabled' do
      before do
        stub_application_setting(shared_runners_enabled: false)
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#any_online_runners?', :freeze_time do
    subject { project.any_online_runners? }

    context 'shared runners' do
      let(:project) { create(:project, shared_runners_enabled: shared_runners_enabled) }
      let(:project_runner) { create(:ci_runner, :project, :online, projects: [project]) }
      let(:shared_runner) { create(:ci_runner, :instance, :online) }
      let(:offline_runner) { create(:ci_runner, :instance) }

      context 'for shared runners disabled' do
        let(:shared_runners_enabled) { false }

        it 'has no runners available' do
          is_expected.to be_falsey
        end

        it 'has a project runner' do
          project_runner

          is_expected.to be_truthy
        end

        it 'has a shared runner, but they are prohibited to use' do
          shared_runner

          is_expected.to be_falsey
        end

        it 'checks the presence of project runner' do
          project_runner

          expect(project.any_online_runners? { |runner| runner == project_runner }).to be_truthy
        end

        it 'returns false if match cannot be found' do
          project_runner

          expect(project.any_online_runners? { false }).to be_falsey
        end

        it 'returns false if runner is offline' do
          offline_runner

          is_expected.to be_falsey
        end
      end

      context 'for shared runners enabled' do
        let(:shared_runners_enabled) { true }

        it 'has a shared runner' do
          shared_runner

          is_expected.to be_truthy
        end

        it 'checks the presence of shared runner' do
          shared_runner

          expect(project.any_online_runners? { |runner| runner == shared_runner }).to be_truthy
        end

        it 'returns false if match cannot be found' do
          shared_runner

          expect(project.any_online_runners? { false }).to be_falsey
        end
      end
    end

    context 'group runners' do
      let(:project) { create(:project, group_runners_enabled: group_runners_enabled) }
      let(:group) { create(:group, projects: [project]) }
      let(:group_runner) { create(:ci_runner, :group, :online, groups: [group]) }
      let(:offline_runner) { create(:ci_runner, :group, groups: [group]) }

      context 'for group runners disabled' do
        let(:group_runners_enabled) { false }

        it 'has no runners available' do
          is_expected.to be_falsey
        end

        it 'has a group runner, but they are prohibited to use' do
          group_runner

          is_expected.to be_falsey
        end
      end

      context 'for group runners enabled' do
        let(:group_runners_enabled) { true }

        it 'has a group runner' do
          group_runner

          is_expected.to be_truthy
        end

        it 'has an offline group runner' do
          offline_runner

          is_expected.to be_falsey
        end

        it 'checks the presence of group runner' do
          group_runner

          expect(project.any_online_runners? { |runner| runner == group_runner }).to be_truthy
        end

        it 'returns false if match cannot be found' do
          group_runner

          expect(project.any_online_runners? { false }).to be_falsey
        end
      end
    end
  end

  shared_examples 'shared_runners' do
    let_it_be(:runner) { create(:ci_runner, :instance) }

    subject { project.shared_runners }

    context 'when shared runners are enabled for project' do
      let(:project) { build_stubbed(:project, shared_runners_enabled: true) }

      it "returns a list of shared runners" do
        is_expected.to eq([runner])
      end
    end

    context 'when shared runners are disabled for project' do
      let(:project) { build_stubbed(:project, shared_runners_enabled: false) }

      it "returns a empty list" do
        is_expected.to be_empty
      end
    end
  end

  describe '#shared_runners' do
    it_behaves_like 'shared_runners'
  end

  describe '#available_shared_runners' do
    it_behaves_like 'shared_runners' do
      subject { project.available_shared_runners }
    end
  end

  describe '#visibility_level' do
    let(:project) { build(:project) }

    subject { project.visibility_level }

    context 'by default' do
      it { is_expected.to eq(Gitlab::VisibilityLevel::PRIVATE) }
    end

    context 'when set to INTERNAL in application settings' do
      before do
        stub_application_setting(default_project_visibility: Gitlab::VisibilityLevel::INTERNAL)
      end

      it { is_expected.to eq(Gitlab::VisibilityLevel::INTERNAL) }

      where(:attribute_name, :value) do
        :visibility | 'public'
        :visibility_level | Gitlab::VisibilityLevel::PUBLIC
        'visibility' | 'public'
        'visibility_level' | Gitlab::VisibilityLevel::PUBLIC
      end

      with_them do
        it 'sets the visibility level' do
          proj = described_class.new(attribute_name => value, name: 'test', path: 'test')

          expect(proj.visibility_level).to eq(Gitlab::VisibilityLevel::PUBLIC)
        end
      end
    end
  end

  describe '#visibility_level_allowed?' do
    let_it_be(:project) { create(:project, :internal) }

    context 'when checking on non-forked project' do
      it { expect(project.visibility_level_allowed?(Gitlab::VisibilityLevel::PRIVATE)).to be_truthy }
      it { expect(project.visibility_level_allowed?(Gitlab::VisibilityLevel::INTERNAL)).to be_truthy }
      it { expect(project.visibility_level_allowed?(Gitlab::VisibilityLevel::PUBLIC)).to be_truthy }
    end

    context 'when checking on forked project' do
      let(:forked_project) { fork_project(project) }

      it { expect(forked_project.visibility_level_allowed?(Gitlab::VisibilityLevel::PRIVATE)).to be_truthy }
      it { expect(forked_project.visibility_level_allowed?(Gitlab::VisibilityLevel::INTERNAL)).to be_truthy }
      it { expect(forked_project.visibility_level_allowed?(Gitlab::VisibilityLevel::PUBLIC)).to be_falsey }
    end
  end

  describe '#pages_show_onboarding?' do
    let(:project) { create(:project) }

    subject { project.pages_show_onboarding? }

    context "if there is no metadata" do
      it { is_expected.to be_truthy }
    end

    context 'if onboarding is complete' do
      before do
        project.pages_metadatum.update_column(:onboarding_complete, true)
      end

      it { is_expected.to be_falsey }
    end

    context 'if there is metadata, but onboarding is not complete' do
      before do
        project.pages_metadatum.update_column(:onboarding_complete, false)
      end

      it { is_expected.to be_truthy }
    end

    # During migration, the onboarding_complete property can still be false,
    # but will be updated later. To account for that case, pages_show_onboarding?
    # should return false if `deployed` is true.
    context "will return false if pages is deployed even if onboarding_complete is false" do
      before do
        project.pages_metadatum.update_column(:onboarding_complete, false)
        create(:pages_deployment, project: project)
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#pages_deployed?' do
    let(:project) { create(:project) }

    subject { project.pages_deployed? }

    context 'if pages are deployed' do
      before do
        create(:pages_deployment, project: project)
      end

      it { is_expected.to be_truthy }
    end

    context "if public folder doesn't exist" do
      it { is_expected.to be_falsey }
    end
  end

  describe '#pages_unique_domain_enabled?' do
    let(:project) { create(:project) }

    subject { project.pages_unique_domain_enabled? }

    context 'if unique domain is enabled' do
      before do
        project.project_setting.update!(pages_unique_domain_enabled: true, pages_unique_domain: 'foo123.example.com')
      end

      it { is_expected.to be(true) }
    end

    context 'if unique domain is disabled' do
      before do
        project.project_setting.update!(pages_unique_domain_enabled: false)
      end

      it { is_expected.to be(false) }
    end
  end

  describe '#default_branch_protected?' do
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:project) { create(:project, namespace: namespace) }

    subject { project.default_branch_protected? }

    where(:default_branch_protection_level, :result) do
      Gitlab::Access::BranchProtection.protection_none                    | false
      Gitlab::Access::BranchProtection.protection_partial                 | false
      Gitlab::Access::BranchProtection.protected_against_developer_pushes | true
      Gitlab::Access::BranchProtection.protected_fully                    | true
      Gitlab::Access::BranchProtection.protected_after_initial_push       | true
    end

    with_them do
      before do
        expect(project.namespace)
          .to receive(:default_branch_protection_settings)
                .and_return(default_branch_protection_level)
      end

      it { is_expected.to eq(result) }
    end
  end

  describe 'initial_push_to_default_branch_allowed_for_developer?' do
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:project) { create(:project, namespace: namespace) }

    subject { project.initial_push_to_default_branch_allowed_for_developer? }

    where(:default_branch_protection_level, :result) do
      Gitlab::Access::BranchProtection.protection_none                    | true
      Gitlab::Access::BranchProtection.protection_partial                 | true
      Gitlab::Access::BranchProtection.protected_against_developer_pushes | false
      Gitlab::Access::BranchProtection.protected_fully                    | false
      Gitlab::Access::BranchProtection.protected_after_initial_push       | true
    end

    with_them do
      before do
        expect(project.namespace)
          .to receive(:default_branch_protection_settings)
                .and_return(default_branch_protection_level)
      end

      it { is_expected.to eq(result) }
    end
  end

  describe '.search' do
    let_it_be(:project) { create(:project, description: 'kitten mittens') }

    it 'returns projects with a matching name' do
      expect(described_class.search(project.name)).to eq([project])
    end

    it 'returns projects with a partially matching name' do
      expect(described_class.search(project.name[0..2])).to eq([project])
    end

    it 'returns projects with a matching name regardless of the casing' do
      expect(described_class.search(project.name.upcase)).to eq([project])
    end

    it 'returns projects with a matching description' do
      expect(described_class.search(project.description)).to eq([project])
    end

    it 'returns projects with a partially matching description' do
      expect(described_class.search('kitten')).to eq([project])
    end

    it 'returns projects with a matching description regardless of the casing' do
      expect(described_class.search('KITTEN')).to eq([project])
    end

    it 'returns projects with a matching path' do
      expect(described_class.search(project.path)).to eq([project])
    end

    it 'returns projects with a partially matching path' do
      expect(described_class.search(project.path[0..2])).to eq([project])
    end

    it 'returns projects with a matching path regardless of the casing' do
      expect(described_class.search(project.path.upcase)).to eq([project])
    end

    it 'defaults use_minimum_char_limit to true' do
      expect(described_class).to receive(:fuzzy_search).with(anything, anything, use_minimum_char_limit: true).once

      described_class.search('kitten')
    end

    it 'passes use_minimum_char_limit if it is set' do
      expect(described_class).to receive(:fuzzy_search).with(anything, anything, use_minimum_char_limit: false).once

      described_class.search('kitten', use_minimum_char_limit: false)
    end

    context 'when include_namespace is true' do
      let_it_be(:group) { create(:group) }
      let_it_be(:project) { create(:project, group: group) }

      it 'returns projects that match the group path' do
        expect(described_class.search(group.path, include_namespace: true)).to eq([project])
      end

      it 'returns projects that match the full path' do
        expect(described_class.search(project.full_path, include_namespace: true)).to eq([project])
      end
    end

    describe 'with pending_delete project' do
      let(:pending_delete_project) { create(:project, pending_delete: true) }

      it 'shows pending deletion project' do
        search_result = described_class.search(pending_delete_project.name)

        expect(search_result).to eq([pending_delete_project])
      end
    end
  end

  describe '.optionally_search' do
    let_it_be(:project) { create(:project) }

    it 'searches for projects matching the query if one is given' do
      relation = described_class.optionally_search(project.name)

      expect(relation).to eq([project])
    end

    it 'returns the current relation if no search query is given' do
      relation = described_class.where(id: project.id)

      expect(relation.optionally_search).to eq(relation)
    end
  end

  describe '.eager_load_namespace_and_owner' do
    it 'eager loads the namespace and namespace owner' do
      create(:project)

      row = described_class.eager_load_namespace_and_owner.first
      recorder = ActiveRecord::QueryRecorder.new { row.namespace.owner }

      expect(recorder.count).to be_zero
    end
  end

  describe '#expire_caches_before_rename' do
    let(:project) { create(:project, :repository) }
    let(:repo)    { double(:repo, exists?: true) }
    let(:wiki)    { double(:wiki, exists?: true) }
    let(:design)  { double(:design, exists?: true) }

    it 'expires the caches of the repository and wiki' do
      # In EE, there are design repositories as well
      allow(Repository).to receive(:new).and_call_original

      allow(Repository).to receive(:new)
        .with('foo', project, shard: project.repository_storage)
        .and_return(repo)

      allow(Repository).to receive(:new)
        .with('foo.wiki', project, shard: project.repository_storage, repo_type: Gitlab::GlRepository::WIKI)
        .and_return(wiki)

      allow(Repository).to receive(:new)
        .with('foo.design', project, shard: project.repository_storage, repo_type: Gitlab::GlRepository::DESIGN)
        .and_return(design)

      expect(repo).to receive(:before_delete)
      expect(wiki).to receive(:before_delete)
      expect(design).to receive(:before_delete)

      project.expire_caches_before_rename('foo')
    end
  end

  describe '.search_by_title' do
    let_it_be(:project) { create(:project, name: 'kittens') }

    it 'returns projects with a matching name' do
      expect(described_class.search_by_title(project.name)).to eq([project])
    end

    it 'returns projects with a partially matching name' do
      expect(described_class.search_by_title('kitten')).to eq([project])
    end

    it 'returns projects with a matching name regardless of the casing' do
      expect(described_class.search_by_title('KITTENS')).to eq([project])
    end
  end

  context 'when checking projects from groups' do
    let(:private_group)    { build(:group, visibility_level: 0)  }
    let(:internal_group)   { build(:group, visibility_level: 10) }

    let(:private_project)  { build(:project, :private, group: private_group) }
    let(:internal_project) { build(:project, :internal, group: internal_group) }

    context 'when group is private project can not be internal' do
      it { expect(private_project.visibility_level_allowed?(Gitlab::VisibilityLevel::INTERNAL)).to be_falsey }
    end

    context 'when group is internal project can not be public' do
      it { expect(internal_project.visibility_level_allowed?(Gitlab::VisibilityLevel::PUBLIC)).to be_falsey }
    end
  end

  describe '#track_project_repository' do
    shared_examples 'tracks storage location' do
      context 'when a project repository entry does not exist' do
        it 'creates a new entry' do
          expect { project.track_project_repository }.to change(project, :project_repository)
        end

        it 'tracks the project storage location' do
          project.track_project_repository

          expect(project.project_repository).to have_attributes(
            disk_path: project.disk_path,
            shard_name: project.repository_storage,
            object_format: 'sha1'
          )
        end

        context 'when repository is missing' do
          let(:project) { create(:project) }

          it 'sets a default sha1 object format' do
            project.track_project_repository

            expect(project.project_repository).to have_attributes(
              disk_path: project.disk_path,
              shard_name: project.repository_storage,
              object_format: 'sha1'
            )
          end
        end

        context 'when repository has sha256 object format' do
          let(:project) { create(:project, :empty_repo, object_format: 'sha256') }

          it 'tracks a correct object format' do
            project.track_project_repository

            expect(project.project_repository).to have_attributes(
              disk_path: project.disk_path,
              shard_name: project.repository_storage,
              object_format: 'sha256'
            )
          end
        end
      end

      context 'when a tracking entry exists' do
        let!(:project_repository) { create(:project_repository, project: project) }
        let!(:shard) { create(:shard, name: 'foo') }

        it 'does not create a new entry in the database' do
          expect { project.track_project_repository }.not_to change(project, :project_repository)
        end

        it 'updates the project storage location' do
          allow(project).to receive(:disk_path).and_return('fancy/new/path')
          allow(project).to receive(:repository_storage).and_return('foo')
          allow(project.repository).to receive(:object_format).and_return('sha1')

          project.track_project_repository

          expect(project.project_repository).to have_attributes(
            disk_path: 'fancy/new/path',
            shard_name: 'foo',
            object_format: 'sha1'
          )
        end

        it 'refreshes a memoized repository value' do
          previous_repository = project.repository

          allow(project).to receive(:disk_path).and_return('fancy/new/path')
          allow(project).to receive(:repository_storage).and_return('foo')
          allow(project.repository).to receive(:object_format).and_return('sha1')

          project.track_project_repository

          expect(project.repository).not_to eq(previous_repository)
        end
      end
    end

    context 'with projects on legacy storage' do
      let_it_be_with_reload(:project) { create(:project, :empty_repo, :legacy_storage) }

      it_behaves_like 'tracks storage location'
    end

    context 'with projects on hashed storage' do
      let_it_be_with_reload(:project) { create(:project, :empty_repo) }

      it_behaves_like 'tracks storage location'
    end
  end

  describe '#create_repository' do
    let_it_be(:project) { build(:project, :repository) }

    context 'using a regular repository' do
      it 'creates the repository' do
        expect(project.repository).to receive(:create_repository)
        expect(project.create_repository).to eq(true)
      end

      it 'adds an error if the repository could not be created' do
        expect(project.repository).to receive(:create_repository) { raise 'Fail in test' }
        expect(project.create_repository).to eq(false)
        expect(project.errors).not_to be_empty
      end

      it 'passes through default branch' do
        expect(project.repository).to receive(:create_repository).with('pineapple', object_format: nil)

        expect(project.create_repository(default_branch: 'pineapple')).to eq(true)
      end
    end

    context 'using a forked repository' do
      it 'does nothing' do
        expect(project).to receive(:forked?).and_return(true)
        expect(project.repository).not_to receive(:create_repository)

        project.create_repository
      end
    end

    context 'using a SHA256 repository' do
      it 'creates the repository' do
        expect(project.repository).to receive(:create_repository).with(nil, object_format: Repository::FORMAT_SHA256)
        expect(project.create_repository(object_format: Repository::FORMAT_SHA256)).to eq(true)
      end
    end
  end

  describe '#ensure_repository' do
    let_it_be(:project) { build(:project, :repository) }

    it 'creates the repository if it not exist' do
      allow(project).to receive(:repository_exists?).and_return(false)
      expect(project).to receive(:create_repository).with(force: true)

      project.ensure_repository
    end

    it 'does not create the repository if it exists' do
      allow(project).to receive(:repository_exists?).and_return(true)

      expect(project).not_to receive(:create_repository)

      project.ensure_repository
    end

    it 'creates the repository if it is a fork' do
      expect(project).to receive(:forked?).and_return(true)
      expect(project).to receive(:repository_exists?).and_return(false)
      expect(project.repository).to receive(:create_repository) { true }

      project.ensure_repository
    end
  end

  describe 'handling import URL' do
    it 'returns the sanitized URL' do
      project = create(:project, :import_started, import_url: 'http://user:pass@test.com')

      project.import_state.finish

      expect(project.reload.import_url).to eq('http://test.com')
    end

    it 'saves the url credentials percent decoded' do
      url = 'http://user:pass%21%3F%40@github.com/t.git'
      project = build(:project, import_url: url)

      # When the credentials are not decoded this expectation fails
      expect(project.import_url).to eq(url)
      expect(project.import_data.credentials).to eq(user: 'user', password: 'pass!?@')
    end

    it 'saves url with no credentials' do
      url = 'http://github.com/t.git'
      project = build(:project, import_url: url)

      expect(project.import_url).to eq(url)
      expect(project.import_data.credentials).to eq(user: nil, password: nil)
    end
  end

  describe '#container_registry_url' do
    let_it_be(:project) { build(:project) }

    subject { project.container_registry_url }

    before do
      stub_container_registry_config(**registry_settings)
    end

    context 'for enabled registry' do
      let(:registry_settings) do
        { enabled: true,
          host_port: 'example.com' }
      end

      it { is_expected.not_to be_nil }
    end

    context 'for disabled registry' do
      let(:registry_settings) do
        { enabled: false }
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#container_repositories_size' do
    let(:project) { build(:project) }

    subject { project.container_repositories_size }

    context 'when there are no container repositories' do
      before do
        allow(project.container_repositories).to receive(:empty?).and_return(true)
      end

      it { is_expected.to eq(0) }
    end

    context 'when there are container repositories' do
      include_context 'container registry client stubs'

      before do
        allow(project.container_repositories).to receive(:empty?).and_return(false)
      end

      context 'when the GitLab API is supported' do
        before do
          stub_gitlab_api_client_to_support_gitlab_api(supported: true)
        end

        context 'when the Gitlab API client returns a value for deduplicated_size' do
          before do
            allow(ContainerRegistry::GitlabApiClient).to receive(:deduplicated_size).with(project.full_path).and_return(123)
          end

          it { is_expected.to eq(123) }
        end

        context 'when the Gitlab API client returns nil for deduplicated_size' do
          before do
            allow(ContainerRegistry::GitlabApiClient).to receive(:deduplicated_size).with(project.full_path).and_return(nil)
          end

          it { is_expected.to be_nil }
        end
      end

      context 'when the GitLab API is not supported' do
        before do
          stub_gitlab_api_client_to_support_gitlab_api(supported: false)
        end

        it { is_expected.to be_nil }
      end
    end
  end

  describe '#container_registry_enabled=' do
    let_it_be_with_reload(:project) { create(:project) }

    it 'updates project_feature', :aggregate_failures do
      project.update!(container_registry_enabled: false)

      expect(project.project_feature.container_registry_access_level).to eq(ProjectFeature::DISABLED)

      project.update!(container_registry_enabled: true)

      expect(project.project_feature.container_registry_access_level).to eq(ProjectFeature::ENABLED)
    end
  end

  describe '#container_registry_enabled' do
    let_it_be_with_reload(:project) { create(:project) }

    it 'delegates to project_feature', :aggregate_failures do
      project.project_feature.update_column(:container_registry_access_level, ProjectFeature::DISABLED)

      expect(project.container_registry_enabled).to eq(false)
      expect(project.container_registry_enabled?).to eq(false)
    end
  end

  describe '#has_container_registry_tags?' do
    let(:project) { build(:project) }

    context 'when container registry is enabled' do
      before do
        stub_container_registry_config(enabled: true)
      end

      context 'when tags are present for multi-level registries' do
        before do
          create(:container_repository, project: project, name: 'image')

          stub_container_registry_tags(repository: /image/, tags: %w[latest rc1])
        end

        it 'has image tags' do
          expect(project).to have_container_registry_tags
        end
      end

      context 'when tags are present for root repository' do
        before do
          stub_container_registry_tags(repository: project.full_path, tags: %w[latest rc1 pre1])
        end

        it 'has image tags' do
          expect(project).to have_container_registry_tags
        end
      end

      context 'when there are no tags at all' do
        before do
          stub_container_registry_tags(repository: :any, tags: [])
        end

        it 'does not have image tags' do
          expect(project).not_to have_container_registry_tags
        end
      end
    end

    context 'when container registry is disabled' do
      before do
        stub_container_registry_config(enabled: false)
      end

      it 'does not have image tags' do
        expect(project).not_to have_container_registry_tags
      end

      it 'does not check root repository tags' do
        expect(project).not_to receive(:full_path)
        expect(project).not_to have_container_registry_tags
      end

      it 'iterates through container repositories' do
        expect(project).to receive(:container_repositories)
        expect(project).not_to have_container_registry_tags
      end
    end
  end

  describe '#ci_config_path=' do
    let(:project) { build_stubbed(:project) }

    where(:default_ci_config_path, :project_ci_config_path, :expected_ci_config_path) do
      nil           | :notset            | :default
      nil           | nil                | :default
      nil           | ''                 | :default
      nil           | "cust\0om/\0/path" | 'custom//path'
      ''            | :notset            | :default
      ''            | nil                | :default
      ''            | ''                 | :default
      ''            | "cust\0om/\0/path" | 'custom//path'
      'global/path' | :notset            | 'global/path'
      'global/path' | nil                | :default
      'global/path' | ''                 | :default
      'global/path' | "cust\0om/\0/path" | 'custom//path'
    end

    with_them do
      before do
        stub_application_setting(default_ci_config_path: default_ci_config_path)

        if project_ci_config_path != :notset
          project.ci_config_path = project_ci_config_path
        end
      end

      it 'returns the correct path' do
        expect(project.ci_config_path.presence || :default).to eq(expected_ci_config_path)
      end
    end
  end

  describe '#latest_successful_build_for_ref' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:pipeline) { create_pipeline(project) }

    it_behaves_like 'latest successful build for sha or ref'

    subject { project.latest_successful_build_for_ref(build_name) }

    context 'with a specified ref' do
      let(:build) { create_build }

      subject { project.latest_successful_build_for_ref(build.name, project.default_branch) }

      it { is_expected.to eq(build) }
    end
  end

  describe '#latest_pipeline' do
    let_it_be(:project) { create(:project, :repository) }

    let(:second_branch) { project.repository.branches[2] }

    let!(:pipeline_for_default_branch) do
      create(:ci_pipeline, project: project, sha: project.commit.id, ref: project.default_branch)
    end

    let!(:pipeline_for_second_branch) do
      create(:ci_pipeline, project: project, sha: second_branch.target, ref: second_branch.name)
    end

    let!(:other_pipeline_for_default_branch) do
      create(:ci_pipeline, project: project, sha: project.commit.parent.id, ref: project.default_branch)
    end

    context 'default repository branch' do
      context 'when explicitly provided' do
        subject { project.latest_pipeline(project.default_branch) }

        it { is_expected.to eq(pipeline_for_default_branch) }
      end

      context 'when not provided' do
        subject { project.latest_pipeline }

        it { is_expected.to eq(pipeline_for_default_branch) }
      end

      context 'with provided sha' do
        subject { project.latest_pipeline(project.default_branch, project.commit.parent.id) }

        it { is_expected.to eq(other_pipeline_for_default_branch) }
      end
    end

    context 'provided ref' do
      subject { project.latest_pipeline(second_branch.name) }

      it { is_expected.to eq(pipeline_for_second_branch) }

      context 'with provided sha' do
        let!(:latest_pipeline_for_ref) do
          create(
            :ci_pipeline,
            project: project,
            sha: pipeline_for_second_branch.sha,
            ref: pipeline_for_second_branch.ref
          )
        end

        subject { project.latest_pipeline(second_branch.name, second_branch.target) }

        it { is_expected.to eq(latest_pipeline_for_ref) }
      end
    end

    context 'bad ref' do
      before do
        # ensure we don't skip the filter by ref by mistakenly return this pipeline
        create(:ci_pipeline, project: project)
      end

      subject { project.latest_pipeline(SecureRandom.uuid) }

      it { is_expected.to be_nil }
    end

    context 'on deleted ref' do
      let(:branch) { project.repository.branches.last }

      let!(:pipeline_on_deleted_ref) do
        create(:ci_pipeline, project: project, sha: branch.target, ref: branch.name)
      end

      before do
        project.repository.rm_branch(project.first_owner, branch.name)
      end

      subject { project.latest_pipeline(branch.name) }

      it 'always returns nil despite a pipeline exists' do
        expect(subject).to be_nil
      end
    end
  end

  describe '#latest_successful_build_for_sha' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:pipeline) { create_pipeline(project) }

    it_behaves_like 'latest successful build for sha or ref'

    subject { project.latest_successful_build_for_sha(build_name, project.commit.sha) }
  end

  describe '#latest_successful_build_for_ref!' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:pipeline) { create_pipeline(project) }

    context 'with many builds' do
      it 'gives the latest builds from latest pipeline' do
        pipeline1 = create_pipeline(project)
        pipeline2 = create_pipeline(project)
        create_build(pipeline1, 'test')
        create_build(pipeline1, 'test2')
        build1_p2 = create_build(pipeline2, 'test')
        create_build(pipeline2, 'test2')

        expect(project.latest_successful_build_for_ref!(build1_p2.name))
          .to eq(build1_p2)
      end
    end

    context 'with succeeded pipeline' do
      let!(:build) { create_build }

      context 'standalone pipeline' do
        it 'returns builds for ref for default_branch' do
          expect(project.latest_successful_build_for_ref!(build.name))
            .to eq(build)
        end

        it 'returns exception if the build cannot be found' do
          expect { project.latest_successful_build_for_ref!(build.name, 'TAIL') }
            .to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'with some pending pipeline' do
        before do
          create_build(create_pipeline(project, 'pending'))
        end

        it 'gives the latest build from latest pipeline' do
          expect(project.latest_successful_build_for_ref!(build.name))
            .to eq(build)
        end
      end
    end

    context 'with pending pipeline' do
      it 'returns empty relation' do
        pipeline.update!(status: 'pending')
        pending_build = create_build(pipeline)

        expect { project.latest_successful_build_for_ref!(pending_build.name) }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '#import_status' do
    context 'with import_state' do
      it 'returns the right status' do
        project = create(:project, :import_started)

        expect(project.import_status).to eq("started")
      end
    end

    context 'without import_state' do
      it 'returns none' do
        project = create(:project)

        expect(project.import_status).to eq('none')
      end
    end
  end

  describe '#import_checksums' do
    context 'with import_checksums' do
      it 'returns the right checksums' do
        project = create(:project)
        create(:import_state, project: project, checksums: {
          'fetched' => {},
          'imported' => {}
        })

        expect(project.import_checksums).to eq(
          'fetched' => {},
          'imported' => {}
        )
      end
    end

    context 'without import_state' do
      it 'returns empty hash' do
        project = create(:project)

        expect(project.import_checksums).to eq({})
      end
    end
  end

  describe '#jira_import_status' do
    let_it_be(:project) { create(:project, import_type: 'jira') }

    context 'when no jira imports' do
      it 'returns none' do
        expect(project.jira_import_status).to eq('initial')
      end
    end

    context 'when there are jira imports' do
      let(:jira_import1) { build(:jira_import_state, :finished, project: project) }
      let(:jira_import2) { build(:jira_import_state, project: project) }

      before do
        expect(project).to receive(:latest_jira_import).and_return(jira_import2)
      end

      context 'when latest import status is initial or jira imports are mising' do
        it 'returns initial' do
          expect(project.jira_import_status).to eq('initial')
        end
      end

      context 'when latest import status is scheduled' do
        before do
          jira_import2.schedule!
        end

        it 'returns scheduled' do
          expect(project.jira_import_status).to eq('scheduled')
        end
      end
    end
  end

  describe '#human_import_status_name' do
    context 'with import_state' do
      it 'returns the right human import status' do
        project = create(:project, :import_started)

        expect(project.human_import_status_name).to eq(_('started'))
      end
    end

    context 'without import_state' do
      it 'returns none' do
        project = create(:project)

        expect(project.human_import_status_name).to eq('none')
      end
    end
  end

  describe '#beautified_import_status_name' do
    context 'when import not finished' do
      it 'returns the right beautified import status' do
        project = create(:project, :import_started)

        expect(project.beautified_import_status_name).to eq('started')
      end
    end

    context 'when import is finished' do
      context 'when import is partially completed' do
        it 'returns partially completed' do
          project = create(:project)

          create(:import_state, project: project, status: 'finished', checksums: {
            'fetched' => { 'labels' => 10 },
            'imported' => { 'labels' => 9 }
          })

          expect(project.beautified_import_status_name).to eq('partially completed')
        end
      end

      context 'when import is fully completed' do
        it 'returns completed' do
          project = create(:project)

          create(:import_state, project: project, status: 'finished', checksums: {
            'fetched' => { 'labels' => 10 },
            'imported' => { 'labels' => 10 }
          })

          expect(project.beautified_import_status_name).to eq('completed')
        end
      end
    end
  end

  describe '#add_import_job' do
    let(:import_jid) { '123' }

    context 'forked' do
      let(:forked_from_project) { create(:project, :repository) }
      let(:project) { create(:project) }

      before do
        fork_project(forked_from_project, nil, target_project: project)
      end

      it 'schedules a RepositoryForkWorker job' do
        expect(RepositoryForkWorker).to receive(:perform_async).with(project.id).and_return(import_jid)

        expect(project.add_import_job).to eq(import_jid)
      end

      context 'without repository' do
        it 'schedules RepositoryImportWorker' do
          project = create(:project, import_url: generate(:url))

          expect(RepositoryImportWorker).to receive(:perform_async).with(project.id).and_return(import_jid)
          expect(project.add_import_job).to eq(import_jid)
        end
      end
    end

    context 'not forked' do
      it 'schedules a RepositoryImportWorker job' do
        project = create(:project, import_url: generate(:url))

        expect(RepositoryImportWorker).to receive(:perform_async).with(project.id).and_return(import_jid)
        expect(project.add_import_job).to eq(import_jid)
      end
    end

    context 'jira import' do
      it 'schedules a jira import job' do
        project = create(:project, import_type: 'jira')
        jira_import = create(:jira_import_state, project: project)

        expect(Gitlab::JiraImport::Stage::StartImportWorker).to receive(:perform_async).with(project.id).and_return(import_jid)

        jira_import.schedule!

        expect(jira_import.jid).to eq(import_jid)
      end
    end
  end

  describe '#notify_project_import_complete?' do
    let(:import_type) { 'gitlab_project' }
    let(:project) { build(:project, import_type: import_type) }

    before do
      allow(project).to receive(:forked?).and_return(false)
    end

    it 'returns false for forked projects' do
      allow(project).to receive(:forked?).and_return(true)

      expect(project.notify_project_import_complete?).to be(false)
    end

    it 'returns false for projects with a remote mirror' do
      allow(project).to receive(:mirror?).and_return(true)

      expect(project.notify_project_import_complete?).to be(false)
    end

    it 'returns false for unsupported import types' do
      project.import_type = 'gitlab_project'

      expect(project.notify_project_import_complete?).to be(false)
    end

    %w[github gitea bitbucket bitbucket_server].each do |import_type|
      it "returns true for #{import_type}" do
        project.import_type = import_type
        expect(project.notify_project_import_complete?).to be(true)
      end
    end
  end

  describe '#safe_import_url' do
    let_it_be(:import_url) { 'https://example.com' }
    let_it_be(:project) do
      create(
        :project,
        import_url: import_url,
        import_data_attributes: { credentials: { user: 'user', password: 'password' } }
      )
    end

    it 'returns import_url with credentials masked' do
      expect(project.safe_import_url).to include('*****:*****')
    end

    it 'returns import_url with no credentials, masked or not' do
      safe_import_url = project.safe_import_url(masked: false)

      expect(safe_import_url).to eq(import_url)
    end
  end

  describe '#jira_import?' do
    let_it_be(:project) { build(:project, import_type: 'jira') }
    let_it_be(:jira_import) { build(:jira_import_state, project: project) }

    before do
      expect(project).to receive(:jira_imports).and_return([jira_import])
    end

    it { expect(project.jira_import?).to be true }
    it { expect(project.import?).to be true }
  end

  describe '#github_import?' do
    let_it_be(:project) { build(:project, import_type: 'github') }

    it { expect(project.github_import?).to be true }
  end

  describe '#github_enterprise_import?' do
    let_it_be(:github_com_project) do
      build(
        :project,
        import_type: 'github',
        import_url: 'https://api.github.com/user/repo'
      )
    end

    let_it_be(:github_enterprise_project) do
      build(
        :project,
        import_type: 'github',
        import_url: 'https://othergithub.net/user/repo'
      )
    end

    it { expect(github_com_project.github_import?).to be true }
    it { expect(github_com_project.github_enterprise_import?).to be false }

    it { expect(github_enterprise_project.github_import?).to be true }
    it { expect(github_enterprise_project.github_enterprise_import?).to be true }
  end

  describe '#remove_import_data' do
    let(:import_data) { ProjectImportData.new(data: { 'test' => 'some data' }) }

    context 'when jira import' do
      let!(:project) { create(:project, import_type: 'jira', import_data: import_data) }
      let!(:jira_import) { create(:jira_import_state, project: project) }

      it 'does remove import data' do
        expect(project.mirror?).to be false
        expect(project.jira_import?).to be true
        expect { project.remove_import_data }.to change { ProjectImportData.count }.by(-1)
      end
    end

    context 'when neither a mirror nor a jira import' do
      let!(:project) { create(:project, import_type: 'github', import_data: import_data) }

      it 'removes import data' do
        expect(project.mirror?).to be false
        expect(project.jira_import?).to be false
        expect { project.remove_import_data }.to change { ProjectImportData.count }.by(-1)
      end
    end
  end

  describe '#gitlab_project_import?' do
    subject(:project) { build(:project, import_type: 'gitlab_project') }

    it { expect(project.gitlab_project_import?).to be true }
  end

  describe '#gitea_import?' do
    subject(:project) { build(:project, import_type: 'gitea') }

    it { expect(project.gitea_import?).to be true }
  end

  describe '#bitbucket_import?' do
    subject(:project) { build(:project, import_type: 'bitbucket') }

    it { expect(project.bitbucket_import?).to be true }
  end

  describe '#bitbucket_server_import?' do
    subject(:project) { build(:project, import_type: 'bitbucket_server') }

    it { expect(project.bitbucket_server_import?).to be true }
  end

  describe '#any_import_in_progress?' do
    let_it_be_with_reload(:project) { create(:project) }

    subject { project.any_import_in_progress? }

    context 'when a file import is in progress' do
      before do
        create(:import_state, :started, project: project)
      end

      it { is_expected.to be_truthy }
    end

    context 'when a relation import is in progress' do
      before do
        create(:relation_import_tracker, :started, project: project)
      end

      it { is_expected.to be_truthy }
    end

    context 'when direct transfer is in progress' do
      before do
        create(:bulk_import_entity, :project_entity, :started, project: project)
      end

      it { is_expected.to be_truthy }
    end

    context 'when no imports are in progress' do
      it { is_expected.to be_falsy }
    end
  end

  describe '#has_remote_mirror?' do
    let(:project) { create(:project, :remote_mirror, :import_started) }

    subject { project.has_remote_mirror? }

    it 'returns true when a remote mirror is enabled' do
      is_expected.to be_truthy
    end

    it 'returns false when remote mirror is disabled' do
      project.remote_mirrors.first.update!(enabled: false)

      is_expected.to be_falsy
    end
  end

  describe '#update_remote_mirrors' do
    let(:project) { create(:project, :remote_mirror, :import_started) }

    delegate :update_remote_mirrors, to: :project

    it 'syncs enabled remote mirror' do
      expect_any_instance_of(RemoteMirror).to receive(:sync)

      update_remote_mirrors
    end

    it 'does nothing when remote mirror is disabled globally and not overridden' do
      stub_application_setting(mirror_available: false)
      project.remote_mirror_available_overridden = false

      expect_any_instance_of(RemoteMirror).not_to receive(:sync)

      update_remote_mirrors
    end

    it 'does not sync disabled remote mirrors' do
      project.remote_mirrors.first.update!(enabled: false)

      expect_any_instance_of(RemoteMirror).not_to receive(:sync)

      update_remote_mirrors
    end
  end

  describe '#remote_mirror_available?' do
    let(:project) { build_stubbed(:project) }

    context 'when remote mirror global setting is enabled' do
      it 'returns true' do
        expect(project.remote_mirror_available?).to be(true)
      end
    end

    context 'when remote mirror global setting is disabled' do
      before do
        stub_application_setting(mirror_available: false)
      end

      it 'returns true when overridden' do
        project.remote_mirror_available_overridden = true

        expect(project.remote_mirror_available?).to be(true)
      end

      it 'returns false when not overridden' do
        expect(project.remote_mirror_available?).to be(false)
      end
    end
  end

  describe '#mark_stuck_remote_mirrors_as_failed!' do
    it 'fails stuck remote mirrors' do
      project = create(:project, :repository, :remote_mirror)

      project.remote_mirrors.first.update!(
        update_status: :started,
        last_update_started_at: 2.days.ago
      )

      expect do
        project.mark_stuck_remote_mirrors_as_failed!
      end.to change { project.remote_mirrors.stuck.count }.from(1).to(0)
    end
  end

  shared_context 'project with group ancestry' do
    let(:parent) { create(:group) }
    let(:child) { create(:group, parent: parent) }
    let(:child2) { create(:group, parent: child) }
    let(:project) { create(:project, namespace: child2) }

    before do
      reload_models(parent, child, child2)
    end
  end

  shared_context 'project with namespace ancestry' do
    let(:namespace) { create :namespace }
    let(:project) { create :project, namespace: namespace }
  end

  shared_examples 'project with group ancestors' do
    it 'returns all ancestors' do
      is_expected.to contain_exactly(child2, child, parent)
    end
  end

  shared_examples 'project with ordered group ancestors' do
    let(:hierarchy_order) { :desc }

    it 'returns ancestors ordered by descending hierarchy' do
      is_expected.to eq([parent, child, child2])
    end
  end

  shared_examples '#ancestors' do
    context 'group ancestory' do
      include_context 'project with group ancestry'

      it_behaves_like 'project with group ancestors' do
        subject { project.ancestors }
      end

      it_behaves_like 'project with ordered group ancestors' do
        subject { project.ancestors(hierarchy_order: hierarchy_order) }
      end
    end

    context 'namespace ancestry' do
      include_context 'project with namespace ancestry'

      subject { project.ancestors }

      it { is_expected.to be_empty }
    end
  end

  describe '#ancestors' do
    include_examples '#ancestors'
  end

  describe '#ancestors_upto' do
    context 'group ancestry' do
      include_context 'project with group ancestry'

      it_behaves_like 'project with group ancestors' do
        subject { project.ancestors_upto }
      end

      it_behaves_like 'project with ordered group ancestors' do
        subject { project.ancestors_upto(hierarchy_order: hierarchy_order) }
      end

      it 'includes ancestors upto but excluding the given ancestor' do
        expect(project.ancestors_upto(parent)).to contain_exactly(child2, child)
      end

      describe 'with hierarchy_order' do
        it 'can be used with upto option' do
          expect(project.ancestors_upto(parent, hierarchy_order: :desc)).to eq([child, child2])
        end
      end
    end

    context 'namespace ancestry' do
      include_context 'project with namespace ancestry'

      subject { project.ancestors_upto }

      it { is_expected.to be_empty }
    end
  end

  describe '#root_ancestor' do
    let(:project) { create(:project) }

    subject { project.root_ancestor }

    it { is_expected.to eq(project.namespace) }

    context 'in a group' do
      let(:group) { create(:group) }
      let(:project) { create(:project, group: group) }

      it { is_expected.to eq(group) }
    end

    context 'in a nested group' do
      let(:root) { create(:group) }
      let(:child) { create(:group, parent: root) }
      let(:project) { create(:project, group: child) }

      it { is_expected.to eq(root) }
    end
  end

  describe '#emails_disabled?' do
    let(:project) { build(:project, emails_enabled: true) }

    it "is the opposite of emails_disabled" do
      expect(project.emails_disabled?).to be_falsey
    end
  end

  describe '#lfs_enabled?' do
    let(:namespace) { create(:namespace) }
    let(:project) { build(:project, namespace: namespace) }

    shared_examples 'project overrides group' do
      it 'returns true when enabled in project' do
        project.update_attribute(:lfs_enabled, true)

        expect(project.lfs_enabled?).to be_truthy
      end

      it 'returns false when disabled in project' do
        project.update_attribute(:lfs_enabled, false)

        expect(project.lfs_enabled?).to be_falsey
      end

      it 'returns the value from the namespace, when no value is set in project' do
        expect(project.lfs_enabled?).to eq(project.namespace.lfs_enabled?)
      end
    end

    context 'LFS disabled in group' do
      before do
        stub_lfs_setting(enabled: true)
        project.namespace.update_attribute(:lfs_enabled, false)
      end

      it_behaves_like 'project overrides group'
    end

    context 'LFS enabled in group' do
      before do
        stub_lfs_setting(enabled: true)
        project.namespace.update_attribute(:lfs_enabled, true)
      end

      it_behaves_like 'project overrides group'
    end

    describe 'LFS disabled globally' do
      before do
        stub_lfs_setting(enabled: false)
      end

      shared_examples 'it always returns false' do
        it do
          expect(project.lfs_enabled?).to be_falsey
          expect(project.namespace.lfs_enabled?).to be_falsey
        end
      end

      context 'when no values are set' do
        it_behaves_like 'it always returns false'
      end

      context 'when all values are set to true' do
        before do
          project.namespace.update_attribute(:lfs_enabled, true)
          project.update_attribute(:lfs_enabled, true)
        end

        it_behaves_like 'it always returns false'
      end
    end
  end

  describe '#after_repository_change_head' do
    let_it_be(:project) { create(:project) }

    it 'updates commit count' do
      expect(ProjectCacheWorker).to receive(:perform_async).with(project.id, [], %w[commit_count])

      project.after_repository_change_head
    end

    it 'reloads the default branch' do
      expect(project).to receive(:reload_default_branch)

      project.after_repository_change_head
    end
  end

  describe '#after_change_head_branch_does_not_exist' do
    let_it_be(:project) { create(:project) }

    it 'adds an error to container if branch does not exist' do
      expect do
        project.after_change_head_branch_does_not_exist('unexisted-branch')
      end.to change { project.errors.size }.from(0).to(1)
    end
  end

  describe '#lfs_objects_for_repository_types' do
    let(:project) { create(:project) }

    it 'returns LFS objects of the specified type only' do
      none, design, wiki = *[nil, :design, :wiki].map do |type|
        create(:lfs_objects_project, project: project, repository_type: type).lfs_object
      end

      expect(project.lfs_objects_for_repository_types(nil)).to contain_exactly(none)
      expect(project.lfs_objects_for_repository_types(nil, :wiki)).to contain_exactly(none, wiki)
      expect(project.lfs_objects_for_repository_types(:design)).to contain_exactly(design)
    end
  end

  context 'forks' do
    include ProjectForksHelper

    let(:project) { create(:project, :public) }
    let!(:forked_project) { fork_project(project) }

    describe '#fork_network' do
      it 'includes a fork of the project' do
        expect(project.fork_network.projects).to include(forked_project)
      end

      it 'includes a fork of a fork' do
        other_fork = fork_project(forked_project)

        expect(project.fork_network.projects).to include(other_fork)
      end

      it 'includes sibling forks' do
        other_fork = fork_project(project)

        expect(forked_project.fork_network.projects).to include(other_fork)
      end

      it 'includes the base project' do
        expect(forked_project.fork_network.projects).to include(project.reload)
      end
    end

    describe '#in_fork_network_of?' do
      it 'is true for a real fork' do
        expect(forked_project.in_fork_network_of?(project)).to be_truthy
      end

      it 'is true for a fork of a fork' do
        other_fork = fork_project(forked_project)

        expect(other_fork.in_fork_network_of?(project)).to be_truthy
      end

      it 'is true for sibling forks' do
        sibling = fork_project(project)

        expect(sibling.in_fork_network_of?(forked_project)).to be_truthy
      end

      it 'is false when another project is given' do
        other_project = build_stubbed(:project)

        expect(forked_project.in_fork_network_of?(other_project)).to be_falsy
      end
    end

    describe '#fork_source' do
      let!(:second_fork) { fork_project(forked_project) }

      it 'returns the direct source if it exists' do
        expect(second_fork.fork_source).to eq(forked_project)
      end

      it 'returns the root of the fork network when the directs source was deleted' do
        forked_project.destroy!

        expect(second_fork.fork_source).to eq(project)
      end

      it 'returns nil if it is the root of the fork network' do
        expect(project.fork_source).to be_nil
      end
    end

    describe '#forks' do
      it 'includes direct forks of the project' do
        expect(project.forks).to contain_exactly(forked_project)
      end
    end

    describe '#lfs_object_oids_from_fork_source' do
      let_it_be(:lfs_object) { create(:lfs_object) }
      let_it_be(:another_lfs_object) { create(:lfs_object) }

      let(:oids) { [lfs_object.oid, another_lfs_object.oid] }

      context 'when fork has one of two LFS objects' do
        before do
          create(:lfs_objects_project, lfs_object: lfs_object, project: project)
          create(:lfs_objects_project, lfs_object: another_lfs_object, project: forked_project)
        end

        it 'returns OIDs of owned LFS objects', :aggregate_failures do
          expect(forked_project.lfs_objects_oids_from_fork_source(oids: oids)).to eq([lfs_object.oid])
          expect(forked_project.lfs_objects_oids(oids: oids)).to eq([another_lfs_object.oid])
        end

        it 'returns empty when project is not a fork' do
          expect(project.lfs_objects_oids_from_fork_source(oids: oids)).to eq([])
        end
      end
    end
  end

  it_behaves_like 'can housekeep repository' do
    let(:resource) { build_stubbed(:project) }
    let(:resource_key) { 'projects' }
    let(:expected_worker_class) { Projects::GitGarbageCollectWorker }
  end

  describe '#deployment_variables' do
    let(:project) { build_stubbed(:project) }
    let(:environment) { 'production' }
    let(:namespace) { 'namespace' }

    subject { project.deployment_variables(environment: environment, kubernetes_namespace: namespace) }

    context 'when the deployment platform is stubbed' do
      before do
        expect(project).to receive(:deployment_platform).with(environment: environment)
          .and_return(deployment_platform)
      end

      context 'when project has a deployment platform' do
        let(:platform_variables) { %w[platform variables] }
        let(:deployment_platform) { double }

        before do
          expect(deployment_platform).to receive(:predefined_variables)
            .with(project: project, environment_name: environment, kubernetes_namespace: namespace)
            .and_return(platform_variables)
        end

        it { is_expected.to eq platform_variables }
      end

      context 'when project has no deployment platform' do
        let(:deployment_platform) { nil }

        it { is_expected.to eq [] }
      end
    end

    context 'when project has a deployment platforms' do
      let(:project) { create(:project) }

      let!(:default_cluster) do
        create(
          :cluster,
          :not_managed,
          platform_type: :kubernetes,
          projects: [project],
          environment_scope: '*',
          platform_kubernetes: default_cluster_kubernetes
        )
      end

      let!(:review_env_cluster) do
        create(
          :cluster,
          :not_managed,
          platform_type: :kubernetes,
          projects: [project],
          environment_scope: 'review/*',
          platform_kubernetes: review_env_cluster_kubernetes
        )
      end

      let(:default_cluster_kubernetes) { create(:cluster_platform_kubernetes, token: 'default-AAA') }
      let(:review_env_cluster_kubernetes) { create(:cluster_platform_kubernetes, token: 'review-AAA') }

      context 'when environment name is review/name' do
        let!(:environment) { create(:environment, project: project, name: 'review/name') }

        it 'returns variables from this service' do
          expect(project.deployment_variables(environment: 'review/name'))
            .to include(key: 'KUBE_TOKEN', value: 'review-AAA', public: false, masked: true)
        end
      end

      context 'when environment name is other' do
        let!(:environment) { create(:environment, project: project, name: 'staging/name') }

        it 'returns variables from this service' do
          expect(project.deployment_variables(environment: 'staging/name'))
            .to include(key: 'KUBE_TOKEN', value: 'default-AAA', public: false, masked: true)
        end
      end
    end
  end

  describe '#default_environment' do
    let(:project) { build(:project) }

    it 'returns production environment when it exists' do
      production = create(:environment, name: "production", project: project)
      create(:environment, name: 'staging', project: project)

      expect(project.default_environment).to eq(production)
    end

    it 'returns first environment when no production environment exists' do
      create(:environment, name: 'staging', project: project)
      create(:environment, name: 'foo', project: project)

      expect(project.default_environment).to eq(project.environments.first)
    end

    it 'returns nil when no available environment exists' do
      expect(project.default_environment).to be_nil
    end
  end

  describe '#any_lfs_file_locks?', :request_store do
    let_it_be(:project) { create(:project) }

    it 'returns false when there are no LFS file locks' do
      expect(project.any_lfs_file_locks?).to be_falsey
    end

    it 'returns a cached true when there are LFS file locks' do
      create(:lfs_file_lock, project: project)

      expect(project.lfs_file_locks).to receive(:any?).once.and_call_original

      2.times { expect(project.any_lfs_file_locks?).to be_truthy }
    end
  end

  describe '#protected_for?' do
    let(:project) { create(:project, :repository) }

    subject { project.protected_for?(ref) }

    shared_examples 'ref is not protected' do
      before do
        stub_application_setting(
          default_branch_protection: Gitlab::Access::PROTECTION_NONE)
      end

      it 'returns false' do
        is_expected.to be false
      end
    end

    shared_examples 'ref is protected branch' do
      before do
        create(:protected_branch, name: 'master', project: project)
      end

      it 'returns true' do
        is_expected.to be true
      end
    end

    shared_examples 'ref is protected tag' do
      before do
        create(:protected_tag, name: 'v1.0.0', project: project)
      end

      it 'returns true' do
        is_expected.to be true
      end
    end

    context 'when ref is nil' do
      let(:ref) { nil }

      it 'returns false' do
        is_expected.to be false
      end
    end

    context 'when ref is ref name' do
      context 'when ref is ambiguous' do
        let(:ref) { 'ref' }

        before do
          project.repository.add_branch(project.creator, 'ref', 'master')
          project.repository.add_tag(project.creator, 'ref', 'master')
        end

        it 'raises an error' do
          expect { subject }.to raise_error(Repository::AmbiguousRefError)
        end
      end

      context 'when the ref is not protected' do
        let(:ref) { 'master' }

        it_behaves_like 'ref is not protected'
      end

      context 'when the ref is a protected branch' do
        let(:ref) { 'master' }

        it_behaves_like 'ref is protected branch'
      end

      context 'when the ref is a protected tag' do
        let(:ref) { 'v1.0.0' }

        it_behaves_like 'ref is protected tag'
      end

      context 'when ref does not exist' do
        let(:ref) { 'something' }

        it 'returns false' do
          is_expected.to be false
        end
      end
    end

    context 'when ref is full ref' do
      context 'when the ref is not protected' do
        let(:ref) { 'refs/heads/master' }

        it_behaves_like 'ref is not protected'
      end

      context 'when the ref is a protected branch' do
        let(:ref) { 'refs/heads/master' }

        it_behaves_like 'ref is protected branch'
      end

      context 'when the ref is a protected tag' do
        let(:ref) { 'refs/tags/v1.0.0' }

        it_behaves_like 'ref is protected tag'
      end

      context 'when branch ref name is a full tag ref' do
        let(:ref) { 'refs/tags/something' }

        before do
          project.repository.add_branch(project.creator, ref, 'master')
        end

        context 'when ref is not protected' do
          it 'returns false' do
            is_expected.to be false
          end
        end

        context 'when ref is a protected branch' do
          before do
            create(:protected_branch, name: 'refs/tags/something', project: project)
          end

          it 'returns true' do
            is_expected.to be true
          end
        end
      end

      context 'when ref does not exist' do
        let(:ref) { 'refs/heads/something' }

        it 'returns false' do
          is_expected.to be false
        end
      end
    end
  end

  describe '#update_project_statistics' do
    let(:project) { create(:project) }

    it "is called after creation" do
      expect(project.statistics).to be_a ProjectStatistics
      expect(project.statistics).to be_persisted
    end

    it "copies the namespace_id" do
      expect(project.statistics.namespace_id).to eq project.namespace_id
    end

    it "updates the namespace_id when changed" do
      namespace = create(:namespace)
      project.update!(namespace: namespace)

      expect(project.statistics.namespace_id).to eq namespace.id
    end
  end

  describe 'inside_path' do
    let!(:project1) { create(:project, namespace: create(:namespace, path: 'name_pace')) }
    let!(:project2) { create(:project) }
    let!(:project3) { create(:project, namespace: create(:namespace, path: 'namespace')) }
    let!(:path) { project1.namespace.full_path }

    it 'returns correct project' do
      expect(described_class.inside_path(path)).to eq([project1])
    end
  end

  describe '#route_map_for' do
    let(:project) { create(:project, :repository) }
    let(:route_map) do
      <<-MAP.strip_heredoc
      - source: /source/(.*)/
        public: '\\1'
      MAP
    end

    before do
      project.repository.create_file(User.last, '.gitlab/route-map.yml', route_map, message: 'Add .gitlab/route-map.yml', branch_name: 'master')
    end

    context 'when there is a .gitlab/route-map.yml at the commit' do
      context 'when the route map is valid' do
        it 'returns a route map' do
          map = project.route_map_for(project.commit.sha)
          expect(map).to be_a_kind_of(Gitlab::RouteMap)
        end
      end

      context 'when the route map is invalid' do
        let(:route_map) { 'INVALID' }

        it 'returns nil' do
          expect(project.route_map_for(project.commit.sha)).to be_nil
        end
      end
    end

    context 'when there is no .gitlab/route-map.yml at the commit' do
      it 'returns nil' do
        expect(project.route_map_for(project.commit.parent.sha)).to be_nil
      end
    end
  end

  describe '#public_path_for_source_path' do
    let(:project) { create(:project, :repository) }
    let(:route_map) do
      Gitlab::RouteMap.new(<<-MAP.strip_heredoc)
        - source: /source/(.*)/
          public: '\\1'
      MAP
    end

    let(:sha) { project.commit.id }

    context 'when there is a route map' do
      before do
        allow(project).to receive(:route_map_for).with(sha).and_return(route_map)
      end

      context 'when the source path is mapped' do
        it 'returns the public path' do
          expect(project.public_path_for_source_path('source/file.html', sha)).to eq('file.html')
        end
      end

      context 'when the source path is not mapped' do
        it 'returns nil' do
          expect(project.public_path_for_source_path('file.html', sha)).to be_nil
        end
      end

      it 'returns a public path with a leading slash unmodified' do
        route_map = Gitlab::RouteMap.new(<<-MAP.strip_heredoc)
          - source: 'source/file.html'
            public: '/public/file'
        MAP
        allow(project).to receive(:route_map_for).with(sha).and_return(route_map)

        expect(project.public_path_for_source_path('source/file.html', sha)).to eq('/public/file')
      end
    end

    context 'when there is no route map' do
      before do
        allow(project).to receive(:route_map_for).with(sha).and_return(nil)
      end

      it 'returns nil' do
        expect(project.public_path_for_source_path('source/file.html', sha)).to be_nil
      end
    end
  end

  describe '#parent' do
    let(:project) { create(:project) }

    it { expect(project.parent).to eq(project.namespace) }
  end

  describe '#parent_id' do
    let(:project) { create(:project) }

    it { expect(project.parent_id).to eq(project.namespace_id) }
  end

  describe '#parent_changed?' do
    let(:project) { create(:project) }

    before do
      project.namespace_id = project.namespace_id + 1
    end

    it { expect(project.parent_changed?).to be_truthy }
  end

  describe '#default_merge_request_target' do
    let_it_be(:project) { create(:project, :public) }

    let!(:forked) { fork_project(project) }

    context 'when mr_default_target_self is set to true' do
      it 'returns the current project' do
        expect(forked.project_setting).to receive(:mr_default_target_self)
          .and_return(true)

        expect(forked.default_merge_request_target).to eq(forked)
      end
    end

    context 'when merge request can not target upstream' do
      it 'returns the current project' do
        expect(forked).to receive(:mr_can_target_upstream?).and_return(false)

        expect(forked.default_merge_request_target).to eq(forked)
      end
    end

    context 'when merge request can target upstream' do
      it 'returns the source project' do
        expect(forked).to receive(:mr_can_target_upstream?).and_return(true)

        expect(forked.default_merge_request_target).to eq(project)
      end
    end
  end

  describe '#mr_can_target_upstream?' do
    let_it_be(:project) { create(:project, :public) }

    let!(:forked) { fork_project(project) }

    context 'when forked from a more visible project' do
      it 'can not target the upstream project' do
        forked.visibility = Gitlab::VisibilityLevel::PRIVATE
        forked.save!

        expect(project.visibility).to eq 'public'
        expect(forked.visibility).to eq 'private'

        expect(forked.mr_can_target_upstream?).to be_falsey
      end
    end

    context 'when forked from a project with disabled merge requests' do
      it 'can not target the upstream project' do
        project.project_feature
          .update!(merge_requests_access_level: ProjectFeature::DISABLED)

        expect(forked.forked_from_project).to receive(:merge_requests_enabled?)
          .and_call_original

        expect(forked.mr_can_target_upstream?).to be_falsey
      end
    end

    context 'when forked from a project with enabled merge requests' do
      it 'can target the upstream project' do
        expect(forked.mr_can_target_upstream?).to be_truthy
      end
    end

    context 'when not forked' do
      it 'can not target the upstream project' do
        expect(project.mr_can_target_upstream?).to be_falsey
      end
    end
  end

  describe '#lfs_http_url_to_repo' do
    let(:project) { create(:project) }

    context 'when a custom HTTP clone URL root is not set' do
      it 'returns the url to the repo without a username' do
        lfs_http_url_to_repo = project.lfs_http_url_to_repo('operation_that_doesnt_matter')

        expect(lfs_http_url_to_repo).to eq("#{project.web_url}.git")
        expect(lfs_http_url_to_repo).not_to include('@')
      end
    end

    context 'when a custom HTTP clone URL root is set' do
      before do
        stub_application_setting(custom_http_clone_url_root: 'https://git.example.com:51234')
      end

      it 'returns the url to the repo, with the root replaced with the custom one' do
        lfs_http_url_to_repo = project.lfs_http_url_to_repo('operation_that_doesnt_matter')

        expect(lfs_http_url_to_repo).to eq("https://git.example.com:51234/#{project.full_path}.git")
      end
    end
  end

  describe '#pipeline_status' do
    let(:project) { create(:project, :repository) }

    it 'builds a pipeline status' do
      expect(project.pipeline_status).to be_a(Gitlab::Cache::Ci::ProjectPipelineStatus)
    end

    it 'hase a loaded pipeline status' do
      expect(project.pipeline_status).to be_loaded
    end
  end

  describe '#update' do
    let(:project) { create(:project) }

    it 'validates the visibility' do
      expect(project).to receive(:visibility_level_allowed_as_fork).and_call_original
      expect(project).to receive(:visibility_level_allowed_by_group).and_call_original

      project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
    end

    context 'when validating if path already exist as pages unique domain' do
      before do
        stub_pages_setting(host: 'example.com')
      end

      it 'rejects paths that match pages unique domain' do
        stub_pages_setting(host: 'example.com')
        create(:project_setting, pages_unique_domain: 'some-unique-domain')

        expect(project.update(path: 'some-unique-domain.example.com')).to eq(false)
        expect(project.errors.full_messages_for(:path)).to match(['Path already in use'])
      end

      it 'accepts path when the host does not match' do
        create(:project_setting, pages_unique_domain: 'some-unique-domain')

        expect(project.update(path: 'some-unique-domain.another-example.com')).to eq(true)
      end

      it 'accepts path when the domain does not match' do
        stub_pages_setting(host: 'example.com')
        create(:project_setting, pages_unique_domain: 'another-unique-domain')

        expect(project.update(path: 'some-unique-domain.example.com')).to eq(true)
      end
    end

    it 'does not validate the visibility' do
      expect(project).not_to receive(:visibility_level_allowed_as_fork).and_call_original
      expect(project).not_to receive(:visibility_level_allowed_by_group).and_call_original

      project.update!(updated_at: Time.current)
    end
  end

  describe '#last_repository_updated_at' do
    it 'sets to created_at upon creation' do
      project = create(:project, created_at: 2.hours.ago)

      expect(project.last_repository_updated_at.to_i).to eq(project.created_at.to_i)
    end
  end

  describe '.public_or_visible_to_user' do
    let!(:user) { create(:user) }

    let!(:private_project) do
      create(:project, :private, creator: user, namespace: user.namespace)
    end

    let!(:public_project) { create(:project, :public) }

    context 'with a user' do
      let(:projects) do
        described_class.all.public_or_visible_to_user(user)
      end

      it 'includes projects the user has access to' do
        expect(projects).to include(private_project)
      end

      it 'includes projects the user can see' do
        expect(projects).to include(public_project)
      end
    end

    context 'without a user' do
      it 'only includes public projects' do
        projects = described_class.all.public_or_visible_to_user

        expect(projects).to eq([public_project])
      end
    end

    context 'min_access_level' do
      let!(:private_project) { create(:project, :private) }

      before do
        private_project.add_guest(user)
      end

      it 'excludes projects when user does not have required minimum access level' do
        projects = described_class.all.public_or_visible_to_user(user, Gitlab::Access::REPORTER)

        expect(projects).to contain_exactly(public_project)
      end
    end

    context 'with deploy token users' do
      let_it_be(:private_project) { create(:project, :private, description: 'Match') }
      let_it_be(:private_project2) { create(:project, :private, description: 'Match') }
      let_it_be(:private_project3) { create(:project, :private, description: 'Mismatch') }

      subject { described_class.all.public_or_visible_to_user(user) }

      context 'deploy token user without project' do
        let_it_be(:user) { create(:deploy_token) }

        it { is_expected.to eq [] }
      end

      context 'deploy token user with projects' do
        let_it_be(:user) { create(:deploy_token, projects: [private_project, private_project2, private_project3]) }

        it { is_expected.to contain_exactly(private_project, private_project2, private_project3) }

        context 'with chained filter' do
          subject { described_class.where(description: 'Match').public_or_visible_to_user(user) }

          it { is_expected.to contain_exactly(private_project, private_project2) }
        end
      end
    end
  end

  describe '.ids_with_issuables_available_for' do
    let!(:user) { create(:user) }

    it 'returns project ids with milestones available for user' do
      project_1 = create(:project, :public, :merge_requests_disabled, :issues_disabled)
      project_2 = create(:project, :public, :merge_requests_disabled)
      project_3 = create(:project, :public, :issues_disabled)
      project_4 = create(:project, :public)
      project_4.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE, merge_requests_access_level: ProjectFeature::PRIVATE)

      project_ids = described_class.ids_with_issuables_available_for(user).pluck(:id)

      expect(project_ids).to include(project_2.id, project_3.id)
      expect(project_ids).not_to include(project_1.id, project_4.id)
    end
  end

  describe '.with_feature_available_for_user' do
    let(:user) { create(:user) }
    let(:feature) { MergeRequest }

    subject { described_class.with_feature_available_for_user(feature, user) }

    shared_examples 'feature disabled' do
      let(:project) { create(:project, :public, :merge_requests_disabled) }

      it 'does not return projects with the project feature disabled' do
        is_expected.not_to include(project)
      end
    end

    shared_examples 'feature public' do
      let(:project) { create(:project, :public, :merge_requests_public) }

      it 'returns projects with the project feature public' do
        is_expected.to include(project)
      end
    end

    shared_examples 'feature enabled' do
      let(:project) { create(:project, :public, :merge_requests_enabled) }

      it 'returns projects with the project feature enabled' do
        is_expected.to include(project)
      end
    end

    shared_examples 'feature access level is nil' do
      let(:project) { create(:project, :public) }

      it 'returns projects with the project feature access level nil' do
        project.project_feature.update!(merge_requests_access_level: nil)

        is_expected.to include(project)
      end
    end

    context 'with user' do
      before do
        project.add_guest(user)
      end

      it_behaves_like 'feature disabled'
      it_behaves_like 'feature public'
      it_behaves_like 'feature enabled'
      it_behaves_like 'feature access level is nil'

      context 'when feature is private' do
        let(:project) { create(:project, :public, :merge_requests_private) }

        context 'when user does not have access to the feature' do
          it 'does not return projects with the project feature private' do
            is_expected.not_to include(project)
          end
        end

        context 'when user has access to the feature' do
          it 'returns projects with the project feature private' do
            project.add_reporter(user)

            is_expected.to include(project)
          end
        end
      end
    end

    context 'user is an admin' do
      let(:user) { create(:user, :admin) }

      it_behaves_like 'feature disabled'
      it_behaves_like 'feature public'
      it_behaves_like 'feature enabled'
      it_behaves_like 'feature access level is nil'

      context 'when feature is private' do
        let(:project) { create(:project, :public, :merge_requests_private) }

        context 'when admin mode is enabled', :enable_admin_mode do
          it 'returns projects with the project feature private' do
            is_expected.to include(project)
          end
        end

        context 'when admin mode is disabled' do
          it 'does not return projects with the project feature private' do
            is_expected.not_to include(project)
          end
        end
      end
    end

    context 'without user' do
      let(:user) { nil }

      it_behaves_like 'feature disabled'
      it_behaves_like 'feature public'
      it_behaves_like 'feature enabled'
      it_behaves_like 'feature access level is nil'

      context 'when feature is private' do
        let(:project) { create(:project, :public, :merge_requests_private) }

        it 'does not return projects with the project feature private' do
          is_expected.not_to include(project)
        end
      end
    end
  end

  describe '.filter_by_feature_visibility' do
    include_context 'ProjectPolicyTable context'
    include ProjectHelpers
    include UserHelpers

    let_it_be(:group) { create(:group) }
    let_it_be_with_reload(:project) { create(:project, namespace: group) }

    let(:user) { create_user_from_membership(project, membership) }

    subject { described_class.filter_by_feature_visibility(feature, user) }

    shared_examples 'filter respects visibility' do
      it 'respects visibility' do
        enable_admin_mode!(user) if admin_mode
        update_feature_access_level(project, feature_access_level, visibility_level: Gitlab::VisibilityLevel.level_value(project_level.to_s))

        expected_objects = expected_count == 1 ? [project] : []

        expect(subject).to eq(expected_objects)
      end
    end

    context 'with reporter level access' do
      let(:feature) { MergeRequest }

      where(:project_level, :feature_access_level, :membership, :admin_mode, :expected_count) do
        permission_table_for_reporter_feature_access
      end

      with_them do
        it_behaves_like 'filter respects visibility'
      end
    end

    context 'with feature issues' do
      let(:feature) { Issue }

      where(:project_level, :feature_access_level, :membership, :admin_mode, :expected_count) do
        permission_table_for_guest_feature_access
      end

      with_them do
        it_behaves_like 'filter respects visibility'
      end
    end

    context 'with feature wiki' do
      let(:feature) { :wiki }

      where(:project_level, :feature_access_level, :membership, :admin_mode, :expected_count) do
        permission_table_for_guest_feature_access
      end

      with_them do
        it_behaves_like 'filter respects visibility'
      end
    end

    context 'with feature code' do
      let(:feature) { :repository }

      where(:project_level, :feature_access_level, :membership, :admin_mode, :expected_count) do
        permission_table_for_guest_feature_access_and_non_private_project_only
      end

      with_them do
        it_behaves_like 'filter respects visibility'
      end
    end
  end

  describe '.wrap_with_cte' do
    let!(:user) { create(:user) }

    let!(:private_project) do
      create(:project, :private, creator: user, namespace: user.namespace)
    end

    let!(:public_project) { create(:project, :public) }

    let(:projects) { described_class.all.public_or_visible_to_user(user) }

    subject { described_class.wrap_with_cte(projects) }

    it 'wrapped query matches original' do
      expect(subject.to_sql).to match(/^WITH "projects_cte" AS MATERIALIZED/)
      expect(subject).to match_array(projects)
    end
  end

  describe '#remove_private_deploy_keys' do
    let!(:project) { create(:project) }

    context 'for a private deploy key' do
      let!(:key) { create(:deploy_key, public: false) }
      let!(:deploy_keys_project) { create(:deploy_keys_project, deploy_key: key, project: project) }

      context 'when the key is not linked to another project' do
        it 'removes the key' do
          project.remove_private_deploy_keys

          expect(project.deploy_keys).not_to include(key)
        end
      end

      context 'when the key is linked to another project' do
        before do
          another_project = create(:project)
          create(:deploy_keys_project, deploy_key: key, project: another_project)
        end

        it 'does not remove the key' do
          project.remove_private_deploy_keys

          expect(project.deploy_keys).to include(key)
        end
      end
    end

    context 'for a public deploy key' do
      let!(:key) { create(:deploy_key, public: true) }
      let!(:deploy_keys_project) { create(:deploy_keys_project, deploy_key: key, project: project) }

      it 'does not remove the key' do
        project.remove_private_deploy_keys

        expect(project.deploy_keys).to include(key)
      end
    end
  end

  describe '#remove_export' do
    let(:project) { create(:project) }
    let(:export_file) { fixture_file_upload('spec/fixtures/project_export.tar.gz') }
    let(:export) { create(:import_export_upload, project: project, export_file: export_file) }

    before do
      export

      allow_next_instance_of(ProjectExportWorker) do |job|
        allow(job).to receive(:jid).and_return(SecureRandom.hex(8))
      end
    end

    it 'removes the export' do
      project.remove_exports

      expect(project.export_file_exists?(export.user)).to be_falsey
    end
  end

  describe '#remove_export_for_user' do
    let(:project) { create(:project) }
    let(:export_file) { fixture_file_upload('spec/fixtures/project_export.tar.gz') }
    let(:user) { create(:user) }
    let(:export) { create(:import_export_upload, project: project, export_file: export_file, user: user) }

    before do
      export

      allow_next_instance_of(ProjectExportWorker) do |job|
        allow(job).to receive(:jid).and_return(SecureRandom.hex(8))
      end
    end

    it 'removes the export' do
      project.remove_export_for_user(user)

      expect(project.export_file_exists?(export.user)).to be_falsey
    end
  end

  context 'with export' do
    let(:project) { create(:project) }
    let(:export_file) { fixture_file_upload('spec/fixtures/project_export.tar.gz') }
    let!(:export) { create(:import_export_upload, project: project, export_file: export_file) }

    it '#export_file_exists? returns true' do
      expect(project.export_file_exists?(export.user)).to be true
    end

    it '#export_archive_exists? returns false' do
      expect(project.export_archive_exists?(export.user)).to be true
    end
  end

  describe '#forks_count' do
    it 'returns the number of forks' do
      project = build(:project)

      expect_any_instance_of(::Projects::BatchForksCountService).to receive(:refresh_cache_and_retrieve_data).and_return({ project => 1 })

      expect(project.forks_count).to eq(1)
    end
  end

  describe '#git_transfer_in_progress?' do
    let(:project) { build(:project) }

    subject { project.git_transfer_in_progress? }

    where(:project_reference_counter, :wiki_reference_counter, :design_reference_counter, :result) do
      0 | 0 | 0 | false
      2 | 0 | 0 | true
      0 | 2 | 0 | true
      0 | 0 | 2 | true
    end

    with_them do
      before do
        allow(project).to receive(:reference_counter).with(type: Gitlab::GlRepository::PROJECT) do
          double(:project_reference_counter, value: project_reference_counter)
        end
        allow(project).to receive(:reference_counter).with(type: Gitlab::GlRepository::WIKI) do
          double(:wiki_reference_counter, value: wiki_reference_counter)
        end
        allow(project).to receive(:reference_counter).with(type: Gitlab::GlRepository::DESIGN) do
          double(:design_reference_counter, value: design_reference_counter)
        end
      end

      specify { expect(subject).to be result }
    end
  end

  context 'legacy storage' do
    let_it_be(:project) { create(:project, :repository, :legacy_storage) }

    let(:gitlab_shell) { Gitlab::Shell.new }
    let(:project_storage) { project.send(:storage) }

    before do
      allow(project).to receive(:gitlab_shell).and_return(gitlab_shell)
      stub_application_setting(hashed_storage_enabled: false)
    end

    describe '#base_dir' do
      it 'returns base_dir based on namespace only' do
        expect(project.base_dir).to eq(project.namespace.full_path)
      end
    end

    describe '#disk_path' do
      it 'returns disk_path based on namespace and project path' do
        expect(project.disk_path).to eq("#{project.namespace.full_path}/#{project.path}")
      end
    end

    describe '#legacy_storage?' do
      it 'returns true when storage_version is nil' do
        project = build(:project, storage_version: nil)

        expect(project.legacy_storage?).to be_truthy
      end

      it 'returns true when the storage_version is 0' do
        project = build(:project, storage_version: 0)

        expect(project.legacy_storage?).to be_truthy
      end
    end

    describe '#hashed_storage?' do
      it 'returns false' do
        expect(project.hashed_storage?(:repository)).to be_falsey
      end
    end
  end

  context 'hashed storage' do
    let_it_be(:project) { create(:project, :repository, skip_disk_validation: true) }

    let(:gitlab_shell) { Gitlab::Shell.new }
    let(:hash) { Digest::SHA2.hexdigest(project.id.to_s) }
    let(:hashed_prefix) { File.join('@hashed', hash[0..1], hash[2..3]) }
    let(:hashed_path) { File.join(hashed_prefix, hash) }

    describe '#legacy_storage?' do
      it 'returns false' do
        expect(project.legacy_storage?).to be_falsey
      end
    end

    describe '#hashed_storage?' do
      it 'returns true if rolled out' do
        expect(project.hashed_storage?(:attachments)).to be_truthy
      end

      it 'returns false when not rolled out yet' do
        project.storage_version = 1

        expect(project.hashed_storage?(:attachments)).to be_falsey
      end
    end

    describe '#base_dir' do
      it 'returns base_dir based on hash of project id' do
        expect(project.base_dir).to eq(hashed_prefix)
      end
    end

    describe '#disk_path' do
      it 'returns disk_path based on hash of project id' do
        expect(project.disk_path).to eq(hashed_path)
      end
    end
  end

  describe '#has_ci?' do
    let_it_be(:project, reload: true) { create(:project) }

    context 'when has .gitlab-ci.yml' do
      before do
        expect(project).to receive(:has_ci_config_file?) { true }
      end

      it "CI is available" do
        expect(project).to have_ci
      end
    end

    context 'when there is no .gitlab-ci.yml' do
      before do
        expect(project).to receive(:has_ci_config_file?) { false }
      end

      it "CI is available" do
        expect(project).to have_ci
      end

      context 'when auto devops is disabled' do
        before do
          stub_application_setting(auto_devops_enabled: false)
        end

        it "CI is not available" do
          expect(project).not_to have_ci
        end
      end
    end
  end

  describe '#has_ci_config_file?' do
    subject(:has_ci_config_file) { project.has_ci_config_file? }

    context 'when the repository does not exist' do
      let_it_be(:project) { create(:project) }

      it { is_expected.to be_falsey }
    end

    context 'when the repository has a .gitlab-ci.yml file' do
      let_it_be(:project) { create(:project, :small_repo, files: { '.gitlab-ci.yml' => 'test' }) }

      it { is_expected.to be_truthy }
    end

    context 'when the repository does not have a .gitlab-ci.yml file' do
      let_it_be(:project) { create(:project, :small_repo, files: { 'README.md' => 'hello' }) }

      it { is_expected.to be_falsey }
    end

    context 'when the repository has a custom CI config file' do
      let_it_be(:project) { create(:project, :small_repo, files: { 'my_ci_file.yml' => 'test' }) }

      before do
        project.ci_config_path = 'my_ci_file.yml'
      end

      it { is_expected.to be_truthy }
    end
  end

  describe '#predefined_project_variables' do
    let_it_be(:project) { create(:project, :repository) }

    subject { project.predefined_project_variables.to_runner_variables }

    specify do
      expect(subject).to include(
        { key: 'CI_CONFIG_PATH', value: Ci::Pipeline::DEFAULT_CONFIG_PATH, public: true, masked: false }
      )
    end

    context 'when ci config path is overridden' do
      before do
        project.update!(ci_config_path: 'random.yml')
      end

      it do
        expect(subject).to include(
          { key: 'CI_CONFIG_PATH', value: 'random.yml', public: true, masked: false }
        )
      end
    end
  end

  describe '#dependency_proxy_variables' do
    let_it_be(:namespace) { create(:namespace, path: 'NameWithUPPERcaseLetters') }
    let_it_be(:project) { create(:project, :repository, namespace: namespace) }

    subject { project.dependency_proxy_variables.to_runner_variables }

    context 'when dependency_proxy is enabled' do
      before do
        stub_config(dependency_proxy: { enabled: true })
      end

      it 'contains the downcased name' do
        expect(subject).to include({ key: 'CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX',
                                     value: "#{Gitlab.host_with_port}/namewithuppercaseletters#{DependencyProxy::URL_SUFFIX}",
                                     public: true,
                                     masked: false })
      end
    end

    context 'when dependency_proxy is disabled' do
      before do
        stub_config(dependency_proxy: { enabled: false })
      end

      it { expect(subject).to be_empty }
    end
  end

  describe '#auto_devops_enabled?' do
    before do
      Feature.enable_percentage_of_actors(:force_autodevops_on_by_default, 0)
    end

    let_it_be(:project, reload: true) { create(:project) }

    subject { project.auto_devops_enabled? }

    context 'when explicitly enabled' do
      before do
        create(:project_auto_devops, project: project)
      end

      it { is_expected.to be_truthy }
    end

    context 'when explicitly disabled' do
      before do
        create(:project_auto_devops, project: project, enabled: false)
      end

      it { is_expected.to be_falsey }
    end

    context 'when enabled in settings' do
      before do
        stub_application_setting(auto_devops_enabled: true)
      end

      it { is_expected.to be_truthy }
    end

    context 'when disabled in settings' do
      before do
        stub_application_setting(auto_devops_enabled: false)
      end

      it { is_expected.to be_falsey }

      context 'when explicitly enabled' do
        before do
          create(:project_auto_devops, project: project)
        end

        it { is_expected.to be_truthy }
      end

      context 'when explicitly disabled' do
        before do
          create(:project_auto_devops, :disabled, project: project)
        end

        it { is_expected.to be_falsey }
      end
    end

    context 'when force_autodevops_on_by_default is enabled for the project' do
      it { is_expected.to be_truthy }
    end

    context 'with group parents' do
      let(:instance_enabled) { true }

      before do
        stub_application_setting(auto_devops_enabled: instance_enabled)
        project.update!(namespace: parent_group)
      end

      context 'when enabled on parent' do
        let(:parent_group) { create(:group, :auto_devops_enabled) }

        context 'when auto devops instance enabled' do
          it { is_expected.to be_truthy }
        end

        context 'when auto devops instance disabled' do
          let(:instance_disabled) { false }

          it { is_expected.to be_truthy }
        end
      end

      context 'when disabled on parent' do
        let(:parent_group) { create(:group, :auto_devops_disabled) }

        context 'when auto devops instance enabled' do
          it { is_expected.to be_falsy }
        end

        context 'when auto devops instance disabled' do
          let(:instance_disabled) { false }

          it { is_expected.to be_falsy }
        end
      end

      context 'when enabled on root parent' do
        let(:parent_group) { create(:group, parent: create(:group, :auto_devops_enabled)) }

        context 'when auto devops instance enabled' do
          it { is_expected.to be_truthy }
        end

        context 'when auto devops instance disabled' do
          let(:instance_disabled) { false }

          it { is_expected.to be_truthy }
        end

        context 'when explicitly disabled on parent' do
          let(:parent_group) { create(:group, :auto_devops_disabled, parent: create(:group, :auto_devops_enabled)) }

          it { is_expected.to be_falsy }
        end
      end

      context 'when disabled on root parent' do
        let(:parent_group) { create(:group, parent: create(:group, :auto_devops_disabled)) }

        context 'when auto devops instance enabled' do
          it { is_expected.to be_falsy }
        end

        context 'when auto devops instance disabled' do
          let(:instance_disabled) { false }

          it { is_expected.to be_falsy }
        end

        context 'when explicitly disabled on parent' do
          let(:parent_group) { create(:group, :auto_devops_disabled, parent: create(:group, :auto_devops_enabled)) }

          it { is_expected.to be_falsy }
        end
      end
    end
  end

  describe '#has_auto_devops_implicitly_enabled?' do
    let_it_be(:project, reload: true) { create(:project) }

    context 'when disabled in settings' do
      before do
        stub_application_setting(auto_devops_enabled: false)
      end

      it 'does not have auto devops implicitly disabled' do
        expect(project).not_to have_auto_devops_implicitly_enabled
      end
    end

    context 'when enabled in settings' do
      before do
        stub_application_setting(auto_devops_enabled: true)
      end

      it 'auto devops is implicitly disabled' do
        expect(project).to have_auto_devops_implicitly_enabled
      end

      context 'when explicitly disabled' do
        before do
          create(:project_auto_devops, project: project, enabled: false)
        end

        it 'does not have auto devops implicitly disabled' do
          expect(project).not_to have_auto_devops_implicitly_enabled
        end
      end

      context 'when explicitly enabled' do
        before do
          create(:project_auto_devops, project: project, enabled: true)
        end

        it 'does not have auto devops implicitly disabled' do
          expect(project).not_to have_auto_devops_implicitly_enabled
        end
      end
    end

    context 'when enabled on group' do
      it 'has auto devops implicitly enabled' do
        project.update!(namespace: create(:group, :auto_devops_enabled))

        expect(project).to have_auto_devops_implicitly_enabled
      end
    end

    context 'when enabled on parent group' do
      it 'has auto devops implicitly enabled' do
        subgroup = create(:group, parent: create(:group, :auto_devops_enabled))
        project.update!(namespace: subgroup)

        expect(project).to have_auto_devops_implicitly_enabled
      end
    end
  end

  describe '#has_auto_devops_implicitly_disabled?' do
    let_it_be(:project, reload: true) { create(:project) }

    before do
      Feature.enable_percentage_of_actors(:force_autodevops_on_by_default, 0)
    end

    context 'when explicitly disabled' do
      before do
        create(:project_auto_devops, project: project, enabled: false)
      end

      it 'does not have auto devops implicitly disabled' do
        expect(project).not_to have_auto_devops_implicitly_disabled
      end
    end

    context 'when explicitly enabled' do
      before do
        create(:project_auto_devops, project: project, enabled: true)
      end

      it 'does not have auto devops implicitly disabled' do
        expect(project).not_to have_auto_devops_implicitly_disabled
      end
    end

    context 'when enabled in settings' do
      before do
        stub_application_setting(auto_devops_enabled: true)
      end

      it 'does not have auto devops implicitly disabled' do
        expect(project).not_to have_auto_devops_implicitly_disabled
      end
    end

    context 'when disabled in settings' do
      before do
        stub_application_setting(auto_devops_enabled: false)
      end

      it 'auto devops is implicitly disabled' do
        expect(project).to have_auto_devops_implicitly_disabled
      end

      context 'when force_autodevops_on_by_default is enabled for the project' do
        before do
          create(:project_auto_devops, project: project, enabled: false)

          Feature.enable_percentage_of_actors(:force_autodevops_on_by_default, 100)
        end

        it 'does not have auto devops implicitly disabled' do
          expect(project).not_to have_auto_devops_implicitly_disabled
        end
      end

      context 'when disabled on group' do
        it 'has auto devops implicitly disabled' do
          project.update!(namespace: create(:group, :auto_devops_disabled))

          expect(project).to have_auto_devops_implicitly_disabled
        end
      end

      context 'when disabled on parent group' do
        it 'has auto devops implicitly disabled' do
          subgroup = create(:group, parent: create(:group, :auto_devops_disabled))
          project.update!(namespace: subgroup)

          expect(project).to have_auto_devops_implicitly_disabled
        end
      end
    end
  end

  describe '#api_variables' do
    let_it_be(:project) { create(:project) }

    it 'exposes API v4 URL' do
      v4_variable = project.api_variables.find { |variable| variable[:key] == "CI_API_V4_URL" }

      expect(v4_variable).not_to be_nil
      expect(v4_variable[:key]).to eq 'CI_API_V4_URL'
      expect(v4_variable[:value]).to end_with '/api/v4'
    end

    it 'exposes API GraphQL URL' do
      graphql_variable = project.api_variables.find { |variable| variable[:key] == "CI_API_GRAPHQL_URL" }

      expect(graphql_variable).not_to be_nil
      expect(graphql_variable[:key]).to eq 'CI_API_GRAPHQL_URL'
      expect(graphql_variable[:value]).to end_with '/api/graphql'
    end

    it 'contains a URL variable for every supported API version' do
      # Ensure future API versions have proper variables defined. We're not doing this for v3.
      supported_versions = API::API.versions - ['v3']
      supported_versions = supported_versions.select do |version|
        API::API.routes.select { |route| route.version == version }.many?
      end

      required_variables = supported_versions.map do |version|
        "CI_API_#{version.upcase}_URL"
      end

      expect(project.api_variables.map { |variable| variable[:key] })
        .to include(*required_variables)
    end
  end

  describe '#latest_successful_builds_for' do
    let(:project) { build(:project) }

    before do
      allow(project).to receive(:default_branch).and_return('master')
    end

    context 'without a ref' do
      it 'returns a pipeline for the default branch' do
        expect(project)
          .to receive(:latest_successful_pipeline_for_default_branch)

        project.latest_successful_pipeline_for
      end
    end

    context 'with the ref set to the default branch' do
      it 'returns a pipeline for the default branch' do
        expect(project)
          .to receive(:latest_successful_pipeline_for_default_branch)

        project.latest_successful_pipeline_for(project.default_branch)
      end
    end

    context 'with a ref that is not the default branch' do
      it 'returns the latest successful pipeline for the given ref' do
        expect(project.ci_pipelines).to receive(:latest_successful_for_ref).with('foo')

        project.latest_successful_pipeline_for('foo')
      end
    end
  end

  describe '#check_repository_path_availability' do
    let(:project) { build(:project, :repository, :legacy_storage) }

    context 'when the repository already exists' do
      let(:project) { create(:project, :repository, :legacy_storage) }

      it 'returns false when repository already exists' do
        expect(project.check_repository_path_availability).to be_falsey
      end
    end

    context 'when the repository does not exist' do
      it 'returns false when repository already exists' do
        expect(project.check_repository_path_availability).to be_truthy
      end

      it 'skips gitlab-shell exists?' do
        project.skip_disk_validation = true

        expect(project.gitlab_shell).not_to receive(:repository_exists?)
        expect(project.check_repository_path_availability).to be_truthy
      end
    end
  end

  describe '#latest_successful_pipeline_for_default_branch' do
    let(:project) { build(:project) }

    before do
      allow(project).to receive(:default_branch).and_return('master')
    end

    it 'memoizes and returns the latest successful pipeline for the default branch' do
      pipeline = double(:pipeline)

      expect(project.ci_pipelines).to receive(:latest_successful_for_ref)
        .with(project.default_branch)
        .and_return(pipeline)
        .once

      2.times do
        expect(project.latest_successful_pipeline_for_default_branch)
          .to eq(pipeline)
      end
    end
  end

  describe '#after_import' do
    let(:project) { create(:project) }
    let(:import_state) { create(:import_state, project: project) }

    it 'runs the correct hooks' do
      expect(project.repository).to receive(:expire_content_cache).ordered
      expect(project.repository).to receive(:remove_prohibited_refs).ordered
      expect(project.wiki.repository).to receive(:expire_content_cache)
      expect(import_state).to receive(:finish)
      expect(project).to receive(:reset_counters_and_iids)
      expect(project).to receive(:after_create_default_branch)
      expect(project).to receive(:refresh_markdown_cache!)
      expect(ProjectCacheWorker).to receive(:perform_async).with(project.id, [], %w[repository_size wiki_size])
      expect(DetectRepositoryLanguagesWorker).to receive(:perform_async).with(project.id)
      expect(AuthorizedProjectUpdate::ProjectRecalculateWorker).to receive(:perform_async).with(project.id)

      project.after_import
    end

    context 'project authorizations refresh' do
      it 'updates user authorizations' do
        create(:import_state, :started, project: project)

        member = build(:project_member, project: project)
        member.importing = true
        member.save!

        Sidekiq::Testing.inline! { project.after_import }

        expect(member.user.authorized_project?(project)).to be true
      end
    end

    context 'branch protection' do
      let_it_be(:namespace) { create(:namespace) }

      let_it_be(:project) { create(:project, :repository, namespace: namespace) }

      before do
        create(:import_state, :started, project: project)
      end

      it 'does not protect when branch protection is disabled' do
        expect(project.namespace).to receive(:default_branch_protection_settings).and_return(Gitlab::Access::BranchProtection.protection_none)

        project.after_import

        expect(project.protected_branches).to be_empty
      end

      it "gives developer access to push when branch protection is set to 'developers can push'" do
        expect(project.namespace).to receive(:default_branch_protection_settings).and_return(Gitlab::Access::BranchProtection.protection_partial)

        project.after_import

        expect(project.protected_branches).not_to be_empty
        expect(project.default_branch).to eq(project.protected_branches.first.name)
        expect(project.protected_branches.first.push_access_levels.map(&:access_level)).to eq([Gitlab::Access::DEVELOPER])
      end

      it "gives developer access to merge when branch protection is set to 'developers can merge'" do
        expect(project.namespace).to receive(:default_branch_protection_settings).and_return(Gitlab::Access::BranchProtection.protected_against_developer_pushes)

        project.after_import

        expect(project.protected_branches).not_to be_empty
        expect(project.default_branch).to eq(project.protected_branches.first.name)
        expect(project.protected_branches.first.merge_access_levels.map(&:access_level)).to eq([Gitlab::Access::DEVELOPER])
      end

      it 'protects default branch' do
        project.after_import

        expect(project.protected_branches).not_to be_empty
        expect(project.default_branch).to eq(project.protected_branches.first.name)
        expect(project.protected_branches.first.push_access_levels.map(&:access_level)).to eq([Gitlab::Access::MAINTAINER])
        expect(project.protected_branches.first.merge_access_levels.map(&:access_level)).to eq([Gitlab::Access::MAINTAINER])
      end
    end

    describe 'project target platforms detection' do
      before do
        create(:import_state, :started, project: project)
      end

      it 'calls enqueue_record_project_target_platforms' do
        expect(project).to receive(:enqueue_record_project_target_platforms)

        project.after_import
      end
    end
  end

  describe '#reset_counters_and_iids' do
    let(:project) { build(:project) }

    it 'runs the correct hooks' do
      expect(project).to receive(:update_project_counter_caches)
      expect(InternalId).to receive(:flush_records!).with(project: project)

      project.reset_counters_and_iids
    end
  end

  describe '#update_project_counter_caches' do
    let(:project) { create(:project) }

    it 'updates all project counter caches' do
      expect_any_instance_of(Projects::OpenIssuesCountService)
        .to receive(:refresh_cache)
        .and_call_original

      expect_any_instance_of(Projects::OpenMergeRequestsCountService)
        .to receive(:refresh_cache)
        .and_call_original

      project.update_project_counter_caches
    end
  end

  describe '#default_branch' do
    context 'with default_branch_name' do
      let_it_be_with_refind(:root_group) { create(:group) }
      let_it_be_with_refind(:project_group) { create(:group, parent: root_group) }
      let_it_be_with_refind(:project) { create(:project, path: 'avatar', namespace: project_group) }

      where(:instance_branch, :root_group_branch, :project_group_branch, :project_branch) do
        ''      | nil           | nil            | nil
        nil     | nil           | nil            | nil
        'main'  | nil           | nil            | 'main'
        'main'  | 'root_branch' | nil            | 'root_branch'
        'main'  | 'root_branch' | 'group_branch' | 'group_branch'
      end

      with_them do
        before do
          allow(Gitlab::CurrentSettings).to receive(:default_branch_name).and_return(instance_branch)
          root_group.namespace_settings.update!(default_branch_name: root_group_branch)
          project_group.namespace_settings.update!(default_branch_name: project_group_branch)
        end

        it { expect(project.default_branch).to eq(project_branch) }
      end
    end
  end

  describe '#to_ability_name' do
    it 'returns project' do
      project = build(:project_empty_repo)

      expect(project.to_ability_name).to eq('project')
    end
  end

  describe '#execute_hooks' do
    let(:data) { { ref: 'refs/heads/master', data: 'data' } }

    it 'executes active projects hooks with the specified scope' do
      hook = create(:project_hook, merge_requests_events: false, push_events: true)
      expect(ProjectHook).to receive(:select_active)
        .with(:push_hooks, data)
        .and_return([hook])
      project = create(:project, hooks: [hook])

      expect_any_instance_of(ProjectHook).to receive(:async_execute).once

      project.execute_hooks(data, :push_hooks)
    end

    it 'does not execute project hooks that dont match the specified scope' do
      hook = create(:project_hook, merge_requests_events: true, push_events: false)
      project = create(:project, hooks: [hook])

      expect_any_instance_of(ProjectHook).not_to receive(:async_execute).once

      project.execute_hooks(data, :push_hooks)
    end

    it 'does not execute project hooks which are not active' do
      hook = create(:project_hook, push_events: true)
      expect(ProjectHook).to receive(:select_active)
        .with(:push_hooks, data)
        .and_return([])
      project = create(:project, hooks: [hook])

      expect_any_instance_of(ProjectHook).not_to receive(:async_execute).once

      project.execute_hooks(data, :push_hooks)
    end

    it 'executes hooks which were backed off and are no longer backed off' do
      project = create(:project)
      hook = create(:project_hook, project: project, push_events: true)
      WebHooks::AutoDisabling::FAILURE_THRESHOLD.succ.times { hook.backoff! }

      expect_any_instance_of(ProjectHook).to receive(:async_execute).once

      travel_to(hook.disabled_until + 1.second) do
        project.execute_hooks(data, :push_hooks)
      end
    end

    it 'executes the system hooks with the specified scope' do
      expect_any_instance_of(SystemHooksService).to receive(:execute_hooks).with(data, :merge_request_hooks)

      project = build(:project)
      project.execute_hooks(data, :merge_request_hooks)
    end

    it 'executes the system hooks when inside a transaction' do
      allow_any_instance_of(WebHookService).to receive(:execute)

      create(:system_hook, merge_requests_events: true)

      project = build(:project)

      # Ideally, we'd test that `WebHookWorker.jobs.size` increased by 1,
      # but since the entire spec run takes place in a transaction, we never
      # actually get to the `after_commit` hook that queues these jobs.
      expect do
        project.transaction do
          project.execute_hooks(data, :merge_request_hooks)
        end
      end.not_to raise_error # Sidekiq::Worker::EnqueueFromTransactionError
    end
  end

  describe '#execute_integrations' do
    let(:integration) { create(:integrations_slack, push_events: true, merge_requests_events: false, active: true) }

    it 'executes integrations with the specified scope' do
      data = 'any data'

      expect_next_found_instance_of(Integrations::Slack) do |instance|
        expect(instance).to receive(:async_execute).with(data).once
      end

      integration.project.execute_integrations(data, :push_hooks)
    end

    it 'does not execute integration that don\'t match the specified scope' do
      expect(Integrations::Slack).not_to receive(:allocate).and_wrap_original do |method|
        method.call.tap do |instance|
          expect(instance).not_to receive(:async_execute)
        end
      end

      integration.project.execute_integrations(anything, :merge_request_hooks)
    end

    it 'does not trigger extra queries when called multiple times' do
      integration.project.execute_integrations({}, :push_hooks)

      recorder = ActiveRecord::QueryRecorder.new do
        integration.project.execute_integrations({}, :push_hooks)
      end

      expect(recorder.count).to be_zero
    end

    context 'with a CI integration' do
      let!(:ci_integration) do
        create(:jenkins_integration, push_events: true, active: true, project: integration.project)
      end

      it 'executes the integrations' do
        [Integrations::Jenkins, Integrations::Slack].each do |integration_type|
          expect_next_found_instance_of(integration_type) do |instance|
            expect(instance).to receive(:async_execute).with('data').once
          end
        end

        integration.project.execute_integrations('data', :push_hooks)
      end

      context 'and skipping ci' do
        it 'does not execute ci integrations' do
          expect_next_found_instance_of(Integrations::Jenkins) do |instance|
            expect(instance).not_to receive(:async_execute)
          end

          expect_next_found_instance_of(Integrations::Slack) do |instance|
            expect(instance).to receive(:async_execute).with('data').once
          end

          integration.project.execute_integrations('data', :push_hooks, skip_ci: true)
        end
      end
    end
  end

  describe '#jenkins_integration_active?' do
    let_it_be_with_reload(:project) { create(:project) }
    let_it_be_with_reload(:integration) { create(:jenkins_integration, push_events: true, project: project) }

    subject { project.jenkins_integration_active? }

    before do
      integration.update!(active: active)
    end

    context 'when a project has an activated Jenkins integration' do
      let(:active) { true }

      it { is_expected.to be_truthy }
    end

    context 'when a project has an inactive Jenkins integration' do
      let(:active) { false }

      it { is_expected.to be_falsey }
    end

    context 'when a project does not have a Jenkins integration at all' do
      let(:active) { true }

      before do
        integration.destroy!
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#has_active_hooks?' do
    let_it_be_with_refind(:project) { create(:project) }

    it { expect(project.has_active_hooks?).to eq(false) }

    it 'returns true when a matching push hook exists' do
      create(:project_hook, push_events: true, project: project)

      expect(project.has_active_hooks?(:merge_request_hooks)).to eq(false)
      expect(project.has_active_hooks?).to eq(true)
    end

    it 'returns true when a matching system hook exists' do
      create(:system_hook, push_events: true)

      expect(project.has_active_hooks?(:merge_request_hooks)).to eq(false)
      expect(project.has_active_hooks?).to eq(true)
    end

    it 'returns true when a plugin exists' do
      expect(Gitlab::FileHook).to receive(:any?).twice.and_return(true)

      expect(project.has_active_hooks?(:merge_request_hooks)).to eq(true)
      expect(project.has_active_hooks?).to eq(true)
    end

    context 'with :emoji_hooks scope' do
      it 'returns true when a matching emoji hook exists' do
        create(:project_hook, emoji_events: true, project: project)

        expect(project.has_active_hooks?(:emoji_hooks)).to eq(true)
      end
    end

    context 'with :access_token_hooks scope' do
      it 'returns true when a matching access token hook exists' do
        create(:project_hook, resource_access_token_events: true, project: project)

        expect(project.has_active_hooks?(:resource_access_token_hooks)).to eq(true)
      end
    end
  end

  describe '#has_active_integrations?' do
    let_it_be_with_refind(:project) { create(:project) }

    it { expect(project.has_active_integrations?).to eq(false) }

    it 'returns true when a matching service exists' do
      create(:custom_issue_tracker_integration, push_events: true, merge_requests_events: false, project: project)

      expect(project.has_active_integrations?(:merge_request_hooks)).to eq(false)
      expect(project.has_active_integrations?).to eq(true)
    end

    it 'caches matching integrations' do
      create(:custom_issue_tracker_integration, push_events: true, merge_requests_events: false, project: project)

      expect(project.has_active_integrations?(:merge_request_hooks)).to eq(false)
      expect(project.has_active_integrations?).to eq(true)

      count = ActiveRecord::QueryRecorder.new do
        expect(project.has_active_integrations?(:merge_request_hooks)).to eq(false)
        expect(project.has_active_integrations?).to eq(true)
      end.count

      expect(count).to eq(0)
    end
  end

  describe '#badges' do
    let(:project_group) { create(:group) }
    let(:project) { create(:project, path: 'avatar', namespace: project_group) }

    before do
      create_list(:project_badge, 2, project: project)
      create(:group_badge, group: project_group)
    end

    it 'returns the project and the project group badges' do
      create(:group_badge, group: create(:group))

      expect(Badge.count).to eq 4
      expect(project.badges.count).to eq 3
    end

    context 'with nested_groups' do
      let(:parent_group) { create(:group) }

      before do
        create_list(:group_badge, 2, group: project_group)
        project_group.update!(parent: parent_group)
      end

      it 'returns the project and the project nested groups badges' do
        expect(project.badges.count).to eq 5
      end
    end
  end

  context 'with cross internal project merge requests' do
    let(:project) { create(:project, :repository, :internal) }
    let(:forked_project) { fork_project(project, nil, repository: true) }
    let(:user) { double(:user) }

    it "does not endlessly loop for internal projects with MRs to each other", :sidekiq_inline do
      allow(user).to receive(:can?).and_return(true, false, true)
      allow(user).to receive(:id).and_return(1)

      create(
        :merge_request,
        target_project: project,
        target_branch: 'merge-test',
        source_project: forked_project,
        source_branch: 'merge-test',
        allow_collaboration: true
      )

      create(
        :merge_request,
        target_project: forked_project,
        target_branch: 'merge-test',
        source_project: project,
        source_branch: 'merge-test',
        allow_collaboration: true
      )

      expect(user).to receive(:can?).at_most(5).times
      project.branch_allows_collaboration?(user, "merge-test")
    end
  end

  describe '#branch_allows_collaboration?' do
    context 'when there are open merge requests that have their source/target branches point to each other' do
      let_it_be(:project) { create(:project, :repository) }
      let_it_be(:developer) { create(:user) }
      let_it_be(:reporter) { create(:user) }
      let_it_be(:guest) { create(:user) }

      before_all do
        create(
          :merge_request,
          target_project: project,
          target_branch: 'master',
          source_project: project,
          source_branch: 'merge-test',
          allow_collaboration: true
        )

        create(
          :merge_request,
          target_project: project,
          target_branch: 'merge-test',
          source_project: project,
          source_branch: 'master',
          allow_collaboration: true
        )

        project.add_developer(developer)
        project.add_reporter(reporter)
        project.add_guest(guest)
      end

      shared_examples_for 'successful check' do
        it 'does not go into an infinite loop' do
          expect { project.branch_allows_collaboration?(user, 'master') }
            .not_to raise_error
        end
      end

      context 'when user is a developer' do
        let(:user) { developer }

        it_behaves_like 'successful check'
      end

      context 'when user is a reporter' do
        let(:user) { reporter }

        it_behaves_like 'successful check'
      end

      context 'when user is a guest' do
        let(:user) { guest }

        it_behaves_like 'successful check'
      end
    end
  end

  context 'with cross project merge requests' do
    let(:user) { create(:user) }
    let(:target_project) { create(:project, :repository) }
    let(:project) { fork_project(target_project, nil, repository: true) }
    let!(:local_merge_request) do
      create(
        :merge_request,
        target_project: project,
        target_branch: 'target-branch',
        source_project: project,
        source_branch: 'awesome-feature-1',
        allow_collaboration: true
      )
    end

    let!(:merge_request) do
      create(
        :merge_request,
        author: author,
        state_id: state_id,
        target_project: target_project,
        target_branch: 'target-branch',
        source_project: project,
        source_branch: 'awesome-feature-1',
        allow_collaboration: true
      )
    end

    let(:author) { project.creator }
    let(:state_id) { MergeRequest.available_states[:opened] }

    before do
      target_project.add_developer(user)
    end

    describe '#merge_requests_allowing_push_to_user' do
      it 'returns open merge requests for which the user has developer access to the target project' do
        expect(project.merge_requests_allowing_push_to_user(user)).to include(merge_request)
      end

      context 'when the merge requests are closed' do
        let(:state_id) { MergeRequest.available_states[:closed] }

        it 'does not include closed merge requests' do
          expect(project.merge_requests_allowing_push_to_user(user)).to be_empty
        end
      end

      it 'does not include merge requests for guest users' do
        guest = create(:user)
        target_project.add_guest(guest)

        expect(project.merge_requests_allowing_push_to_user(guest)).to be_empty
      end

      it 'does not include the merge request for other users' do
        other_user = create(:user)

        expect(project.merge_requests_allowing_push_to_user(other_user)).to be_empty
      end

      it 'is empty when no user is passed' do
        expect(project.merge_requests_allowing_push_to_user(nil)).to be_empty
      end
    end

    describe '#any_branch_allows_collaboration?' do
      context 'when there is an open merge request allowing collaboration' do
        it 'allows access', :sidekiq_might_not_need_inline do
          expect(project.any_branch_allows_collaboration?(user))
            .to be_truthy
        end

        context 'when the merge request author is not allowed to push_code' do
          let(:author) { create(:user) }

          it 'returns false' do
            expect(project.any_branch_allows_collaboration?(user))
              .to be_falsey
          end
        end

        context 'when the merge request is closed' do
          let(:state_id) { MergeRequest.available_states[:closed] }

          it 'returns false' do
            expect(project.any_branch_allows_collaboration?(user))
              .to be_falsey
          end
        end

        context 'when the merge request is merged' do
          let(:state_id) { MergeRequest.available_states[:merged] }

          it 'returns false' do
            expect(project.any_branch_allows_collaboration?(user))
              .to be_falsey
          end
        end
      end
    end

    describe '#branch_allows_collaboration?' do
      it 'allows access if the user can merge the merge request', :sidekiq_might_not_need_inline do
        expect(project.branch_allows_collaboration?(user, 'awesome-feature-1'))
          .to be_truthy
      end

      it 'does not allow guest users access' do
        guest = create(:user)
        target_project.add_guest(guest)

        expect(project.branch_allows_collaboration?(guest, 'awesome-feature-1'))
          .to be_falsy
      end

      it 'does not allow access to branches for which the merge request was closed' do
        create(
          :merge_request,
          :closed,
          target_project: target_project,
          target_branch: 'target-branch',
          source_project: project,
          source_branch: 'rejected-feature-1',
          allow_collaboration: true
        )

        expect(project.branch_allows_collaboration?(user, 'rejected-feature-1'))
          .to be_falsy
      end

      it 'does not allow access if the user cannot merge the merge request' do
        create(:protected_branch, :maintainers_can_push, project: target_project, name: 'target-branch')

        expect(project.branch_allows_collaboration?(user, 'awesome-feature-1'))
          .to be_falsy
      end

      context 'when the requeststore is active', :request_store do
        it 'only queries per project across instances' do
          control = ActiveRecord::QueryRecorder.new { project.branch_allows_collaboration?(user, 'awesome-feature-1') }

          expect { 2.times { described_class.find(project.id).branch_allows_collaboration?(user, 'awesome-feature-1') } }
            .not_to exceed_query_limit(control).with_threshold(2)
        end
      end

      context 'when the merge request author is not allowed to push_code' do
        let(:author) { create(:user) }

        it 'returns false' do
          expect(project.branch_allows_collaboration?(user, 'awesome-feature-1'))
            .to be_falsey
        end
      end
    end
  end

  describe '#external_authorization_classification_label' do
    it 'falls back to the default when none is configured' do
      enable_external_authorization_service_check

      expect(build(:project).external_authorization_classification_label)
        .to eq('default_label')
    end

    it 'returns the classification label if it was configured on the project' do
      enable_external_authorization_service_check

      project = build(:project, external_authorization_classification_label: 'hello')

      expect(project.external_authorization_classification_label)
        .to eq('hello')
    end
  end

  describe "#pages_https_only?" do
    subject { build(:project) }

    context "when HTTPS pages are disabled" do
      it { is_expected.not_to be_pages_https_only }
    end

    context "when HTTPS pages are enabled", :https_pages_enabled do
      it { is_expected.to be_pages_https_only }
    end
  end

  describe "#pages_https_only? validation", :https_pages_enabled do
    subject(:project) do
      # set-up dirty object:
      create(:project, pages_https_only: false).tap do |p|
        p.pages_https_only = true
      end
    end

    context "when no domains are associated" do
      it { is_expected.to be_valid }
    end

    context "when domains including keys and certificates are associated" do
      before do
        allow(project)
          .to receive(:pages_domains)
          .and_return([instance_double(PagesDomain, https?: true)])
      end

      it { is_expected.to be_valid }
    end

    context "when domains including no keys or certificates are associated" do
      before do
        allow(project)
          .to receive(:pages_domains)
          .and_return([instance_double(PagesDomain, https?: false)])
      end

      it { is_expected.not_to be_valid }
    end
  end

  describe '#pages_url' do
    let_it_be(:project) { create(:project) }

    let(:pages_url_config) { nil }
    let(:url_builder) { ::Gitlab::Pages::UrlBuilder.new(project, pages_url_config) }

    subject(:pages_url) { project.pages_url(pages_url_config) }

    it "lets URL builder handle the URL resolution" do
      expect(::Gitlab::Pages::UrlBuilder).to receive(:new).with(project, pages_url_config).and_return(url_builder)
      expect(url_builder).to receive(:pages_url).and_return('http://namespace1.example.com/project-1/foo')
      expect(pages_url).to eq('http://namespace1.example.com/project-1/foo')
    end

    context "when a config argument is passed" do
      let(:pages_url_config) { { path_prefix: 'foo' } }

      it "lets URL builder handle the URL resolution" do
        expect(::Gitlab::Pages::UrlBuilder).to receive(:new).with(project, pages_url_config).and_return(url_builder)
        expect(url_builder).to receive(:pages_url).and_return('http://namespace1.example.com/project-1/foo')
        expect(pages_url).to eq('http://namespace1.example.com/project-1/foo')
      end
    end
  end

  describe '#toggle_ci_cd_settings!' do
    it 'toggles the value on #settings' do
      project = create(:project, group_runners_enabled: false)

      expect(project.group_runners_enabled).to be false

      project.toggle_ci_cd_settings!(:group_runners_enabled)

      expect(project.group_runners_enabled).to be true
    end
  end

  describe '#gitlab_deploy_token' do
    let(:project) { create(:project) }

    subject(:gitlab_deploy_token) { project.gitlab_deploy_token }

    context 'when there is a gitlab deploy token associated' do
      let!(:deploy_token) { create(:deploy_token, :gitlab_deploy_token, projects: [project]) }

      it { is_expected.to eq(deploy_token) }
    end

    context 'when there is no a gitlab deploy token associated' do
      it { is_expected.to be_nil }
    end

    context 'when there is a gitlab deploy token associated but is has been revoked' do
      let!(:deploy_token) { create(:deploy_token, :gitlab_deploy_token, :revoked, projects: [project]) }

      it { is_expected.to be_nil }
    end

    context 'when there is a gitlab deploy token associated but it is expired' do
      let!(:deploy_token) { create(:deploy_token, :gitlab_deploy_token, :expired, projects: [project]) }

      it { is_expected.to be_nil }
    end

    context 'when there is a deploy token associated with a different name' do
      let!(:deploy_token) { create(:deploy_token, projects: [project]) }

      it { is_expected.to be_nil }
    end

    context 'when there is a deploy token associated to a different project' do
      let(:project_2) { create(:project) }
      let!(:deploy_token) { create(:deploy_token, :gitlab_deploy_token, projects: [project_2]) }

      it { is_expected.to be_nil }
    end

    context 'when the project group has a gitlab deploy token associated' do
      let(:group) { create(:group) }
      let(:project) { create(:project, group: group) }
      let!(:deploy_token) { create(:deploy_token, :gitlab_deploy_token, :group, groups: [group]) }

      it { is_expected.to eq(deploy_token) }
    end

    context 'when the project and its group has a gitlab deploy token associated' do
      let(:group) { create(:group) }
      let(:project) { create(:project, group: group) }
      let!(:project_deploy_token) { create(:deploy_token, :gitlab_deploy_token, projects: [project]) }
      let!(:group_deploy_token) { create(:deploy_token, :gitlab_deploy_token, :group, groups: [group]) }

      it { is_expected.to eq(project_deploy_token) }
    end
  end

  context 'with uploads' do
    it_behaves_like 'model with uploads', true do
      let(:model_object) { create(:project, :with_avatar) }
      let(:upload_attribute) { :avatar }
      let(:uploader_class) { AttachmentUploader }
    end
  end

  describe '#members_among' do
    let(:users) { create_list(:user, 3) }

    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, namespace: group) }

    before do
      project.add_guest(users.first)
      project.group.add_maintainer(users.last)
    end

    context 'when users is an Array' do
      it 'returns project members among the users' do
        expect(project.members_among(users)).to eq([users.first, users.last])
      end

      it 'maintains input order' do
        expect(project.members_among(users.reverse)).to eq([users.last, users.first])
      end

      it 'returns empty array if users is empty' do
        result = project.members_among([])

        expect(result).to be_empty
      end
    end

    context 'when users is a relation' do
      it 'returns project members among the users' do
        result = project.members_among(User.where(id: users.map(&:id)))

        expect(result).to be_a(ActiveRecord::Relation)
        expect(result).to eq([users.first, users.last])
      end

      it 'returns empty relation if users is empty' do
        result = project.members_among(User.none)

        expect(result).to be_a(ActiveRecord::Relation)
        expect(result).to be_empty
      end
    end
  end

  describe '#find_or_initialize_integrations' do
    let_it_be(:subject) { create(:project) }

    it 'avoids N+1 database queries' do
      control = ActiveRecord::QueryRecorder.new { subject.find_or_initialize_integrations }

      expect(control.count).to be <= 4
    end

    it 'avoids N+1 database queries with more available integrations' do
      allow(Integration).to receive(:available_integration_names).and_return(%w[pushover])
      control = ActiveRecord::QueryRecorder.new { subject.find_or_initialize_integrations }

      allow(Integration).to receive(:available_integration_names).and_call_original
      expect { subject.find_or_initialize_integrations }.not_to exceed_query_limit(control)
    end

    context 'with disabled integrations' do
      before do
        allow(Integration).to receive(:available_integration_names).and_return(%w[prometheus pushover teamcity])
        allow(subject).to receive(:disabled_integrations).and_return(%w[prometheus])
      end

      it 'returns only enabled integrations sorted' do
        expect(subject.find_or_initialize_integrations).to match [
          have_attributes(title: 'JetBrains TeamCity'),
          have_attributes(title: 'Pushover')
        ]
      end
    end

    context 'with instance specific integration' do
      it 'does not contain instance specific integrations' do
        expect(subject.find_or_initialize_integrations).not_to include(
          have_attributes(title: 'Beyond Identity')
        )
      end
    end
  end

  describe '#disabled_integrations' do
    subject { build(:project).disabled_integrations }

    it { is_expected.to include('zentao') }
  end

  describe '#find_or_initialize_integration' do
    it 'avoids N+1 database queries' do
      allow(Integration).to receive(:available_integration_names).and_return(%w[prometheus pushover])

      control = ActiveRecord::QueryRecorder.new { subject.find_or_initialize_integration('prometheus') }

      allow(Integration).to receive(:available_integration_names).and_call_original

      expect { subject.find_or_initialize_integration('prometheus') }.not_to exceed_query_limit(control)
    end

    it 'returns nil if integration is disabled' do
      allow(subject).to receive(:disabled_integrations).and_return(%w[prometheus])

      expect(subject.find_or_initialize_integration('prometheus')).to be_nil
    end

    it 'returns nil if integration does not exist' do
      expect(subject.find_or_initialize_integration('non-existing')).to be_nil
    end

    context 'with an existing integration' do
      subject { create(:project) }

      before do
        create(:prometheus_integration, project: subject, api_url: 'https://prometheus.project.com/')
      end

      it 'retrieves the integration' do
        expect(subject.find_or_initialize_integration('prometheus').api_url).to eq('https://prometheus.project.com/')
      end
    end

    context 'with an instance-level integration' do
      before do
        create(:prometheus_integration, :instance, api_url: 'https://prometheus.instance.com/')
      end

      it 'builds the integration from the instance integration' do
        expect(subject.find_or_initialize_integration('prometheus').api_url).to eq('https://prometheus.instance.com/')
      end
    end

    context 'without an existing integration or instance-level' do
      it 'builds the integration' do
        expect(subject.find_or_initialize_integration('prometheus')).to be_a(::Integrations::Prometheus)
        expect(subject.find_or_initialize_integration('prometheus').api_url).to be_nil
      end
    end

    context 'with instance specific integrations' do
      it 'does not create an instance specific integration' do
        expect(subject.find_or_initialize_integration('beyond_identity')).to be_nil
      end
    end
  end

  describe '.for_group' do
    it 'returns the projects for a given group' do
      group = create(:group)
      project = create(:project, namespace: group)

      expect(described_class.for_group(group)).to eq([project])
    end
  end

  describe '.for_group_and_its_ancestor_groups' do
    it 'returns projects for group and its ancestors' do
      group_1 = create(:group)
      project_1 = create(:project, namespace: group_1)
      group_2 = create(:group, parent: group_1)
      project_2 = create(:project, namespace: group_2)
      group_3 = create(:group, parent: group_2)
      project_3 = create(:project, namespace: group_2)
      group_4 = create(:group, parent: group_3)
      create(:project, namespace: group_4)

      expect(described_class.for_group_and_its_ancestor_groups(group_3)).to match_array([project_1, project_2, project_3])
    end
  end

  describe '.pending_data_repair_analysis' do
    it 'returns projects that are not in ContainerRegistry::DataRepairDetail' do
      project_1 = create(:project)
      project_2 = create(:project)

      expect(described_class.pending_data_repair_analysis).to match_array([project_1, project_2])

      create(:container_registry_data_repair_detail, project: project_1)

      expect(described_class.pending_data_repair_analysis).to match_array([project_2])
    end
  end

  describe '.with_package_registry_enabled' do
    subject { described_class.with_package_registry_enabled }

    it 'returns projects with the package registry enabled' do
      project_1 = create(:project)
      create(:project, package_registry_access_level: ProjectFeature::DISABLED, packages_enabled: false)

      expect(subject).to contain_exactly(project_1)
    end
  end

  describe '.with_public_package_registry' do
    let_it_be(:project) { create(:project, package_registry_access_level: ::ProjectFeature::PUBLIC) }
    let_it_be(:other_project) { create(:project, package_registry_access_level: ::ProjectFeature::ENABLED) }

    subject { described_class.with_public_package_registry }

    it { is_expected.to contain_exactly(project) }
  end

  describe '.not_a_fork' do
    let_it_be(:project) { create(:project, :public) }

    subject(:not_a_fork) { described_class.not_a_fork }

    it 'returns projects which are not forks' do
      fork_project(project)

      expect(not_a_fork).to contain_exactly(project)
    end
  end

  describe '.deployments' do
    subject { project.deployments }

    let(:project) { create(:project, :repository) }

    before do
      allow_any_instance_of(Deployment).to receive(:create_ref)
    end

    context 'when there is a deployment record with created status' do
      let(:deployment) { create(:deployment, :created, project: project) }

      it 'does not return the record' do
        is_expected.to be_empty
      end
    end

    context 'when there is a deployment record with running status' do
      let(:deployment) { create(:deployment, :running, project: project) }

      it 'does not return the record' do
        is_expected.to be_empty
      end
    end

    context 'when there is a deployment record with success status' do
      let(:deployment) { create(:deployment, :success, project: project) }

      it 'returns the record' do
        is_expected.to eq([deployment])
      end
    end
  end

  describe '#snippets_visible?' do
    it 'returns true when a logged in user can read snippets' do
      project = create(:project, :public)
      user = create(:user)

      expect(project.snippets_visible?(user)).to eq(true)
    end

    it 'returns true when an anonymous user can read snippets' do
      project = create(:project, :public)

      expect(project.snippets_visible?).to eq(true)
    end

    it 'returns false when a user can not read snippets' do
      project = create(:project, :private)
      user = create(:user)

      expect(project.snippets_visible?(user)).to eq(false)
    end
  end

  describe '#all_clusters' do
    let(:project) { create(:project) }
    let(:cluster) { create(:cluster, cluster_type: :project_type, projects: [project]) }

    subject { project.all_clusters }

    it 'returns project level cluster' do
      expect(subject).to eq([cluster])
    end

    context 'project belongs to a group' do
      let(:group_cluster) { create(:cluster, :group) }
      let(:group) { group_cluster.group }
      let(:project) { create(:project, group: group) }

      it 'returns clusters for groups of this project' do
        expect(subject).to contain_exactly(cluster, group_cluster)
      end
    end

    context 'project is hosted on instance with integrated cluster' do
      let(:group_cluster) { create(:cluster, :group) }
      let(:instance_cluster) { create(:cluster, :instance) }
      let(:group) { group_cluster.group }
      let(:project) { create(:project, group: group) }

      it 'returns all available clusters for this project' do
        expect(subject).to contain_exactly(cluster, group_cluster, instance_cluster)
      end
    end
  end

  describe '#object_pool_params' do
    let(:project) { create(:project, :repository, :public) }

    subject { project.object_pool_params }

    context 'when the objects cannot be pooled' do
      let(:project) { create(:project, :repository, :private) }

      it { is_expected.to be_empty }
    end

    context 'when a pool is created' do
      it 'returns that pool repository' do
        expect(subject).not_to be_empty
        expect(subject[:pool_repository]).to be_persisted

        expect(project.reload.pool_repository).to eq(subject[:pool_repository])
      end
    end
  end

  describe '#git_objects_poolable?' do
    subject { project }

    context 'when not using hashed storage' do
      let(:project) { create(:project, :legacy_storage, :public, :repository) }

      it { is_expected.not_to be_git_objects_poolable }
    end

    context 'when the project is private' do
      let(:project) { create(:project, :private) }

      it { is_expected.not_to be_git_objects_poolable }
    end

    context 'when the project is public' do
      let(:project) { create(:project, :repository, :public) }

      it { is_expected.to be_git_objects_poolable }
    end

    context 'when the project is internal' do
      let(:project) { create(:project, :repository, :internal) }

      it { is_expected.to be_git_objects_poolable }
    end

    context 'when objects are poolable' do
      let(:project) { create(:project, :repository, :public) }

      it { is_expected.to be_git_objects_poolable }
    end
  end

  describe '#swap_pool_repository!' do
    subject(:swap_pool_repository!) { project.swap_pool_repository! }

    let_it_be_with_reload(:project) { create(:project, :empty_repo) }
    let_it_be(:shard_to) { create(:shard, name: 'test_second_storage') }

    let(:disk_path1) { '@pool/aa/bb' }
    let(:disk_path2) { disk_path1 }

    let!(:pool1) { create(:pool_repository, disk_path: disk_path1, source_project: project) }
    let!(:pool2) { create(:pool_repository, disk_path: disk_path2, shard: shard_to, source_project: project) }
    let(:project_pool) { pool1 }
    let(:repository_storage) { shard_to.name }

    before do
      stub_storage_settings('test_second_storage' => {})

      project.update!(pool_repository: project_pool, repository_storage: repository_storage)
    end

    shared_examples 'no pool repository swap' do
      it 'does not change pool repository for the project' do
        expect { swap_pool_repository! }.not_to change { project.reload.pool_repository }
      end
    end

    it 'moves project to the new pool repository' do
      expect { swap_pool_repository! }.to change { project.reload.pool_repository }.from(pool1).to(pool2)
    end

    context 'when repository does not exist' do
      let(:project) { build(:project) }

      it_behaves_like 'no pool repository swap'
    end

    context 'when project does not have a pool repository' do
      let(:project_pool) { nil }

      it_behaves_like 'no pool repository swap'
    end

    context 'when project pool is on the same shard as repository' do
      let(:project_pool) { pool2 }

      it_behaves_like 'no pool repository swap'
    end

    context 'when pool repository for shard is missing' do
      let(:pool2) { nil }

      it 'raises record not found error' do
        expect { swap_pool_repository! }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when pool repository has a different disk path' do
      let(:disk_path2) { '@pool/different' }

      it 'raises record not found error' do
        expect { swap_pool_repository! }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '#leave_pool_repository' do
    let(:pool) { create(:pool_repository) }
    let(:project) { create(:project, :repository, pool_repository: pool) }

    subject { project.leave_pool_repository }

    it 'removes the membership and disconnects alternates' do
      expect(pool).to receive(:unlink_repository).with(project.repository, disconnect: true).and_call_original

      subject

      expect(pool.member_projects.reload).not_to include(project)
    end

    context 'when the project is pending delete' do
      it 'removes the membership and does not disconnect alternates' do
        project.pending_delete = true

        expect(pool).to receive(:unlink_repository).with(project.repository, disconnect: false).and_call_original

        subject

        expect(pool.member_projects.reload).not_to include(project)
      end
    end
  end

  describe '#link_pool_repository' do
    let(:pool) { create(:pool_repository) }
    let(:project) { build(:project, :empty_repo, pool_repository: pool) }

    subject { project.link_pool_repository }

    it 'links pool repository to project repository' do
      expect(pool).to receive(:link_repository).with(project.repository)

      subject
    end

    context 'when pool repository is missing' do
      let(:pool) { nil }

      it 'does not link anything' do
        allow_next_instance_of(PoolRepository) do |pool_repository|
          expect(pool_repository).not_to receive(:link_repository)
        end

        subject
      end
    end

    context 'when pool repository is on the different shard as project repository' do
      let(:pool) { create(:pool_repository, shard: create(:shard, name: 'new')) }

      it 'does not link anything' do
        expect(pool).not_to receive(:link_repository)

        subject
      end
    end
  end

  describe '#check_personal_projects_limit' do
    context 'when creating a project for a group' do
      it 'does nothing' do
        creator = build(:user)
        project = build(:project, namespace: build(:group), creator: creator)

        allow(creator)
          .to receive(:can_create_project?)
          .and_return(false)

        project.check_personal_projects_limit

        expect(project.errors).to be_empty
      end
    end

    context 'when the user is not allowed to create a personal project' do
      let(:user) { build(:user) }
      let(:project) { build(:project, creator: user) }

      before do
        allow(user)
          .to receive(:can_create_project?)
          .and_return(false)
      end

      context 'when the project limit is zero' do
        it 'adds a validation error' do
          allow(user)
            .to receive(:projects_limit)
            .and_return(0)

          project.check_personal_projects_limit

          expect(project.errors[:limit_reached].first)
            .to eq('You cannot create projects in your personal namespace. Contact your GitLab administrator.')
        end
      end

      context 'when the project limit is greater than zero' do
        it 'adds a validation error' do
          allow(user)
            .to receive(:projects_limit)
            .and_return(5)

          project.check_personal_projects_limit

          expect(project.errors[:limit_reached].first)
            .to eq("You've reached your limit of 5 projects created. Contact your GitLab administrator.")
        end
      end
    end

    context 'when the user is allowed to create personal projects' do
      it 'does nothing' do
        user = build(:user)
        project = build(:project, creator: user)

        allow(user)
          .to receive(:can_create_project?)
          .and_return(true)

        project.check_personal_projects_limit

        expect(project.errors).to be_empty
      end
    end
  end

  describe '#changing_shared_runners_enabled_is_allowed' do
    where(:shared_runners_setting, :project_shared_runners_enabled, :valid_record) do
      :shared_runners_enabled     | true  | true
      :shared_runners_enabled     | false | true
      :shared_runners_disabled_and_overridable   | true  | true
      :shared_runners_disabled_and_overridable   | false | true
      :shared_runners_disabled_and_unoverridable | true  | false
      :shared_runners_disabled_and_unoverridable | false | true
    end

    with_them do
      let(:group) { create(:group, shared_runners_setting) }
      let(:project) { build(:project, namespace: group, shared_runners_enabled: project_shared_runners_enabled) }

      it 'validates the configuration' do
        expect(project.valid?).to eq(valid_record)

        unless valid_record
          expect(project.errors[:shared_runners_enabled]).to contain_exactly('cannot be enabled because parent group does not allow it')
        end
      end
    end
  end

  describe '#parent_organization_match' do
    let_it_be(:group) { create(:group, :with_organization) }

    subject(:project) { build(:project, namespace: group, organization: organization) }

    context "when project belongs to parent's organization" do
      let(:organization) { group.organization }

      it { is_expected.to be_valid }
    end

    context "when project does not belong to parent's organization" do
      let(:organization) { build(:organization) }

      it 'is not valid and adds an error message' do
        expect(project).not_to be_valid
        expect(project.errors[:organization_id]).to include("must match the parent organization's ID")
      end
    end
  end

  describe '#mark_pages_onboarding_complete' do
    let(:project) { create(:project) }

    it "creates new record and sets onboarding_complete to true if none exists yet" do
      project.mark_pages_onboarding_complete

      expect(project.pages_metadatum.reload.onboarding_complete).to eq(true)
    end

    it "overrides an existing setting" do
      pages_metadatum = project.pages_metadatum
      pages_metadatum.update!(onboarding_complete: false)

      expect do
        project.mark_pages_onboarding_complete
      end.to change { pages_metadatum.reload.onboarding_complete }.from(false).to(true)
    end
  end

  describe '#has_pool_repository?' do
    it 'returns false when it does not have a pool repository' do
      subject = create(:project, :repository)

      expect(subject.has_pool_repository?).to be false
    end

    it 'returns true when it has a pool repository' do
      pool    = create(:pool_repository, :ready)
      subject = create(:project, :repository, pool_repository: pool)

      expect(subject.has_pool_repository?).to be true
    end
  end

  describe '#access_request_approvers_to_be_notified' do
    shared_examples 'returns active, non_invited, non_requested owners/maintainers of the project' do
      specify do
        maintainer = create(:project_member, :maintainer, source: project)

        create(:project_member, :developer, project: project)
        create(:project_member, :maintainer, :invited, project: project)
        create(:project_member, :maintainer, :access_request, project: project)
        create(:project_member, :maintainer, :blocked, project: project)
        create(:project_member, :owner, :blocked, project: project)

        expect(project.access_request_approvers_to_be_notified.to_a).to match_array([maintainer, owner])
      end
    end

    context 'for a personal project' do
      let_it_be(:project) { create(:project) }
      let_it_be(:owner) { project.members.find_by(user_id: project.first_owner.id) }

      it_behaves_like 'returns active, non_invited, non_requested owners/maintainers of the project'
    end

    context 'for a project in a group' do
      let_it_be(:project) { create(:project, group: create(:group, :public)) }
      let_it_be(:owner) { create(:project_member, :owner, source: project) }

      it 'returns a maximum of ten maintainers/owners of the project in recent_sign_in descending order' do
        users = create_list(:user, 11, :with_sign_ins)

        active_maintainers_and_owners = users.map do |user|
          create(:project_member, [:maintainer, :owner].sample, user: user, project: project)
        end

        active_maintainers_and_owners_in_recent_sign_in_desc_order = project.members
                                                                            .id_in(active_maintainers_and_owners)
                                                                            .order_recent_sign_in.limit(10)

        expect(project.access_request_approvers_to_be_notified).to eq(active_maintainers_and_owners_in_recent_sign_in_desc_order)
      end

      it_behaves_like 'returns active, non_invited, non_requested owners/maintainers of the project'
    end
  end

  describe '.with_pages_deployed' do
    it 'returns only projects that have pages deployed' do
      _project_without_pages = create(:project)
      project_with_pages = create(:project)
      create(:pages_deployment, project: project_with_pages)

      expect(described_class.with_pages_deployed).to contain_exactly(project_with_pages)
    end
  end

  describe '.pages_metadata_not_migrated' do
    it 'returns only projects that have pages deployed' do
      _project_with_pages_metadata_migrated = create(:project)
      project_with_pages_metadata_not_migrated = create(:project)
      project_with_pages_metadata_not_migrated.pages_metadatum.destroy!

      expect(described_class.pages_metadata_not_migrated).to contain_exactly(project_with_pages_metadata_not_migrated)
    end
  end

  # this describe block tests the legacy behavior, it is to be removed with the
  # fix_pages_ci_variables Feature flag.
  describe '#pages_variables' do
    let(:group) { build(:group, path: 'group') }
    let(:project) { build(:project, path: 'project', namespace: group) }

    it 'returns the pages variables' do
      expect(project.pages_variables.to_hash).to eq({
        'CI_PAGES_DOMAIN' => 'example.com'
      })
    end

    context 'with fix_pages_ci_variables disabled' do
      before do
        stub_feature_flags(fix_pages_ci_variables: false)
      end

      it 'returns the pages variables' do
        expect(project.pages_variables.to_hash).to eq({
          'CI_PAGES_DOMAIN' => 'example.com',
          'CI_PAGES_URL' => 'http://group.example.com/project'
        })
      end

      it 'returns the pages variables' do
        build(
          :project_setting,
          project: project,
          pages_unique_domain_enabled: true,
          pages_unique_domain: 'unique-domain'
        )

        expect(project.pages_variables.to_hash).to eq({
          'CI_PAGES_DOMAIN' => 'example.com',
          'CI_PAGES_URL' => 'http://unique-domain.example.com'
        })
      end
    end
  end

  describe '#closest_setting' do
    shared_examples_for 'fetching closest setting' do
      let!(:namespace) { create(:namespace) }
      let!(:project) { create(:project, namespace: namespace) }

      let(:setting_name) { :some_setting }
      let(:setting) { project.closest_setting(setting_name) }

      before do
        allow(project).to receive(:read_attribute).with(setting_name).and_return(project_setting)
        allow(namespace).to receive(:closest_setting).with(setting_name).and_return(group_setting)
        stub_application_setting(setting_name => global_setting)
      end

      it 'returns closest non-nil value' do
        expect(setting).to eq(result)
      end
    end

    context 'when setting is of non-boolean type' do
      where(:global_setting, :group_setting, :project_setting, :result) do
        100 | 200 | 300 | 300
        100 | 200 | nil | 200
        100 | nil | nil | 100
        nil | nil | nil | nil
      end

      with_them do
        it_behaves_like 'fetching closest setting'
      end
    end

    context 'when setting is of boolean type' do
      where(:global_setting, :group_setting, :project_setting, :result) do
        true | true  | false | false
        true | false | nil   | false
        true | nil   | nil   | true
      end

      with_them do
        it_behaves_like 'fetching closest setting'
      end
    end
  end

  describe '#drop_visibility_level!' do
    context 'when has a group' do
      let(:group) { create(:group, visibility_level: group_visibility_level) }
      let(:project) { build(:project, namespace: group, visibility_level: project_visibility_level) }

      context 'when the group `visibility_level` is more strict' do
        let(:group_visibility_level) { Gitlab::VisibilityLevel::PRIVATE }
        let(:project_visibility_level) { Gitlab::VisibilityLevel::INTERNAL }

        it 'sets `visibility_level` value from the group' do
          expect { project.drop_visibility_level! }
            .to change { project.visibility_level }
            .to(Gitlab::VisibilityLevel::PRIVATE)
        end
      end

      context 'when the group `visibility_level` is less strict' do
        let(:group_visibility_level) { Gitlab::VisibilityLevel::INTERNAL }
        let(:project_visibility_level) { Gitlab::VisibilityLevel::PRIVATE }

        it 'does not change the value of the `visibility_level` field' do
          expect { project.drop_visibility_level! }
            .not_to change { project.visibility_level }
        end
      end
    end

    context 'when `restricted_visibility_levels` of the GitLab instance exist' do
      before do
        stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::INTERNAL])
      end

      let(:project) { build(:project, visibility_level: project_visibility_level) }

      context 'when `visibility_level` is included into `restricted_visibility_levels`' do
        let(:project_visibility_level) { Gitlab::VisibilityLevel::INTERNAL }

        it 'sets `visibility_level` value to `PRIVATE`' do
          expect { project.drop_visibility_level! }
            .to change { project.visibility_level }
            .to(Gitlab::VisibilityLevel::PRIVATE)
        end
      end

      context 'when `restricted_visibility_levels` does not include `visibility_level`' do
        let(:project_visibility_level) { Gitlab::VisibilityLevel::PUBLIC }

        it 'does not change the value of the `visibility_level` field' do
          expect { project.drop_visibility_level! }
            .to not_change { project.visibility_level }
        end
      end
    end
  end

  describe '#jira_subscription_exists?' do
    let(:project) { create(:project) }

    subject { project.jira_subscription_exists? }

    context 'jira connect subscription exists' do
      let!(:jira_connect_subscription) { create(:jira_connect_subscription, namespace: project.namespace) }

      it { is_expected.to eq(true) }
    end
  end

  describe 'with_issues_or_mrs_available_for_user' do
    before do
      described_class.delete_all
    end

    it 'returns correct projects' do
      user = create(:user)
      project1 = create(:project, :public, :merge_requests_disabled, :issues_enabled)
      project2 = create(:project, :public, :merge_requests_disabled, :issues_disabled)
      project3 = create(:project, :public, :issues_enabled, :merge_requests_enabled)
      project4 = create(:project, :private, :issues_private, :merge_requests_private)

      [project1, project2, project3, project4].each { |project| project.add_developer(user) }

      expect(described_class.with_issues_or_mrs_available_for_user(user))
        .to contain_exactly(project1, project3, project4)
    end
  end

  describe '#limited_protected_branches' do
    let(:project) { create(:project) }
    let!(:protected_branch) { create(:protected_branch, project: project) }
    let!(:another_protected_branch) { create(:protected_branch, project: project) }

    subject { project.limited_protected_branches(1) }

    it 'returns limited number of protected branches based on specified limit' do
      expect(subject.count).to eq(1)
    end
  end

  describe '#group_protected_branches' do
    subject { project.group_protected_branches }

    let(:project) { create(:project, group: group) }
    let(:group) { create(:group) }
    let(:protected_branch) { create(:protected_branch, group: group, project: nil) }

    it 'returns protected branches of the group' do
      is_expected.to match_array([protected_branch])
    end

    context 'when project belongs to namespace' do
      let(:project) { create(:project) }

      it 'returns empty relation' do
        is_expected.to be_empty
      end
    end
  end

  describe '#all_protected_branches' do
    let(:group) { create(:group) }
    let!(:group_protected_branch) { create(:protected_branch, group: group, project: nil) }
    let!(:project_protected_branch) { create(:protected_branch, project: subject) }

    subject { create(:project, group: group) }

    it 'return all protected branches' do
      expect(subject.all_protected_branches).to match_array([group_protected_branch, project_protected_branch])
    end
  end

  describe '#lfs_objects_oids' do
    let(:project) { create(:project) }
    let(:lfs_object) { create(:lfs_object) }
    let(:another_lfs_object) { create(:lfs_object) }

    subject { project.lfs_objects_oids }

    context 'when project has associated LFS objects' do
      before do
        create(:lfs_objects_project, lfs_object: lfs_object, project: project)
        create(:lfs_objects_project, lfs_object: another_lfs_object, project: project)
      end

      it 'returns OIDs of LFS objects' do
        expect(subject).to match_array([lfs_object.oid, another_lfs_object.oid])
      end

      context 'and there are specified oids' do
        subject { project.lfs_objects_oids(oids: [lfs_object.oid]) }

        it 'returns OIDs of LFS objects that match specified oids' do
          expect(subject).to eq([lfs_object.oid])
        end
      end

      it 'lfs_objects_projects associations are deleted along with project' do
        expect { project.delete }.to change(LfsObjectsProject, :count).by(-2)
      end

      it 'lfs_objects associations are unchanged when the assicated project is removed' do
        expect { project.delete }.not_to change(LfsObject, :count)
      end
    end

    context 'when project has no associated LFS objects' do
      it 'returns empty array' do
        expect(subject).to be_empty
      end
    end
  end

  describe '#prometheus_integration_active?' do
    let(:project) { create(:project) }

    subject { project.prometheus_integration_active? }

    before do
      create(:prometheus_integration, project: project, manual_configuration: manual_configuration)
    end

    context 'when project has an activated prometheus integration' do
      let(:manual_configuration) { true }

      it { is_expected.to be_truthy }
    end

    context 'when project has an inactive prometheus integration' do
      let(:manual_configuration) { false }

      it 'the integration is marked as inactive' do
        expect(subject).to be_falsey
      end
    end
  end

  describe '#add_export_job' do
    let_it_be(:user) { create(:user) }
    let_it_be_with_reload(:project) { create(:project) }

    it 'enqueues CreateionProjectExportWorker' do
      expect(Projects::ImportExport::CreateRelationExportsWorker)
        .to receive(:perform_async)
        .with(user.id, project.id, nil, { exported_by_admin: false })

      project.add_export_job(current_user: user)
    end

    context 'when user is admin', :enable_admin_mode do
      let_it_be(:user) { create(:admin) }

      it 'passes `exported_by_admin` correctly in the `params` hash' do
        expect(Projects::ImportExport::CreateRelationExportsWorker)
        .to receive(:perform_async)
        .with(user.id, project.id, nil, { exported_by_admin: true })

        project.add_export_job(current_user: user)
      end
    end

    context 'when project storage_size does not exceed the application setting max_export_size' do
      it 'starts project export worker' do
        stub_application_setting(max_export_size: 1)
        allow(project.statistics).to receive(:storage_size).and_return(0.megabytes)

        expect(Projects::ImportExport::CreateRelationExportsWorker).to receive(:perform_async).with(user.id, project.id, nil, { exported_by_admin: false })

        project.add_export_job(current_user: user)
      end
    end

    context 'when project storage_size exceeds the application setting max_export_size' do
      it 'raises Project::ExportLimitExceeded' do
        stub_application_setting(max_export_size: 1)
        allow(project.statistics).to receive(:storage_size).and_return(2.megabytes)

        expect(Projects::ImportExport::CreateRelationExportsWorker).not_to receive(:perform_async)
        expect { project.add_export_job(current_user: user) }.to raise_error(Project::ExportLimitExceeded)
      end
    end

    context 'when application setting max_export_size is not set' do
      it 'starts project export worker' do
        allow(project.statistics).to receive(:storage_size).and_return(2.megabytes)
        expect(Projects::ImportExport::CreateRelationExportsWorker).to receive(:perform_async).with(user.id, project.id, nil, { exported_by_admin: false })

        project.add_export_job(current_user: user)
      end
    end
  end

  describe '#export_in_progress?' do
    let(:project) { build(:project) }
    let!(:project_export_job) { create(:project_export_job, project: project, user: project.creator) }

    context 'when project export is enqueued' do
      it { expect(project.export_in_progress?(project_export_job.user)).to be false }
    end

    context 'when project export is in progress' do
      before do
        project_export_job.start!
      end

      it { expect(project.export_in_progress?(project_export_job.user)).to be true }
    end

    context 'when project export is completed' do
      before do
        finish_job(project_export_job)
      end

      it { expect(project.export_in_progress?(project_export_job.user)).to be false }
    end
  end

  describe '#export_status' do
    let(:project) { build(:project) }
    let!(:project_export_job) { create(:project_export_job, project: project, user: project.creator) }

    context 'when project export is enqueued' do
      it { expect(project.export_status(project.creator)).to eq :queued }
    end

    context 'when project export is failed' do
      before do
        project_export_job.fail_op!
      end

      it { expect(project.export_status(project.creator)).to eq :failed }
    end

    context 'when project export is in progress' do
      before do
        project_export_job.start!
      end

      it { expect(project.export_status(project.creator)).to eq :started }
    end

    context 'when project export is completed' do
      before do
        finish_job(project_export_job)
        allow(project).to receive(:export_file_exists?).and_return(true)
      end

      it { expect(project.export_status(project.creator)).to eq :finished }
    end

    context 'when project export is being regenerated' do
      let!(:new_project_export_job) { create(:project_export_job, project: project, user: project.creator) }

      before do
        finish_job(project_export_job)
        allow(project).to receive(:export_file_exists?).and_return(true)
      end

      it { expect(project.export_status(new_project_export_job.user)).to eq :regeneration_in_progress }
    end
  end

  describe '#import_export_upload_by_user' do
    let(:project) { create(:project) }
    let(:user) { create(:user) }
    let!(:import_export_upload) { create(:import_export_upload, project: project, user: user) }

    it 'returns the import_export_upload' do
      expect(project.import_export_upload_by_user(user)).to eq import_export_upload
    end

    context 'when import_export_upload does not exist for user' do
      let(:import_export_upload) { create(:import_export_upload, project: project) }

      it 'returns nil' do
        expect(project.import_export_upload_by_user(user)).to be nil
      end
    end
  end

  describe 'with Debian Distributions' do
    subject { create(:project) }

    it_behaves_like 'model with Debian distributions'
  end

  describe '#environments_for_scope' do
    let_it_be(:project, reload: true) { create(:project) }

    before do
      create_list(:environment, 2, project: project)
    end

    it 'retrieves all project environments when using the * wildcard' do
      expect(project.environments_for_scope("*")).to eq(project.environments)
    end

    it 'retrieves a specific project environment when using the name of that environment' do
      environment = project.environments.first

      expect(project.environments_for_scope(environment.name)).to eq([environment])
    end
  end

  describe '#latest_jira_import' do
    let_it_be(:project) { create(:project) }

    context 'when no jira imports' do
      it 'returns nil' do
        expect(project.latest_jira_import).to be nil
      end
    end

    context 'when single jira import' do
      let!(:jira_import1) { create(:jira_import_state, project: project) }

      it 'returns the jira import' do
        expect(project.latest_jira_import).to eq(jira_import1)
      end
    end

    context 'when multiple jira imports' do
      let!(:jira_import1) { create(:jira_import_state, :finished, created_at: 1.day.ago, project: project) }
      let!(:jira_import2) { create(:jira_import_state, :failed, created_at: 2.days.ago, project: project) }
      let!(:jira_import3) { create(:jira_import_state, :started, created_at: 3.days.ago, project: project) }

      it 'returns latest jira import by created_at' do
        expect(project.jira_imports.pluck(:id)).to eq([jira_import3.id, jira_import2.id, jira_import1.id])
        expect(project.latest_jira_import).to eq(jira_import1)
      end
    end
  end

  describe '#packages_enabled' do
    subject { create(:project).packages_enabled }

    it { is_expected.to be true }

    context 'when packages_enabled is enabled' do
      where(:project_visibility, :expected_result) do
        Gitlab::VisibilityLevel::PRIVATE  | ProjectFeature::PRIVATE
        Gitlab::VisibilityLevel::INTERNAL | ProjectFeature::ENABLED
        Gitlab::VisibilityLevel::PUBLIC   | ProjectFeature::PUBLIC
      end

      with_them do
        it 'set package_registry_access_level to correct value' do
          project = create(:project,
            visibility_level: project_visibility,
            packages_enabled: false,
            package_registry_access_level: ProjectFeature::DISABLED
          )

          project.update!(packages_enabled: true)

          expect(project.package_registry_access_level).to eq(expected_result)
        end
      end
    end

    context 'when packages_enabled is disabled' do
      Gitlab::VisibilityLevel.options.values.each do |project_visibility|
        it 'set package_registry_access_level to DISABLED' do
          project = create(:project,
            visibility_level: project_visibility,
            packages_enabled: true,
            package_registry_access_level: ProjectFeature::PUBLIC
          )

          project.update!(packages_enabled: false)

          expect(project.package_registry_access_level).to eq(ProjectFeature::DISABLED)
        end
      end
    end
  end

  describe '#related_group_ids' do
    let_it_be(:group) { create(:group) }
    let_it_be(:sub_group) { create(:group, parent: group) }

    context 'when associated with a namespace' do
      let(:project) { create(:project, namespace: create(:namespace)) }
      let!(:linked_group) { create(:project_group_link, project: project).group }

      it 'only includes linked groups' do
        expect(project.related_group_ids).to contain_exactly(linked_group.id)
      end
    end

    context 'when associated with a group' do
      let(:project) { create(:project, group: sub_group) }
      let!(:linked_group) { create(:project_group_link, project: project).group }

      it 'includes self, ancestors and linked groups' do
        expect(project.related_group_ids).to contain_exactly(group.id, sub_group.id, linked_group.id)
      end
    end
  end

  describe '#package_already_taken?' do
    let_it_be(:namespace) { create(:namespace, path: 'test') }
    let_it_be(:project) { create(:project, :public, namespace: namespace) }
    let_it_be_with_reload(:package) { create(:npm_package, project: project, name: "@#{namespace.path}/foo", version: '1.2.3') }

    subject { project.package_already_taken?(package_name, package_version, package_type: :npm) }

    context 'within the package project' do
      where(:package_name, :package_version, :expected_result) do
        '@test/bar' | '1.2.3' | false
        '@test/bar' | '5.5.5' | false
        '@test/foo' | '1.2.3' | false
        '@test/foo' | '5.5.5' | false
      end

      with_them do
        it { is_expected.to eq expected_result }
      end
    end

    context 'within a different project' do
      let_it_be(:alt_project) { create(:project, :public, namespace: namespace) }

      subject { alt_project.package_already_taken?(package_name, package_version, package_type: :npm) }

      where(:package_name, :package_version, :expected_result) do
        '@test/bar' | '1.2.3' | false
        '@test/bar' | '5.5.5' | false
        '@test/foo' | '1.2.3' | true
        '@test/foo' | '5.5.5' | false
      end

      with_them do
        it { is_expected.to eq expected_result }
      end

      context 'for a different package type' do
        it 'returns false' do
          result = alt_project.package_already_taken?(package.name, package.version, package_type: :nuget)
          expect(result).to be false
        end
      end

      context 'with a pending_destruction package' do
        before do
          package.pending_destruction!
        end

        where(:package_name, :package_version, :expected_result) do
          '@test/bar' | '1.2.3' | false
          '@test/bar' | '5.5.5' | false
          '@test/foo' | '1.2.3' | false
          '@test/foo' | '5.5.5' | false
        end

        with_them do
          it { is_expected.to eq expected_result }
        end
      end
    end
  end

  describe '#design_management_enabled?' do
    let(:project) { build(:project) }

    where(:lfs_enabled, :hashed_storage_enabled, :expectation) do
      false | false | false
      true  | false | false
      false | true  | false
      true  | true  | true
    end

    with_them do
      before do
        expect(project).to receive(:lfs_enabled?).and_return(lfs_enabled)
        allow(project).to receive(:hashed_storage?).with(:repository).and_return(hashed_storage_enabled)
      end

      it do
        expect(project.design_management_enabled?).to be(expectation)
      end
    end
  end

  describe '#parent_loaded?' do
    let_it_be(:project) { create(:project) }

    before do
      project.namespace = create(:namespace)

      project.reload
    end

    it 'is false when the parent is not loaded' do
      expect(project.parent_loaded?).to be_falsey
    end

    it 'is true when the parent is loaded' do
      project.parent

      expect(project.parent_loaded?).to be_truthy
    end
  end

  describe '#bots' do
    subject { project.bots }

    let_it_be(:project) { create(:project) }
    let_it_be(:project_bot) { create(:user, :project_bot) }
    let_it_be(:user) { create(:user) }

    before_all do
      [project_bot, user].each do |member|
        project.add_maintainer(member)
      end
    end

    it { is_expected.to contain_exactly(project_bot) }
    it { is_expected.not_to include(user) }
  end

  describe '#enabled_group_deploy_keys' do
    let_it_be(:project) { create(:project) }

    subject { project.enabled_group_deploy_keys }

    context 'when a project does not have a group' do
      it { is_expected.to be_empty }
    end

    context 'when a project has a parent group' do
      let!(:group) { create(:group, projects: [project]) }

      context 'and this group has a group deploy key enabled' do
        let!(:group_deploy_key) { create(:group_deploy_key, groups: [group]) }

        it { is_expected.to contain_exactly(group_deploy_key) }

        context 'and this group has parent group which also has a group deploy key enabled' do
          let(:super_group) { create(:group) }

          it 'returns both group deploy keys' do
            super_group = create(:group)
            super_group_deploy_key = create(:group_deploy_key, groups: [super_group])
            group.update!(parent: super_group)

            expect(subject).to contain_exactly(group_deploy_key, super_group_deploy_key)
          end
        end
      end

      context 'and another group has a group deploy key enabled' do
        let_it_be(:group_deploy_key) { create(:group_deploy_key) }

        it 'does not return this group deploy key' do
          another_group = create(:group)
          create(:group_deploy_key, groups: [another_group])

          expect(subject).to be_empty
        end
      end
    end
  end

  describe '#default_branch_or_main' do
    let(:project) { create(:project, :repository) }

    it 'returns default branch' do
      expect(project.default_branch_or_main).to eq(project.default_branch)
    end

    context 'when default branch is nil' do
      let(:project) { create(:project, :empty_repo) }

      it 'returns Gitlab::DefaultBranch.value' do
        expect(project.default_branch_or_main).to eq(Gitlab::DefaultBranch.value)
      end
    end
  end

  describe 'topics' do
    let_it_be(:project) { create(:project, name: 'topic-project', topic_list: 'topic1, topic2, topic3') }

    it 'topic_list returns correct string array' do
      expect(project.topic_list).to eq(%w[topic1 topic2 topic3])
    end

    it 'topics returns correct topic records' do
      expect(project.topics.first.class.name).to eq('Projects::Topic')
      expect(project.topics.map(&:name)).to eq(%w[topic1 topic2 topic3])
    end

    context 'topic_list=' do
      where(:topic_list, :expected_result) do
        ['topicA', 'topicB']              | %w[topicA topicB] # rubocop:disable Style/WordArray
        ['topicB', 'topicA']              | %w[topicB topicA] # rubocop:disable Style/WordArray
        ['   topicC  ', ' topicD    ']    | %w[topicC topicD]
        ['topicE', 'topicF', 'topicE']    | %w[topicE topicF] # rubocop:disable Style/WordArray
        ['topicE  ', 'topicF', ' topicE'] | %w[topicE topicF]
        'topicA, topicB'                  | %w[topicA topicB]
        'topicB, topicA'                  | %w[topicB topicA]
        '   topicC  , topicD    '         | %w[topicC topicD]
        'topicE, topicF, topicE'          | %w[topicE topicF]
        'topicE  , topicF,  topicE'       | %w[topicE topicF]
      end

      with_them do
        it 'set topics' do
          project.topic_list = topic_list
          project.save!

          expect(project.topics.map(&:name)).to eq(expected_result)
        end
      end

      it 'set topics if only the order is changed' do
        project.topic_list = 'topicA, topicB'
        project.save!

        expect(project.reload.topics.map(&:name)).to eq(%w[topicA topicB])

        project.topic_list = 'topicB, topicA'
        project.save!

        expect(project.reload.topics.map(&:name)).to eq(%w[topicB topicA])
      end

      it 'does not persist topics before project is saved' do
        project.topic_list = 'topicA, topicB'

        expect(project.reload.topics.map(&:name)).to eq(%w[topic1 topic2 topic3])
      end

      it 'does not update topics if project is not valid' do
        project.name = nil
        project.topic_list = 'topicA, topicB'

        expect(project.save).to be_falsy
        expect(project.reload.topics.map(&:name)).to eq(%w[topic1 topic2 topic3])
      end

      it 'does not add new topic if name is not unique (case insensitive)' do
        project.topic_list = 'topic1, TOPIC2, topic3'

        project.save!

        expect(project.reload.topics.map(&:name)).to eq(%w[topic1 topic2 topic3])
      end

      it 'assigns slug value for new topics' do
        topic = create(:topic, name: 'old topic', title: 'old topic', slug: nil, organization: project.organization)
        project.topic_list = topic.name
        project.save!

        project.topic_list = 'old topic, new topic'
        expect { expect(project.save).to be true }.to change { Projects::Topic.count }.by(1)

        topics = project.reset.topics
        expect(topics.map(&:name)).to match_array(['old topic', 'new topic'])

        old_topic = topics.first
        new_topic = topics.last

        expect(old_topic.slug).to be_nil
        expect(new_topic.slug).to eq('newtopic')
      end
    end

    context 'public topics counter' do
      let_it_be(:topic_1) { create(:topic, name: 't1', organization: project.organization) }
      let_it_be(:topic_2) { create(:topic, name: 't2', organization: project.organization) }
      let_it_be(:topic_3) { create(:topic, name: 't3', organization: project.organization) }

      let(:private) { Gitlab::VisibilityLevel::PRIVATE }
      let(:internal) { Gitlab::VisibilityLevel::INTERNAL }
      let(:public) { Gitlab::VisibilityLevel::PUBLIC }

      subject do
        project_updates = {
          visibility_level: new_visibility,
          topic_list: new_topic_list
        }.compact

        project.update!(project_updates)
      end

      where(:initial_visibility, :new_visibility, :new_topic_list, :expected_count_changes) do
        ref(:private)  | nil            | 't2, t3' | [0, 0, 0]
        ref(:internal) | nil            | 't2, t3' | [-1, 0, 1]
        ref(:public)   | nil            | 't2, t3' | [-1, 0, 1]
        ref(:private)  | ref(:public)   | nil      | [1, 1, 0]
        ref(:private)  | ref(:internal) | nil      | [1, 1, 0]
        ref(:private)  | ref(:private)  | nil      | [0, 0, 0]
        ref(:internal) | ref(:public)   | nil      | [0, 0, 0]
        ref(:internal) | ref(:internal) | nil      | [0, 0, 0]
        ref(:internal) | ref(:private)  | nil      | [-1, -1, 0]
        ref(:public)   | ref(:public)   | nil      | [0, 0, 0]
        ref(:public)   | ref(:internal) | nil      | [0, 0, 0]
        ref(:public)   | ref(:private)  | nil      | [-1, -1, 0]
        ref(:private)  | ref(:public)   | 't2, t3' | [0, 1, 1]
        ref(:private)  | ref(:internal) | 't2, t3' | [0, 1, 1]
        ref(:private)  | ref(:private)  | 't2, t3' | [0, 0, 0]
        ref(:internal) | ref(:public)   | 't2, t3' | [-1, 0, 1]
        ref(:internal) | ref(:internal) | 't2, t3' | [-1, 0, 1]
        ref(:internal) | ref(:private)  | 't2, t3' | [-1, -1, 0]
        ref(:public)   | ref(:public)   | 't2, t3' | [-1, 0, 1]
        ref(:public)   | ref(:internal) | 't2, t3' | [-1, 0, 1]
        ref(:public)   | ref(:private)  | 't2, t3' | [-1, -1, 0]
      end

      with_them do
        it 'increments or decrements counters of topics' do
          project.reload.update!(
            visibility_level: initial_visibility,
            topic_list: [topic_1.name, topic_2.name]
          )

          expect { subject }
            .to change { topic_1.reload.non_private_projects_count }.by(expected_count_changes[0])
            .and change { topic_2.reload.non_private_projects_count }.by(expected_count_changes[1])
            .and change { topic_3.reload.non_private_projects_count }.by(expected_count_changes[2])
        end
      end
    end

    context 'having the same topics for different organizations' do
      let_it_be(:namespace_one) { create(:namespace, organization: create(:organization)) }
      let_it_be(:namespace_two) { create(:namespace, organization: create(:organization)) }

      let_it_be(:project_one) do
        create(:project, name: 'project-1', topic_list: 'topic-1, topic-2', namespace: namespace_one)
      end

      let_it_be(:project_two) do
        create(:project, name: 'project-2', topic_list: 'topic-1, topic-2', namespace: namespace_two)
      end

      let_it_be(:project_three) do
        create(:project, name: 'project-3', topic_list: 'topic-1, topic-2', namespace: namespace_two)
      end

      let(:project_list) { [project_one, project_two, project_three] }

      it 'associate topics to the same organization as the project' do
        project_list.each do |project_from_list|
          project_from_list.topics.each do |topic|
            expect(topic.organization_id).to eq(project_from_list.organization_id)
          end
        end
      end
    end
  end

  shared_examples 'all_runners' do
    let_it_be(:group) { create(:group) }
    let_it_be_with_refind(:project) { create(:project, group: group) }
    let_it_be(:other_group) { create(:group) }
    let_it_be(:other_project) { create(:project) }
    let_it_be(:instance_runner) { create(:ci_runner, :instance) }
    let_it_be(:group_runner) { create(:ci_runner, :group, groups: [group]) }
    let_it_be(:other_group_runner) { create(:ci_runner, :group, groups: [other_group]) }
    let_it_be(:project_runner) { create(:ci_runner, :project, projects: [project]) }
    let_it_be(:other_project_runner) { create(:ci_runner, :project, projects: [other_project]) }

    subject { project.all_runners }

    context 'when shared runners are enabled for project' do
      before do
        project.update!(shared_runners_enabled: true)
      end

      it 'returns a list with all runners' do
        is_expected.to match_array([instance_runner, group_runner, project_runner])
      end
    end

    context 'when shared runners are disabled for project' do
      before do
        project.update!(shared_runners_enabled: false)
      end

      it 'returns a list without shared runners' do
        is_expected.to match_array([group_runner, project_runner])
      end
    end

    context 'when group runners are enabled for project' do
      before do
        project.update!(group_runners_enabled: true)
      end

      it 'returns a list with all runners' do
        is_expected.to match_array([instance_runner, group_runner, project_runner])
      end
    end

    context 'when group runners are disabled for project' do
      before do
        project.update!(group_runners_enabled: false)
      end

      it 'returns a list without group runners' do
        is_expected.to match_array([instance_runner, project_runner])
      end
    end
  end

  describe '#all_runners' do
    it_behaves_like 'all_runners'
  end

  describe '#all_available_runners' do
    it_behaves_like 'all_runners' do
      subject { project.all_available_runners }
    end
  end

  describe '#enforced_runner_token_expiration_interval and #effective_runner_token_expiration_interval' do
    shared_examples 'no enforced expiration interval' do
      it { expect(subject.enforced_runner_token_expiration_interval).to be_nil }
    end

    shared_examples 'enforced expiration interval' do |enforced_interval:|
      it { expect(subject.enforced_runner_token_expiration_interval).to eq(enforced_interval) }
    end

    shared_examples 'no effective expiration interval' do
      it { expect(subject.effective_runner_token_expiration_interval).to be_nil }
    end

    shared_examples 'effective expiration interval' do |effective_interval:|
      it { expect(subject.effective_runner_token_expiration_interval).to eq(effective_interval) }
    end

    context 'when there is no interval' do
      let_it_be(:project) { create(:project) }

      subject { project }

      it_behaves_like 'no enforced expiration interval'
      it_behaves_like 'no effective expiration interval'
    end

    context 'when there is a project interval' do
      let_it_be(:project) { create(:project, runner_token_expiration_interval: 3.days.to_i) }

      subject { project }

      it_behaves_like 'no enforced expiration interval'
      it_behaves_like 'effective expiration interval', effective_interval: 3.days
    end

    # runner_token_expiration_interval should not affect the expiration interval, only
    # project_runner_token_expiration_interval should.
    context 'when there is a site-wide enforced shared interval' do
      before do
        stub_application_setting(runner_token_expiration_interval: 5.days.to_i)
      end

      let_it_be(:project) { create(:project) }

      subject { project }

      it_behaves_like 'no enforced expiration interval'
      it_behaves_like 'no effective expiration interval'
    end

    # group_runner_token_expiration_interval should not affect the expiration interval, only
    # project_runner_token_expiration_interval should.
    context 'when there is a site-wide enforced group interval' do
      before do
        stub_application_setting(group_runner_token_expiration_interval: 5.days.to_i)
      end

      let_it_be(:project) { create(:project) }

      subject { project }

      it_behaves_like 'no enforced expiration interval'
      it_behaves_like 'no effective expiration interval'
    end

    context 'when there is a site-wide enforced project interval' do
      before do
        stub_application_setting(project_runner_token_expiration_interval: 5.days.to_i)
      end

      let_it_be(:project) { create(:project) }

      subject { project }

      it_behaves_like 'enforced expiration interval', enforced_interval: 5.days
      it_behaves_like 'effective expiration interval', effective_interval: 5.days
    end

    # runner_token_expiration_interval should not affect the expiration interval, only
    # project_runner_token_expiration_interval should.
    context 'when there is a group-enforced group interval' do
      let_it_be(:group_settings) { create(:namespace_settings, runner_token_expiration_interval: 4.days.to_i) }
      let_it_be(:group) { create(:group, namespace_settings: group_settings) }
      let_it_be(:project) { create(:project, group: group) }

      subject { project }

      it_behaves_like 'no enforced expiration interval'
      it_behaves_like 'no effective expiration interval'
    end

    # subgroup_runner_token_expiration_interval should not affect the expiration interval, only
    # project_runner_token_expiration_interval should.
    context 'when there is a group-enforced subgroup interval' do
      let_it_be(:group_settings) { create(:namespace_settings, subgroup_runner_token_expiration_interval: 4.days.to_i) }
      let_it_be(:group) { create(:group, namespace_settings: group_settings) }
      let_it_be(:project) { create(:project, group: group) }

      subject { project }

      it_behaves_like 'no enforced expiration interval'
      it_behaves_like 'no effective expiration interval'
    end

    context 'when there is an owner group-enforced project interval' do
      let_it_be(:group_settings) { create(:namespace_settings, project_runner_token_expiration_interval: 4.days.to_i) }
      let_it_be(:group) { create(:group, namespace_settings: group_settings) }
      let_it_be(:project) { create(:project, group: group) }

      subject { project }

      it_behaves_like 'enforced expiration interval', enforced_interval: 4.days
      it_behaves_like 'effective expiration interval', effective_interval: 4.days
    end

    context 'when there is a grandparent group-enforced interval' do
      let_it_be(:grandparent_group_settings) { create(:namespace_settings, project_runner_token_expiration_interval: 3.days.to_i) }
      let_it_be(:grandparent_group) { create(:group, namespace_settings: grandparent_group_settings) }
      let_it_be(:parent_group_settings) { create(:namespace_settings) }
      let_it_be(:parent_group) { create(:group, parent: grandparent_group, namespace_settings: parent_group_settings) }
      let_it_be(:group_settings) { create(:namespace_settings, project_runner_token_expiration_interval: 4.days.to_i) }
      let_it_be(:group) { create(:group, parent: parent_group, namespace_settings: group_settings) }
      let_it_be(:project) { create(:project, group: group) }

      subject { project }

      it_behaves_like 'enforced expiration interval', enforced_interval: 3.days
      it_behaves_like 'effective expiration interval', effective_interval: 3.days
    end

    context 'when there is a parent group-enforced interval overridden by group-enforced interval' do
      let_it_be(:parent_group_settings) { create(:namespace_settings, project_runner_token_expiration_interval: 5.days.to_i) }
      let_it_be(:parent_group) { create(:group, namespace_settings: parent_group_settings) }
      let_it_be(:group_settings) { create(:namespace_settings, project_runner_token_expiration_interval: 4.days.to_i) }
      let_it_be(:group) { create(:group, parent: parent_group, namespace_settings: group_settings) }
      let_it_be(:project) { create(:project, group: group) }

      subject { project }

      it_behaves_like 'enforced expiration interval', enforced_interval: 4.days
      it_behaves_like 'effective expiration interval', effective_interval: 4.days
    end

    context 'when site-wide enforced interval overrides project interval' do
      before do
        stub_application_setting(project_runner_token_expiration_interval: 3.days.to_i)
      end

      let_it_be(:project) { create(:project, runner_token_expiration_interval: 4.days.to_i) }

      subject { project }

      it_behaves_like 'enforced expiration interval', enforced_interval: 3.days
      it_behaves_like 'effective expiration interval', effective_interval: 3.days
    end

    context 'when project interval overrides site-wide enforced interval' do
      before do
        stub_application_setting(project_runner_token_expiration_interval: 5.days.to_i)
      end

      let_it_be(:project) { create(:project, runner_token_expiration_interval: 4.days.to_i) }

      subject { project }

      it_behaves_like 'enforced expiration interval', enforced_interval: 5.days
      it_behaves_like 'effective expiration interval', effective_interval: 4.days

      it 'has human-readable expiration intervals' do
        expect(subject.enforced_runner_token_expiration_interval_human_readable).to eq('5d')
        expect(subject.effective_runner_token_expiration_interval_human_readable).to eq('4d')
      end
    end

    context 'when site-wide enforced interval overrides group-enforced interval' do
      before do
        stub_application_setting(project_runner_token_expiration_interval: 3.days.to_i)
      end

      let_it_be(:group_settings) { create(:namespace_settings, project_runner_token_expiration_interval: 4.days.to_i) }
      let_it_be(:group) { create(:group, namespace_settings: group_settings) }
      let_it_be(:project) { create(:project, group: group) }

      subject { project }

      it_behaves_like 'enforced expiration interval', enforced_interval: 3.days
      it_behaves_like 'effective expiration interval', effective_interval: 3.days
    end

    context 'when group-enforced interval overrides site-wide enforced interval' do
      before do
        stub_application_setting(project_runner_token_expiration_interval: 5.days.to_i)
      end

      let_it_be(:group_settings) { create(:namespace_settings, project_runner_token_expiration_interval: 4.days.to_i) }
      let_it_be(:group) { create(:group, namespace_settings: group_settings) }
      let_it_be(:project) { create(:project, group: group) }

      subject { project }

      it_behaves_like 'enforced expiration interval', enforced_interval: 4.days
      it_behaves_like 'effective expiration interval', effective_interval: 4.days
    end

    context 'when group-enforced interval overrides project interval' do
      let_it_be(:group_settings) { create(:namespace_settings, project_runner_token_expiration_interval: 3.days.to_i) }
      let_it_be(:group) { create(:group, namespace_settings: group_settings) }
      let_it_be(:project) { create(:project, group: group, runner_token_expiration_interval: 4.days.to_i) }

      subject { project }

      it_behaves_like 'enforced expiration interval', enforced_interval: 3.days
      it_behaves_like 'effective expiration interval', effective_interval: 3.days
    end

    context 'when project interval overrides group-enforced interval' do
      let_it_be(:group_settings) { create(:namespace_settings, project_runner_token_expiration_interval: 5.days.to_i) }
      let_it_be(:group) { create(:group, namespace_settings: group_settings) }
      let_it_be(:project) { create(:project, group: group, runner_token_expiration_interval: 4.days.to_i) }

      subject { project }

      it_behaves_like 'enforced expiration interval', enforced_interval: 5.days
      it_behaves_like 'effective expiration interval', effective_interval: 4.days
    end

    # Unrelated groups should not affect the expiration interval.
    context 'when there is an enforced project interval in an unrelated group' do
      let_it_be(:unrelated_group_settings) { create(:namespace_settings, project_runner_token_expiration_interval: 4.days.to_i) }
      let_it_be(:unrelated_group) { create(:group, namespace_settings: unrelated_group_settings) }
      let_it_be(:project) { create(:project) }

      subject { project }

      it_behaves_like 'no enforced expiration interval'
      it_behaves_like 'no effective expiration interval'
    end

    # Subgroups should not affect the parent group expiration interval.
    context 'when there is an enforced project interval in a subgroup' do
      let_it_be(:group) { create(:group) }
      let_it_be(:subgroup_settings) { create(:namespace_settings, project_runner_token_expiration_interval: 4.days.to_i) }
      let_it_be(:subgroup) { create(:group, parent: group, namespace_settings: subgroup_settings) }
      let_it_be(:project) { create(:project, group: group) }

      subject { project }

      it_behaves_like 'no enforced expiration interval'
      it_behaves_like 'no effective expiration interval'
    end
  end

  it_behaves_like 'it has loose foreign keys' do
    let(:factory_name) { :project }
  end

  context 'Projects::SyncEvent' do
    let!(:project) { create(:project) }

    let_it_be(:new_namespace1) { create(:namespace) }
    let_it_be(:new_namespace2) { create(:namespace) }

    context 'when creating the project' do
      it 'creates a projects_sync_event record' do
        expect(project.sync_events.count).to eq(1)
      end

      it 'enqueues ProcessProjectSyncEventsWorker' do
        expect(Projects::ProcessSyncEventsWorker).to receive(:perform_async)

        create(:project)
      end
    end

    context 'when updating project namespace_id' do
      it 'creates a projects_sync_event record' do
        expect do
          project.update!(namespace_id: new_namespace1.id)
        end.to change(Projects::SyncEvent, :count).by(1)

        expect(project.sync_events.count).to eq(2)
      end

      it 'enqueues ProcessProjectSyncEventsWorker' do
        expect(Projects::ProcessSyncEventsWorker).to receive(:perform_async)

        project.update!(namespace_id: new_namespace1.id)
      end
    end

    context 'when updating project other attribute' do
      it 'creates a projects_sync_event record' do
        expect do
          project.update!(name: 'hello')
        end.not_to change(Projects::SyncEvent, :count)
      end
    end

    context 'in the same transaction' do
      context 'when updating different namespace_id' do
        it 'creates two projects_sync_event records' do
          expect do
            Project.transaction do
              project.update!(namespace_id: new_namespace1.id)
              project.update!(namespace_id: new_namespace2.id)
            end
          end.to change(Projects::SyncEvent, :count).by(2)

          expect(project.sync_events.count).to eq(3)
        end
      end

      context 'when updating the same namespace_id' do
        it 'creates one projects_sync_event record' do
          expect do
            Project.transaction do
              project.update!(namespace_id: new_namespace1.id)
              project.update!(namespace_id: new_namespace1.id)
            end
          end.to change(Projects::SyncEvent, :count).by(1)

          expect(project.sync_events.count).to eq(2)
        end
      end
    end
  end

  describe '.not_hidden' do
    it 'lists projects that are not hidden' do
      project = create(:project)
      hidden_project = create(:project, :hidden)

      expect(described_class.not_hidden).to contain_exactly(project)
      expect(described_class.not_hidden).not_to include(hidden_project)
    end
  end

  describe '#pending_delete_or_hidden?' do
    let_it_be(:project) { create(:project, name: 'test-project') }

    where(:pending_delete, :hidden, :expected_result) do
      true  | false | true
      true  | true  | true
      false | true  | true
      false | false | false
    end

    with_them do
      it 'returns true if project is pending delete or hidden' do
        project.pending_delete = pending_delete
        project.hidden = hidden
        project.save!

        expect(project.pending_delete_or_hidden?).to eq(expected_result)
      end
    end
  end

  describe '#work_items_feature_flag_enabled?' do
    let_it_be(:group_project) { create(:project, :in_subgroup) }

    it_behaves_like 'checks parent group and self feature flag' do
      let(:feature_flag_method) { :work_items_feature_flag_enabled? }
      let(:feature_flag) { :work_items }
      let(:subject_project) { group_project }
    end
  end

  describe '#glql_integration_feature_flag_enabled?' do
    let_it_be(:group_project) { create(:project, :in_subgroup) }

    it_behaves_like 'checks parent group and self feature flag' do
      let(:feature_flag_method) { :glql_integration_feature_flag_enabled? }
      let(:feature_flag) { :glql_integration }
      let(:subject_project) { group_project }
    end
  end

  describe '#continue_indented_text_feature_flag_enabled?' do
    let_it_be(:group_project) { create(:project, :in_subgroup) }

    it_behaves_like 'checks parent group and self feature flag' do
      let(:feature_flag_method) { :continue_indented_text_feature_flag_enabled? }
      let(:feature_flag) { :continue_indented_text }
      let(:subject_project) { group_project }
    end
  end

  describe '#wiki_comments_feature_flag_enabled?' do
    let_it_be(:group_project) { create(:project, :in_subgroup) }

    it_behaves_like 'checks parent group and self feature flag' do
      let(:feature_flag_method) { :wiki_comments_feature_flag_enabled? }
      let(:feature_flag) { :wiki_comments }
      let(:subject_project) { group_project }
    end
  end

  describe '#work_items_beta_feature_flag_enabled?' do
    let_it_be(:group_project) { create(:project, :in_subgroup) }

    it_behaves_like 'checks parent group feature flag' do
      let(:feature_flag_method) { :work_items_beta_feature_flag_enabled? }
      let(:feature_flag) { :work_items_beta }
      let(:subject_project) { group_project }
    end
  end

  describe '#work_items_alpha_feature_flag_enabled?' do
    let_it_be(:group_project) { create(:project, :in_subgroup) }

    it_behaves_like 'checks parent group feature flag' do
      let(:feature_flag_method) { :work_items_alpha_feature_flag_enabled? }
      let(:feature_flag) { :work_items_alpha }
      let(:subject_project) { group_project }
    end
  end

  describe 'serialization' do
    let(:object) { build(:project) }

    it_behaves_like 'blocks unsafe serialization'
  end

  describe '#enqueue_record_project_target_platforms' do
    let_it_be(:project) { create(:project) }

    let(:com) { true }

    before do
      allow(Gitlab).to receive(:com?).and_return(com)
    end

    it 'enqueues a Projects::RecordTargetPlatformsWorker' do
      expect(Projects::RecordTargetPlatformsWorker).to receive(:perform_async).with(project.id)

      project.enqueue_record_project_target_platforms
    end

    shared_examples 'does not enqueue a Projects::RecordTargetPlatformsWorker' do
      it 'does not enqueue a Projects::RecordTargetPlatformsWorker' do
        expect(Projects::RecordTargetPlatformsWorker).not_to receive(:perform_async)

        project.enqueue_record_project_target_platforms
      end
    end

    context 'when not in gitlab.com' do
      let(:com) { false }

      it_behaves_like 'does not enqueue a Projects::RecordTargetPlatformsWorker'
    end
  end

  describe '#inactive?' do
    let_it_be_with_reload(:project) { create(:project, name: 'test-project') }

    it_behaves_like 'returns true if project is inactive'
  end

  describe '.inactive' do
    before do
      stub_application_setting(inactive_projects_min_size_mb: 5)
      stub_application_setting(inactive_projects_send_warning_email_after_months: 12)
    end

    it 'returns projects that are inactive' do
      create_project_with_statistics.tap do |project|
        project.update!(last_activity_at: Time.current)
      end
      create_project_with_statistics.tap do |project|
        project.update!(last_activity_at: 13.months.ago)
      end
      inactive_large_project = create_project_with_statistics(with_data: true, size_multiplier: 2.gigabytes)
                                 .tap { |project| project.update!(last_activity_at: 2.years.ago) }
      create_project_with_statistics(with_data: true, size_multiplier: 2.gigabytes)
                               .tap { |project| project.update!(last_activity_at: 1.month.ago) }

      expect(described_class.inactive).to contain_exactly(inactive_large_project)
    end
  end

  describe "#refreshing_build_artifacts_size?" do
    let_it_be(:project) { create(:project) }

    subject { project.refreshing_build_artifacts_size? }

    context 'when project has no existing refresh record' do
      it { is_expected.to be_falsey }
    end

    context 'when project has existing refresh record' do
      context 'and refresh has not yet started' do
        before do
          allow(project)
            .to receive_message_chain(:build_artifacts_size_refresh, :started?)
            .and_return(false)
        end

        it { is_expected.to eq(false) }
      end

      context 'and refresh has started' do
        before do
          allow(project)
            .to receive_message_chain(:build_artifacts_size_refresh, :started?)
            .and_return(true)
        end

        it { is_expected.to eq(true) }
      end
    end
  end

  describe '#group_group_links' do
    context 'with group project' do
      let_it_be(:group) { create(:group) }
      let_it_be(:project) { create(:project, group: group) }

      it 'returns group links of group' do
        expect(group).to receive(:shared_with_group_links_of_ancestors_and_self)

        project.group_group_links
      end
    end

    context 'with personal project' do
      let_it_be(:project) { create(:project) }

      it 'returns none' do
        expect(project.group_group_links).to eq(GroupGroupLink.none)
      end
    end
  end

  describe '#security_training_available?' do
    subject { build(:project) }

    it 'returns false' do
      expect(subject.security_training_available?).to eq false
    end
  end

  describe '#packages_policy_subject' do
    let_it_be(:project) { create(:project) }

    it 'returns wrapper' do
      expect(project.packages_policy_subject).to be_a(Packages::Policies::Project)
      expect(project.packages_policy_subject.project).to eq(project)
    end
  end

  describe '#destroy_deployment_by_id' do
    let(:project) { create(:project, :repository) }

    let!(:deployment) { create(:deployment, :created, project: project) }
    let!(:old_deployment) { create(:deployment, :created, project: project, finished_at: 1.year.ago) }

    it 'will call fast_destroy_all on a specific deployment by id' do
      expect(Deployment).to receive(:fast_destroy_all).and_call_original

      expect do
        project.destroy_deployment_by_id(project.deployments.first.id)
      end.to change { project.deployments.count }.by(-1)

      expect(project.deployments).to match_array([old_deployment])
    end
  end

  describe '#can_create_custom_domains?' do
    let_it_be(:project) { create(:project) }
    let_it_be(:pages_domain) { create(:pages_domain, project: project) }

    subject { project.can_create_custom_domains? }

    context 'when max custom domain setting is set to 0' do
      it { is_expected.to be true }
    end

    context 'when max custom domain setting is not set to 0' do
      before do
        Gitlab::CurrentSettings.update!(max_pages_custom_domains_per_project: 1)
      end

      it { is_expected.to be false }
    end
  end

  describe '#can_suggest_reviewers?' do
    let_it_be(:project) { create(:project) }

    subject(:can_suggest_reviewers) { project.can_suggest_reviewers? }

    it { is_expected.to be(false) }
  end

  describe '#suggested_reviewers_available?' do
    let_it_be(:project) { create(:project) }

    subject(:suggested_reviewers_available) { project.suggested_reviewers_available? }

    it { is_expected.to be(false) }
  end

  describe '.cascading_with_parent_namespace' do
    let_it_be_with_reload(:group) { create(:group, :with_root_storage_statistics) }
    let_it_be_with_reload(:subgroup) { create(:group, parent: group) }
    let_it_be_with_reload(:project) { create(:project, group: subgroup) }
    let_it_be_with_reload(:project_without_group) { create(:project) }

    shared_examples 'cascading settings' do |attribute|
      it 'return self value when no parent' do
        expect(project_without_group.group).to be_nil

        project_without_group.update!(attribute => true)
        expect(project_without_group.public_send("#{attribute}?", inherit_group_setting: true)).to be_truthy
        expect(project_without_group.public_send("#{attribute}_locked?")).to be_falsey

        project_without_group.update!(attribute => false)
        expect(project_without_group.public_send("#{attribute}?", inherit_group_setting: true)).to be_falsey
        expect(project_without_group.public_send("#{attribute}_locked?")).to be_falsey
      end

      it 'return self value when unlocked' do
        subgroup.namespace_settings.update!(attribute => false)
        group.namespace_settings.update!(attribute => false)

        project.update!(attribute => true)
        expect(project.public_send("#{attribute}?", inherit_group_setting: true)).to be_truthy
        expect(project.public_send("#{attribute}_locked?")).to be_falsey

        project.update!(attribute => false)
        expect(project.public_send("#{attribute}?", inherit_group_setting: true)).to be_falsey
        expect(project.public_send("#{attribute}_locked?")).to be_falsey
      end

      it 'still return self value when locked subgroup' do
        subgroup.namespace_settings.update!(attribute => true)
        group.namespace_settings.update!(attribute => false)

        project.update!(attribute => true)
        expect(project.public_send("#{attribute}?", inherit_group_setting: true)).to be_truthy
        expect(project.public_send("#{attribute}_locked?")).to be_falsey

        project.update!(attribute => false)
        expect(project.public_send("#{attribute}?", inherit_group_setting: true)).to be_falsey
        expect(project.public_send("#{attribute}_locked?")).to be_falsey
      end

      it 'still return unlocked value when locked group' do
        subgroup.namespace_settings.update!(attribute => false)
        group.namespace_settings.update!(attribute => true)

        project.update!(attribute => true)
        expect(project.public_send("#{attribute}?", inherit_group_setting: true)).to be_truthy
        expect(project.public_send("#{attribute}_locked?")).to be_falsey

        project.update!(attribute => false)
        expect(project.public_send("#{attribute}?", inherit_group_setting: true)).to be_falsey
        expect(project.public_send("#{attribute}_locked?")).to be_falsey
      end
    end

    it_behaves_like 'cascading settings', :only_allow_merge_if_pipeline_succeeds
    it_behaves_like 'cascading settings', :allow_merge_on_skipped_pipeline
    it_behaves_like 'cascading settings', :only_allow_merge_if_all_discussions_are_resolved
  end

  describe '#archived' do
    it { expect(subject.archived).to be_falsey }
    it { expect(described_class.new(archived: true).archived).to be_truthy }
  end

  describe '#resolve_outdated_diff_discussions' do
    it { expect(subject.resolve_outdated_diff_discussions).to be_falsey }

    context 'when set explicitly' do
      subject { described_class.new(resolve_outdated_diff_discussions: true) }

      it { expect(subject.resolve_outdated_diff_discussions).to be_truthy }
    end
  end

  describe '#only_allow_merge_if_all_discussions_are_resolved' do
    it { expect(subject.only_allow_merge_if_all_discussions_are_resolved).to be_falsey }

    context 'when set explicitly' do
      subject { described_class.new(only_allow_merge_if_all_discussions_are_resolved: true) }

      it { expect(subject.only_allow_merge_if_all_discussions_are_resolved).to be_truthy }
    end
  end

  describe '#remove_source_branch_after_merge' do
    it { expect(subject.remove_source_branch_after_merge).to be_truthy }

    context 'when set explicitly' do
      subject { described_class.new(remove_source_branch_after_merge: false) }

      it { expect(subject.remove_source_branch_after_merge).to be_falsey }
    end
  end

  describe '.is_importing' do
    it 'returns projects that have import in progress' do
      project_1 = create(:project, :import_scheduled, import_type: 'github')
      project_2 = create(:project, :import_started, import_type: 'github')
      create(:project, :import_finished, import_type: 'github')

      expect(described_class.is_importing).to match_array([project_1, project_2])
    end
  end

  describe '.without_created_and_owned_by_banned_user' do
    let_it_be(:other_project) { create(:project) }

    subject(:results) { described_class.without_created_and_owned_by_banned_user }

    context 'when project creator is not banned' do
      let_it_be(:project_of_active_user) { create(:project, creator: create(:user)) }

      it 'includes the project' do
        expect(results).to match_array([other_project, project_of_active_user])
      end
    end

    context 'when project creator is banned' do
      let_it_be(:banned_user) { create(:user, :banned) }
      let_it_be(:project_of_banned_user) { create(:project, creator: banned_user) }

      context 'when project creator is also an owner' do
        let_it_be(:project_auth) do
          project = project_of_banned_user
          create(:project_authorization, :owner, user: project.creator, project: project)
        end

        it 'excludes the project' do
          expect(results).to match_array([other_project])
        end
      end

      context 'when project creator is not an owner' do
        it 'includes the project' do
          expect(results).to match_array([other_project, project_of_banned_user])
        end
      end
    end
  end

  describe '#created_and_owned_by_banned_user?' do
    subject { project.created_and_owned_by_banned_user? }

    context 'when creator is banned' do
      let_it_be(:creator) { create(:user, :banned) }
      let_it_be(:project) { create(:project, creator: creator) }

      it { is_expected.to eq false }

      context 'when creator is an owner' do
        let_it_be(:project_auth) do
          create(:project_authorization, :owner, user: project.creator, project: project)
        end

        it { is_expected.to eq true }
      end
    end

    context 'when creator is not banned' do
      let_it_be(:project) { create(:project) }

      it { is_expected.to eq false }
    end

    context 'when there is no creator' do
      let_it_be(:project) { build_stubbed(:project, creator: nil) }

      it { is_expected.to eq false }
    end
  end

  it_behaves_like 'something that has web-hooks' do
    let_it_be_with_reload(:object) { create(:project) }

    def create_hook
      create(:project_hook, project: object)
    end
  end

  describe 'deprecated project attributes' do
    where(:project_attr, :project_method, :project_feature_attr) do
      :wiki_enabled | :wiki_enabled? | :wiki_access_level
      :builds_enabled | :builds_enabled? | :builds_access_level
      :merge_requests_enabled | :merge_requests_enabled? | :merge_requests_access_level
      :issues_enabled | :issues_enabled? | :issues_access_level
      :snippets_enabled | :snippets_enabled? | :snippets_access_level
    end

    with_them do
      it 'delegates the attributes to project feature' do
        project = Project.new(project_attr => false)

        expect(project.public_send(project_method)).to eq(false)
        expect(project.project_feature.public_send(project_feature_attr)).to eq(ProjectFeature::DISABLED)
      end

      it 'sets the default value' do
        project = Project.new

        expect(project.public_send(project_method)).to eq(true)
        expect(project.project_feature.public_send(project_feature_attr)).to eq(ProjectFeature::ENABLED)
      end
    end
  end

  describe '#repository_object_format' do
    subject { project.repository_object_format }

    let_it_be(:project) { create(:project) }

    context 'when project without a repository' do
      it { is_expected.to be_nil }
    end

    context 'when project with sha1 repository' do
      let_it_be(:project_repository) { create(:project_repository, project: project, object_format: 'sha1') }

      it { is_expected.to eq 'sha1' }
    end

    context 'when project with sha256 repository' do
      let_it_be(:project_repository) { create(:project_repository, project: project, object_format: 'sha256') }

      it { is_expected.to eq 'sha256' }
    end
  end

  describe '#supports_lock_on_merge?' do
    it_behaves_like 'checks self (project) and root ancestor feature flag' do
      let(:feature_flag) { :enforce_locked_labels_on_merge }
      let(:feature_flag_method) { :supports_lock_on_merge? }
    end
  end

  describe 'catalog resource process sync events worker' do
    let_it_be_with_reload(:project) { create(:project, name: 'Test project', description: 'Test description') }

    context 'when the project has a catalog resource' do
      let_it_be(:resource) { create(:ci_catalog_resource, project: project) }

      context 'when project name is updated' do
        it 'enqueues Ci::Catalog::Resources::ProcessSyncEventsWorker' do
          expect(Ci::Catalog::Resources::ProcessSyncEventsWorker).to receive(:perform_async).once

          project.update!(name: 'New name')
        end
      end

      context 'when project description is updated' do
        it 'enqueues Ci::Catalog::Resources::ProcessSyncEventsWorker' do
          expect(Ci::Catalog::Resources::ProcessSyncEventsWorker).to receive(:perform_async).once

          project.update!(description: 'New description')
        end
      end

      context 'when project visibility_level is updated' do
        it 'enqueues Ci::Catalog::Resources::ProcessSyncEventsWorker' do
          expect(Ci::Catalog::Resources::ProcessSyncEventsWorker).to receive(:perform_async).once

          project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
        end
      end

      context 'when neither the project name, description, nor visibility_level are updated' do
        it 'does not enqueue Ci::Catalog::Resources::ProcessSyncEventsWorker' do
          expect(Ci::Catalog::Resources::ProcessSyncEventsWorker).not_to receive(:perform_async)

          project.update!(path: 'path')
        end
      end
    end

    context 'when the project does not have a catalog resource' do
      it 'does not enqueue Ci::Catalog::Resources::ProcessSyncEventsWorker' do
        expect(Ci::Catalog::Resources::ProcessSyncEventsWorker).not_to receive(:perform_async)

        project.update!(
          name: 'New name',
          description: 'New description',
          visibility_level: Gitlab::VisibilityLevel::INTERNAL)
      end
    end
  end

  describe '#allows_multiple_merge_request_assignees?' do
    let(:project) { build_stubbed(:project) }

    subject(:allows_multiple_merge_request_assignees?) { project.allows_multiple_merge_request_assignees? }

    it { is_expected.to eq(false) }
  end

  describe '#allows_multiple_merge_request_reviewers?' do
    let(:project) { build_stubbed(:project) }

    subject(:allows_multiple_merge_request_reviewers?) { project.allows_multiple_merge_request_reviewers? }

    it { is_expected.to eq(false) }
  end

  describe '#on_demand_dast_available?' do
    let_it_be(:project) { create(:project) }

    subject(:on_demand_dast_available?) { project.on_demand_dast_available? }

    it { is_expected.to be_falsy }
  end

  private

  def finish_job(export_job)
    export_job.start
    export_job.finish
  end

  def create_pipeline(project, status = 'success')
    create(
      :ci_pipeline,
      project: project,
      sha: project.commit.sha,
      ref: project.default_branch,
      status: status
    )
  end

  def create_build(new_pipeline = pipeline, name = 'test')
    create(
      :ci_build,
      :success,
      :artifacts,
      pipeline: new_pipeline,
      status: new_pipeline.status,
      name: name
    )
  end

  context 'with loose foreign key on projects.creator_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let_it_be(:parent) { create(:user) }
      let_it_be(:model) { create(:project, creator: parent) }
    end
  end

  describe '#parent_groups' do
    context 'when project has parent groups' do
      let_it_be(:nested_group) { create(:group, parent: group) }
      let_it_be_with_reload(:group) { create(:group, name: 'foo', parent: nested_group) }
      let_it_be(:project) { create(:project, group: group) }

      it 'builds an groups path' do
        groups_path = project.parent_groups
        expect(groups_path).to match_array([group, nested_group])
      end
    end

    context 'when project does not have a parent group' do
      let_it_be(:project) { create(:project) }

      it 'builds an empty path' do
        groups_path = project.parent_groups
        expect(groups_path).to eq([])
      end
    end
  end

  describe '.by_project_namespace' do
    let_it_be(:project) { create(:project) }
    let(:project_namespace) { project.project_namespace }

    it 'returns project' do
      expect(described_class.by_project_namespace(project_namespace)).to match_array([project])
    end

    context 'when using ID' do
      it 'returns project' do
        expect(described_class.by_project_namespace(project_namespace.id)).to match_array([project])
      end
    end

    context 'when using non-existent-id' do
      it 'returns nothing' do
        expect(described_class.by_project_namespace(non_existing_record_id)).to be_empty
      end
    end
  end

  describe '#supports_saved_replies?' do
    let_it_be(:project) { create(:project) }

    it { expect(project.supports_saved_replies?).to eq(false) }
  end

  describe '#merge_trains_enabled?' do
    let_it_be(:project) { create(:project) }

    it { expect(project.merge_trains_enabled?).to eq(false) }
  end

  describe '#lfs_file_locks_changed_epoch', :clean_gitlab_redis_cache do
    let(:project) { build(:project, id: 1) }
    let(:epoch) { Time.current.strftime('%s%L').to_i }

    it 'returns a cached epoch value in milliseconds', :aggregate_failures, :freeze_time do
      cold_cache_control = RedisCommands::Recorder.new do
        expect(project.lfs_file_locks_changed_epoch).to eq epoch
      end

      expect(cold_cache_control.by_command('get').count).to eq 1
      expect(cold_cache_control.by_command('set').count).to eq 1

      warm_cache_control = RedisCommands::Recorder.new do
        expect(project.lfs_file_locks_changed_epoch).to eq epoch
      end

      expect(warm_cache_control.by_command('get').count).to eq 1
      expect(warm_cache_control.by_command('set').count).to eq 0
    end
  end

  describe '#refresh_lfs_file_locks_changed_epoch' do
    let(:project) { build(:project, id: 1) }
    let(:original_time) { Time.current }
    let(:refresh_time) { original_time + 1.second }
    let(:original_epoch) { original_time.strftime('%s%L').to_i }
    let(:refreshed_epoch) { original_epoch + 1.second.in_milliseconds }

    it 'refreshes the cache and returns the new epoch value', :aggregate_failures, :freeze_time do
      expect(project.lfs_file_locks_changed_epoch).to eq(original_epoch)

      travel_to(refresh_time)

      expect(project.lfs_file_locks_changed_epoch).to eq(original_epoch)

      control = RedisCommands::Recorder.new do
        expect(project.refresh_lfs_file_locks_changed_epoch).to eq(refreshed_epoch)
      end
      expect(control.by_command('get').count).to eq 0
      expect(control.by_command('set').count).to eq 1

      expect(project.lfs_file_locks_changed_epoch).to eq(refreshed_epoch)
    end
  end

  describe '.by_any_traversal_id_overlap' do
    let_it_be(:project_1) { create(:project, :in_group) }
    let_it_be(:sub_group) { create(:group, parent: project_1.namespace) }
    let_it_be(:project_2) { create(:project, group: sub_group) }

    it 'returns projects that contain any overlap with the provided traversal_ids array' do
      expect(described_class.by_any_overlap_with_traversal_ids(project_1.namespace_id)).to contain_exactly(project_1, project_2)
    end
  end

  describe '#crm_group' do
    context 'when project does not belong to group' do
      let(:project) { build(:project) }

      it 'returns nil' do
        expect(project.crm_group).to be_nil
      end
    end

    context 'when project belongs to a group' do
      let(:group) { build(:group) }
      let(:project) { build(:project, group: group) }

      it 'returns the group.crm_group' do
        expect(project.crm_group).to be(group.crm_group)
      end
    end
  end

  describe '#placeholder_reference_store' do
    context 'when the project has an import state' do
      let(:project) { build(:project, import_state: build(:import_state)) }

      it { expect(project.placeholder_reference_store).to be_a(::Import::PlaceholderReferences::Store) }
    end

    context 'when the project has no import state' do
      let(:project) { build(:project, import_state: nil) }

      it { expect(project.placeholder_reference_store).to be_nil }
    end
  end

  describe '#uploads_sharding_key' do
    it 'returns namespace_id' do
      namespace = build_stubbed(:namespace)
      project = build_stubbed(:project, namespace: namespace)

      expect(project.uploads_sharding_key).to eq(namespace_id: namespace.id)
    end
  end

  describe '#pages_domain_present?' do
    let_it_be(:project) { create(:project) }

    before do
      allow(project).to receive(:pages_url).and_return('https://example.com')
    end

    context 'when the domain matches pages_url' do
      it 'returns true' do
        expect(project.pages_domain_present?('https://example.com')).to be(true)
      end
    end

    context 'when the domain exists in pages_domains' do
      let!(:pages_domain) { create(:pages_domain, project: project, domain: 'custom.com') }

      it 'returns true' do
        expect(project.pages_domain_present?('https://custom.com')).to be(true)
      end
    end

    context 'when the domain does not match pages_url or pages_domains' do
      it 'returns false' do
        expect(project.pages_domain_present?('https://unknown.com')).to be(false)
      end
    end
  end
end
