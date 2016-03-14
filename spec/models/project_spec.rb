# == Schema Information
#
# Table name: projects
#
#  id                     :integer          not null, primary key
#  name                   :string(255)
#  path                   :string(255)
#  description            :text
#  created_at             :datetime
#  updated_at             :datetime
#  creator_id             :integer
#  issues_enabled         :boolean          default(TRUE), not null
#  wall_enabled           :boolean          default(TRUE), not null
#  merge_requests_enabled :boolean          default(TRUE), not null
#  wiki_enabled           :boolean          default(TRUE), not null
#  namespace_id           :integer
#  issues_tracker         :string(255)      default("gitlab"), not null
#  issues_tracker_id      :string(255)
#  snippets_enabled       :boolean          default(TRUE), not null
#  last_activity_at       :datetime
#  import_url             :string(255)
#  visibility_level       :integer          default(0), not null
#  archived               :boolean          default(FALSE), not null
#  avatar                 :string(255)
#  import_status          :string(255)
#  repository_size        :float            default(0.0)
#  star_count             :integer          default(0), not null
#  import_type            :string(255)
#  import_source          :string(255)
#  commit_count           :integer          default(0)
#  import_error           :text
#  ci_id                  :integer
#  builds_enabled         :boolean          default(TRUE), not null
#  shared_runners_enabled :boolean          default(TRUE), not null
#  runners_token          :string
#  build_coverage_regex   :string
#  build_allow_git_fetch  :boolean          default(TRUE), not null
#  build_timeout          :integer          default(3600), not null
#

require 'spec_helper'

describe Project, models: true do
  describe 'associations' do
    it { is_expected.to belong_to(:group) }
    it { is_expected.to belong_to(:namespace) }
    it { is_expected.to belong_to(:creator).class_name('User') }
    it { is_expected.to have_many(:users) }
    it { is_expected.to have_many(:events).dependent(:destroy) }
    it { is_expected.to have_many(:merge_requests).dependent(:destroy) }
    it { is_expected.to have_many(:issues).dependent(:destroy) }
    it { is_expected.to have_many(:milestones).dependent(:destroy) }
    it { is_expected.to have_many(:project_members).dependent(:destroy) }
    it { is_expected.to have_many(:notes).dependent(:destroy) }
    it { is_expected.to have_many(:snippets).class_name('ProjectSnippet').dependent(:destroy) }
    it { is_expected.to have_many(:deploy_keys_projects).dependent(:destroy) }
    it { is_expected.to have_many(:deploy_keys) }
    it { is_expected.to have_many(:hooks).dependent(:destroy) }
    it { is_expected.to have_many(:protected_branches).dependent(:destroy) }
    it { is_expected.to have_one(:forked_project_link).dependent(:destroy) }
    it { is_expected.to have_one(:slack_service).dependent(:destroy) }
    it { is_expected.to have_one(:pushover_service).dependent(:destroy) }
    it { is_expected.to have_one(:asana_service).dependent(:destroy) }
    it { is_expected.to have_many(:commit_statuses) }
    it { is_expected.to have_many(:ci_commits) }
    it { is_expected.to have_many(:builds) }
    it { is_expected.to have_many(:runner_projects) }
    it { is_expected.to have_many(:runners) }
    it { is_expected.to have_many(:variables) }
    it { is_expected.to have_many(:triggers) }
    it { is_expected.to have_many(:todos).dependent(:destroy) }
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
    it { is_expected.to validate_length_of(:name).is_within(0..255) }

    it { is_expected.to validate_presence_of(:path) }
    it { is_expected.to validate_uniqueness_of(:path).scoped_to(:namespace_id) }
    it { is_expected.to validate_length_of(:path).is_within(0..255) }
    it { is_expected.to validate_length_of(:description).is_within(0..2000) }
    it { is_expected.to validate_presence_of(:creator) }
    it { is_expected.to validate_length_of(:issues_tracker_id).is_within(0..255) }
    it { is_expected.to validate_presence_of(:namespace) }

    it 'should not allow new projects beyond user limits' do
      project2 = build(:project)
      allow(project2).to receive(:creator).and_return(double(can_create_project?: false, projects_limit: 0).as_null_object)
      expect(project2).not_to be_valid
      expect(project2.errors[:limit_reached].first).to match(/Your project limit is 0/)
    end
  end

  describe 'project token' do
    it 'should set an random token if none provided' do
      project = FactoryGirl.create :empty_project, runners_token: ''
      expect(project.runners_token).not_to eq('')
    end

    it 'should not set an random toke if one provided' do
      project = FactoryGirl.create :empty_project, runners_token: 'my-token'
      expect(project.runners_token).to eq('my-token')
    end
  end

  describe 'Respond to' do
    it { is_expected.to respond_to(:url_to_repo) }
    it { is_expected.to respond_to(:repo_exists?) }
    it { is_expected.to respond_to(:update_merge_requests) }
    it { is_expected.to respond_to(:execute_hooks) }
    it { is_expected.to respond_to(:name_with_namespace) }
    it { is_expected.to respond_to(:owner) }
    it { is_expected.to respond_to(:path_with_namespace) }
  end

  describe '#to_reference' do
    let(:project) { create(:empty_project) }

    it 'returns a String reference to the object' do
      expect(project.to_reference).to eq project.path_with_namespace
    end
  end

  it 'should return valid url to repo' do
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

  describe 'last_activity methods' do
    let(:project) { create(:project) }
    let(:last_event) { double(created_at: Time.now) }

    describe 'last_activity' do
      it 'should alias last_activity to last_event' do
        allow(project).to receive(:last_event).and_return(last_event)
        expect(project.last_activity).to eq(last_event)
      end
    end

    describe 'last_activity_date' do
      it 'returns the creation date of the project\'s last event if present' do
        create(:event, project: project)
        expect(project.last_activity_at.to_i).to eq(last_event.created_at.to_i)
      end

      it 'returns the project\'s last update date if it has no events' do
        expect(project.last_activity_date).to eq(project.updated_at)
      end
    end
  end

  describe '#get_issue' do
    let(:project) { create(:empty_project) }
    let!(:issue)  { create(:issue, project: project) }

    context 'with default issues tracker' do
      it 'returns an issue' do
        expect(project.get_issue(issue.iid)).to eq issue
      end

      it 'returns count of open issues' do
        expect(project.open_issues_count).to eq(1)
      end

      it 'returns nil when no issue found' do
        expect(project.get_issue(999)).to be_nil
      end
    end

    context 'with external issues tracker' do
      before do
        allow(project).to receive(:default_issues_tracker?).and_return(false)
      end

      it 'returns an ExternalIssue' do
        issue = project.get_issue('FOO-1234')
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

  describe :update_merge_requests do
    let(:project) { create(:project) }
    let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
    let(:key) { create(:key, user_id: project.owner.id) }
    let(:prev_commit_id) { merge_request.commits.last.id }
    let(:commit_id) { merge_request.commits.first.id }

    it 'should close merge request if last commit from source branch was pushed to target branch' do
      project.update_merge_requests(prev_commit_id, commit_id, "refs/heads/#{merge_request.target_branch}", key.user)
      merge_request.reload
      expect(merge_request.merged?).to be_truthy
    end

    it 'should update merge request commits with new one if pushed to source branch' do
      project.update_merge_requests(prev_commit_id, commit_id, "refs/heads/#{merge_request.source_branch}", key.user)
      merge_request.reload
      expect(merge_request.last_commit.id).to eq(commit_id)
    end
  end

  describe :find_with_namespace do
    context 'with namespace' do
      before do
        @group = create :group, name: 'gitlab'
        @project = create(:project, name: 'gitlabhq', namespace: @group)
      end

      it { expect(Project.find_with_namespace('gitlab/gitlabhq')).to eq(@project) }
      it { expect(Project.find_with_namespace('GitLab/GitlabHQ')).to eq(@project) }
      it { expect(Project.find_with_namespace('gitlab-ci')).to be_nil }
    end
  end

  describe :to_param do
    context 'with namespace' do
      before do
        @group = create :group, name: 'gitlab'
        @project = create(:project, name: 'gitlabhq', namespace: @group)
      end

      it { expect(@project.to_param).to eq('gitlabhq') }
    end
  end

  describe :repository do
    let(:project) { create(:project) }

    it 'should return valid repo' do
      expect(project.repository).to be_kind_of(Repository)
    end
  end

  describe :default_issues_tracker? do
    let(:project) { create(:project) }
    let(:ext_project) { create(:redmine_project) }

    it "should be true if used internal tracker" do
      expect(project.default_issues_tracker?).to be_truthy
    end

    it "should be false if used other tracker" do
      expect(ext_project.default_issues_tracker?).to be_falsey
    end
  end

  describe :can_have_issues_tracker_id? do
    let(:project) { create(:project) }
    let(:ext_project) { create(:redmine_project) }

    it 'should be true for projects with external issues tracker if issues enabled' do
      expect(ext_project.can_have_issues_tracker_id?).to be_truthy
    end

    it 'should be false for projects with internal issue tracker if issues enabled' do
      expect(project.can_have_issues_tracker_id?).to be_falsey
    end

    it 'should be always false if issues disabled' do
      project.issues_enabled = false
      ext_project.issues_enabled = false

      expect(project.can_have_issues_tracker_id?).to be_falsey
      expect(ext_project.can_have_issues_tracker_id?).to be_falsey
    end
  end

  describe :open_branches do
    let(:project) { create(:project) }

    before do
      project.protected_branches.create(name: 'master')
    end

    it { expect(project.open_branches.map(&:name)).to include('feature') }
    it { expect(project.open_branches.map(&:name)).not_to include('master') }
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

  describe :avatar_type do
    let(:project) { create(:project) }

    it 'should be true if avatar is image' do
      project.update_attribute(:avatar, 'uploads/avatar.png')
      expect(project.avatar_type).to be_truthy
    end

    it 'should be false if avatar is html page' do
      project.update_attribute(:avatar, 'uploads/avatar.html')
      expect(project.avatar_type).to eq(['only images allowed'])
    end
  end

  describe :avatar_url do
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
  end

  describe :ci_commit do
    let(:project) { create :project }
    let(:commit) { create :ci_commit, project: project }

    it { expect(project.ci_commit(commit.sha)).to eq(commit) }
  end

  describe :builds_enabled do
    let(:project) { create :project }

    before { project.builds_enabled = true }

    subject { project.builds_enabled }

    it { expect(project.builds_enabled?).to be_truthy }
  end

  describe '.trending' do
    let(:group)    { create(:group) }
    let(:project1) { create(:empty_project, :public, group: group) }
    let(:project2) { create(:empty_project, :public, group: group) }

    before do
      2.times do
        create(:note_on_commit, project: project1)
      end

      create(:note_on_commit, project: project2)
    end

    describe 'without an explicit start date' do
      subject { described_class.trending.to_a }

      it 'sorts Projects by the amount of notes in descending order' do
        expect(subject).to eq([project1, project2])
      end
    end

    describe 'with an explicit start date' do
      let(:date) { 2.months.ago }

      subject { described_class.trending(date).to_a }

      before do
        2.times do
          # Little fix for special issue related to Fractional Seconds support for MySQL.
          # See: https://github.com/rails/rails/pull/14359/files
          create(:note_on_commit, project: project2, created_at: date + 1)
        end
      end

      it 'sorts Projects by the amount of notes in descending order' do
        expect(subject).to eq([project2, project1])
      end
    end
  end

  describe '.visible_to_user' do
    let!(:project) { create(:project, :private) }
    let!(:user)    { create(:user) }

    subject { described_class.visible_to_user(user) }

    describe 'when a user has access to a project' do
      before do
        project.team.add_user(user, Gitlab::Access::MASTER)
      end

      it { is_expected.to eq([project]) }
    end

    describe 'when a user does not have access to any projects' do
      it { is_expected.to eq([]) }
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

  describe :any_runners do
    let(:project) { create(:empty_project, shared_runners_enabled: shared_runners_enabled) }
    let(:specific_runner) { create(:ci_runner) }
    let(:shared_runner) { create(:ci_runner, :shared) }

    context 'for shared runners disabled' do
      let(:shared_runners_enabled) { false }

      it 'there are no runners available' do
        expect(project.any_runners?).to be_falsey
      end

      it 'there is a specific runner' do
        project.runners << specific_runner
        expect(project.any_runners?).to be_truthy
      end

      it 'there is a shared runner, but they are prohibited to use' do
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

      it 'there is a shared runner' do
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
      let(:forked_project) { create :forked_project_with_submodules }

      before do
        forked_project.build_forked_project_link(forked_to_project_id: forked_project.id, forked_from_project_id: project.id)
        forked_project.save
      end

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
  end

  describe '#rename_repo' do
    let(:project) { create(:project) }
    let(:gitlab_shell) { Gitlab::Shell.new }

    before do
      # Project#gitlab_shell returns a new instance of Gitlab::Shell on every
      # call. This makes testing a bit easier.
      allow(project).to receive(:gitlab_shell).and_return(gitlab_shell)
    end

    it 'renames a repository' do
      allow(project).to receive(:previous_changes).and_return('path' => ['foo'])

      ns = project.namespace_dir

      expect(gitlab_shell).to receive(:mv_repository).
        ordered.
        with("#{ns}/foo", "#{ns}/#{project.path}").
        and_return(true)

      expect(gitlab_shell).to receive(:mv_repository).
        ordered.
        with("#{ns}/foo.wiki", "#{ns}/#{project.path}.wiki").
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

      expect(repo).to receive(:expire_cache)
      expect(repo).to receive(:expire_emptiness_caches)

      expect(wiki).to receive(:expire_cache)
      expect(wiki).to receive(:expire_emptiness_caches)

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
end
