require 'spec_helper'

describe Project, models: true do
  describe 'associations' do
    it { is_expected.to belong_to(:group) }
    it { is_expected.to belong_to(:namespace) }
    it { is_expected.to belong_to(:creator).class_name('User') }
    it { is_expected.to have_many(:users) }
    it { is_expected.to have_many(:services) }
    it { is_expected.to have_many(:events).dependent(:destroy) }
    it { is_expected.to have_many(:merge_requests).dependent(:destroy) }
    it { is_expected.to have_many(:issues).dependent(:destroy) }
    it { is_expected.to have_many(:milestones).dependent(:destroy) }
    it { is_expected.to have_many(:project_members).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:project_members) }
    it { is_expected.to have_many(:requesters).dependent(:destroy) }
    it { is_expected.to have_many(:notes).dependent(:destroy) }
    it { is_expected.to have_many(:snippets).class_name('ProjectSnippet').dependent(:destroy) }
    it { is_expected.to have_many(:deploy_keys_projects).dependent(:destroy) }
    it { is_expected.to have_many(:deploy_keys) }
    it { is_expected.to have_many(:hooks).dependent(:destroy) }
    it { is_expected.to have_many(:protected_branches).dependent(:destroy) }
    it { is_expected.to have_many(:chat_services) }
    it { is_expected.to have_one(:forked_project_link).dependent(:destroy) }
    it { is_expected.to have_one(:slack_service).dependent(:destroy) }
    it { is_expected.to have_one(:pushover_service).dependent(:destroy) }
    it { is_expected.to have_one(:asana_service).dependent(:destroy) }
    it { is_expected.to have_many(:boards).dependent(:destroy) }
    it { is_expected.to have_one(:campfire_service).dependent(:destroy) }
    it { is_expected.to have_one(:drone_ci_service).dependent(:destroy) }
    it { is_expected.to have_one(:emails_on_push_service).dependent(:destroy) }
    it { is_expected.to have_one(:builds_email_service).dependent(:destroy) }
    it { is_expected.to have_one(:emails_on_push_service).dependent(:destroy) }
    it { is_expected.to have_one(:irker_service).dependent(:destroy) }
    it { is_expected.to have_one(:pivotaltracker_service).dependent(:destroy) }
    it { is_expected.to have_one(:hipchat_service).dependent(:destroy) }
    it { is_expected.to have_one(:flowdock_service).dependent(:destroy) }
    it { is_expected.to have_one(:assembla_service).dependent(:destroy) }
    it { is_expected.to have_one(:mattermost_slash_commands_service).dependent(:destroy) }
    it { is_expected.to have_one(:gemnasium_service).dependent(:destroy) }
    it { is_expected.to have_one(:buildkite_service).dependent(:destroy) }
    it { is_expected.to have_one(:bamboo_service).dependent(:destroy) }
    it { is_expected.to have_one(:teamcity_service).dependent(:destroy) }
    it { is_expected.to have_one(:jira_service).dependent(:destroy) }
    it { is_expected.to have_one(:redmine_service).dependent(:destroy) }
    it { is_expected.to have_one(:custom_issue_tracker_service).dependent(:destroy) }
    it { is_expected.to have_one(:bugzilla_service).dependent(:destroy) }
    it { is_expected.to have_one(:gitlab_issue_tracker_service).dependent(:destroy) }
    it { is_expected.to have_one(:external_wiki_service).dependent(:destroy) }
    it { is_expected.to have_one(:project_feature).dependent(:destroy) }
    it { is_expected.to have_one(:import_data).class_name('ProjectImportData').dependent(:destroy) }
    it { is_expected.to have_one(:last_event).class_name('Event') }
    it { is_expected.to have_one(:forked_from_project).through(:forked_project_link) }
    it { is_expected.to have_many(:commit_statuses) }
    it { is_expected.to have_many(:pipelines) }
    it { is_expected.to have_many(:builds) }
    it { is_expected.to have_many(:runner_projects) }
    it { is_expected.to have_many(:runners) }
    it { is_expected.to have_many(:variables) }
    it { is_expected.to have_many(:triggers) }
    it { is_expected.to have_many(:labels).class_name('ProjectLabel').dependent(:destroy) }
    it { is_expected.to have_many(:users_star_projects).dependent(:destroy) }
    it { is_expected.to have_many(:environments).dependent(:destroy) }
    it { is_expected.to have_many(:deployments).dependent(:destroy) }
    it { is_expected.to have_many(:todos).dependent(:destroy) }
    it { is_expected.to have_many(:releases).dependent(:destroy) }
    it { is_expected.to have_many(:lfs_objects_projects).dependent(:destroy) }
    it { is_expected.to have_many(:project_group_links).dependent(:destroy) }
    it { is_expected.to have_many(:notification_settings).dependent(:destroy) }
    it { is_expected.to have_many(:forks).through(:forked_project_links) }

    context 'after initialized' do
      it "has a project_feature" do
        project = FactoryGirl.build(:project)

        expect(project.project_feature.present?).to be_present
      end
    end

    describe '#members & #requesters' do
      let(:project) { create(:empty_project, :public, :access_requestable) }
      let(:requester) { create(:user) }
      let(:developer) { create(:user) }
      before do
        project.request_access(requester)
        project.team << [developer, :developer]
      end

      describe '#members' do
        it 'includes members and exclude requesters' do
          member_user_ids = project.members.pluck(:user_id)

          expect(member_user_ids).to include(developer.id)
          expect(member_user_ids).not_to include(requester.id)
        end
      end

      describe '#requesters' do
        it 'does not include requesters' do
          requester_user_ids = project.requesters.pluck(:user_id)

          expect(requester_user_ids).to include(requester.id)
          expect(requester_user_ids).not_to include(developer.id)
        end
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
    it { is_expected.to validate_length_of(:name).is_within(0..255) }

    it { is_expected.to validate_presence_of(:path) }
    it { is_expected.to validate_uniqueness_of(:path).scoped_to(:namespace_id) }
    it { is_expected.to validate_length_of(:path).is_within(0..255) }
    it { is_expected.to validate_length_of(:description).is_within(0..2000) }
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

    context 'repository storages inclussion' do
      let(:project2) { build(:project, repository_storage: 'missing') }

      before do
        storages = { 'custom' => 'tmp/tests/custom_repositories' }
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
  end

  describe 'default_scope' do
    it 'excludes projects pending deletion from the results' do
      project = create(:empty_project)
      create(:empty_project, pending_delete: true)

      expect(Project.all).to eq [project]
    end
  end

  describe 'project token' do
    it 'sets an random token if none provided' do
      project = FactoryGirl.create :empty_project, runners_token: ''
      expect(project.runners_token).not_to eq('')
    end

    it 'does not set an random token if one provided' do
      project = FactoryGirl.create :empty_project, runners_token: 'my-token'
      expect(project.runners_token).to eq('my-token')
    end
  end

  describe 'Respond to' do
    it { is_expected.to respond_to(:url_to_repo) }
    it { is_expected.to respond_to(:repo_exists?) }
    it { is_expected.to respond_to(:execute_hooks) }
    it { is_expected.to respond_to(:owner) }
    it { is_expected.to respond_to(:path_with_namespace) }
  end

  describe '#name_with_namespace' do
    let(:project) { build_stubbed(:empty_project) }

    it { expect(project.name_with_namespace).to eq "#{project.namespace.human_name} / #{project.name}" }
    it { expect(project.human_name).to eq project.name_with_namespace }
  end

  describe '#to_reference' do
    let(:project) { create(:empty_project) }

    it 'returns a String reference to the object' do
      expect(project.to_reference).to eq project.path_with_namespace
    end
  end

  describe '#repository_storage_path' do
    let(:project) { create(:project, repository_storage: 'custom') }

    before do
      FileUtils.mkdir('tmp/tests/custom_repositories')
      storages = { 'custom' => 'tmp/tests/custom_repositories' }
      allow(Gitlab.config.repositories).to receive(:storages).and_return(storages)
    end

    after do
      FileUtils.rm_rf('tmp/tests/custom_repositories')
    end

    it 'returns the repository storage path' do
      expect(project.repository_storage_path).to eq('tmp/tests/custom_repositories')
    end
  end

  it 'returns valid url to repo' do
    project = Project.new(path: 'somewhere')
    expect(project.url_to_repo).to eq(Gitlab.config.gitlab_shell.ssh_path_prefix + 'somewhere.git')
  end

  describe "#web_url" do
    let(:project) { create(:empty_project, path: "somewhere") }

    it 'returns the full web URL for this repo' do
      expect(project.web_url).to eq("#{Gitlab.config.gitlab.url}/#{project.namespace.path}/somewhere")
    end
  end

  describe "#web_url_without_protocol" do
    let(:project) { create(:empty_project, path: "somewhere") }

    it 'returns the web URL without the protocol for this repo' do
      expect(project.web_url_without_protocol).to eq("#{Gitlab.config.gitlab.url.split('://')[1]}/#{project.namespace.path}/somewhere")
    end
  end

  describe "#new_issue_address" do
    let(:project) { create(:empty_project, path: "somewhere") }
    let(:user) { create(:user) }

    context 'incoming email enabled' do
      before do
        stub_incoming_email_setting(enabled: true, address: "p+%{key}@gl.ab")
      end

      it 'returns the address to create a new issue' do
        address = "p+#{project.path_with_namespace}+#{user.incoming_email_token}@gl.ab"

        expect(project.new_issue_address(user)).to eq(address)
      end
    end

    context 'incoming email disabled' do
      before do
        stub_incoming_email_setting(enabled: false)
      end

      it 'returns nil' do
        expect(project.new_issue_address(user)).to be_nil
      end
    end
  end

  describe 'last_activity methods' do
    let(:timestamp) { 2.hours.ago }
    # last_activity_at gets set to created_at upon creation
    let(:project) { create(:project, created_at: timestamp, updated_at: timestamp) }

    describe 'last_activity' do
      it 'alias last_activity to last_event' do
        last_event = create(:event, project: project)

        expect(project.last_activity).to eq(last_event)
      end
    end

    describe 'last_activity_date' do
      it 'returns the creation date of the project\'s last event if present' do
        new_event = create(:event, project: project, created_at: Time.now)

        project.reload
        expect(project.last_activity_at.to_i).to eq(new_event.created_at.to_i)
      end

      it 'returns the project\'s last update date if it has no events' do
        expect(project.last_activity_date).to eq(project.updated_at)
      end
    end
  end

  describe '#get_issue' do
    let(:project) { create(:empty_project) }
    let!(:issue)  { create(:issue, project: project) }
    let(:user)    { create(:user) }

    before do
      project.team << [user, :developer]
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
      before do
        allow(project).to receive(:default_issues_tracker?).and_return(false)
      end

      it 'returns an ExternalIssue' do
        issue = project.get_issue('FOO-1234', user)
        expect(issue).to be_kind_of(ExternalIssue)
        expect(issue.iid).to eq 'FOO-1234'
        expect(issue.project).to eq project
      end
    end
  end

  describe '#issue_exists?' do
    let(:project) { create(:empty_project) }

    it 'is truthy when issue exists' do
      expect(project).to receive(:get_issue).and_return(double)
      expect(project.issue_exists?(1)).to be_truthy
    end

    it 'is falsey when issue does not exist' do
      expect(project).to receive(:get_issue).and_return(nil)
      expect(project.issue_exists?(1)).to be_falsey
    end
  end

  describe '.find_with_namespace' do
    context 'with namespace' do
      before do
        @group = create :group, name: 'gitlab'
        @project = create(:project, name: 'gitlabhq', namespace: @group)
      end

      it { expect(Project.find_with_namespace('gitlab/gitlabhq')).to eq(@project) }
      it { expect(Project.find_with_namespace('GitLab/GitlabHQ')).to eq(@project) }
      it { expect(Project.find_with_namespace('gitlab-ci')).to be_nil }
    end

    context 'when multiple projects using a similar name exist' do
      let(:group) { create(:group, name: 'gitlab') }

      let!(:project1) do
        create(:empty_project, name: 'gitlab1', path: 'gitlab', namespace: group)
      end

      let!(:project2) do
        create(:empty_project, name: 'gitlab2', path: 'GITLAB', namespace: group)
      end

      it 'returns the row where the path matches literally' do
        expect(Project.find_with_namespace('gitlab/GITLAB')).to eq(project2)
      end
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
        project = create(:empty_project, path: 'gitlab')
        project.path = 'foo&bar'

        expect(project).not_to be_valid
        expect(project.to_param).to eq 'gitlab'
      end

      it 'returns current path when new record' do
        project = build(:empty_project, path: 'gitlab')
        project.path = 'foo&bar'

        expect(project).not_to be_valid
        expect(project.to_param).to eq 'foo&bar'
      end
    end
  end

  describe '#repository' do
    let(:project) { create(:project) }

    it 'returns valid repo' do
      expect(project.repository).to be_kind_of(Repository)
    end
  end

  describe '#default_issues_tracker?' do
    let(:project) { create(:project) }
    let(:ext_project) { create(:redmine_project) }

    it "is true if used internal tracker" do
      expect(project.default_issues_tracker?).to be_truthy
    end

    it "is false if used other tracker" do
      expect(ext_project.default_issues_tracker?).to be_falsey
    end
  end

  describe '#external_issue_tracker' do
    let(:project) { create(:project) }
    let(:ext_project) { create(:redmine_project) }

    context 'on existing projects with no value for has_external_issue_tracker' do
      before(:each) do
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
  end

  describe '#has_wiki?' do
    let(:no_wiki_project)       { create(:project, wiki_access_level: ProjectFeature::DISABLED, has_external_wiki: false) }
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

  describe '#open_branches' do
    let(:project) { create(:project) }

    before do
      project.protected_branches.create(name: 'master')
    end

    it { expect(project.open_branches.map(&:name)).to include('feature') }
    it { expect(project.open_branches.map(&:name)).not_to include('master') }

    it "includes branches matching a protected branch wildcard" do
      expect(project.open_branches.map(&:name)).to include('feature')

      create(:protected_branch, name: 'feat*', project: project)

      expect(Project.find(project.id).open_branches.map(&:name)).to include('feature')
    end
  end

  describe '#star_count' do
    it 'counts stars from multiple users' do
      user1 = create :user
      user2 = create :user
      project = create :project, :public

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
      project1 = create :project, :public
      project2 = create :project, :public

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

    context 'When avatar file is uploaded' do
      before do
        project.update_columns(avatar: 'uploads/avatar.png')
        allow(project.avatar).to receive(:present?) { true }
      end

      let(:avatar_path) do
        "/uploads/project/avatar/#{project.id}/uploads/avatar.png"
      end

      it { should eq "http://localhost#{avatar_path}" }
    end

    context 'When avatar file in git' do
      before do
        allow(project).to receive(:avatar_in_git) { true }
      end

      let(:avatar_path) do
        "/#{project.namespace.name}/#{project.path}/avatar"
      end

      it { should eq "http://localhost#{avatar_path}" }
    end

    context 'when git repo is empty' do
      let(:project) { create(:empty_project) }

      it { should eq nil }
    end
  end

  describe '#pipeline_for' do
    let(:project) { create(:project) }
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
    let(:project) { create :project }

    subject { project.builds_enabled }

    it { expect(project.builds_enabled?).to be_truthy }
  end

  describe '.cached_count', caching: true do
    let(:group)     { create(:group, :public) }
    let!(:project1) { create(:empty_project, :public, group: group) }
    let!(:project2) { create(:empty_project, :public, group: group) }

    it 'returns total project count' do
      expect(Project).to receive(:count).once.and_call_original

      3.times do
        expect(Project.cached_count).to eq(2)
      end
    end
  end

  describe '.trending' do
    let(:group)    { create(:group, :public) }
    let(:project1) { create(:empty_project, :public, group: group) }
    let(:project2) { create(:empty_project, :public, group: group) }

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
    let(:project) { create(:empty_project) }

    before do
      storages = {
        'default' => 'tmp/tests/repositories',
        'picked'  => 'tmp/tests/repositories',
      }
      allow(Gitlab.config.repositories).to receive(:storages).and_return(storages)
    end

    it 'picks storage from ApplicationSetting' do
      expect_any_instance_of(ApplicationSetting).to receive(:pick_repository_storage).and_return('picked')

      expect(project.repository_storage).to eq('picked')
    end
  end

  context 'shared runners by default' do
    let(:project) { create(:empty_project) }

    subject { project.shared_runners_enabled }

    context 'are enabled' do
      before { stub_application_setting(shared_runners_enabled: true) }

      it { is_expected.to be_truthy }
    end

    context 'are disabled' do
      before { stub_application_setting(shared_runners_enabled: false) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#any_runners' do
    let(:project) { create(:empty_project, shared_runners_enabled: shared_runners_enabled) }
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

    it 'returns projects with a matching namespace name' do
      expect(described_class.search(project.namespace.name)).to eq([project])
    end

    it 'returns projects with a partially matching namespace name' do
      expect(described_class.search(project.namespace.name[0..2])).to eq([project])
    end

    it 'returns projects with a matching namespace name regardless of the casing' do
      expect(described_class.search(project.namespace.name.upcase)).to eq([project])
    end

    it 'returns projects when eager loading namespaces' do
      relation = described_class.all.includes(:namespace)

      expect(relation.search(project.namespace.name)).to eq([project])
    end
  end

  describe '#rename_repo' do
    let(:project) { create(:project) }
    let(:gitlab_shell) { Gitlab::Shell.new }

    before do
      # Project#gitlab_shell returns a new instance of Gitlab::Shell on every
      # call. This makes testing a bit easier.
      allow(project).to receive(:gitlab_shell).and_return(gitlab_shell)

      allow(project).to receive(:previous_changes).and_return('path' => ['foo'])
    end

    it 'renames a repository' do
      ns = project.namespace_dir

      expect(gitlab_shell).to receive(:mv_repository).
        ordered.
        with(project.repository_storage_path, "#{ns}/foo", "#{ns}/#{project.path}").
        and_return(true)

      expect(gitlab_shell).to receive(:mv_repository).
        ordered.
        with(project.repository_storage_path, "#{ns}/foo.wiki", "#{ns}/#{project.path}.wiki").
        and_return(true)

      expect_any_instance_of(SystemHooksService).
        to receive(:execute_hooks_for).
        with(project, :rename)

      expect_any_instance_of(Gitlab::UploadsTransfer).
        to receive(:rename_project).
        with('foo', project.path, ns)

      expect(project).to receive(:expire_caches_before_rename)

      project.rename_repo
    end

    context 'container registry with tags' do
      before do
        stub_container_registry_config(enabled: true)
        stub_container_registry_tags('tag')
      end

      subject { project.rename_repo }

      it { expect{subject}.to raise_error(Exception) }
    end
  end

  describe '#expire_caches_before_rename' do
    let(:project) { create(:project) }
    let(:repo)    { double(:repo, exists?: true) }
    let(:wiki)    { double(:wiki, exists?: true) }

    it 'expires the caches of the repository and wiki' do
      allow(Repository).to receive(:new).
        with('foo', project).
        and_return(repo)

      allow(Repository).to receive(:new).
        with('foo.wiki', project).
        and_return(wiki)

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
    let(:project) { create(:project) }
    let(:shell) { Gitlab::Shell.new }

    before do
      allow(project).to receive(:gitlab_shell).and_return(shell)
    end

    context 'using a regular repository' do
      it 'creates the repository' do
        expect(shell).to receive(:add_repository).
          with(project.repository_storage_path, project.path_with_namespace).
          and_return(true)

        expect(project.repository).to receive(:after_create)

        expect(project.create_repository).to eq(true)
      end

      it 'adds an error if the repository could not be created' do
        expect(shell).to receive(:add_repository).
          with(project.repository_storage_path, project.path_with_namespace).
          and_return(false)

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

  describe '#protected_branch?' do
    context 'existing project' do
      let(:project) { create(:project) }

      it 'returns true when the branch matches a protected branch via direct match' do
        create(:protected_branch, project: project, name: "foo")

        expect(project.protected_branch?('foo')).to eq(true)
      end

      it 'returns true when the branch matches a protected branch via wildcard match' do
        create(:protected_branch, project: project, name: "production/*")

        expect(project.protected_branch?('production/some-branch')).to eq(true)
      end

      it 'returns false when the branch does not match a protected branch via direct match' do
        expect(project.protected_branch?('foo')).to eq(false)
      end

      it 'returns false when the branch does not match a protected branch via wildcard match' do
        create(:protected_branch, project: project, name: "production/*")

        expect(project.protected_branch?('staging/some-branch')).to eq(false)
      end
    end

    context "new project" do
      let(:project) { create(:empty_project) }

      it 'returns false when default_protected_branch is unprotected' do
        stub_application_setting(default_branch_protection: Gitlab::Access::PROTECTION_NONE)

        expect(project.protected_branch?('master')).to be false
      end

      it 'returns false when default_protected_branch lets developers push' do
        stub_application_setting(default_branch_protection: Gitlab::Access::PROTECTION_DEV_CAN_PUSH)

        expect(project.protected_branch?('master')).to be false
      end

      it 'returns true when default_branch_protection does not let developers push but let developer merge branches' do
        stub_application_setting(default_branch_protection: Gitlab::Access::PROTECTION_DEV_CAN_MERGE)

        expect(project.protected_branch?('master')).to be true
      end

      it 'returns true when default_branch_protection is in full protection' do
        stub_application_setting(default_branch_protection: Gitlab::Access::PROTECTION_FULL)

        expect(project.protected_branch?('master')).to be true
      end
    end
  end

  describe '#user_can_push_to_empty_repo?' do
    let(:project) { create(:empty_project) }
    let(:user)    { create(:user) }

    it 'returns false when default_branch_protection is in full protection and user is developer' do
      project.team << [user, :developer]
      stub_application_setting(default_branch_protection: Gitlab::Access::PROTECTION_FULL)

      expect(project.user_can_push_to_empty_repo?(user)).to be_falsey
    end

    it 'returns false when default_branch_protection only lets devs merge and user is dev' do
      project.team << [user, :developer]
      stub_application_setting(default_branch_protection: Gitlab::Access::PROTECTION_DEV_CAN_MERGE)

      expect(project.user_can_push_to_empty_repo?(user)).to be_falsey
    end

    it 'returns true when default_branch_protection lets devs push and user is developer' do
      project.team << [user, :developer]
      stub_application_setting(default_branch_protection: Gitlab::Access::PROTECTION_DEV_CAN_PUSH)

      expect(project.user_can_push_to_empty_repo?(user)).to be_truthy
    end

    it 'returns true when default_branch_protection is unprotected and user is developer' do
      project.team << [user, :developer]
      stub_application_setting(default_branch_protection: Gitlab::Access::PROTECTION_NONE)

      expect(project.user_can_push_to_empty_repo?(user)).to be_truthy
    end

    it 'returns true when user is master' do
      project.team << [user, :master]

      expect(project.user_can_push_to_empty_repo?(user)).to be_truthy
    end
  end

  describe '#container_registry_path_with_namespace' do
    let(:project) { create(:empty_project, path: 'PROJECT') }

    subject { project.container_registry_path_with_namespace }

    it { is_expected.not_to eq(project.path_with_namespace) }
    it { is_expected.to eq(project.path_with_namespace.downcase) }
  end

  describe '#container_registry_repository' do
    let(:project) { create(:empty_project) }

    before { stub_container_registry_config(enabled: true) }

    subject { project.container_registry_repository }

    it { is_expected.not_to be_nil }
  end

  describe '#container_registry_repository_url' do
    let(:project) { create(:empty_project) }

    subject { project.container_registry_repository_url }

    before { stub_container_registry_config(**registry_settings) }

    context 'for enabled registry' do
      let(:registry_settings) do
        {
          enabled: true,
          host_port: 'example.com',
        }
      end

      it { is_expected.not_to be_nil }
    end

    context 'for disabled registry' do
      let(:registry_settings) do
        {
          enabled: false
        }
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#has_container_registry_tags?' do
    let(:project) { create(:empty_project) }

    subject { project.has_container_registry_tags? }

    context 'for enabled registry' do
      before { stub_container_registry_config(enabled: true) }

      context 'with tags' do
        before { stub_container_registry_tags('test', 'test2') }

        it { is_expected.to be_truthy }
      end

      context 'when no tags' do
        before { stub_container_registry_tags }

        it { is_expected.to be_falsey }
      end
    end

    context 'for disabled registry' do
      before { stub_container_registry_config(enabled: false) }

      it { is_expected.to be_falsey }
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

    let(:project) { create(:project) }
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
    context 'forked' do
      let(:forked_project_link) { create(:forked_project_link) }
      let(:forked_from_project) { forked_project_link.forked_from_project }
      let(:project) { forked_project_link.forked_to_project }

      it 'schedules a RepositoryForkWorker job' do
        expect(RepositoryForkWorker).to receive(:perform_async).
          with(project.id, forked_from_project.repository_storage_path,
              forked_from_project.path_with_namespace, project.namespace.path)

        project.add_import_job
      end
    end

    context 'not forked' do
      let(:project) { create(:project) }

      it 'schedules a RepositoryImportWorker job' do
        expect(RepositoryImportWorker).to receive(:perform_async).with(project.id)

        project.add_import_job
      end
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

  describe '.where_paths_in' do
    context 'without any paths' do
      it 'returns an empty relation' do
        expect(Project.where_paths_in([])).to eq([])
      end
    end

    context 'without any valid paths' do
      it 'returns an empty relation' do
        expect(Project.where_paths_in(%w[foo])).to eq([])
      end
    end

    context 'with valid paths' do
      let!(:project1) { create(:project) }
      let!(:project2) { create(:project) }

      it 'returns the projects matching the paths' do
        projects = Project.where_paths_in([project1.path_with_namespace,
                                           project2.path_with_namespace])

        expect(projects).to contain_exactly(project1, project2)
      end

      it 'returns projects regardless of the casing of paths' do
        projects = Project.where_paths_in([project1.path_with_namespace.upcase,
                                           project2.path_with_namespace.upcase])

        expect(projects).to contain_exactly(project1, project2)
      end
    end
  end

  describe 'authorized_for_user' do
    let(:group) { create(:group) }
    let(:developer) { create(:user) }
    let(:master) { create(:user) }
    let(:personal_project) { create(:project, namespace: developer.namespace) }
    let(:group_project) { create(:project, namespace: group) }
    let(:members_project) { create(:project) }
    let(:shared_project) { create(:project) }

    before do
      group.add_master(master)
      group.add_developer(developer)

      members_project.team << [developer, :developer]
      members_project.team << [master, :master]

      create(:project_group_link, project: shared_project, group: group, group_access: Gitlab::Access::DEVELOPER)
    end

    it 'returns false for no user' do
      expect(personal_project.authorized_for_user?(nil)).to be(false)
    end

    it 'returns true for personal projects of the user' do
      expect(personal_project.authorized_for_user?(developer)).to be(true)
    end

    it 'returns true for projects of groups the user is a member of' do
      expect(group_project.authorized_for_user?(developer)).to be(true)
    end

    it 'returns true for projects for which the user is a member of' do
      expect(members_project.authorized_for_user?(developer)).to be(true)
    end

    it 'returns true for projects shared on a group the user is a member of' do
      expect(shared_project.authorized_for_user?(developer)).to be(true)
    end

    it 'checks for the correct minimum level access' do
      expect(group_project.authorized_for_user?(developer, Gitlab::Access::MASTER)).to be(false)
      expect(group_project.authorized_for_user?(master, Gitlab::Access::MASTER)).to be(true)
      expect(members_project.authorized_for_user?(developer, Gitlab::Access::MASTER)).to be(false)
      expect(members_project.authorized_for_user?(master, Gitlab::Access::MASTER)).to be(true)
      expect(shared_project.authorized_for_user?(developer, Gitlab::Access::MASTER)).to be(false)
      expect(shared_project.authorized_for_user?(master, Gitlab::Access::MASTER)).to be(false)
      expect(shared_project.authorized_for_user?(developer, Gitlab::Access::DEVELOPER)).to be(true)
      expect(shared_project.authorized_for_user?(master, Gitlab::Access::DEVELOPER)).to be(true)
    end
  end

  describe 'change_head' do
    let(:project) { create(:project) }

    it 'calls the before_change_head method' do
      expect(project.repository).to receive(:before_change_head)
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

    it 'expires the avatar cache' do
      expect(project.repository).to receive(:expire_avatar_cache)
      project.change_head(project.default_branch)
    end

    it 'reloads the default branch' do
      expect(project).to receive(:reload_default_branch)
      project.change_head(project.default_branch)
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

  describe '#environments_for' do
    let(:project) { create(:project) }
    let(:environment) { create(:environment, project: project) }

    context 'tagged deployment' do
      before do
        create(:deployment, environment: environment, ref: '1.0', tag: true, sha: project.commit.id)
      end

      it 'returns environment when with_tags is set' do
        expect(project.environments_for('master', commit: project.commit, with_tags: true))
          .to contain_exactly(environment)
      end

      it 'does not return environment when no with_tags is set' do
        expect(project.environments_for('master', commit: project.commit))
          .to be_empty
      end

      it 'does not return environment when commit is not part of deployment' do
        expect(project.environments_for('master', commit: project.commit('feature')))
          .to be_empty
      end
    end

    context 'branch deployment' do
      before do
        create(:deployment, environment: environment, ref: 'master', sha: project.commit.id)
      end

      it 'returns environment when ref is set' do
        expect(project.environments_for('master', commit: project.commit))
          .to contain_exactly(environment)
      end

      it 'does not environment when ref is different' do
        expect(project.environments_for('feature', commit: project.commit))
          .to be_empty
      end

      it 'does not return environment when commit is not part of deployment' do
        expect(project.environments_for('master', commit: project.commit('feature')))
          .to be_empty
      end

      it 'returns environment when commit constraint is not set' do
        expect(project.environments_for('master'))
          .to contain_exactly(environment)
      end
    end
  end

  describe '#environments_recently_updated_on_branch' do
    let(:project) { create(:project) }
    let(:environment) { create(:environment, project: project) }

    context 'when last deployment to environment is the most recent one' do
      before do
        create(:deployment, environment: environment, ref: 'feature')
      end

      it 'finds recently updated environment' do
        expect(project.environments_recently_updated_on_branch('feature'))
          .to contain_exactly(environment)
      end
    end

    context 'when last deployment to environment is not the most recent' do
      before do
        create(:deployment, environment: environment, ref: 'feature')
        create(:deployment, environment: environment, ref: 'master')
      end

      it 'does not find environment' do
        expect(project.environments_recently_updated_on_branch('feature'))
          .to be_empty
      end
    end

    context 'when there are two environments that deploy to the same branch' do
      let(:second_environment) { create(:environment, project: project) }

      before do
        create(:deployment, environment: environment, ref: 'feature')
        create(:deployment, environment: second_environment, ref: 'feature')
      end

      it 'finds both environments' do
        expect(project.environments_recently_updated_on_branch('feature'))
          .to contain_exactly(environment, second_environment)
      end
    end
  end

  def enable_lfs
    allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)
  end
end
