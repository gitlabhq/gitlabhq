require 'spec_helper'

describe Project do
  describe 'associations' do
    it { is_expected.to belong_to(:group) }
    it { is_expected.to belong_to(:namespace) }
    it { is_expected.to belong_to(:creator).class_name('User') }
    it { is_expected.to have_many(:users) }
    it { is_expected.to have_many(:services) }
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:merge_requests) }
    it { is_expected.to have_many(:issues) }
    it { is_expected.to have_many(:milestones) }
    it { is_expected.to have_many(:project_members).dependent(:delete_all) }
    it { is_expected.to have_many(:users).through(:project_members) }
    it { is_expected.to have_many(:requesters).dependent(:delete_all) }
    it { is_expected.to have_many(:notes) }
    it { is_expected.to have_many(:snippets).class_name('ProjectSnippet') }
    it { is_expected.to have_many(:deploy_keys_projects) }
    it { is_expected.to have_many(:deploy_keys) }
    it { is_expected.to have_many(:hooks) }
    it { is_expected.to have_many(:protected_branches) }
    it { is_expected.to have_one(:forked_project_link) }
    it { is_expected.to have_one(:slack_service) }
    it { is_expected.to have_one(:microsoft_teams_service) }
    it { is_expected.to have_one(:mattermost_service) }
    it { is_expected.to have_one(:packagist_service) }
    it { is_expected.to have_one(:pushover_service) }
    it { is_expected.to have_one(:asana_service) }
    it { is_expected.to have_many(:boards) }
    it { is_expected.to have_one(:campfire_service) }
    it { is_expected.to have_one(:drone_ci_service) }
    it { is_expected.to have_one(:emails_on_push_service) }
    it { is_expected.to have_one(:pipelines_email_service) }
    it { is_expected.to have_one(:irker_service) }
    it { is_expected.to have_one(:pivotaltracker_service) }
    it { is_expected.to have_one(:hipchat_service) }
    it { is_expected.to have_one(:flowdock_service) }
    it { is_expected.to have_one(:assembla_service) }
    it { is_expected.to have_one(:slack_slash_commands_service) }
    it { is_expected.to have_one(:mattermost_slash_commands_service) }
    it { is_expected.to have_one(:gemnasium_service) }
    it { is_expected.to have_one(:buildkite_service) }
    it { is_expected.to have_one(:bamboo_service) }
    it { is_expected.to have_one(:teamcity_service) }
    it { is_expected.to have_one(:jira_service) }
    it { is_expected.to have_one(:redmine_service) }
    it { is_expected.to have_one(:custom_issue_tracker_service) }
    it { is_expected.to have_one(:bugzilla_service) }
    it { is_expected.to have_one(:gitlab_issue_tracker_service) }
    it { is_expected.to have_one(:external_wiki_service) }
    it { is_expected.to have_one(:project_feature) }
    it { is_expected.to have_one(:statistics).class_name('ProjectStatistics') }
    it { is_expected.to have_one(:import_data).class_name('ProjectImportData') }
    it { is_expected.to have_one(:last_event).class_name('Event') }
    it { is_expected.to have_one(:forked_from_project).through(:forked_project_link) }
    it { is_expected.to have_one(:auto_devops).class_name('ProjectAutoDevops') }
    it { is_expected.to have_many(:commit_statuses) }
    it { is_expected.to have_many(:pipelines) }
    it { is_expected.to have_many(:builds) }
    it { is_expected.to have_many(:build_trace_section_names)}
    it { is_expected.to have_many(:runner_projects) }
    it { is_expected.to have_many(:runners) }
    it { is_expected.to have_many(:active_runners) }
    it { is_expected.to have_many(:variables) }
    it { is_expected.to have_many(:triggers) }
    it { is_expected.to have_many(:pages_domains) }
    it { is_expected.to have_many(:labels).class_name('ProjectLabel') }
    it { is_expected.to have_many(:users_star_projects) }
    it { is_expected.to have_many(:environments) }
    it { is_expected.to have_many(:deployments) }
    it { is_expected.to have_many(:todos) }
    it { is_expected.to have_many(:releases) }
    it { is_expected.to have_many(:lfs_objects_projects) }
    it { is_expected.to have_many(:project_group_links) }
    it { is_expected.to have_many(:notification_settings).dependent(:delete_all) }
    it { is_expected.to have_many(:forks).through(:forked_project_links) }
    it { is_expected.to have_many(:uploads).dependent(:destroy) }
    it { is_expected.to have_many(:pipeline_schedules) }
    it { is_expected.to have_many(:members_and_requesters) }
    it { is_expected.to have_many(:clusters) }
    it { is_expected.to have_many(:custom_attributes).class_name('ProjectCustomAttribute') }

    context 'after initialized' do
      it "has a project_feature" do
        expect(described_class.new.project_feature).to be_present
      end
    end

    describe '#members & #requesters' do
      let(:project) { create(:project, :public, :access_requestable) }
      let(:requester) { create(:user) }
      let(:developer) { create(:user) }
      before do
        project.request_access(requester)
        project.add_developer(developer)
      end

      it_behaves_like 'members and requesters associations' do
        let(:namespace) { project }
      end
    end

    describe '#boards' do
      it 'raises an error when attempting to add more than one board to the project' do
        subject.boards.build

        expect { subject.boards.build }.to raise_error(Project::BoardLimitExceeded, 'Number of permitted boards exceeded')
        expect(subject.boards.size).to eq 1
      end
    end
  end

  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(Gitlab::ConfigHelper) }
    it { is_expected.to include_module(Gitlab::ShellAdapter) }
    it { is_expected.to include_module(Gitlab::VisibilityLevel) }
    it { is_expected.to include_module(Gitlab::CurrentSettings) }
    it { is_expected.to include_module(Referable) }
    it { is_expected.to include_module(Sortable) }
  end

  describe 'validation' do
    let!(:project) { create(:project) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:namespace_id) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }

    it { is_expected.to validate_presence_of(:path) }
    it { is_expected.to validate_uniqueness_of(:path).scoped_to(:namespace_id) }
    it { is_expected.to validate_length_of(:path).is_at_most(255) }

    it { is_expected.to validate_length_of(:description).is_at_most(2000) }

    it { is_expected.to validate_length_of(:ci_config_path).is_at_most(255) }
    it { is_expected.to allow_value('').for(:ci_config_path) }
    it { is_expected.not_to allow_value('test/../foo').for(:ci_config_path) }
    it { is_expected.not_to allow_value('/test/foo').for(:ci_config_path) }

    it { is_expected.to validate_presence_of(:creator) }

    it { is_expected.to validate_presence_of(:namespace) }

    it { is_expected.to validate_presence_of(:repository_storage) }

    it 'does not allow new projects beyond user limits' do
      project2 = build(:project)
      allow(project2).to receive(:creator).and_return(double(can_create_project?: false, projects_limit: 0).as_null_object)
      expect(project2).not_to be_valid
      expect(project2.errors[:limit_reached].first).to match(/Personal project creation is not allowed/)
    end

    describe 'wiki path conflict' do
      context "when the new path has been used by the wiki of other Project" do
        it 'has an error on the name attribute' do
          new_project = build_stubbed(:project, namespace_id: project.namespace_id, path: "#{project.path}.wiki")

          expect(new_project).not_to be_valid
          expect(new_project.errors[:name].first).to eq('has already been taken')
        end
      end

      context "when the new wiki path has been used by the path of other Project" do
        it 'has an error on the name attribute' do
          project_with_wiki_suffix = create(:project, path: 'foo.wiki')
          new_project = build_stubbed(:project, namespace_id: project_with_wiki_suffix.namespace_id, path: 'foo')

          expect(new_project).not_to be_valid
          expect(new_project.errors[:name].first).to eq('has already been taken')
        end
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

    it 'does not allow an invalid URI as import_url' do
      project2 = build(:project, import_url: 'invalid://')

      expect(project2).not_to be_valid
    end

    it 'does allow a valid URI as import_url' do
      project2 = build(:project, import_url: 'ssh://test@gitlab.com/project.git')

      expect(project2).to be_valid
    end

    it 'allows an empty URI' do
      project2 = build(:project, import_url: '')

      expect(project2).to be_valid
    end

    it 'does not produce import data on an empty URI' do
      project2 = build(:project, import_url: '')

      expect(project2.import_data).to be_nil
    end

    it 'does not produce import data on an invalid URI' do
      project2 = build(:project, import_url: 'test://')

      expect(project2.import_data).to be_nil
    end

    it "does not allow blocked import_url localhost" do
      project2 = build(:project, import_url: 'http://localhost:9000/t.git')

      expect(project2).to be_invalid
      expect(project2.errors[:import_url]).to include('imports are not allowed from that URL')
    end

    it "does not allow blocked import_url port" do
      project2 = build(:project, import_url: 'http://github.com:25/t.git')

      expect(project2).to be_invalid
      expect(project2.errors[:import_url]).to include('imports are not allowed from that URL')
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
        expect(new_project.errors.full_messages.first).to eq('The project is still being deleted. Please try again later.')
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

  describe 'project token' do
    it 'sets an random token if none provided' do
      project = FactoryBot.create :project, runners_token: ''
      expect(project.runners_token).not_to eq('')
    end

    it 'does not set an random token if one provided' do
      project = FactoryBot.create :project, runners_token: 'my-token'
      expect(project.runners_token).to eq('my-token')
    end
  end

  describe 'Respond to' do
    it { is_expected.to respond_to(:url_to_repo) }
    it { is_expected.to respond_to(:repo_exists?) }
    it { is_expected.to respond_to(:execute_hooks) }
    it { is_expected.to respond_to(:owner) }
    it { is_expected.to respond_to(:path_with_namespace) }
    it { is_expected.to respond_to(:full_path) }
  end

  describe 'delegation' do
    [:add_guest, :add_reporter, :add_developer, :add_master, :add_user, :add_users].each do |method|
      it { is_expected.to delegate_method(method).to(:team) }
    end

    it { is_expected.to delegate_method(:members).to(:team).with_prefix(true) }
    it { is_expected.to delegate_method(:name).to(:owner).with_prefix(true).with_arguments(allow_nil: true) }
  end

  describe '#to_reference' do
    let(:owner)     { create(:user, name: 'Gitlab') }
    let(:namespace) { create(:namespace, path: 'sample-namespace', owner: owner) }
    let(:project)   { create(:project, path: 'sample-project', namespace: namespace) }
    let(:group)     { create(:group, name: 'Group', path: 'sample-group', owner: owner) }

    context 'when nil argument' do
      it 'returns nil' do
        expect(project.to_reference).to be_nil
      end
    end

    context 'when full is true' do
      it 'returns complete path to the project' do
        expect(project.to_reference(full: true)).to          eq 'sample-namespace/sample-project'
        expect(project.to_reference(project, full: true)).to eq 'sample-namespace/sample-project'
        expect(project.to_reference(group, full: true)).to   eq 'sample-namespace/sample-project'
      end
    end

    context 'when same project argument' do
      it 'returns nil' do
        expect(project.to_reference(project)).to be_nil
      end
    end

    context 'when cross namespace project argument' do
      let(:another_namespace_project) { create(:project, name: 'another-project') }

      it 'returns complete path to the project' do
        expect(project.to_reference(another_namespace_project)).to eq 'sample-namespace/sample-project'
      end
    end

    context 'when same namespace / cross-project argument' do
      let(:another_project) { create(:project, namespace: namespace) }

      it 'returns path to the project' do
        expect(project.to_reference(another_project)).to eq 'sample-project'
      end
    end

    context 'when different namespace / cross-project argument' do
      let(:another_namespace) { create(:namespace, path: 'another-namespace', owner: owner) }
      let(:another_project)   { create(:project, path: 'another-project', namespace: another_namespace) }

      it 'returns full path to the project' do
        expect(project.to_reference(another_project)).to eq 'sample-namespace/sample-project'
      end
    end

    context 'when argument is a namespace' do
      context 'with same project path' do
        it 'returns path to the project' do
          expect(project.to_reference(namespace)).to eq 'sample-project'
        end
      end

      context 'with different project path' do
        it 'returns full path to the project' do
          expect(project.to_reference(group)).to eq 'sample-namespace/sample-project'
        end
      end
    end
  end

  describe '#to_human_reference' do
    let(:owner) { create(:user, name: 'Gitlab') }
    let(:namespace) { create(:namespace, name: 'Sample namespace', owner: owner) }
    let(:project) { create(:project, name: 'Sample project', namespace: namespace) }

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
      let(:another_namespace_project) { create(:project, name: 'another-project') }

      it 'returns complete name with namespace of the project' do
        expect(project.to_human_reference(another_namespace_project)).to eq 'Gitlab / Sample project'
      end
    end

    context 'when same namespace / cross-project argument' do
      let(:another_project) { create(:project, namespace: namespace) }

      it 'returns name of the project' do
        expect(project.to_human_reference(another_project)).to eq 'Sample project'
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

  describe '#repository_storage_path' do
    let(:project) { create(:project) }

    it 'returns the repository storage path' do
      expect(Dir.exist?(project.repository_storage_path)).to be(true)
    end
  end

  it 'returns valid url to repo' do
    project = described_class.new(path: 'somewhere')
    expect(project.url_to_repo).to eq(Gitlab.config.gitlab_shell.ssh_path_prefix + 'somewhere.git')
  end

  describe "#web_url" do
    let(:project) { create(:project, path: "somewhere") }

    it 'returns the full web URL for this repo' do
      expect(project.web_url).to eq("#{Gitlab.config.gitlab.url}/#{project.namespace.full_path}/somewhere")
    end
  end

  describe "#new_issuable_address" do
    let(:project) { create(:project, path: "somewhere") }
    let(:user) { create(:user) }

    context 'incoming email enabled' do
      before do
        stub_incoming_email_setting(enabled: true, address: "p+%{key}@gl.ab")
      end

      it 'returns the address to create a new issue' do
        address = "p+#{project.full_path}+#{user.incoming_email_token}@gl.ab"

        expect(project.new_issuable_address(user, 'issue')).to eq(address)
      end

      it 'returns the address to create a new merge request' do
        address = "p+#{project.full_path}+merge-request+#{user.incoming_email_token}@gl.ab"

        expect(project.new_issuable_address(user, 'merge_request')).to eq(address)
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
        new_event = create(:event, :closed, project: project, created_at: Time.now)

        project.reload
        expect(project.last_activity_at.to_i).to eq(new_event.created_at.to_i)
      end

      it 'returns the project\'s last update date if it has no events' do
        expect(project.last_activity_date).to eq(project.updated_at)
      end
    end
  end

  describe '#get_issue' do
    let(:project) { create(:project) }
    let!(:issue)  { create(:issue, project: project) }
    let(:user)    { create(:user) }

    before do
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
        expect(project.get_issue(999, user)).to be_nil
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

  describe '#issue_exists?' do
    let(:project) { create(:project) }

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
        @group = create :group, name: 'gitlab'
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

  describe '#repository' do
    let(:project) { create(:project, :repository) }

    it 'returns valid repo' do
      expect(project.repository).to be_kind_of(Repository)
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

  describe '#empty_repo?' do
    context 'when the repo does not exist' do
      let(:project) { build_stubbed(:project) }

      it 'returns true' do
        expect(project.empty_repo?).to be(true)
      end
    end

    context 'when the repo exists' do
      let(:project) { create(:project, :repository) }
      let(:empty_project) { create(:project, :empty_repo) }

      it { expect(empty_project.empty_repo?).to be(true) }
      it { expect(project.empty_repo?).to be(false) }
    end
  end

  describe '#external_issue_tracker' do
    let(:project) { create(:project) }
    let(:ext_project) { create(:redmine_project) }

    context 'on existing projects with no value for has_external_issue_tracker' do
      before do
        project.update_column(:has_external_issue_tracker, nil)
        ext_project.update_column(:has_external_issue_tracker, nil)
      end

      it 'updates the has_external_issue_tracker boolean' do
        expect do
          project.external_issue_tracker
        end.to change { project.reload.has_external_issue_tracker }.to(false)

        expect do
          ext_project.external_issue_tracker
        end.to change { ext_project.reload.has_external_issue_tracker }.to(true)
      end
    end

    it 'returns nil and does not query services when there is no external issue tracker' do
      expect(project).not_to receive(:services)

      expect(project.external_issue_tracker).to eq(nil)
    end

    it 'retrieves external_issue_tracker querying services and cache it when there is external issue tracker' do
      ext_project.reload # Factory returns a project with changed attributes
      expect(ext_project).to receive(:services).once.and_call_original

      2.times { expect(ext_project.external_issue_tracker).to be_a_kind_of(RedmineService) }
    end
  end

  describe '#cache_has_external_issue_tracker' do
    let(:project) { create(:project, has_external_issue_tracker: nil) }

    it 'stores true if there is any external_issue_tracker' do
      services = double(:service, external_issue_trackers: [RedmineService.new])
      expect(project).to receive(:services).and_return(services)

      expect do
        project.cache_has_external_issue_tracker
      end.to change { project.has_external_issue_tracker}.to(true)
    end

    it 'stores false if there is no external_issue_tracker' do
      services = double(:service, external_issue_trackers: [])
      expect(project).to receive(:services).and_return(services)

      expect do
        project.cache_has_external_issue_tracker
      end.to change { project.has_external_issue_tracker}.to(false)
    end

    it 'does not cache data when in a read-only GitLab instance' do
      allow(Gitlab::Database).to receive(:read_only?) { true }

      expect do
        project.cache_has_external_issue_tracker
      end.not_to change { project.has_external_issue_tracker }
    end
  end

  describe '#cache_has_external_wiki' do
    let(:project) { create(:project, has_external_wiki: nil) }

    it 'stores true if there is any external_wikis' do
      services = double(:service, external_wikis: [ExternalWikiService.new])
      expect(project).to receive(:services).and_return(services)

      expect do
        project.cache_has_external_wiki
      end.to change { project.has_external_wiki}.to(true)
    end

    it 'stores false if there is no external_wikis' do
      services = double(:service, external_wikis: [])
      expect(project).to receive(:services).and_return(services)

      expect do
        project.cache_has_external_wiki
      end.to change { project.has_external_wiki}.to(false)
    end

    it 'does not cache data when in a read-only GitLab instance' do
      allow(Gitlab::Database).to receive(:read_only?) { true }

      expect do
        project.cache_has_external_wiki
      end.not_to change { project.has_external_wiki }
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

  describe '#external_wiki' do
    let(:project) { create(:project) }

    context 'with an active external wiki' do
      before do
        create(:service, project: project, type: 'ExternalWikiService', active: true)
        project.external_wiki
      end

      it 'sets :has_external_wiki as true' do
        expect(project.has_external_wiki).to be(true)
      end

      it 'sets :has_external_wiki as false if an external wiki service is destroyed later' do
        expect(project.has_external_wiki).to be(true)

        project.services.external_wikis.first.destroy

        expect(project.has_external_wiki).to be(false)
      end
    end

    context 'with an inactive external wiki' do
      before do
        create(:service, project: project, type: 'ExternalWikiService', active: false)
      end

      it 'sets :has_external_wiki as false' do
        expect(project.has_external_wiki).to be(false)
      end
    end

    context 'with no external wiki' do
      before do
        project.external_wiki
      end

      it 'sets :has_external_wiki as false' do
        expect(project.has_external_wiki).to be(false)
      end

      it 'sets :has_external_wiki as true if an external wiki service is created later' do
        expect(project.has_external_wiki).to be(false)

        create(:service, project: project, type: 'ExternalWikiService', active: true)

        expect(project.has_external_wiki).to be(true)
      end
    end
  end

  describe '#star_count' do
    it 'counts stars from multiple users' do
      user1 = create :user
      user2 = create :user
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
      user = create :user
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
      expect(project.avatar_type).to eq(['only images allowed'])
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

      let(:avatar_path) { "/#{project.full_path}/avatar" }

      it { is_expected.to eq "http://#{Gitlab.config.gitlab.host}#{avatar_path}" }
    end

    context 'when git repo is empty' do
      let(:project) { create(:project) }

      it { is_expected.to eq nil }
    end
  end

  describe '#pipeline_for' do
    let(:project) { create(:project, :repository) }
    let!(:pipeline) { create_pipeline }

    shared_examples 'giving the correct pipeline' do
      it { is_expected.to eq(pipeline) }

      context 'return latest' do
        let!(:pipeline2) { create_pipeline }

        it { is_expected.to eq(pipeline2) }
      end
    end

    context 'with explicit sha' do
      subject { project.pipeline_for('master', pipeline.sha) }

      it_behaves_like 'giving the correct pipeline'
    end

    context 'with implicit sha' do
      subject { project.pipeline_for('master') }

      it_behaves_like 'giving the correct pipeline'
    end

    def create_pipeline
      create(:ci_pipeline,
             project: project,
             ref: 'master',
             sha: project.commit('master').sha)
    end
  end

  describe '#builds_enabled' do
    let(:project) { create(:project) }

    subject { project.builds_enabled }

    it { expect(project.builds_enabled?).to be_truthy }
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
    let(:project1) { create(:project, :public, group: group) }
    let(:project2) { create(:project, :public, group: group) }

    before do
      2.times do
        create(:note_on_commit, project: project1)
      end

      create(:note_on_commit, project: project2)

      TrendingProject.refresh!
    end

    subject { described_class.trending.to_a }

    it 'sorts projects by the amount of notes in descending order' do
      expect(subject).to eq([project1, project2])
    end

    it 'does not take system notes into account' do
      10.times do
        create(:note_on_commit, project: project2, system: true)
      end

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

  describe '.visible_to_user' do
    let!(:project) { create(:project, :private) }
    let!(:user)    { create(:user) }

    subject { described_class.visible_to_user(user) }

    describe 'when a user has access to a project' do
      before do
        project.add_user(user, Gitlab::Access::MASTER)
      end

      it { is_expected.to eq([project]) }
    end

    describe 'when a user does not have access to any projects' do
      it { is_expected.to eq([]) }
    end
  end

  context 'repository storage by default' do
    let(:project) { create(:project) }

    before do
      storages = {
        'default' => { 'path' => 'tmp/tests/repositories' },
        'picked'  => { 'path' => 'tmp/tests/repositories' }
      }
      allow(Gitlab.config.repositories).to receive(:storages).and_return(storages)
    end

    it 'picks storage from ApplicationSetting' do
      expect_any_instance_of(ApplicationSetting).to receive(:pick_repository_storage).and_return('picked')

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

  describe '#any_runners' do
    let(:project) { create(:project, shared_runners_enabled: shared_runners_enabled) }
    let(:specific_runner) { create(:ci_runner) }
    let(:shared_runner) { create(:ci_runner, :shared) }

    context 'for shared runners disabled' do
      let(:shared_runners_enabled) { false }

      it 'has no runners available' do
        expect(project.any_runners?).to be_falsey
      end

      it 'has a specific runner' do
        project.runners << specific_runner
        expect(project.any_runners?).to be_truthy
      end

      it 'has a shared runner, but they are prohibited to use' do
        shared_runner
        expect(project.any_runners?).to be_falsey
      end

      it 'checks the presence of specific runner' do
        project.runners << specific_runner
        expect(project.any_runners? { |runner| runner == specific_runner }).to be_truthy
      end
    end

    context 'for shared runners enabled' do
      let(:shared_runners_enabled) { true }

      it 'has a shared runner' do
        shared_runner
        expect(project.any_runners?).to be_truthy
      end

      it 'checks the presence of shared runner' do
        shared_runner
        expect(project.any_runners? { |runner| runner == shared_runner }).to be_truthy
      end
    end
  end

  describe '#shared_runners' do
    let!(:runner) { create(:ci_runner, :shared) }

    subject { project.shared_runners }

    context 'when shared runners are enabled for project' do
      let!(:project) { create(:project, shared_runners_enabled: true) }

      it "returns a list of shared runners" do
        is_expected.to eq([runner])
      end
    end

    context 'when shared runners are disabled for project' do
      let!(:project) { create(:project, shared_runners_enabled: false) }

      it "returns a empty list" do
        is_expected.to be_empty
      end
    end
  end

  describe '#visibility_level_allowed?' do
    let(:project) { create(:project, :internal) }

    context 'when checking on non-forked project' do
      it { expect(project.visibility_level_allowed?(Gitlab::VisibilityLevel::PRIVATE)).to be_truthy }
      it { expect(project.visibility_level_allowed?(Gitlab::VisibilityLevel::INTERNAL)).to be_truthy }
      it { expect(project.visibility_level_allowed?(Gitlab::VisibilityLevel::PUBLIC)).to be_truthy }
    end

    context 'when checking on forked project' do
      let(:project)        { create(:project, :internal) }
      let(:forked_project) { create(:project, forked_from_project: project) }

      it { expect(forked_project.visibility_level_allowed?(Gitlab::VisibilityLevel::PRIVATE)).to be_truthy }
      it { expect(forked_project.visibility_level_allowed?(Gitlab::VisibilityLevel::INTERNAL)).to be_truthy }
      it { expect(forked_project.visibility_level_allowed?(Gitlab::VisibilityLevel::PUBLIC)).to be_falsey }
    end
  end

  describe '#pages_deployed?' do
    let(:project) { create :project }

    subject { project.pages_deployed? }

    context 'if public folder does exist' do
      before do
        allow(Dir).to receive(:exist?).with(project.public_pages_path).and_return(true)
      end

      it { is_expected.to be_truthy }
    end

    context "if public folder doesn't exist" do
      it { is_expected.to be_falsey }
    end
  end

  describe '#pages_url' do
    let(:group) { create :group, name: group_name }
    let(:project) { create :project, namespace: group, name: project_name }
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
    end

    context 'project page' do
      let(:group_name) { 'Group' }
      let(:project_name) { 'Project' }

      it { is_expected.to eq("http://group.example.com/project") }
    end
  end

  describe '.search' do
    let(:project) { create(:project, description: 'kitten mittens') }

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

    describe 'with pending_delete project' do
      let(:pending_delete_project) { create(:project, pending_delete: true) }

      it 'shows pending deletion project' do
        search_result = described_class.search(pending_delete_project.name)

        expect(search_result).to eq([pending_delete_project])
      end
    end
  end

  describe '#expire_caches_before_rename' do
    let(:project) { create(:project, :repository) }
    let(:repo)    { double(:repo, exists?: true) }
    let(:wiki)    { double(:wiki, exists?: true) }

    it 'expires the caches of the repository and wiki' do
      allow(Repository).to receive(:new)
        .with('foo', project)
        .and_return(repo)

      allow(Repository).to receive(:new)
        .with('foo.wiki', project)
        .and_return(wiki)

      expect(repo).to receive(:before_delete)
      expect(wiki).to receive(:before_delete)

      project.expire_caches_before_rename('foo')
    end
  end

  describe '.search_by_title' do
    let(:project) { create(:project, name: 'kittens') }

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
    let(:private_group)    { create(:group, visibility_level: 0)  }
    let(:internal_group)   { create(:group, visibility_level: 10) }

    let(:private_project)  { create :project, :private, group: private_group }
    let(:internal_project) { create :project, :internal, group: internal_group }

    context 'when group is private project can not be internal' do
      it { expect(private_project.visibility_level_allowed?(Gitlab::VisibilityLevel::INTERNAL)).to be_falsey }
    end

    context 'when group is internal project can not be public' do
      it { expect(internal_project.visibility_level_allowed?(Gitlab::VisibilityLevel::PUBLIC)).to be_falsey }
    end
  end

  describe '#create_repository' do
    let(:project) { create(:project, :repository) }
    let(:shell) { Gitlab::Shell.new }

    before do
      allow(project).to receive(:gitlab_shell).and_return(shell)
    end

    context 'using a regular repository' do
      it 'creates the repository' do
        expect(shell).to receive(:add_repository)
          .with(project.repository_storage, project.disk_path)
          .and_return(true)

        expect(project.repository).to receive(:after_create)

        expect(project.create_repository).to eq(true)
      end

      it 'adds an error if the repository could not be created' do
        expect(shell).to receive(:add_repository)
          .with(project.repository_storage, project.disk_path)
          .and_return(false)

        expect(project.repository).not_to receive(:after_create)

        expect(project.create_repository).to eq(false)
        expect(project.errors).not_to be_empty
      end
    end

    context 'using a forked repository' do
      it 'does nothing' do
        expect(project).to receive(:forked?).and_return(true)
        expect(shell).not_to receive(:add_repository)

        project.create_repository
      end
    end
  end

  describe '#ensure_repository' do
    let(:project) { create(:project, :repository) }
    let(:shell) { Gitlab::Shell.new }

    before do
      allow(project).to receive(:gitlab_shell).and_return(shell)
    end

    it 'creates the repository if it not exist' do
      allow(project).to receive(:repository_exists?)
        .and_return(false)

      allow(shell).to receive(:add_repository)
        .with(project.repository_storage_path, project.disk_path)
        .and_return(true)

      expect(project).to receive(:create_repository).with(force: true)

      project.ensure_repository
    end

    it 'does not create the repository if it exists' do
      allow(project).to receive(:repository_exists?)
        .and_return(true)

      expect(project).not_to receive(:create_repository)

      project.ensure_repository
    end

    it 'creates the repository if it is a fork' do
      expect(project).to receive(:forked?).and_return(true)

      allow(project).to receive(:repository_exists?)
        .and_return(false)

      expect(shell).to receive(:add_repository)
        .with(project.repository_storage, project.disk_path)
        .and_return(true)

      project.ensure_repository
    end
  end

  describe '#user_can_push_to_empty_repo?' do
    let(:project) { create(:project) }
    let(:user)    { create(:user) }

    it 'returns false when default_branch_protection is in full protection and user is developer' do
      project.add_developer(user)
      stub_application_setting(default_branch_protection: Gitlab::Access::PROTECTION_FULL)

      expect(project.user_can_push_to_empty_repo?(user)).to be_falsey
    end

    it 'returns false when default_branch_protection only lets devs merge and user is dev' do
      project.add_developer(user)
      stub_application_setting(default_branch_protection: Gitlab::Access::PROTECTION_DEV_CAN_MERGE)

      expect(project.user_can_push_to_empty_repo?(user)).to be_falsey
    end

    it 'returns true when default_branch_protection lets devs push and user is developer' do
      project.add_developer(user)
      stub_application_setting(default_branch_protection: Gitlab::Access::PROTECTION_DEV_CAN_PUSH)

      expect(project.user_can_push_to_empty_repo?(user)).to be_truthy
    end

    it 'returns true when default_branch_protection is unprotected and user is developer' do
      project.add_developer(user)
      stub_application_setting(default_branch_protection: Gitlab::Access::PROTECTION_NONE)

      expect(project.user_can_push_to_empty_repo?(user)).to be_truthy
    end

    it 'returns true when user is master' do
      project.add_master(user)

      expect(project.user_can_push_to_empty_repo?(user)).to be_truthy
    end
  end

  describe '#container_registry_url' do
    let(:project) { create(:project) }

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

  describe '#has_container_registry_tags?' do
    let(:project) { create(:project) }

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

        it 'should have image tags' do
          expect(project).to have_container_registry_tags
        end
      end

      context 'when tags are present for root repository' do
        before do
          stub_container_registry_tags(repository: project.full_path,
                                       tags: %w[latest rc1 pre1])
        end

        it 'should have image tags' do
          expect(project).to have_container_registry_tags
        end
      end

      context 'when there are no tags at all' do
        before do
          stub_container_registry_tags(repository: :any, tags: [])
        end

        it 'should not have image tags' do
          expect(project).not_to have_container_registry_tags
        end
      end
    end

    context 'when container registry is disabled' do
      before do
        stub_container_registry_config(enabled: false)
      end

      it 'should not have image tags' do
        expect(project).not_to have_container_registry_tags
      end

      it 'should not check root repository tags' do
        expect(project).not_to receive(:full_path)
        expect(project).not_to have_container_registry_tags
      end

      it 'should iterate through container repositories' do
        expect(project).to receive(:container_repositories)
        expect(project).not_to have_container_registry_tags
      end
    end
  end

  describe '#ci_config_path=' do
    let(:project) { create(:project) }

    it 'sets nil' do
      project.update!(ci_config_path: nil)

      expect(project.ci_config_path).to be_nil
    end

    it 'sets a string' do
      project.update!(ci_config_path: 'foo/.gitlab_ci.yml')

      expect(project.ci_config_path).to eq('foo/.gitlab_ci.yml')
    end

    it 'sets a string but removes all null characters' do
      project.update!(ci_config_path: "f\0oo/\0/.gitlab_ci.yml")

      expect(project.ci_config_path).to eq('foo//.gitlab_ci.yml')
    end
  end

  describe 'Project import job' do
    let(:project) { create(:project, import_url: generate(:url)) }

    before do
      allow_any_instance_of(Gitlab::Shell).to receive(:import_repository)
        .with(project.repository_storage_path, project.disk_path, project.import_url)
        .and_return(true)

      expect_any_instance_of(Repository).to receive(:after_import)
        .and_call_original
    end

    it 'imports a project' do
      expect_any_instance_of(RepositoryImportWorker).to receive(:perform).and_call_original

      expect { project.import_schedule }.to change { project.import_jid }
      expect(project.reload.import_status).to eq('finished')
    end
  end

  describe 'project import state transitions' do
    context 'state transition: [:started] => [:finished]' do
      let(:after_import_service) { spy(:after_import_service) }
      let(:housekeeping_service) { spy(:housekeeping_service) }

      before do
        allow(Projects::AfterImportService)
          .to receive(:new) { after_import_service }

        allow(after_import_service)
          .to receive(:execute) { housekeeping_service.execute }

        allow(Projects::HousekeepingService)
          .to receive(:new) { housekeeping_service }
      end

      it 'resets project import_error' do
        error_message = 'Some error'
        mirror = create(:project_empty_repo, :import_started, import_error: error_message)

        expect { mirror.import_finish }.to change { mirror.import_error }.from(error_message).to(nil)
      end

      it 'performs housekeeping when an import of a fresh project is completed' do
        project = create(:project_empty_repo, :import_started, import_type: :github)

        project.import_finish

        expect(after_import_service).to have_received(:execute)
        expect(housekeeping_service).to have_received(:execute)
      end

      it 'does not perform housekeeping when project repository does not exist' do
        project = create(:project, :import_started, import_type: :github)

        project.import_finish

        expect(housekeeping_service).not_to have_received(:execute)
      end

      it 'does not perform housekeeping when project does not have a valid import type' do
        project = create(:project, :import_started, import_type: nil)

        project.import_finish

        expect(housekeeping_service).not_to have_received(:execute)
      end
    end
  end

  describe '#latest_successful_builds_for' do
    def create_pipeline(status = 'success')
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

    let(:project) { create(:project, :repository) }
    let(:pipeline) { create_pipeline }

    context 'with many builds' do
      it 'gives the latest builds from latest pipeline' do
        pipeline1 = create_pipeline
        pipeline2 = create_pipeline
        build1_p2 = create_build(pipeline2, 'test')
        create_build(pipeline1, 'test')
        create_build(pipeline1, 'test2')
        build2_p2 = create_build(pipeline2, 'test2')

        latest_builds = project.latest_successful_builds_for

        expect(latest_builds).to contain_exactly(build2_p2, build1_p2)
      end
    end

    context 'with succeeded pipeline' do
      let!(:build) { create_build }

      context 'standalone pipeline' do
        it 'returns builds for ref for default_branch' do
          builds = project.latest_successful_builds_for

          expect(builds).to contain_exactly(build)
        end

        it 'returns empty relation if the build cannot be found' do
          builds = project.latest_successful_builds_for('TAIL')

          expect(builds).to be_kind_of(ActiveRecord::Relation)
          expect(builds).to be_empty
        end
      end

      context 'with some pending pipeline' do
        before do
          create_build(create_pipeline('pending'))
        end

        it 'gives the latest build from latest pipeline' do
          latest_build = project.latest_successful_builds_for

          expect(latest_build).to contain_exactly(build)
        end
      end
    end

    context 'with pending pipeline' do
      before do
        pipeline.update(status: 'pending')
        create_build(pipeline)
      end

      it 'returns empty relation' do
        builds = project.latest_successful_builds_for

        expect(builds).to be_kind_of(ActiveRecord::Relation)
        expect(builds).to be_empty
      end
    end
  end

  describe '#add_import_job' do
    let(:import_jid) { '123' }

    context 'forked' do
      let(:forked_project_link) { create(:forked_project_link, :forked_to_empty_project) }
      let(:forked_from_project) { forked_project_link.forked_from_project }
      let(:project) { forked_project_link.forked_to_project }

      it 'schedules a RepositoryForkWorker job' do
        expect(RepositoryForkWorker).to receive(:perform_async).with(
          project.id,
          forked_from_project.repository_storage_path,
          forked_from_project.disk_path).and_return(import_jid)

        expect(project.add_import_job).to eq(import_jid)
      end
    end

    context 'not forked' do
      it 'schedules a RepositoryImportWorker job' do
        project = create(:project, import_url: generate(:url))

        expect(RepositoryImportWorker).to receive(:perform_async).with(project.id).and_return(import_jid)
        expect(project.add_import_job).to eq(import_jid)
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

  describe '#ancestors_upto', :nested_groups do
    let(:parent) { create(:group) }
    let(:child) { create(:group, parent: parent) }
    let(:child2) { create(:group, parent: child) }
    let(:project) { create(:project, namespace: child2) }

    it 'returns all ancestors when no namespace is given' do
      expect(project.ancestors_upto).to contain_exactly(child2, child, parent)
    end

    it 'includes ancestors upto but excluding the given ancestor' do
      expect(project.ancestors_upto(parent)).to contain_exactly(child2, child)
    end
  end

  describe '#lfs_enabled?' do
    let(:project) { create(:project) }

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
        project.namespace.update_attribute(:lfs_enabled, false)
        enable_lfs
      end

      it_behaves_like 'project overrides group'
    end

    context 'LFS enabled in group' do
      before do
        project.namespace.update_attribute(:lfs_enabled, true)
        enable_lfs
      end

      it_behaves_like 'project overrides group'
    end

    describe 'LFS disabled globally' do
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
    let(:project) { create(:project, :repository) }

    it 'returns error if branch does not exist' do
      expect(project.change_head('unexisted-branch')).to be false
      expect(project.errors.size).to eq(1)
    end

    it 'calls the before_change_head and after_change_head methods' do
      expect(project.repository).to receive(:before_change_head)
      expect(project.repository).to receive(:after_change_head)

      project.change_head(project.default_branch)
    end

    it 'creates the new reference with rugged' do
      expect(project.repository.rugged.references).to receive(:create).with('HEAD',
                                                                            "refs/heads/#{project.default_branch}",
                                                                            force: true)
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

      it 'is true for a fork of a fork', :postgresql do
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
        forked_project.destroy

        expect(second_fork.fork_source).to eq(project)
      end

      it 'returns nil if it is the root of the fork network' do
        expect(project.fork_source).to be_nil
      end
    end

    describe '#lfs_storage_project' do
      it 'returns self for non-forks' do
        expect(project.lfs_storage_project).to eq project
      end

      it 'returns the fork network root for forks' do
        second_fork = fork_project(forked_project)

        expect(second_fork.lfs_storage_project).to eq project
      end

      it 'returns self when fork_source is nil' do
        expect(forked_project).to receive(:fork_source).and_return(nil)

        expect(forked_project.lfs_storage_project).to eq forked_project
      end
    end
  end

  describe '#pushes_since_gc' do
    let(:project) { create(:project) }

    after do
      project.reset_pushes_since_gc
    end

    context 'without any pushes' do
      it 'returns 0' do
        expect(project.pushes_since_gc).to eq(0)
      end
    end

    context 'with a number of pushes' do
      it 'returns the number of pushes' do
        3.times { project.increment_pushes_since_gc }

        expect(project.pushes_since_gc).to eq(3)
      end
    end
  end

  describe '#increment_pushes_since_gc' do
    let(:project) { create(:project) }

    after do
      project.reset_pushes_since_gc
    end

    it 'increments the number of pushes since the last GC' do
      3.times { project.increment_pushes_since_gc }

      expect(project.pushes_since_gc).to eq(3)
    end
  end

  describe '#reset_pushes_since_gc' do
    let(:project) { create(:project) }

    after do
      project.reset_pushes_since_gc
    end

    it 'resets the number of pushes since the last GC' do
      3.times { project.increment_pushes_since_gc }

      project.reset_pushes_since_gc

      expect(project.pushes_since_gc).to eq(0)
    end
  end

  describe '#deployment_variables' do
    context 'when project has no deployment service' do
      let(:project) { create(:project) }

      it 'returns an empty array' do
        expect(project.deployment_variables).to eq []
      end
    end

    context 'when project has a deployment service' do
      shared_examples 'same behavior between KubernetesService and Platform::Kubernetes' do
        it 'returns variables from this service' do
          expect(project.deployment_variables).to include(
            { key: 'KUBE_TOKEN', value: project.deployment_platform.token, public: false }
          )
        end
      end

      context 'when user configured kubernetes from Integration > Kubernetes' do
        let(:project) { create(:kubernetes_project) }

        it_behaves_like 'same behavior between KubernetesService and Platform::Kubernetes'
      end

      context 'when user configured kubernetes from CI/CD > Clusters' do
        let!(:cluster) { create(:cluster, :project, :provided_by_gcp) }
        let(:project) { cluster.project }

        it_behaves_like 'same behavior between KubernetesService and Platform::Kubernetes'
      end
    end
  end

  describe '#secret_variables_for' do
    let(:project) { create(:project) }

    let!(:secret_variable) do
      create(:ci_variable, value: 'secret', project: project)
    end

    let!(:protected_variable) do
      create(:ci_variable, :protected, value: 'protected', project: project)
    end

    subject { project.secret_variables_for(ref: 'ref') }

    before do
      stub_application_setting(
        default_branch_protection: Gitlab::Access::PROTECTION_NONE)
    end

    shared_examples 'ref is protected' do
      it 'contains all the variables' do
        is_expected.to contain_exactly(secret_variable, protected_variable)
      end
    end

    context 'when the ref is not protected' do
      it 'contains only the secret variables' do
        is_expected.to contain_exactly(secret_variable)
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
  end

  describe '#protected_for?' do
    let(:project) { create(:project) }

    subject { project.protected_for?('ref') }

    context 'when the ref is not protected' do
      before do
        stub_application_setting(
          default_branch_protection: Gitlab::Access::PROTECTION_NONE)
      end

      it 'returns false' do
        is_expected.to be_falsey
      end
    end

    context 'when the ref is a protected branch' do
      before do
        allow(project).to receive(:repository).and_call_original
        allow(project).to receive_message_chain(:repository, :branch_exists?).and_return(true)
        create(:protected_branch, name: 'ref', project: project)
      end

      it 'returns true' do
        is_expected.to be_truthy
      end
    end

    context 'when the ref is a protected tag' do
      before do
        allow(project).to receive_message_chain(:repository, :branch_exists?).and_return(false)
        allow(project).to receive_message_chain(:repository, :tag_exists?).and_return(true)
        create(:protected_tag, name: 'ref', project: project)
      end

      it 'returns true' do
        is_expected.to be_truthy
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
      project.update(namespace: namespace)

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
      project.namespace_id = 7
    end

    it { expect(project.parent_changed?).to be_truthy }
  end

  def enable_lfs
    allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)
  end

  describe '#pages_url' do
    let(:group) { create :group, name: 'Group' }
    let(:nested_group) { create :group, parent: group }
    let(:domain) { 'Example.com' }

    subject { project.pages_url }

    before do
      allow(Settings.pages).to receive(:host).and_return(domain)
      allow(Gitlab.config.pages).to receive(:url).and_return('http://example.com')
    end

    context 'top-level group' do
      let(:project) { create :project, namespace: group, name: project_name }

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
      let(:project) { create :project, namespace: nested_group, name: project_name }
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

  describe '#http_url_to_repo' do
    let(:project) { create :project }

    it 'returns the url to the repo without a username' do
      expect(project.http_url_to_repo).to eq("#{project.web_url}.git")
      expect(project.http_url_to_repo).not_to include('@')
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

  describe '#append_or_update_attribute' do
    let(:project) { create(:project) }

    it 'shows full error updating an invalid MR' do
      error_message = 'Failed to replace merge_requests because one or more of the new records could not be saved.'\
                      ' Validate fork Source project is not a fork of the target project'

      expect { project.append_or_update_attribute(:merge_requests, [create(:merge_request)]) }
        .to raise_error(ActiveRecord::RecordNotSaved, error_message)
    end

    it 'updates the project succesfully' do
      merge_request = create(:merge_request, target_project: project, source_project: project)

      expect { project.append_or_update_attribute(:merge_requests, [merge_request]) }
        .not_to raise_error
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

      it { is_expected.to be(false) }
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

  describe '#remove_pages' do
    let(:project) { create(:project) }
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

    it 'removes the pages directory' do
      expect_any_instance_of(Projects::UpdatePagesConfigurationService).to receive(:execute)
      expect_any_instance_of(Gitlab::PagesTransfer).to receive(:rename_project).and_return(true)
      expect(PagesWorker).to receive(:perform_in).with(5.minutes, :remove, namespace.full_path, anything)

      project.remove_pages
    end

    it 'is a no-op when there is no namespace' do
      project.update_column(:namespace_id, nil)

      expect_any_instance_of(Projects::UpdatePagesConfigurationService).not_to receive(:execute)
      expect_any_instance_of(Gitlab::PagesTransfer).not_to receive(:rename_project)

      project.remove_pages
    end

    it 'is run when the project is destroyed' do
      expect(project).to receive(:remove_pages).and_call_original

      project.destroy
    end
  end

  describe '#forks_count' do
    it 'returns the number of forks' do
      project = build(:project)

      expect_any_instance_of(Projects::ForksCountService).to receive(:count).and_return(1)

      expect(project.forks_count).to eq(1)
    end
  end

  context 'legacy storage' do
    let(:project) { create(:project, :repository) }
    let(:gitlab_shell) { Gitlab::Shell.new }
    let(:project_storage) { project.send(:storage) }

    before do
      allow(project).to receive(:gitlab_shell).and_return(gitlab_shell)
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

    describe '#ensure_storage_path_exists' do
      it 'delegates to gitlab_shell to ensure namespace is created' do
        expect(gitlab_shell).to receive(:add_namespace).with(project.repository_storage_path, project.base_dir)

        project.ensure_storage_path_exists
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

    describe '#rename_repo' do
      before do
        # Project#gitlab_shell returns a new instance of Gitlab::Shell on every
        # call. This makes testing a bit easier.
        allow(project).to receive(:gitlab_shell).and_return(gitlab_shell)
        allow(project).to receive(:previous_changes).and_return('path' => ['foo'])
      end

      it 'renames a repository' do
        stub_container_registry_config(enabled: false)

        expect(gitlab_shell).to receive(:mv_repository)
          .ordered
          .with(project.repository_storage_path, "#{project.namespace.full_path}/foo", "#{project.full_path}")
          .and_return(true)

        expect(gitlab_shell).to receive(:mv_repository)
          .ordered
          .with(project.repository_storage_path, "#{project.namespace.full_path}/foo.wiki", "#{project.full_path}.wiki")
          .and_return(true)

        expect_any_instance_of(SystemHooksService)
          .to receive(:execute_hooks_for)
            .with(project, :rename)

        expect_any_instance_of(Gitlab::UploadsTransfer)
          .to receive(:rename_project)
            .with('foo', project.path, project.namespace.full_path)

        expect(project).to receive(:expire_caches_before_rename)

        expect(project).to receive(:expires_full_path_cache)

        project.rename_repo
      end

      context 'container registry with images' do
        let(:container_repository) { create(:container_repository) }

        before do
          stub_container_registry_config(enabled: true)
          stub_container_registry_tags(repository: :any, tags: ['tag'])
          project.container_repositories << container_repository
        end

        subject { project.rename_repo }

        it { expect { subject }.to raise_error(StandardError) }
      end

      context 'gitlab pages' do
        before do
          expect(project_storage).to receive(:rename_repo) { true }
        end

        it 'moves pages folder to new location' do
          expect_any_instance_of(Gitlab::PagesTransfer).to receive(:rename_project)

          project.rename_repo
        end
      end

      context 'attachments' do
        before do
          expect(project_storage).to receive(:rename_repo) { true }
        end

        it 'moves uploads folder to new location' do
          expect_any_instance_of(Gitlab::UploadsTransfer).to receive(:rename_project)

          project.rename_repo
        end
      end

      it 'updates project full path in .git/config' do
        allow(project_storage).to receive(:rename_repo).and_return(true)

        project.rename_repo

        expect(project.repository.rugged.config['gitlab.fullpath']).to eq(project.full_path)
      end
    end

    describe '#pages_path' do
      it 'returns a path where pages are stored' do
        expect(project.pages_path).to eq(File.join(Settings.pages.path, project.namespace.full_path, project.path))
      end
    end

    describe '#migrate_to_hashed_storage!' do
      it 'returns true' do
        expect(project.migrate_to_hashed_storage!).to be_truthy
      end

      it 'flags as read-only' do
        expect { project.migrate_to_hashed_storage! }.to change { project.repository_read_only }.to(true)
      end

      it 'schedules ProjectMigrateHashedStorageWorker with delayed start when the project repo is in use' do
        Gitlab::ReferenceCounter.new(project.gl_repository(is_wiki: false)).increase

        expect(ProjectMigrateHashedStorageWorker).to receive(:perform_in)

        project.migrate_to_hashed_storage!
      end

      it 'schedules ProjectMigrateHashedStorageWorker with delayed start when the wiki repo is in use' do
        Gitlab::ReferenceCounter.new(project.gl_repository(is_wiki: true)).increase

        expect(ProjectMigrateHashedStorageWorker).to receive(:perform_in)

        project.migrate_to_hashed_storage!
      end

      it 'schedules ProjectMigrateHashedStorageWorker' do
        expect(ProjectMigrateHashedStorageWorker).to receive(:perform_async).with(project.id)

        project.migrate_to_hashed_storage!
      end
    end
  end

  context 'hashed storage' do
    let(:project) { create(:project, :repository, skip_disk_validation: true) }
    let(:gitlab_shell) { Gitlab::Shell.new }
    let(:hash) { Digest::SHA2.hexdigest(project.id.to_s) }

    before do
      stub_application_setting(hashed_storage_enabled: true)
    end

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
        expect(project.base_dir).to eq("@hashed/#{hash[0..1]}/#{hash[2..3]}")
      end
    end

    describe '#disk_path' do
      it 'returns disk_path based on hash of project id' do
        hashed_path = "@hashed/#{hash[0..1]}/#{hash[2..3]}/#{hash}"

        expect(project.disk_path).to eq(hashed_path)
      end
    end

    describe '#ensure_storage_path_exists' do
      it 'delegates to gitlab_shell to ensure namespace is created' do
        allow(project).to receive(:gitlab_shell).and_return(gitlab_shell)

        expect(gitlab_shell).to receive(:add_namespace).with(project.repository_storage_path, "@hashed/#{hash[0..1]}/#{hash[2..3]}")

        project.ensure_storage_path_exists
      end
    end

    describe '#rename_repo' do
      before do
        # Project#gitlab_shell returns a new instance of Gitlab::Shell on every
        # call. This makes testing a bit easier.
        allow(project).to receive(:gitlab_shell).and_return(gitlab_shell)
        allow(project).to receive(:previous_changes).and_return('path' => ['foo'])
      end

      it 'renames a repository' do
        stub_container_registry_config(enabled: false)

        expect(gitlab_shell).not_to receive(:mv_repository)

        expect_any_instance_of(SystemHooksService)
          .to receive(:execute_hooks_for)
            .with(project, :rename)

        expect(project).to receive(:expire_caches_before_rename)

        expect(project).to receive(:expires_full_path_cache)

        project.rename_repo
      end

      context 'container registry with images' do
        let(:container_repository) { create(:container_repository) }

        before do
          stub_container_registry_config(enabled: true)
          stub_container_registry_tags(repository: :any, tags: ['tag'])
          project.container_repositories << container_repository
        end

        subject { project.rename_repo }

        it { expect { subject }.to raise_error(StandardError) }
      end

      context 'gitlab pages' do
        it 'moves pages folder to new location' do
          expect_any_instance_of(Gitlab::PagesTransfer).to receive(:rename_project)

          project.rename_repo
        end
      end

      context 'attachments' do
        it 'keeps uploads folder location unchanged' do
          expect_any_instance_of(Gitlab::UploadsTransfer).not_to receive(:rename_project)

          project.rename_repo
        end

        context 'when not rolled out' do
          let(:project) { create(:project, :repository, storage_version: 1, skip_disk_validation: true) }

          it 'moves pages folder to new location' do
            expect_any_instance_of(Gitlab::UploadsTransfer).to receive(:rename_project)

            project.rename_repo
          end
        end
      end

      it 'updates project full path in .git/config' do
        project.rename_repo

        expect(project.repository.rugged.config['gitlab.fullpath']).to eq(project.full_path)
      end
    end

    describe '#pages_path' do
      it 'returns a path where pages are stored' do
        expect(project.pages_path).to eq(File.join(Settings.pages.path, project.namespace.full_path, project.path))
      end
    end

    describe '#migrate_to_hashed_storage!' do
      it 'returns nil' do
        expect(project.migrate_to_hashed_storage!).to be_nil
      end

      it 'does not flag as read-only' do
        expect { project.migrate_to_hashed_storage! }.not_to change { project.repository_read_only }
      end
    end
  end

  describe '#gl_repository' do
    let(:project) { create(:project) }

    it 'delegates to Gitlab::GlRepository.gl_repository' do
      expect(Gitlab::GlRepository).to receive(:gl_repository).with(project, true)

      project.gl_repository(is_wiki: true)
    end
  end

  describe '#has_ci?' do
    set(:project) { create(:project) }
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

      it "CI is not available" do
        expect(project).not_to have_ci
      end

      context 'when auto devops is enabled' do
        before do
          stub_application_setting(auto_devops_enabled: true)
        end

        it "CI is available" do
          expect(project).to have_ci
        end
      end
    end
  end

  describe '#auto_devops_enabled?' do
    set(:project) { create(:project) }

    subject { project.auto_devops_enabled? }

    context 'when enabled in settings' do
      before do
        stub_application_setting(auto_devops_enabled: true)
      end

      it 'auto devops is implicitly enabled' do
        expect(project.auto_devops).to be_nil
        expect(project).to be_auto_devops_enabled
      end

      context 'when explicitly enabled' do
        before do
          create(:project_auto_devops, project: project)
        end

        it "auto devops is enabled" do
          expect(project).to be_auto_devops_enabled
        end
      end

      context 'when explicitly disabled' do
        before do
          create(:project_auto_devops, project: project, enabled: false)
        end

        it "auto devops is disabled" do
          expect(project).not_to be_auto_devops_enabled
        end
      end
    end

    context 'when disabled in settings' do
      before do
        stub_application_setting(auto_devops_enabled: false)
      end

      it 'auto devops is implicitly disabled' do
        expect(project.auto_devops).to be_nil
        expect(project).not_to be_auto_devops_enabled
      end

      context 'when explicitly enabled' do
        before do
          create(:project_auto_devops, project: project)
        end

        it "auto devops is enabled" do
          expect(project).to be_auto_devops_enabled
        end
      end
    end
  end

  describe '#has_auto_devops_implicitly_disabled?' do
    set(:project) { create(:project) }

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
          create(:project_auto_devops, project: project)
        end

        it 'does not have auto devops implicitly disabled' do
          expect(project).not_to have_auto_devops_implicitly_disabled
        end
      end
    end
  end

  context '#auto_devops_variables' do
    set(:project) { create(:project) }

    subject { project.auto_devops_variables }

    context 'when enabled in settings' do
      before do
        stub_application_setting(auto_devops_enabled: true)
      end

      context 'when domain is empty' do
        before do
          create(:project_auto_devops, project: project, domain: nil)
        end

        it 'variables are empty' do
          is_expected.to be_empty
        end
      end

      context 'when domain is configured' do
        before do
          create(:project_auto_devops, project: project, domain: 'example.com')
        end

        it "variables are not empty" do
          is_expected.not_to be_empty
        end
      end
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
        expect(project.pipelines).to receive(:latest_successful_for).with('foo')

        project.latest_successful_pipeline_for('foo')
      end
    end
  end

  describe '#check_repository_path_availability' do
    let(:project) { build(:project) }

    it 'skips gitlab-shell exists?' do
      project.skip_disk_validation = true

      expect(project.gitlab_shell).not_to receive(:exists?)
      expect(project.check_repository_path_availability).to be_truthy
    end
  end

  describe '#latest_successful_pipeline_for_default_branch' do
    let(:project) { build(:project) }

    before do
      allow(project).to receive(:default_branch).and_return('master')
    end

    it 'memoizes and returns the latest successful pipeline for the default branch' do
      pipeline = double(:pipeline)

      expect(project.pipelines).to receive(:latest_successful_for)
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
    let(:project) { build(:project) }

    it 'runs the correct hooks' do
      expect(project.repository).to receive(:after_import)
      expect(project).to receive(:import_finish)
      expect(project).to receive(:update_project_counter_caches)
      expect(project).to receive(:remove_import_jid)
      expect(project).to receive(:after_create_default_branch)

      project.after_import
    end

    context 'branch protection' do
      let(:project) { create(:project, :repository) }

      it 'does not protect when branch protection is disabled' do
        stub_application_setting(default_branch_protection: Gitlab::Access::PROTECTION_NONE)

        project.after_import

        expect(project.protected_branches).to be_empty
      end

      it "gives developer access to push when branch protection is set to 'developers can push'" do
        stub_application_setting(default_branch_protection: Gitlab::Access::PROTECTION_DEV_CAN_PUSH)

        project.after_import

        expect(project.protected_branches).not_to be_empty
        expect(project.default_branch).to eq(project.protected_branches.first.name)
        expect(project.protected_branches.first.push_access_levels.map(&:access_level)).to eq([Gitlab::Access::DEVELOPER])
      end

      it "gives developer access to merge when branch protection is set to 'developers can merge'" do
        stub_application_setting(default_branch_protection: Gitlab::Access::PROTECTION_DEV_CAN_MERGE)

        project.after_import

        expect(project.protected_branches).not_to be_empty
        expect(project.default_branch).to eq(project.protected_branches.first.name)
        expect(project.protected_branches.first.merge_access_levels.map(&:access_level)).to eq([Gitlab::Access::DEVELOPER])
      end

      it 'protects default branch' do
        project.after_import

        expect(project.protected_branches).not_to be_empty
        expect(project.default_branch).to eq(project.protected_branches.first.name)
        expect(project.protected_branches.first.push_access_levels.map(&:access_level)).to eq([Gitlab::Access::MASTER])
        expect(project.protected_branches.first.merge_access_levels.map(&:access_level)).to eq([Gitlab::Access::MASTER])
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

  describe '#remove_import_jid', :clean_gitlab_redis_cache do
    let(:project) {  }

    context 'without an import JID' do
      it 'does nothing' do
        project = create(:project)

        expect(Gitlab::SidekiqStatus)
          .not_to receive(:unset)

        project.remove_import_jid
      end
    end

    context 'with an import JID' do
      it 'unsets the import JID' do
        project = create(:project, import_jid: '123')

        expect(Gitlab::SidekiqStatus)
          .to receive(:unset)
          .with('123')
          .and_call_original

        project.remove_import_jid

        expect(project.import_jid).to be_nil
      end
    end
  end

  describe '#wiki_repository_exists?' do
    it 'returns true when the wiki repository exists' do
      project = create(:project, :wiki_repo)

      expect(project.wiki_repository_exists?).to eq(true)
    end

    it 'returns false when the wiki repository does not exist' do
      project = create(:project)

      expect(project.wiki_repository_exists?).to eq(false)
    end
  end

  describe '#write_repository_config' do
    set(:project) { create(:project, :repository) }

    it 'writes full path in .git/config when key is missing' do
      project.write_repository_config

      expect(project.repository.rugged.config['gitlab.fullpath']).to eq project.full_path
    end

    it 'updates full path in .git/config when key is present' do
      project.write_repository_config(gl_full_path: 'old/path')

      expect { project.write_repository_config }.to change { project.repository.rugged.config['gitlab.fullpath'] }.from('old/path').to(project.full_path)
    end

    it 'does not raise an error with an empty repository' do
      project = create(:project_empty_repo)

      expect { project.write_repository_config }.not_to raise_error
    end
  end
end
