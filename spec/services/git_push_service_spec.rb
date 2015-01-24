require 'spec_helper'

describe GitPushService do
  include RepoHelpers

  let (:user)          { create :user }
  let (:project)       { create :project }
  let (:service) { GitPushService.new }

  before do
    @blankrev = Gitlab::Git::BLANK_SHA
    @oldrev = sample_commit.parent_id
    @newrev = sample_commit.id
    @ref = 'refs/heads/master'
  end

  describe 'Push branches' do
    context 'new branch' do
      subject do
        service.execute(project, user, @blankrev, @newrev, @ref)
      end

      it { is_expected.to be_truthy }
    end

    context 'existing branch' do
      subject do
        service.execute(project, user, @oldrev, @newrev, @ref)
      end

      it { is_expected.to be_truthy }
    end

    context 'rm branch' do
      subject do
        service.execute(project, user, @oldrev, @blankrev, @ref)
      end

      it { is_expected.to be_truthy }
    end
  end

  describe "Git Push Data" do
    before do
      service.execute(project, user, @oldrev, @newrev, @ref)
      @push_data = service.push_data
      @commit = project.repository.commit(@newrev)
    end

    subject { @push_data }

    it { is_expected.to include(before: @oldrev) }
    it { is_expected.to include(after: @newrev) }
    it { is_expected.to include(ref: @ref) }
    it { is_expected.to include(user_id: user.id) }
    it { is_expected.to include(user_name: user.name) }
    it { is_expected.to include(project_id: project.id) }

    context "with repository data" do
      subject { @push_data[:repository] }

      it { is_expected.to include(name: project.name) }
      it { is_expected.to include(url: project.url_to_repo) }
      it { is_expected.to include(description: project.description) }
      it { is_expected.to include(homepage: project.web_url) }
    end

    context "with commits" do
      subject { @push_data[:commits] }

      it { is_expected.to be_an(Array) }
      it 'has 1 element' do
        expect(subject.size).to eq(1)
      end

      context "the commit" do
        subject { @push_data[:commits].first }

        it { is_expected.to include(id: @commit.id) }
        it { is_expected.to include(message: @commit.safe_message) }
        it { is_expected.to include(timestamp: @commit.date.xmlschema) }
        it do
          is_expected.to include(
            url: [
              Gitlab.config.gitlab.url,
              project.namespace.to_param,
              project.to_param,
              'commit',
              @commit.id
            ].join('/')
          )
        end

        context "with a author" do
          subject { @push_data[:commits].first[:author] }

          it { is_expected.to include(name: @commit.author_name) }
          it { is_expected.to include(email: @commit.author_email) }
        end
      end
    end
  end

  describe "Push Event" do
    before do
      service.execute(project, user, @oldrev, @newrev, @ref)
      @event = Event.last
    end

    it { expect(@event).not_to be_nil }
    it { expect(@event.project).to eq(project) }
    it { expect(@event.action).to eq(Event::PUSHED) }
    it { expect(@event.data).to eq(service.push_data) }
  end

  describe "Web Hooks" do
    context "execute web hooks" do
      it "when pushing a branch for the first time" do
        expect(project).to receive(:execute_hooks)
        expect(project.default_branch).to eq("master")
        expect(project.protected_branches).to receive(:create).with({ name: "master", developers_can_push: false })
        service.execute(project, user, @blankrev, 'newrev', 'refs/heads/master')
      end

      it "when pushing a branch for the first time with default branch protection disabled" do
        ApplicationSetting.any_instance.stub(default_branch_protection: 0)

        expect(project).to receive(:execute_hooks)
        expect(project.default_branch).to eq("master")
        expect(project.protected_branches).not_to receive(:create)
        service.execute(project, user, @blankrev, 'newrev', 'refs/heads/master')
      end

      it "when pushing a branch for the first time with default branch protection set to 'developers can push'" do
        ApplicationSetting.any_instance.stub(default_branch_protection: 1)

        expect(project).to receive(:execute_hooks)
        expect(project.default_branch).to eq("master")
        expect(project.protected_branches).to receive(:create).with({ name: "master", developers_can_push: true })
        service.execute(project, user, @blankrev, 'newrev', 'refs/heads/master')
      end

      it "when pushing new commits to existing branch" do
        expect(project).to receive(:execute_hooks)
        service.execute(project, user, 'oldrev', 'newrev', 'refs/heads/master')
      end

      it "when pushing tags" do
        expect(project).not_to receive(:execute_hooks)
        service.execute(project, user, 'newrev', 'newrev', 'refs/tags/v1.0.0')
      end
    end
  end

  describe "cross-reference notes" do
    let(:issue) { create :issue, project: project }
    let(:commit_author) { create :user }
    let(:commit) { project.repository.commit }

    before do
      commit.stub({
        safe_message: "this commit \n mentions ##{issue.id}",
        references: [issue],
        author_name: commit_author.name,
        author_email: commit_author.email
      })
      project.repository.stub(commits_between: [commit])
    end

    it "creates a note if a pushed commit mentions an issue" do
      expect(Note).to receive(:create_cross_reference_note).with(issue, commit, commit_author, project)

      service.execute(project, user, @oldrev, @newrev, @ref)
    end

    it "only creates a cross-reference note if one doesn't already exist" do
      Note.create_cross_reference_note(issue, commit, user, project)

      expect(Note).not_to receive(:create_cross_reference_note).with(issue, commit, commit_author, project)

      service.execute(project, user, @oldrev, @newrev, @ref)
    end

    it "defaults to the pushing user if the commit's author is not known" do
      commit.stub(author_name: 'unknown name', author_email: 'unknown@email.com')
      expect(Note).to receive(:create_cross_reference_note).with(issue, commit, user, project)

      service.execute(project, user, @oldrev, @newrev, @ref)
    end

    it "finds references in the first push to a non-default branch" do
      allow(project.repository).to receive(:commits_between).with(@blankrev, @newrev).and_return([])
      allow(project.repository).to receive(:commits_between).with("master", @newrev).and_return([commit])

      expect(Note).to receive(:create_cross_reference_note).with(issue, commit, commit_author, project)

      service.execute(project, user, @blankrev, @newrev, 'refs/heads/other')
    end

    it "finds references in the first push to a default branch" do
      allow(project.repository).to receive(:commits_between).with(@blankrev, @newrev).and_return([])
      allow(project.repository).to receive(:commits).with(@newrev).and_return([commit])

      expect(Note).to receive(:create_cross_reference_note).with(issue, commit, commit_author, project)

      service.execute(project, user, @blankrev, @newrev, 'refs/heads/master')
    end
  end

  describe "closing issues from pushed commits" do
    let(:issue) { create :issue, project: project }
    let(:other_issue) { create :issue, project: project }
    let(:commit_author) { create :user }
    let(:closing_commit) { project.repository.commit }

    before do
      closing_commit.stub({
        issue_closing_regex: /^([Cc]loses|[Ff]ixes) #\d+/,
        safe_message: "this is some work.\n\ncloses ##{issue.iid}",
        author_name: commit_author.name,
        author_email: commit_author.email
      })

      project.repository.stub(commits_between: [closing_commit])
    end

    it "closes issues with commit messages" do
      service.execute(project, user, @oldrev, @newrev, @ref)

      expect(Issue.find(issue.id)).to be_closed
    end

    it "doesn't create cross-reference notes for a closing reference" do
      expect {
        service.execute(project, user, @oldrev, @newrev, @ref)
      }.not_to change { Note.where(project_id: project.id, system: true, commit_id: closing_commit.id).count }
    end

    it "doesn't close issues when pushed to non-default branches" do
      project.stub(default_branch: 'durf')

      # The push still shouldn't create cross-reference notes.
      expect {
        service.execute(project, user, @oldrev, @newrev, 'refs/heads/hurf')
      }.not_to change { Note.where(project_id: project.id, system: true).count }

      expect(Issue.find(issue.id)).to be_opened
    end
  end
end

