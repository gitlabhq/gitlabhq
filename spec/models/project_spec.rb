# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Project, factory_default: :keep do
  include ProjectForksHelper
  include GitHelpers
  include ExternalAuthorizationServiceHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:namespace) { create_default(:namespace).freeze }

  it_behaves_like 'having unique enum values'

  describe 'associations' do
    it { is_expected.to belong_to(:group) }
    it { is_expected.to belong_to(:namespace) }
    it { is_expected.to belong_to(:creator).class_name('User') }
    it { is_expected.to belong_to(:pool_repository) }
    it { is_expected.to have_many(:users) }
    it { is_expected.to have_many(:integrations) }
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:merge_requests) }
    it { is_expected.to have_many(:merge_request_metrics).class_name('MergeRequest::Metrics') }
    it { is_expected.to have_many(:issues) }
    it { is_expected.to have_many(:milestones) }
    it { is_expected.to have_many(:iterations) }
    it { is_expected.to have_many(:project_members).dependent(:delete_all) }
    it { is_expected.to have_many(:users).through(:project_members) }
    it { is_expected.to have_many(:requesters).dependent(:delete_all) }
    it { is_expected.to have_many(:notes).dependent(:destroy) }
    it { is_expected.to have_many(:snippets).class_name('ProjectSnippet') }
    it { is_expected.to have_many(:deploy_keys_projects) }
    it { is_expected.to have_many(:deploy_keys) }
    it { is_expected.to have_many(:hooks) }
    it { is_expected.to have_many(:protected_branches) }
    it { is_expected.to have_many(:exported_protected_branches) }
    it { is_expected.to have_one(:slack_integration) }
    it { is_expected.to have_one(:microsoft_teams_integration) }
    it { is_expected.to have_one(:mattermost_integration) }
    it { is_expected.to have_one(:hangouts_chat_integration) }
    it { is_expected.to have_one(:unify_circuit_integration) }
    it { is_expected.to have_one(:webex_teams_integration) }
    it { is_expected.to have_one(:packagist_integration) }
    it { is_expected.to have_one(:pushover_integration) }
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
    it { is_expected.to have_one(:flowdock_integration) }
    it { is_expected.to have_one(:assembla_integration) }
    it { is_expected.to have_one(:slack_slash_commands_integration) }
    it { is_expected.to have_one(:mattermost_slash_commands_integration) }
    it { is_expected.to have_one(:buildkite_integration) }
    it { is_expected.to have_one(:bamboo_integration) }
    it { is_expected.to have_one(:teamcity_integration) }
    it { is_expected.to have_one(:jira_integration) }
    it { is_expected.to have_one(:redmine_integration) }
    it { is_expected.to have_one(:youtrack_integration) }
    it { is_expected.to have_one(:custom_issue_tracker_integration) }
    it { is_expected.to have_one(:bugzilla_integration) }
    it { is_expected.to have_one(:ewm_integration) }
    it { is_expected.to have_one(:external_wiki_integration) }
    it { is_expected.to have_one(:confluence_integration) }
    it { is_expected.to have_one(:project_feature) }
    it { is_expected.to have_one(:project_repository) }
    it { is_expected.to have_one(:container_expiration_policy) }
    it { is_expected.to have_one(:statistics).class_name('ProjectStatistics') }
    it { is_expected.to have_one(:import_data).class_name('ProjectImportData') }
    it { is_expected.to have_one(:last_event).class_name('Event') }
    it { is_expected.to have_one(:forked_from_project).through(:fork_network_member) }
    it { is_expected.to have_one(:auto_devops).class_name('ProjectAutoDevops') }
    it { is_expected.to have_one(:tracing_setting).class_name('ProjectTracingSetting') }
    it { is_expected.to have_one(:error_tracking_setting).class_name('ErrorTracking::ProjectErrorTrackingSetting') }
    it { is_expected.to have_one(:project_setting) }
    it { is_expected.to have_one(:alerting_setting).class_name('Alerting::ProjectAlertingSetting') }
    it { is_expected.to have_one(:mock_ci_integration) }
    it { is_expected.to have_one(:mock_monitoring_integration) }
    it { is_expected.to have_many(:commit_statuses) }
    it { is_expected.to have_many(:ci_pipelines) }
    it { is_expected.to have_many(:ci_refs) }
    it { is_expected.to have_many(:builds) }
    it { is_expected.to have_many(:build_trace_section_names)}
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
    it { is_expected.to have_many(:clusters) }
    it { is_expected.to have_many(:management_clusters).class_name('Clusters::Cluster') }
    it { is_expected.to have_many(:kubernetes_namespaces) }
    it { is_expected.to have_many(:cluster_agents).class_name('Clusters::Agent') }
    it { is_expected.to have_many(:custom_attributes).class_name('ProjectCustomAttribute') }
    it { is_expected.to have_many(:project_badges).class_name('ProjectBadge') }
    it { is_expected.to have_many(:lfs_file_locks) }
    it { is_expected.to have_many(:project_deploy_tokens) }
    it { is_expected.to have_many(:deploy_tokens).through(:project_deploy_tokens) }
    it { is_expected.to have_many(:cycle_analytics_stages).inverse_of(:project) }
    it { is_expected.to have_many(:value_streams).inverse_of(:project) }
    it { is_expected.to have_many(:external_pull_requests) }
    it { is_expected.to have_many(:sourced_pipelines) }
    it { is_expected.to have_many(:source_pipelines) }
    it { is_expected.to have_many(:prometheus_alert_events) }
    it { is_expected.to have_many(:self_managed_prometheus_alert_events) }
    it { is_expected.to have_many(:alert_management_alerts) }
    it { is_expected.to have_many(:alert_management_http_integrations) }
    it { is_expected.to have_many(:jira_imports) }
    it { is_expected.to have_many(:metrics_users_starred_dashboards).inverse_of(:project) }
    it { is_expected.to have_many(:repository_storage_moves) }
    it { is_expected.to have_many(:reviews).inverse_of(:project) }
    it { is_expected.to have_many(:packages).class_name('Packages::Package') }
    it { is_expected.to have_many(:package_files).class_name('Packages::PackageFile') }
    it { is_expected.to have_many(:debian_distributions).class_name('Packages::Debian::ProjectDistribution').dependent(:destroy) }
    it { is_expected.to have_many(:pipeline_artifacts) }
    it { is_expected.to have_many(:terraform_states).class_name('Terraform::State').inverse_of(:project) }
    it { is_expected.to have_many(:timelogs) }

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
        create(:lfs_objects_project, project: project,
                                     lfs_object: lfs_object,
                                     repository_type: repository_type)
      end

      expect(project.lfs_objects_projects.size).to eq(2)
      expect(project.lfs_objects.size).to eq(1)
      expect(project.lfs_objects.to_a).to eql([lfs_object])
    end

    context 'after initialized' do
      it "has a project_feature" do
        expect(described_class.new.project_feature).to be_present
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
    end

    context 'updating cd_cd_settings' do
      it 'does not raise an error' do
        project = create(:project)

        expect { project.update!(ci_cd_settings: nil) }.not_to raise_exception
      end
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
  end

  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(Gitlab::ConfigHelper) }
    it { is_expected.to include_module(Gitlab::ShellAdapter) }
    it { is_expected.to include_module(Gitlab::VisibilityLevel) }
    it { is_expected.to include_module(Referable) }
    it { is_expected.to include_module(Sortable) }
  end

  describe 'validation' do
    let!(:project) { create(:project) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:namespace_id) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_presence_of(:path) }
    it { is_expected.to validate_length_of(:path).is_at_most(255) }
    it { is_expected.to validate_length_of(:description).is_at_most(2000) }
    it { is_expected.to validate_length_of(:ci_config_path).is_at_most(255) }
    it { is_expected.to allow_value('').for(:ci_config_path) }
    it { is_expected.not_to allow_value('test/../foo').for(:ci_config_path) }
    it { is_expected.not_to allow_value('/test/foo').for(:ci_config_path) }
    it { is_expected.to validate_presence_of(:creator) }
    it { is_expected.to validate_presence_of(:namespace) }
    it { is_expected.to validate_presence_of(:repository_storage) }
    it { is_expected.to validate_numericality_of(:max_artifacts_size).only_integer.is_greater_than(0) }

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
      expect_any_instance_of(described_class).to receive(:visibility_level_allowed_as_fork).and_call_original
      expect_any_instance_of(described_class).to receive(:visibility_level_allowed_by_group).and_call_original

      create(:project)
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
      project = build(:project, project_feature: nil)

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

      it 'does not allow urls with CR or LF characters' do
        project = build(:project)

        aggregate_failures do
          urls_with_CRLF.each do |url|
            project.import_url = url

            expect(project).not_to be_valid
            expect(project.errors.full_messages.first).to match(/is blocked: URI is invalid/)
          end
        end
      end
    end

    describe 'project pending deletion' do
      let!(:project_pending_deletion) do
        create(:project,
               pending_delete: true)
      end

      let(:new_project) do
        build(:project,
              name: project_pending_deletion.name,
              namespace: project_pending_deletion.namespace)
      end

      before do
        new_project.validate
      end

      it 'contains errors related to the project being deleted' do
        expect(new_project.errors.full_messages.first).to eq(_('The project is still being deleted. Please try again later.'))
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

      it 'allows a path ending in a period' do
        project = build(:project, path: 'foo.')

        expect(project).to be_valid
      end
    end
  end

  describe '#merge_requests_author_approval' do
    where(:attribute_value, :return_value) do
      true  | true
      false | false
      nil   | false
    end

    with_them do
      let(:project) { create(:project, merge_requests_author_approval: attribute_value) }

      it 'returns expected value' do
        expect(project.merge_requests_author_approval).to eq(return_value)
        expect(project.merge_requests_author_approval?).to eq(return_value)
      end
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

  describe '#has_packages?' do
    let_it_be(:project) { create(:project, :public) }

    subject { project.has_packages?(package_type) }

    shared_examples 'returning true examples' do
      let!(:package) { create("#{package_type}_package", project: project) }

      it { is_expected.to be true }
    end

    shared_examples 'returning false examples' do
      it { is_expected.to be false }
    end

    context 'with maven packages' do
      it_behaves_like 'returning true examples' do
        let(:package_type) { :maven }
      end
    end

    context 'with npm packages' do
      it_behaves_like 'returning true examples' do
        let(:package_type) { :npm }
      end
    end

    context 'with conan packages' do
      it_behaves_like 'returning true examples' do
        let(:package_type) { :conan }
      end
    end

    context 'with no package type' do
      it_behaves_like 'returning false examples' do
        let(:package_type) { nil }
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

  describe 'project token' do
    it 'sets an random token if none provided' do
      project = FactoryBot.create(:project, runners_token: '')
      expect(project.runners_token).not_to eq('')
    end

    it 'does not set an random token if one provided' do
      project = FactoryBot.create(:project, runners_token: 'my-token')
      expect(project.runners_token).to eq('my-token')
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
    [:add_guest, :add_reporter, :add_developer, :add_maintainer, :add_user, :add_users].each do |method|
      it { is_expected.to delegate_method(method).to(:team) }
    end

    it { is_expected.to delegate_method(:members).to(:team).with_prefix(true) }
    it { is_expected.to delegate_method(:name).to(:owner).with_prefix(true).with_arguments(allow_nil: true) }
    it { is_expected.to delegate_method(:root_ancestor).to(:namespace).with_arguments(allow_nil: true) }
    it { is_expected.to delegate_method(:last_pipeline).to(:commit).with_arguments(allow_nil: true) }
    it { is_expected.to delegate_method(:allow_editing_commit_messages?).to(:project_setting) }
    it { is_expected.to delegate_method(:container_registry_enabled?).to(:project_feature) }
    it { is_expected.to delegate_method(:container_registry_access_level).to(:project_feature) }

    include_examples 'ci_cd_settings delegation' do
      # Skip attributes defined in EE code
      let(:exclude_attributes) do
        %w(
          merge_pipelines_enabled
          merge_trains_enabled
          auto_rollback_enabled
        )
      end
    end

    describe '#ci_forward_deployment_enabled?' do
      it_behaves_like 'a ci_cd_settings predicate method', prefix: 'ci_' do
        let(:delegated_method) { :forward_deployment_enabled? }
      end
    end

    describe '#ci_job_token_scope_enabled?' do
      it_behaves_like 'a ci_cd_settings predicate method', prefix: 'ci_' do
        let(:delegated_method) { :job_token_scope_enabled? }
      end
    end

    describe '#restrict_user_defined_variables?' do
      it_behaves_like 'a ci_cd_settings predicate method' do
        let(:delegated_method) { :restrict_user_defined_variables? }
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

    context 'when read_container_registry_access_level is disabled' do
      before do
        stub_feature_flags(read_container_registry_access_level: false)
      end

      it { is_expected.not_to delegate_method(:container_registry_enabled?).to(:project_feature) }
    end
  end

  describe 'reference methods' do
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
  end

  describe '#merge_method' do
    using RSpec::Parameterized::TableSyntax

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

    describe 'last_activity_date' do
      it 'returns the creation date of the project\'s last event if present' do
        new_event = create(:event, :closed, project: project, created_at: Time.current)

        project.reload
        expect(project.last_activity_at.to_i).to eq(new_event.created_at.to_i)
      end

      it 'returns the project\'s last update date if it has no events' do
        expect(project.last_activity_date).to eq(project.updated_at)
      end

      it 'returns the most recent timestamp' do
        project.update!(updated_at: nil,
                       last_activity_at: timestamp,
                       last_repository_updated_at: timestamp - 1.hour)

        expect(project.last_activity_date).to be_like_time(timestamp)

        project.update!(updated_at: timestamp,
                       last_activity_at: timestamp - 1.hour,
                       last_repository_updated_at: nil)

        expect(project.last_activity_date).to be_like_time(timestamp)
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

  describe '#open_issues_count', :aggregate_failures do
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

    it 'invokes the count service with no current_user' do
      count_service = instance_double(Projects::OpenIssuesCountService)
      expect(Projects::OpenIssuesCountService).to receive(:new).with(project, nil).and_return(count_service)
      expect(count_service).to receive(:count)

      project.open_issues_count
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
        @project = create(:project, name: 'gitlabhq', namespace: @group)
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
      project = create(:redmine_project)

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

  describe '#default_owner' do
    let_it_be(:owner)     { create(:user) }
    let_it_be(:namespace) { create(:namespace, owner: owner) }

    context 'the project does not have a group' do
      let(:project) { build(:project, namespace: namespace) }

      it 'is the namespace owner' do
        expect(project.default_owner).to eq(owner)
      end
    end

    context 'the project is in a group' do
      let(:group)   { build(:group) }
      let(:project) { build(:project, group: group, namespace: namespace) }

      it 'is the group owner' do
        allow(group).to receive(:default_owner).and_return(Object.new)

        expect(project.default_owner).to eq(group.default_owner)
      end
    end
  end

  describe '#external_issue_tracker' do
    it 'sets Project#has_external_issue_tracker when it is nil' do
      project_with_no_tracker = create(:project, has_external_issue_tracker: nil)
      project_with_tracker = create(:redmine_project, has_external_issue_tracker: nil)

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
      project = create(:redmine_project)

      expect(project).to receive(:integrations).once.and_call_original
      2.times { expect(project.external_issue_tracker).to be_a_kind_of(Integrations::Redmine) }
    end
  end

  describe '#has_external_issue_tracker' do
    let_it_be(:project) { create(:project) }

    def subject
      project.reload.has_external_issue_tracker
    end

    it 'is false when external issue tracker service is not active' do
      create(:service, project: project, category: 'issue_tracker', active: false)

      is_expected.to eq(false)
    end

    it 'is false when other service is active' do
      create(:service, project: project, category: 'not_issue_tracker', active: true)

      is_expected.to eq(false)
    end

    context 'when there is an active external issue tracker service' do
      let!(:service) do
        create(:service, project: project, type: 'JiraService', category: 'issue_tracker', active: true)
      end

      specify { is_expected.to eq(true) }

      it 'becomes false when external issue tracker service is destroyed' do
        expect do
          Integration.find(service.id).delete
        end.to change { subject }.to(false)
      end

      it 'becomes false when external issue tracker service becomes inactive' do
        expect do
          service.update_column(:active, false)
        end.to change { subject }.to(false)
      end

      context 'when there are two active external issue tracker services' do
        let_it_be(:second_service) do
          create(:service, project: project, type: 'CustomIssueTracker', category: 'issue_tracker', active: true)
        end

        it 'does not become false when external issue tracker service is destroyed' do
          expect do
            Integration.find(service.id).delete
          end.not_to change { subject }
        end

        it 'does not become false when external issue tracker service becomes inactive' do
          expect do
            service.update_column(:active, false)
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
      create(:service, project: project, type: 'ExternalWikiService', active: true)

      is_expected.to be_kind_of(Integrations::ExternalWiki)
    end

    it 'does not return an inactive external wiki' do
      create(:service, project: project, type: 'ExternalWikiService', active: false)

      is_expected.to eq(nil)
    end

    it 'sets Project#has_external_wiki when it is nil' do
      create(:service, project: project, type: 'ExternalWikiService', active: true)
      project.update_column(:has_external_wiki, nil)

      expect { subject }.to change { project.has_external_wiki }.from(nil).to(true)
    end
  end

  describe '#has_external_wiki' do
    let_it_be(:project) { create(:project) }

    def subject
      project.reload.has_external_wiki
    end

    specify { is_expected.to eq(false) }

    context 'when there is an active external wiki service' do
      let!(:service) do
        create(:service, project: project, type: 'ExternalWikiService', active: true)
      end

      specify { is_expected.to eq(true) }

      it 'becomes false if the external wiki service is destroyed' do
        expect do
          Integration.find(service.id).delete
        end.to change { subject }.to(false)
      end

      it 'becomes false if the external wiki service becomes inactive' do
        expect do
          service.update_column(:active, false)
        end.to change { subject }.to(false)
      end
    end

    it 'is false when external wiki service is not active' do
      create(:service, project: project, type: 'ExternalWikiService', active: false)

      is_expected.to eq(false)
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

  describe '#avatar_type' do
    let(:project) { create(:project) }

    it 'is true if avatar is image' do
      project.update_attribute(:avatar, 'uploads/avatar.png')
      expect(project.avatar_type).to be_truthy
    end

    it 'is false if avatar is html page' do
      project.update_attribute(:avatar, 'uploads/avatar.html')
      project.avatar_type

      expect(project.errors.added?(:avatar, "file format is not supported. Please try one of the following supported formats: png, jpg, jpeg, gif, bmp, tiff, ico, webp")).to be true
    end
  end

  describe '#avatar_url' do
    subject { project.avatar_url }

    let(:project) { create(:project) }

    context 'when avatar file is uploaded' do
      let(:project) { create(:project, :public, :with_avatar) }

      it 'shows correct url' do
        expect(project.avatar_url).to eq(project.avatar.url)
        expect(project.avatar_url(only_path: false)).to eq([Gitlab.config.gitlab.url, project.avatar.url].join)
      end
    end

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

  describe '#builds_enabled' do
    let(:project) { create(:project) }

    subject { project.builds_enabled }

    it { expect(project.builds_enabled?).to be_truthy }
  end

  describe '.sort_by_attribute' do
    it 'reorders the input relation by start count desc' do
      project1 = create(:project, star_count: 2)
      project2 = create(:project, star_count: 1)
      project3 = create(:project)

      projects = described_class.sort_by_attribute(:stars_desc)

      expect(projects).to eq([project1, project2, project3])
    end
  end

  describe '.with_shared_runners' do
    subject { described_class.with_shared_runners }

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

  describe '.with_active_jira_integrations' do
    it 'returns the correct integrations' do
      active_jira_integration = create(:jira_integration)
      active_service = create(:service, active: true)

      expect(described_class.with_active_jira_integrations).to include(active_jira_integration.project)
      expect(described_class.with_active_jira_integrations).not_to include(active_service.project)
    end
  end

  describe '.with_jira_dvcs_cloud' do
    it 'returns the correct project' do
      jira_dvcs_cloud_project = create(:project, :jira_dvcs_cloud)
      jira_dvcs_server_project = create(:project, :jira_dvcs_server)

      expect(described_class.with_jira_dvcs_cloud).to include(jira_dvcs_cloud_project)
      expect(described_class.with_jira_dvcs_cloud).not_to include(jira_dvcs_server_project)
    end
  end

  describe '.with_jira_dvcs_server' do
    it 'returns the correct project' do
      jira_dvcs_server_project = create(:project, :jira_dvcs_server)
      jira_dvcs_cloud_project = create(:project, :jira_dvcs_cloud)

      expect(described_class.with_jira_dvcs_server).to include(jira_dvcs_server_project)
      expect(described_class.with_jira_dvcs_server).not_to include(jira_dvcs_cloud_project)
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
        project.add_user(user, Gitlab::Access::MAINTAINER)
      end

      it { is_expected.to eq([project]) }
    end

    describe 'when a user does not have access to any projects' do
      it { is_expected.to eq([]) }
    end
  end

  describe '.with_integration' do
    before do
      create_list(:prometheus_project, 2)
    end

    let(:integration) { :prometheus_integration }

    it 'avoids n + 1' do
      expect { described_class.with_integration(integration).map(&integration) }
        .not_to exceed_query_limit(1)
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

  describe '#service_desk_enabled?' do
    let_it_be(:namespace) { create(:namespace) }

    subject(:project) { build(:project, :private, namespace: namespace, service_desk_enabled: true) }

    before do
      allow(Gitlab::IncomingEmail).to receive(:enabled?).and_return(true)
      allow(Gitlab::IncomingEmail).to receive(:supports_wildcard?).and_return(true)
    end

    it 'is enabled' do
      expect(project.service_desk_enabled?).to be_truthy
      expect(project.service_desk_enabled).to be_truthy
    end
  end

  describe '#service_desk_address' do
    let_it_be(:project, reload: true) { create(:project, service_desk_enabled: true) }

    subject { project.service_desk_address }

    shared_examples 'with incoming email address' do
      context 'when incoming email is enabled' do
        before do
          config = double(enabled: true, address: 'test+%{key}@mail.com')
          allow(::Gitlab.config).to receive(:incoming_email).and_return(config)
        end

        it 'uses project full path as service desk address key' do
          expect(project.service_desk_address).to eq("test+#{project.full_path_slug}-#{project.project_id}-issue-@mail.com")
        end
      end

      context 'when incoming email is disabled' do
        before do
          config = double(enabled: false)
          allow(::Gitlab.config).to receive(:incoming_email).and_return(config)
        end

        it 'uses project full path as service desk address key' do
          expect(project.service_desk_address).to be_nil
        end
      end
    end

    context 'when service_desk_email is disabled' do
      before do
        allow(::Gitlab::ServiceDeskEmail).to receive(:enabled?).and_return(false)
      end

      it_behaves_like 'with incoming email address'
    end

    context 'when service_desk_email is enabled' do
      before do
        config = double(enabled: true, address: 'foo+%{key}@bar.com')
        allow(::Gitlab::ServiceDeskEmail).to receive(:config).and_return(config)
      end

      it 'returns custom address when project_key is set' do
        create(:service_desk_setting, project: project, project_key: 'key1')

        expect(subject).to eq("foo+#{project.full_path_slug}-key1@bar.com")
      end

      it_behaves_like 'with incoming email address'
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

      expect(Project.with_service_desk_key('key1')).to contain_exactly(project1, project2)
    end

    it 'returns empty if there is no project with the key' do
      expect(Project.with_service_desk_key('key1')).to be_empty
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

          expect { subject }.not_to raise_error(ActionController::RoutingError)
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

  describe '#any_online_runners?' do
    subject { project.any_online_runners? }

    context 'shared runners' do
      let(:project) { create(:project, shared_runners_enabled: shared_runners_enabled) }
      let(:specific_runner) { create(:ci_runner, :project, :online, projects: [project]) }
      let(:shared_runner) { create(:ci_runner, :instance, :online) }
      let(:offline_runner) { create(:ci_runner, :instance) }

      context 'for shared runners disabled' do
        let(:shared_runners_enabled) { false }

        it 'has no runners available' do
          is_expected.to be_falsey
        end

        it 'has a specific runner' do
          specific_runner

          is_expected.to be_truthy
        end

        it 'has a shared runner, but they are prohibited to use' do
          shared_runner

          is_expected.to be_falsey
        end

        it 'checks the presence of specific runner' do
          specific_runner

          expect(project.any_online_runners? { |runner| runner == specific_runner }).to be_truthy
        end

        it 'returns false if match cannot be found' do
          specific_runner

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
      using RSpec::Parameterized::TableSyntax

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

  describe '#pages_deployed?' do
    let(:project) { create(:project) }

    subject { project.pages_deployed? }

    context 'if pages are deployed' do
      before do
        project.pages_metadatum.update_column(:deployed, true)
      end

      it { is_expected.to be_truthy }
    end

    context "if public folder doesn't exist" do
      it { is_expected.to be_falsey }
    end
  end

  describe '#default_branch_protected?' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:project) { create(:project, namespace: namespace) }

    subject { project.default_branch_protected? }

    where(:default_branch_protection_level, :result) do
      Gitlab::Access::PROTECTION_NONE           | false
      Gitlab::Access::PROTECTION_DEV_CAN_PUSH   | false
      Gitlab::Access::PROTECTION_DEV_CAN_MERGE  | true
      Gitlab::Access::PROTECTION_FULL           | true
    end

    with_them do
      before do
        expect(project.namespace).to receive(:default_branch_protection).and_return(default_branch_protection_level)
      end

      it { is_expected.to eq(result) }
    end
  end

  describe '#pages_url' do
    let(:group) { create(:group, name: group_name) }
    let(:project) { create(:project, namespace: group, name: project_name) }
    let(:domain) { 'Example.com' }

    subject { project.pages_url }

    before do
      allow(Settings.pages).to receive(:host).and_return(domain)
      allow(Gitlab.config.pages).to receive(:url).and_return('http://example.com')
    end

    context 'group page' do
      let(:group_name) { 'Group' }
      let(:project_name) { 'group.example.com' }

      it { is_expected.to eq("http://group.example.com") }

      context 'mixed case path' do
        before do
          project.update!(path: 'Group.example.com')
        end

        it { is_expected.to eq("http://group.example.com") }
      end
    end

    context 'project page' do
      let(:group_name) { 'Group' }
      let(:project_name) { 'Project' }

      it { is_expected.to eq("http://group.example.com/project") }

      context 'mixed case path' do
        before do
          project.update!(path: 'Project')
        end

        it { is_expected.to eq("http://group.example.com/Project") }
      end
    end
  end

  describe '#pages_group_url' do
    let(:group) { create(:group, name: group_name) }
    let(:project) { create(:project, namespace: group, name: project_name) }
    let(:domain) { 'Example.com' }
    let(:port) { 1234 }

    subject { project.pages_group_url }

    before do
      allow(Settings.pages).to receive(:host).and_return(domain)
      allow(Gitlab.config.pages).to receive(:url).and_return("http://example.com:#{port}")
    end

    context 'group page' do
      let(:group_name) { 'Group' }
      let(:project_name) { 'group.example.com' }

      it { is_expected.to eq("http://group.example.com:#{port}") }
    end

    context 'project page' do
      let(:group_name) { 'Group' }
      let(:project_name) { 'Project' }

      it { is_expected.to eq("http://group.example.com:#{port}") }
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
            shard_name: project.repository_storage
          )
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

          project.track_project_repository

          expect(project.project_repository).to have_attributes(
            disk_path: 'fancy/new/path',
            shard_name: 'foo'
          )
        end
      end
    end

    context 'with projects on legacy storage' do
      let(:project) { create(:project, :legacy_storage) }

      it_behaves_like 'tracks storage location'
    end

    context 'with projects on hashed storage' do
      let(:project) { create(:project) }

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
    end

    context 'using a forked repository' do
      it 'does nothing' do
        expect(project).to receive(:forked?).and_return(true)
        expect(project.repository).not_to receive(:create_repository)

        project.create_repository
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

  describe '#set_container_registry_access_level' do
    let_it_be_with_reload(:project) { create(:project) }

    it 'updates project_feature', :aggregate_failures do
      # Simulate an existing project that has container_registry enabled
      project.update_column(:container_registry_enabled, true)
      project.project_feature.update_column(:container_registry_access_level, ProjectFeature::ENABLED)

      project.update!(container_registry_enabled: false)

      expect(project.read_attribute(:container_registry_enabled)).to eq(false)
      expect(project.project_feature.container_registry_access_level).to eq(ProjectFeature::DISABLED)

      project.update!(container_registry_enabled: true)

      expect(project.read_attribute(:container_registry_enabled)).to eq(true)
      expect(project.project_feature.container_registry_access_level).to eq(ProjectFeature::ENABLED)
    end

    it 'rollsback both projects and project_features row in case of error', :aggregate_failures do
      project.update_column(:container_registry_enabled, true)
      project.project_feature.update_column(:container_registry_access_level, ProjectFeature::ENABLED)

      allow(project).to receive(:valid?).and_return(false)

      expect { project.update!(container_registry_enabled: false) }.to raise_error(ActiveRecord::RecordInvalid)

      expect(project.reload.read_attribute(:container_registry_enabled)).to eq(true)
      expect(project.project_feature.reload.container_registry_access_level).to eq(ProjectFeature::ENABLED)
    end
  end

  describe '#container_registry_enabled' do
    let_it_be_with_reload(:project) { create(:project) }

    it 'delegates to project_feature', :aggregate_failures do
      project.update_column(:container_registry_enabled, true)
      project.project_feature.update_column(:container_registry_access_level, ProjectFeature::DISABLED)

      expect(project.container_registry_enabled).to eq(false)
      expect(project.container_registry_enabled?).to eq(false)
    end

    context 'with read_container_registry_access_level disabled' do
      before do
        stub_feature_flags(read_container_registry_access_level: false)
      end

      it 'reads project.container_registry_enabled' do
        project.update_column(:container_registry_enabled, true)
        project.project_feature.update_column(:container_registry_access_level, ProjectFeature::DISABLED)

        expect(project.container_registry_enabled).to eq(true)
        expect(project.container_registry_enabled?).to eq(true)
      end
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

          stub_container_registry_tags(repository: /image/,
                                       tags: %w[latest rc1])
        end

        it 'has image tags' do
          expect(project).to have_container_registry_tags
        end
      end

      context 'when tags are present for root repository' do
        before do
          stub_container_registry_tags(repository: project.full_path,
                                       tags: %w[latest rc1 pre1])
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

  describe '#uses_default_ci_config?' do
    let(:project) { build(:project)}

    it 'has a custom ci config path' do
      project.ci_config_path = 'something_custom'

      expect(project.uses_default_ci_config?).to be_falsey
    end

    it 'has a blank ci config path' do
      project.ci_config_path = ''

      expect(project.uses_default_ci_config?).to be_truthy
    end

    it 'does not have a custom ci config path' do
      project.ci_config_path = nil

      expect(project.uses_default_ci_config?).to be_truthy
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
      create(:ci_pipeline, project: project, sha: project.commit.id,
                           ref: project.default_branch)
    end

    let!(:pipeline_for_second_branch) do
      create(:ci_pipeline, project: project, sha: second_branch.target,
                           ref: second_branch.name)
    end

    let!(:other_pipeline_for_default_branch) do
      create(:ci_pipeline, project: project, sha: project.commit.parent.id,
                           ref: project.default_branch)
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
          create(:ci_pipeline, project: project, sha: pipeline_for_second_branch.sha,
                               ref: pipeline_for_second_branch.ref)
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
        project.repository.rm_branch(project.owner, branch.name)
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

  describe '#jira_import?' do
    let_it_be(:project) { build(:project, import_type: 'jira') }
    let_it_be(:jira_import) { build(:jira_import_state, project: project) }

    before do
      expect(project).to receive(:jira_imports).and_return([jira_import])
    end

    it { expect(project.jira_import?).to be true }
    it { expect(project.import?).to be true }
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

  describe '#has_remote_mirror?' do
    let(:project) { create(:project, :remote_mirror, :import_started) }

    subject { project.has_remote_mirror? }

    before do
      allow_any_instance_of(RemoteMirror).to receive(:refresh_remote)
    end

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

    before do
      allow_any_instance_of(RemoteMirror).to receive(:refresh_remote)
    end

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

  describe '#mark_primary_write_location' do
    let(:project) { create(:project) }

    it 'marks the location with project ID' do
      expect(Gitlab::Database::LoadBalancing::Sticking).to receive(:mark_primary_write_location).with(:project, project.id)

      project.mark_primary_write_location
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

  describe '#ancestors_upto' do
    let_it_be(:parent) { create(:group) }
    let_it_be(:child) { create(:group, parent: parent) }
    let_it_be(:child2) { create(:group, parent: child) }
    let_it_be(:project) { create(:project, namespace: child2) }

    it 'returns all ancestors when no namespace is given' do
      expect(project.ancestors_upto).to contain_exactly(child2, child, parent)
    end

    it 'includes ancestors upto but excluding the given ancestor' do
      expect(project.ancestors_upto(parent)).to contain_exactly(child2, child)
    end

    describe 'with hierarchy_order' do
      it 'returns ancestors ordered by descending hierarchy' do
        expect(project.ancestors_upto(hierarchy_order: :desc)).to eq([parent, child, child2])
      end

      it 'can be used with upto option' do
        expect(project.ancestors_upto(parent, hierarchy_order: :desc)).to eq([child, child2])
      end
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
    let_it_be(:namespace) { create(:namespace) }

    let(:project) { build(:project, namespace: namespace, emails_disabled: false) }

    context 'emails disabled in group' do
      it 'returns true' do
        allow(project.namespace).to receive(:emails_disabled?) { true }

        expect(project.emails_disabled?).to be_truthy
      end
    end

    context 'emails enabled in group' do
      before do
        allow(project.namespace).to receive(:emails_disabled?) { false }
      end

      it 'returns false' do
        expect(project.emails_disabled?).to be_falsey
      end

      it 'returns true' do
        project.update_attribute(:emails_disabled, true)

        expect(project.emails_disabled?).to be_truthy
      end
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

  describe '#change_head' do
    let_it_be(:project) { create(:project, :repository) }

    it 'returns error if branch does not exist' do
      expect(project.change_head('unexisted-branch')).to be false
      expect(project.errors.size).to eq(1)
    end

    it 'calls the before_change_head and after_change_head methods' do
      expect(project.repository).to receive(:before_change_head)
      expect(project.repository).to receive(:after_change_head)

      project.change_head(project.default_branch)
    end

    it 'updates commit count' do
      expect(ProjectCacheWorker).to receive(:perform_async).with(project.id, [], [:commit_count])

      project.change_head(project.default_branch)
    end

    it 'copies the gitattributes' do
      expect(project.repository).to receive(:copy_gitattributes).with(project.default_branch)
      project.change_head(project.default_branch)
    end

    it 'reloads the default branch' do
      expect(project).to receive(:reload_default_branch)
      project.change_head(project.default_branch)
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
        let(:platform_variables) { %w(platform variables) }
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
        create(:cluster,
                :not_managed,
                platform_type: :kubernetes,
                projects: [project],
                environment_scope: '*',
                platform_kubernetes: default_cluster_kubernetes)
      end

      let!(:review_env_cluster) do
        create(:cluster,
                :not_managed,
                platform_type: :kubernetes,
                projects: [project],
                environment_scope: 'review/*',
                platform_kubernetes: review_env_cluster_kubernetes)
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

  describe '#ci_variables_for' do
    let_it_be(:project) { create(:project) }

    let(:environment_scope) { '*' }

    let!(:ci_variable) do
      create(:ci_variable, value: 'secret', project: project, environment_scope: environment_scope)
    end

    let!(:protected_variable) do
      create(:ci_variable, :protected, value: 'protected', project: project)
    end

    subject { project.reload.ci_variables_for(ref: 'ref') }

    before do
      stub_application_setting(
        default_branch_protection: Gitlab::Access::PROTECTION_NONE)
    end

    shared_examples 'ref is protected' do
      it 'contains all the variables' do
        is_expected.to contain_exactly(ci_variable, protected_variable)
      end
    end

    it 'memoizes the result by ref and environment', :request_store do
      scoped_variable = create(:ci_variable, value: 'secret', project: project, environment_scope: 'scoped')

      expect(project).to receive(:protected_for?).with('ref').once.and_return(true)
      expect(project).to receive(:protected_for?).with('other').twice.and_return(false)

      2.times do
        expect(project.reload.ci_variables_for(ref: 'ref', environment: 'production')).to contain_exactly(ci_variable, protected_variable)
        expect(project.reload.ci_variables_for(ref: 'other')).to contain_exactly(ci_variable)
        expect(project.reload.ci_variables_for(ref: 'other', environment: 'scoped')).to contain_exactly(ci_variable, scoped_variable)
      end
    end

    context 'when the ref is not protected' do
      before do
        allow(project).to receive(:protected_for?).with('ref').and_return(false)
      end

      it 'contains only the CI variables' do
        is_expected.to contain_exactly(ci_variable)
      end
    end

    context 'when the ref is a protected branch' do
      before do
        allow(project).to receive(:protected_for?).with('ref').and_return(true)
      end

      it_behaves_like 'ref is protected'
    end

    context 'when the ref is a protected tag' do
      before do
        allow(project).to receive(:protected_for?).with('ref').and_return(true)
      end

      it_behaves_like 'ref is protected'
    end

    context 'when environment name is specified' do
      let(:environment) { 'review/name' }

      subject do
        project.ci_variables_for(ref: 'ref', environment: environment)
      end

      context 'when environment scope is exactly matched' do
        let(:environment_scope) { 'review/name' }

        it { is_expected.to contain_exactly(ci_variable) }
      end

      context 'when environment scope is matched by wildcard' do
        let(:environment_scope) { 'review/*' }

        it { is_expected.to contain_exactly(ci_variable) }
      end

      context 'when environment scope does not match' do
        let(:environment_scope) { 'review/*/special' }

        it { is_expected.not_to contain_exactly(ci_variable) }
      end

      context 'when environment scope has _' do
        let(:environment_scope) { '*_*' }

        it 'does not treat it as wildcard' do
          is_expected.not_to contain_exactly(ci_variable)
        end

        context 'when environment name contains underscore' do
          let(:environment) { 'foo_bar/test' }
          let(:environment_scope) { 'foo_bar/*' }

          it 'matches literally for _' do
            is_expected.to contain_exactly(ci_variable)
          end
        end
      end

      # The environment name and scope cannot have % at the moment,
      # but we're considering relaxing it and we should also make sure
      # it doesn't break in case some data sneaked in somehow as we're
      # not checking this integrity in database level.
      context 'when environment scope has %' do
        it 'does not treat it as wildcard' do
          ci_variable.update_attribute(:environment_scope, '*%*')

          is_expected.not_to contain_exactly(ci_variable)
        end

        context 'when environment name contains a percent' do
          let(:environment) { 'foo%bar/test' }

          it 'matches literally for _' do
            ci_variable.environment_scope = 'foo%bar/*'

            is_expected.to contain_exactly(ci_variable)
          end
        end
      end

      context 'when variables with the same name have different environment scopes' do
        let!(:partially_matched_variable) do
          create(:ci_variable,
                 key: ci_variable.key,
                 value: 'partial',
                 environment_scope: 'review/*',
                 project: project)
        end

        let!(:perfectly_matched_variable) do
          create(:ci_variable,
                 key: ci_variable.key,
                 value: 'prefect',
                 environment_scope: 'review/name',
                 project: project)
        end

        it 'puts variables matching environment scope more in the end' do
          is_expected.to eq(
            [ci_variable,
             partially_matched_variable,
             perfectly_matched_variable])
        end
      end
    end
  end

  describe '#ci_instance_variables_for' do
    let(:project) { build_stubbed(:project) }

    let!(:instance_variable) do
      create(:ci_instance_variable, value: 'secret')
    end

    let!(:protected_instance_variable) do
      create(:ci_instance_variable, :protected, value: 'protected')
    end

    subject { project.ci_instance_variables_for(ref: 'ref') }

    before do
      stub_application_setting(
        default_branch_protection: Gitlab::Access::PROTECTION_NONE)
    end

    context 'when the ref is not protected' do
      before do
        allow(project).to receive(:protected_for?).with('ref').and_return(false)
      end

      it 'contains only the CI variables' do
        is_expected.to contain_exactly(instance_variable)
      end
    end

    context 'when the ref is protected' do
      before do
        allow(project).to receive(:protected_for?).with('ref').and_return(true)
      end

      it 'contains all the variables' do
        is_expected.to contain_exactly(instance_variable, protected_instance_variable)
      end
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

  describe '#pages_url' do
    let(:group) { create(:group, name: 'Group') }
    let(:nested_group) { create(:group, parent: group) }
    let(:domain) { 'Example.com' }

    subject { project.pages_url }

    before do
      allow(Settings.pages).to receive(:host).and_return(domain)
      allow(Gitlab.config.pages).to receive(:url).and_return('http://example.com')
    end

    context 'top-level group' do
      let(:project) { create(:project, namespace: group, name: project_name) }

      context 'group page' do
        let(:project_name) { 'group.example.com' }

        it { is_expected.to eq("http://group.example.com") }
      end

      context 'project page' do
        let(:project_name) { 'Project' }

        it { is_expected.to eq("http://group.example.com/project") }
      end
    end

    context 'nested group' do
      let(:project) { create(:project, namespace: nested_group, name: project_name) }
      let(:expected_url) { "http://group.example.com/#{nested_group.path}/#{project.path}" }

      context 'group page' do
        let(:project_name) { 'group.example.com' }

        it { is_expected.to eq(expected_url) }
      end

      context 'project page' do
        let(:project_name) { 'Project' }

        it { is_expected.to eq(expected_url) }
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
      let_it_be(:private_project) { create(:project, :private) }

      subject { described_class.all.public_or_visible_to_user(user) }

      context 'deploy token user without project' do
        let_it_be(:user) { create(:deploy_token) }

        it { is_expected.to eq [] }
      end

      context 'deploy token user with project' do
        let_it_be(:user) { create(:deploy_token, projects: [private_project]) }

        it { is_expected.to include(private_project) }
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
      project_4.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE, merge_requests_access_level: ProjectFeature::PRIVATE )

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

    let_it_be(:group) { create(:group) }

    let!(:project) { create(:project, project_level, namespace: group ) }
    let(:user) { create_user_from_membership(project, membership) }

    context 'reporter level access' do
      let(:feature) { MergeRequest }

      where(:project_level, :feature_access_level, :membership, :admin_mode, :expected_count) do
        permission_table_for_reporter_feature_access
      end

      with_them do
        it "respects visibility" do
          enable_admin_mode!(user) if admin_mode
          update_feature_access_level(project, feature_access_level)

          expected_objects = expected_count == 1 ? [project] : []

          expect(
            described_class.filter_by_feature_visibility(feature, user)
          ).to eq(expected_objects)
        end
      end
    end

    context 'issues' do
      let(:feature) { Issue }

      where(:project_level, :feature_access_level, :membership, :admin_mode, :expected_count) do
        permission_table_for_guest_feature_access
      end

      with_them do
        it "respects visibility" do
          enable_admin_mode!(user) if admin_mode
          update_feature_access_level(project, feature_access_level)

          expected_objects = expected_count == 1 ? [project] : []

          expect(
            described_class.filter_by_feature_visibility(feature, user)
          ).to eq(expected_objects)
        end
      end
    end

    context 'wiki' do
      let(:feature) { :wiki }

      where(:project_level, :feature_access_level, :membership, :admin_mode, :expected_count) do
        permission_table_for_guest_feature_access
      end

      with_them do
        it "respects visibility" do
          enable_admin_mode!(user) if admin_mode
          update_feature_access_level(project, feature_access_level)

          expected_objects = expected_count == 1 ? [project] : []

          expect(
            described_class.filter_by_feature_visibility(feature, user)
          ).to eq(expected_objects)
        end
      end
    end

    context 'code' do
      let(:feature) { :repository }

      where(:project_level, :feature_access_level, :membership, :admin_mode, :expected_count) do
        permission_table_for_guest_feature_access_and_non_private_project_only
      end

      with_them do
        it "respects visibility" do
          enable_admin_mode!(user) if admin_mode
          update_feature_access_level(project, feature_access_level)

          expected_objects = expected_count == 1 ? [project] : []

          expect(
            described_class.filter_by_feature_visibility(feature, user)
          ).to eq(expected_objects)
        end
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
      expect(subject.to_sql).to match(/^WITH "projects_cte" AS #{Gitlab::Database::AsWithMaterialized.materialized_if_supported}/)
      expect(subject).to match_array(projects)
    end
  end

  describe '#pages_available?' do
    let(:project) { create(:project, group: group) }

    subject { project.pages_available? }

    before do
      allow(Gitlab.config.pages).to receive(:enabled).and_return(true)
    end

    context 'when the project is in a top level namespace' do
      let(:group) { create(:group) }

      it { is_expected.to be(true) }
    end

    context 'when the project is in a subgroup' do
      let(:group) { create(:group, :nested) }

      it { is_expected.to be(true) }
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

  describe '#legacy_remove_pages' do
    let(:project) { create(:project).tap { |project| project.mark_pages_as_deployed } }
    let(:pages_metadatum) { project.pages_metadatum }
    let(:namespace) { project.namespace }
    let(:pages_path) { project.pages_path }

    around do |example|
      FileUtils.mkdir_p(pages_path)
      begin
        example.run
      ensure
        FileUtils.rm_rf(pages_path)
      end
    end

    it 'removes the pages directory and marks the project as not having pages deployed' do
      expect_any_instance_of(Gitlab::PagesTransfer).to receive(:rename_project).and_return(true)
      expect(PagesWorker).to receive(:perform_in).with(5.minutes, :remove, namespace.full_path, anything)

      expect { project.legacy_remove_pages }.to change { pages_metadatum.reload.deployed }.from(true).to(false)
    end

    it 'does nothing if updates on legacy storage are disabled' do
      allow(Settings.pages.local_store).to receive(:enabled).and_return(false)

      expect(Gitlab::PagesTransfer).not_to receive(:new)
      expect(PagesWorker).not_to receive(:perform_in)

      project.legacy_remove_pages
    end

    it 'is run when the project is destroyed' do
      expect(project).to receive(:legacy_remove_pages).and_call_original

      expect { project.destroy! }.not_to raise_error
    end
  end

  describe '#remove_export' do
    let(:project) { create(:project, :with_export) }

    before do
      allow_next_instance_of(ProjectExportWorker) do |job|
        allow(job).to receive(:jid).and_return(SecureRandom.hex(8))
      end
    end

    it 'removes the export' do
      project.remove_exports

      expect(project.export_file_exists?).to be_falsey
    end
  end

  context 'with export' do
    let(:project) { create(:project, :with_export) }

    it '#export_file_exists? returns true' do
      expect(project.export_file_exists?).to be true
    end

    it '#export_archive_exists? returns false' do
      expect(project.export_archive_exists?).to be true
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

    describe '#pages_path' do
      it 'returns a path where pages are stored' do
        expect(project.pages_path).to eq(File.join(Settings.pages.path, project.namespace.full_path, project.path))
      end
    end

    describe '#migrate_to_hashed_storage!' do
      let(:project) { create(:project, :empty_repo, :legacy_storage) }

      it 'returns true' do
        expect(project.migrate_to_hashed_storage!).to be_truthy
      end

      it 'does not run validation' do
        expect(project).not_to receive(:valid?)

        project.migrate_to_hashed_storage!
      end

      it 'schedules HashedStorage::ProjectMigrateWorker with delayed start when the project repo is in use' do
        Gitlab::ReferenceCounter.new(Gitlab::GlRepository::PROJECT.identifier_for_container(project)).increase

        expect(HashedStorage::ProjectMigrateWorker).to receive(:perform_in)

        project.migrate_to_hashed_storage!
      end

      it 'schedules HashedStorage::ProjectMigrateWorker with delayed start when the wiki repo is in use' do
        Gitlab::ReferenceCounter.new(Gitlab::GlRepository::WIKI.identifier_for_container(project.wiki)).increase

        expect(HashedStorage::ProjectMigrateWorker).to receive(:perform_in)

        project.migrate_to_hashed_storage!
      end

      it 'schedules HashedStorage::ProjectMigrateWorker' do
        expect(HashedStorage::ProjectMigrateWorker).to receive(:perform_async).with(project.id)

        project.migrate_to_hashed_storage!
      end
    end

    describe '#rollback_to_legacy_storage!' do
      let(:project) { create(:project, :empty_repo, :legacy_storage) }

      it 'returns nil' do
        expect(project.rollback_to_legacy_storage!).to be_nil
      end

      it 'does not run validations' do
        expect(project).not_to receive(:valid?)

        project.rollback_to_legacy_storage!
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

    describe '#pages_path' do
      it 'returns a path where pages are stored' do
        expect(project.pages_path).to eq(File.join(Settings.pages.path, project.namespace.full_path, project.path))
      end
    end

    describe '#migrate_to_hashed_storage!' do
      let(:project) { create(:project, :repository, skip_disk_validation: true) }

      it 'returns nil' do
        expect(project.migrate_to_hashed_storage!).to be_nil
      end

      it 'does not flag as read-only' do
        expect { project.migrate_to_hashed_storage! }.not_to change { project.repository_read_only }
      end

      context 'when partially migrated' do
        it 'enqueues a job' do
          project = create(:project, storage_version: 1, skip_disk_validation: true)

          Sidekiq::Testing.fake! do
            expect { project.migrate_to_hashed_storage! }.to change(HashedStorage::ProjectMigrateWorker.jobs, :size).by(1)
          end
        end
      end
    end

    describe '#rollback_to_legacy_storage!' do
      let(:project) { create(:project, :repository, skip_disk_validation: true) }

      it 'returns true' do
        expect(project.rollback_to_legacy_storage!).to be_truthy
      end

      it 'does not run validations' do
        expect(project).not_to receive(:valid?)

        project.rollback_to_legacy_storage!
      end

      it 'does not flag as read-only' do
        expect { project.rollback_to_legacy_storage! }.not_to change { project.repository_read_only }
      end

      it 'enqueues a job' do
        Sidekiq::Testing.fake! do
          expect { project.rollback_to_legacy_storage! }.to change(HashedStorage::ProjectRollbackWorker.jobs, :size).by(1)
        end
      end
    end
  end

  describe '#has_ci?' do
    let_it_be(:project, reload: true) { create(:project) }

    let(:repository) { double }

    before do
      expect(project).to receive(:repository) { repository }
    end

    context 'when has .gitlab-ci.yml' do
      before do
        expect(repository).to receive(:gitlab_ci_yml) { 'content' }
      end

      it "CI is available" do
        expect(project).to have_ci
      end
    end

    context 'when there is no .gitlab-ci.yml' do
      before do
        expect(repository).to receive(:gitlab_ci_yml) { nil }
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

  describe '#predefined_project_variables' do
    let_it_be(:project) { create(:project, :repository) }

    subject { project.predefined_project_variables.to_runner_variables }

    specify do
      expect(subject).to include
      [
        { key: 'CI_CONFIG_PATH', value: Ci::Pipeline::DEFAULT_CONFIG_PATH, public: true, masked: false }
      ]
    end

    context 'when ci config path is overridden' do
      before do
        project.update!(ci_config_path: 'random.yml')
      end

      it do
        expect(subject).to include
        [
          { key: 'CI_CONFIG_PATH', value: 'random.yml', public: true, masked: false }
        ]
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
      expect(project.api_variables.first[:key]).to eq 'CI_API_V4_URL'
      expect(project.api_variables.first[:value]).to include '/api/v4'
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
        .to contain_exactly(*required_variables)
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
      expect(project.repository).to receive(:expire_content_cache)
      expect(project.wiki.repository).to receive(:expire_content_cache)
      expect(import_state).to receive(:finish)
      expect(project).to receive(:update_project_counter_caches)
      expect(project).to receive(:after_create_default_branch)
      expect(project).to receive(:refresh_markdown_cache!)
      expect(InternalId).to receive(:flush_records!).with(project: project)
      expect(ProjectCacheWorker).to receive(:perform_async).with(project.id, [], [:repository_size])
      expect(DetectRepositoryLanguagesWorker).to receive(:perform_async).with(project.id)
      expect(project).to receive(:write_repository_config)

      project.after_import
    end

    context 'branch protection' do
      let_it_be(:namespace) { create(:namespace) }

      let(:project) { create(:project, :repository, namespace: namespace) }

      before do
        create(:import_state, :started, project: project)
      end

      it 'does not protect when branch protection is disabled' do
        expect(project.namespace).to receive(:default_branch_protection).and_return(Gitlab::Access::PROTECTION_NONE)

        project.after_import

        expect(project.protected_branches).to be_empty
      end

      it "gives developer access to push when branch protection is set to 'developers can push'" do
        expect(project.namespace).to receive(:default_branch_protection).and_return(Gitlab::Access::PROTECTION_DEV_CAN_PUSH)

        project.after_import

        expect(project.protected_branches).not_to be_empty
        expect(project.default_branch).to eq(project.protected_branches.first.name)
        expect(project.protected_branches.first.push_access_levels.map(&:access_level)).to eq([Gitlab::Access::DEVELOPER])
      end

      it "gives developer access to merge when branch protection is set to 'developers can merge'" do
        expect(project.namespace).to receive(:default_branch_protection).and_return(Gitlab::Access::PROTECTION_DEV_CAN_MERGE)

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

  describe '#write_repository_config' do
    let_it_be(:project) { create(:project, :repository) }

    it 'writes full path in .git/config when key is missing' do
      project.write_repository_config

      expect(rugged_config['gitlab.fullpath']).to eq project.full_path
    end

    it 'updates full path in .git/config when key is present' do
      project.write_repository_config(gl_full_path: 'old/path')

      expect { project.write_repository_config }.to change { rugged_config['gitlab.fullpath'] }.from('old/path').to(project.full_path)
    end

    it 'does not raise an error with an empty repository' do
      project = create(:project_empty_repo)

      expect { project.write_repository_config }.not_to raise_error
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
  end

  describe '#has_active_hooks?' do
    let_it_be(:project) { create(:project) }

    it { expect(project.has_active_hooks?).to be_falsey }

    it 'returns true when a matching push hook exists' do
      create(:project_hook, push_events: true, project: project)

      expect(project.has_active_hooks?(:merge_request_events)).to be_falsey
      expect(project.has_active_hooks?).to be_truthy
    end

    it 'returns true when a matching system hook exists' do
      create(:system_hook, push_events: true)

      expect(project.has_active_hooks?(:merge_request_events)).to be_falsey
      expect(project.has_active_hooks?).to be_truthy
    end

    it 'returns true when a plugin exists' do
      expect(Gitlab::FileHook).to receive(:any?).twice.and_return(true)

      expect(project.has_active_hooks?(:merge_request_events)).to be_truthy
      expect(project.has_active_hooks?).to be_truthy
    end
  end

  describe '#has_active_integrations?' do
    let_it_be(:project) { create(:project) }

    it { expect(project.has_active_integrations?).to be_falsey }

    it 'returns true when a matching service exists' do
      create(:custom_issue_tracker_integration, push_events: true, merge_requests_events: false, project: project)

      expect(project.has_active_integrations?(:merge_request_hooks)).to be_falsey
      expect(project.has_active_integrations?).to be_truthy
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
        target_project: target_project,
        target_branch: 'target-branch',
        source_project: project,
        source_branch: 'awesome-feature-1',
        allow_collaboration: true
      )
    end

    before do
      target_project.add_developer(user)
    end

    describe '#merge_requests_allowing_push_to_user' do
      it 'returns open merge requests for which the user has developer access to the target project' do
        expect(project.merge_requests_allowing_push_to_user(user)).to include(merge_request)
      end

      it 'does not include closed merge requests' do
        merge_request.close

        expect(project.merge_requests_allowing_push_to_user(user)).to be_empty
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
      it 'allows access when there are merge requests open allowing collaboration', :sidekiq_might_not_need_inline do
        expect(project.any_branch_allows_collaboration?(user))
          .to be_truthy
      end

      it 'does not allow access when there are no merge requests open allowing collaboration' do
        merge_request.close!

        expect(project.any_branch_allows_collaboration?(user))
          .to be_falsey
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
        create(:merge_request, :closed,
               target_project: target_project,
               target_branch: 'target-branch',
               source_project: project,
               source_branch: 'rejected-feature-1',
               allow_collaboration: true)

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

      project = build(:project,
                      external_authorization_classification_label: 'hello')

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

    subject { project.gitlab_deploy_token }

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
      let!(:deploy_token) { create(:deploy_token, projects: [project_2]) }

      it { is_expected.to be_nil }
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
      control_count = ActiveRecord::QueryRecorder.new { subject.find_or_initialize_integrations }.count

      expect(control_count).to be <= 4
    end

    it 'avoids N+1 database queries with more available integrations' do
      allow(Integration).to receive(:available_integration_names).and_return(%w[pushover])
      control_count = ActiveRecord::QueryRecorder.new { subject.find_or_initialize_integrations }

      allow(Integration).to receive(:available_integration_names).and_call_original
      expect { subject.find_or_initialize_integrations }.not_to exceed_query_limit(control_count)
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
  end

  describe '#find_or_initialize_integration' do
    it 'avoids N+1 database queries' do
      allow(Integration).to receive(:available_integration_names).and_return(%w[prometheus pushover])

      control_count = ActiveRecord::QueryRecorder.new { subject.find_or_initialize_integration('prometheus') }.count

      allow(Integration).to receive(:available_integration_names).and_call_original

      expect { subject.find_or_initialize_integration('prometheus') }.not_to exceed_query_limit(control_count)
    end

    it 'returns nil if integration is disabled' do
      allow(subject).to receive(:disabled_integrations).and_return(%w[prometheus])

      expect(subject.find_or_initialize_integration('prometheus')).to be_nil
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

    context 'with an instance-level and template integrations' do
      before do
        create(:prometheus_integration, :instance, api_url: 'https://prometheus.instance.com/')
        create(:prometheus_integration, :template, api_url: 'https://prometheus.template.com/')
      end

      it 'builds the integration from the instance integration' do
        expect(subject.find_or_initialize_integration('prometheus').api_url).to eq('https://prometheus.instance.com/')
      end
    end

    context 'with a template integration and no instance-level' do
      before do
        create(:prometheus_integration, :template, api_url: 'https://prometheus.template.com/')
      end

      it 'builds the integration from the template' do
        expect(subject.find_or_initialize_integration('prometheus').api_url).to eq('https://prometheus.template.com/')
      end
    end

    context 'without an exisiting integration, or instance-level or template' do
      it 'builds the integration' do
        expect(subject.find_or_initialize_integration('prometheus')).to be_a(::Integrations::Prometheus)
        expect(subject.find_or_initialize_integration('prometheus').api_url).to be_nil
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

  describe '#leave_pool_repository' do
    let(:pool) { create(:pool_repository) }
    let(:project) { create(:project, :repository, pool_repository: pool) }

    it 'removes the membership' do
      project.leave_pool_repository

      expect(pool.member_projects.reload).not_to include(project)
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
            .to match(/Personal project creation is not allowed/)
        end
      end

      context 'when the project limit is greater than zero' do
        it 'adds a validation error' do
          allow(user)
            .to receive(:projects_limit)
            .and_return(5)

          project.check_personal_projects_limit

          expect(project.errors[:limit_reached].first)
            .to match(/Your project limit is 5 projects/)
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

  describe 'validation #changing_shared_runners_enabled_is_allowed' do
    where(:shared_runners_setting, :project_shared_runners_enabled, :valid_record) do
      'enabled'                    | true  | true
      'enabled'                    | false | true
      'disabled_with_override'     | true  | true
      'disabled_with_override'     | false | true
      'disabled_and_unoverridable' | true  | false
      'disabled_and_unoverridable' | false | true
    end

    with_them do
      let(:group) { create(:group) }
      let(:project) { build(:project, namespace: group, shared_runners_enabled: project_shared_runners_enabled) }

      before do
        allow_next_found_instance_of(Group) do |group|
          allow(group).to receive(:shared_runners_setting).and_return(shared_runners_setting)
        end
      end

      it 'validates the configuration' do
        expect(project.valid?).to eq(valid_record)

        unless valid_record
          expect(project.errors[:shared_runners_enabled]).to contain_exactly('cannot be enabled because parent group does not allow it')
        end
      end
    end
  end

  describe '#mark_pages_as_deployed' do
    let(:project) { create(:project) }
    let(:artifacts_archive) { create(:ci_job_artifact, project: project) }

    it "works when artifacts_archive is missing" do
      project.mark_pages_as_deployed

      expect(project.pages_metadatum.reload.deployed).to eq(true)
    end

    it "creates new record and sets deployed to true if none exists yet" do
      project.pages_metadatum.destroy!
      project.reload

      project.mark_pages_as_deployed(artifacts_archive: artifacts_archive)

      expect(project.pages_metadatum.reload.deployed).to eq(true)
    end

    it "updates the existing record and sets deployed to true and records artifact archive" do
      pages_metadatum = project.pages_metadatum
      pages_metadatum.update!(deployed: false)

      expect do
        project.mark_pages_as_deployed(artifacts_archive: artifacts_archive)
      end.to change { pages_metadatum.reload.deployed }.from(false).to(true)
               .and change { pages_metadatum.reload.artifacts_archive }.from(nil).to(artifacts_archive)
    end
  end

  describe '#mark_pages_as_not_deployed' do
    let(:project) { create(:project) }
    let(:artifacts_archive) { create(:ci_job_artifact, project: project) }

    it "creates new record and sets deployed to false if none exists yet" do
      project.pages_metadatum.destroy!
      project.reload

      project.mark_pages_as_not_deployed

      expect(project.pages_metadatum.reload.deployed).to eq(false)
    end

    it "updates the existing record and sets deployed to false and clears artifacts_archive" do
      pages_metadatum = project.pages_metadatum
      pages_metadatum.update!(deployed: true, artifacts_archive: artifacts_archive)

      expect do
        project.mark_pages_as_not_deployed
      end.to change { pages_metadatum.reload.deployed }.from(true).to(false)
               .and change { pages_metadatum.reload.artifacts_archive }.from(artifacts_archive).to(nil)
    end
  end

  describe '#update_pages_deployment!' do
    let(:project) { create(:project) }
    let(:deployment) { create(:pages_deployment, project: project) }

    it "creates new metadata record if none exists yet and sets deployment" do
      project.pages_metadatum.destroy!
      project.reload

      project.update_pages_deployment!(deployment)

      expect(project.pages_metadatum.pages_deployment).to eq(deployment)
    end

    it "updates the existing metadara record with deployment" do
      expect do
        project.update_pages_deployment!(deployment)
      end.to change { project.pages_metadatum.reload.pages_deployment }.from(nil).to(deployment)
    end
  end

  describe '#set_first_pages_deployment!' do
    let(:project) { create(:project) }
    let(:deployment) { create(:pages_deployment, project: project) }

    it "creates new metadata record if none exists yet and sets deployment" do
      project.pages_metadatum.destroy!
      project.reload

      project.set_first_pages_deployment!(deployment)

      expect(project.pages_metadatum.reload.pages_deployment).to eq(deployment)
      expect(project.pages_metadatum.reload.deployed).to eq(true)
    end

    it "updates the existing metadara record with deployment" do
      expect do
        project.set_first_pages_deployment!(deployment)
      end.to change { project.pages_metadatum.reload.pages_deployment }.from(nil).to(deployment)

      expect(project.pages_metadatum.reload.deployed).to eq(true)
    end

    it 'only updates metadata for this project' do
      other_project = create(:project)

      expect do
        project.set_first_pages_deployment!(deployment)
      end.not_to change { other_project.pages_metadatum.reload.pages_deployment }.from(nil)

      expect(other_project.pages_metadatum.reload.deployed).to eq(false)
    end

    it 'does nothing if metadata already references some deployment' do
      existing_deployment = create(:pages_deployment, project: project)
      project.set_first_pages_deployment!(existing_deployment)

      expect do
        project.set_first_pages_deployment!(deployment)
      end.not_to change { project.pages_metadatum.reload.pages_deployment }.from(existing_deployment)
    end

    it 'marks project as not deployed if deployment is nil' do
      project.mark_pages_as_deployed

      expect do
        project.set_first_pages_deployment!(nil)
      end.to change { project.pages_metadatum.reload.deployed }.from(true).to(false)
    end
  end

  describe '#has_pool_repsitory?' do
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
    let_it_be(:project) { create(:project, group: create(:group, :public)) }

    it 'returns a maximum of ten maintainers of the project in recent_sign_in descending order' do
      limit = 2
      stub_const("Member::ACCESS_REQUEST_APPROVERS_TO_BE_NOTIFIED_LIMIT", limit)
      users = create_list(:user, limit + 1, :with_sign_ins)
      active_maintainers = users.map do |user|
        create(:project_member, :maintainer, user: user, project: project)
      end

      active_maintainers_in_recent_sign_in_desc_order = project.members_and_requesters
                                                               .id_in(active_maintainers)
                                                               .order_recent_sign_in.limit(limit)

      expect(project.access_request_approvers_to_be_notified).to eq(active_maintainers_in_recent_sign_in_desc_order)
    end

    it 'returns active, non_invited, non_requested maintainers of the project' do
      maintainer = create(:project_member, :maintainer, source: project)

      create(:project_member, :developer, project: project)
      create(:project_member, :maintainer, :invited, project: project)
      create(:project_member, :maintainer, :access_request, project: project)
      create(:project_member, :maintainer, :blocked, project: project)

      expect(project.access_request_approvers_to_be_notified.to_a).to eq([maintainer])
    end
  end

  describe '#pages_lookup_path' do
    let(:pages_domain) { build(:pages_domain) }
    let(:project) { build(:project) }

    it 'returns instance of Pages::LookupPath' do
      expect(Pages::LookupPath).to receive(:new).with(project, domain: pages_domain, trim_prefix: 'mygroup').and_call_original

      expect(project.pages_lookup_path(domain: pages_domain, trim_prefix: 'mygroup')).to be_a(Pages::LookupPath)
    end
  end

  describe '.with_pages_deployed' do
    it 'returns only projects that have pages deployed' do
      _project_without_pages = create(:project)
      project_with_pages = create(:project)
      project_with_pages.mark_pages_as_deployed

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

  describe '#pages_group_root?' do
    it 'returns returns true if pages_url is same as pages_group_url' do
      project = build(:project)
      expect(project).to receive(:pages_url).and_return(project.pages_group_url)

      expect(project.pages_group_root?).to eq(true)
    end

    it 'returns returns false if pages_url is different than pages_group_url' do
      project = build(:project)

      expect(project.pages_group_root?).to eq(false)
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
        allow(Gitlab::CurrentSettings).to receive(setting_name).and_return(global_setting)
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

  describe 'with integrations and chat names' do
    subject { create(:project) }

    let(:integration) { create(:service, project: subject) }

    before do
      create_list(:chat_name, 5, integration: integration)
    end

    it 'removes chat names on removal' do
      expect { subject.destroy! }.to change { ChatName.count }.by(-5)
    end
  end

  describe 'with_issues_or_mrs_available_for_user' do
    before do
      Project.delete_all
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

  describe '#self_monitoring?' do
    let_it_be(:project) { create(:project) }

    subject { project.self_monitoring? }

    context 'when the project is instance self monitoring' do
      before do
        stub_application_setting(self_monitoring_project_id: project.id)
      end

      it { is_expected.to be true }
    end

    context 'when the project is not self monitoring' do
      it { is_expected.to be false }
    end
  end

  describe '#add_export_job' do
    context 'if not already present' do
      it 'starts project export job' do
        user = create(:user)
        project = build(:project)

        expect(ProjectExportWorker).to receive(:perform_async).with(user.id, project.id, nil, {})

        project.add_export_job(current_user: user)
      end
    end
  end

  describe '#export_in_progress?' do
    let(:project) { build(:project) }
    let!(:project_export_job ) { create(:project_export_job, project: project) }

    context 'when project export is enqueued' do
      it { expect(project.export_in_progress?).to be false }
    end

    context 'when project export is in progress' do
      before do
        project_export_job.start!
      end

      it { expect(project.export_in_progress?).to be true }
    end

    context 'when project export is completed' do
      before do
        finish_job(project_export_job)
      end

      it { expect(project.export_in_progress?).to be false }
    end
  end

  describe '#export_status' do
    let(:project) { build(:project) }
    let!(:project_export_job ) { create(:project_export_job, project: project) }

    context 'when project export is enqueued' do
      it { expect(project.export_status).to eq :queued }
    end

    context 'when project export is in progress' do
      before do
        project_export_job.start!
      end

      it { expect(project.export_status).to eq :started }
    end

    context 'when project export is completed' do
      before do
        finish_job(project_export_job)
        allow(project).to receive(:export_file_exists?).and_return(true)
      end

      it { expect(project.export_status).to eq :finished }
    end

    context 'when project export is being regenerated' do
      let!(:new_project_export_job ) { create(:project_export_job, project: project) }

      before do
        finish_job(project_export_job)
        allow(project).to receive(:export_file_exists?).and_return(true)
      end

      it { expect(project.export_status).to eq :regeneration_in_progress }
    end
  end

  describe '#has_packages?' do
    let(:project) { create(:project, :public) }

    subject { project.has_packages?(package_type) }

    shared_examples 'has_package' do
      context 'package of package_type exists' do
        let!(:package) { create("#{package_type}_package", project: project) }

        it { is_expected.to be true }
      end

      context 'package of package_type does not exist' do
        it { is_expected.to be false }
      end
    end

    context 'with maven packages' do
      it_behaves_like 'has_package' do
        let(:package_type) { :maven }
      end
    end

    context 'with npm packages' do
      it_behaves_like 'has_package' do
        let(:package_type) { :npm }
      end
    end

    context 'with conan packages' do
      it_behaves_like 'has_package' do
        let(:package_type) { :conan }
      end
    end

    context 'calling has_package? with nil' do
      let(:package_type) { nil }

      it { is_expected.to be false }
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
  end

  describe '#package_already_taken?' do
    let(:namespace) { create(:namespace) }
    let(:project) { create(:project, :public, namespace: namespace) }
    let!(:package) { create(:npm_package, project: project, name: "@#{namespace.path}/foo") }

    context 'no package exists with the same name' do
      it 'returns false' do
        result = project.package_already_taken?("@#{namespace.path}/bar")
        expect(result).to be false
      end

      it 'returns false if it is the project that the package belongs to' do
        result = project.package_already_taken?("@#{namespace.path}/foo")
        expect(result).to be false
      end
    end

    context 'a package already exists with the same name' do
      let(:alt_project) { create(:project, :public, namespace: namespace) }

      it 'returns true' do
        result = alt_project.package_already_taken?("@#{namespace.path}/foo")
        expect(result).to be true
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

  describe "#metrics_setting" do
    let(:project) { build(:project) }

    it 'creates setting if it does not exist' do
      expect(project.metrics_setting).to be_an_instance_of(ProjectMetricsSetting)
    end
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

    describe '#activity_path' do
      it 'returns the project activity_path' do
        expected_path = "/#{project.namespace.path}/#{project.name}/activity"

        expect(project.activity_path).to eq(expected_path)
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

  describe '#increment_statistic_value' do
    let(:project) { build_stubbed(:project) }

    subject(:increment) do
      project.increment_statistic_value(:build_artifacts_size, -10)
    end

    it 'increments the value' do
      expect(ProjectStatistics)
        .to receive(:increment_statistic)
        .with(project, :build_artifacts_size, -10)

      increment
    end

    context 'when the project is scheduled for removal' do
      let(:project) { build_stubbed(:project, pending_delete: true) }

      it 'does not increment the value' do
        expect(ProjectStatistics).not_to receive(:increment_statistic)

        increment
      end
    end
  end

  describe 'topics' do
    let_it_be(:project) { create(:project, topic_list: 'topic1, topic2, topic3') }

    it 'topic_list returns correct string array' do
      expect(project.topic_list).to match_array(%w[topic1 topic2 topic3])
    end

    it 'topics returns correct tag records' do
      expect(project.topics.first.class.name).to eq('ActsAsTaggableOn::Tag')
      expect(project.topics.map(&:name)).to match_array(%w[topic1 topic2 topic3])
    end
  end

  shared_examples 'all_runners' do
    let_it_be_with_refind(:project) { create(:project, group: create(:group)) }
    let_it_be(:instance_runner) { create(:ci_runner, :instance) }
    let_it_be(:group_runner) { create(:ci_runner, :group, groups: [project.group]) }
    let_it_be(:other_group_runner) { create(:ci_runner, :group) }
    let_it_be(:project_runner) { create(:ci_runner, :project, projects: [project]) }
    let_it_be(:other_project_runner) { create(:ci_runner, :project) }

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

  def finish_job(export_job)
    export_job.start
    export_job.finish
  end

  def rugged_config
    rugged_repo(project.repository).config
  end

  def create_pipeline(project, status = 'success')
    create(:ci_pipeline, project: project,
                         sha: project.commit.sha,
                         ref: project.default_branch,
                         status: status)
  end

  def create_build(new_pipeline = pipeline, name = 'test')
    create(:ci_build, :success, :artifacts,
           pipeline: new_pipeline,
           status: new_pipeline.status,
           name: name)
  end
end
