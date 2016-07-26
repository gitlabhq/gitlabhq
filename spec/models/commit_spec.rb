require 'spec_helper'

describe Commit, models: true do
  let(:project) { create(:project, :public) }
  let(:commit)  { project.commit }

  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(Mentionable) }
    it { is_expected.to include_module(Participable) }
    it { is_expected.to include_module(Referable) }
    it { is_expected.to include_module(StaticModel) }
  end

  describe '#to_reference' do
    it 'returns a String reference to the object' do
      expect(commit.to_reference).to eq commit.id
    end

    it 'supports a cross-project reference' do
      cross = double('project')
      expect(commit.to_reference(cross)).to eq "#{project.to_reference}@#{commit.id}"
    end
  end

  describe '#reference_link_text' do
    it 'returns a String reference to the object' do
      expect(commit.reference_link_text).to eq commit.short_id
    end

    it 'supports a cross-project reference' do
      cross = double('project')
      expect(commit.reference_link_text(cross)).to eq "#{project.to_reference}@#{commit.short_id}"
    end
  end

  describe '#title' do
    it "returns no_commit_message when safe_message is blank" do
      allow(commit).to receive(:safe_message).and_return('')
      expect(commit.title).to eq("--no commit message")
    end

    it "truncates a message without a newline at 80 characters" do
      message = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec sodales id felis id blandit. Vivamus egestas lacinia lacus, sed rutrum mauris.'

      allow(commit).to receive(:safe_message).and_return(message)
      expect(commit.title).to eq("#{message[0..79]}…")
    end

    it "truncates a message with a newline before 80 characters at the newline" do
      message = commit.safe_message.split(" ").first

      allow(commit).to receive(:safe_message).and_return(message + "\n" + message)
      expect(commit.title).to eq(message)
    end

    it "does not truncates a message with a newline after 80 but less 100 characters" do
      message = <<eos
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec sodales id felis id blandit.
Vivamus egestas lacinia lacus, sed rutrum mauris.
eos

      allow(commit).to receive(:safe_message).and_return(message)
      expect(commit.title).to eq(message.split("\n").first)
    end
  end

  describe "delegation" do
    subject { commit }

    it { is_expected.to respond_to(:message) }
    it { is_expected.to respond_to(:authored_date) }
    it { is_expected.to respond_to(:committed_date) }
    it { is_expected.to respond_to(:committer_email) }
    it { is_expected.to respond_to(:author_email) }
    it { is_expected.to respond_to(:parents) }
    it { is_expected.to respond_to(:date) }
    it { is_expected.to respond_to(:diffs) }
    it { is_expected.to respond_to(:tree) }
    it { is_expected.to respond_to(:id) }
    it { is_expected.to respond_to(:to_patch) }
  end

  describe '#closes_issues' do
    let(:issue) { create :issue, project: project }
    let(:other_project) { create :project, :public }
    let(:other_issue) { create :issue, project: other_project }
    let(:commiter) { create :user }

    before do
      project.team << [commiter, :developer]
      other_project.team << [commiter, :developer]
    end

    it 'detects issues that this commit is marked as closing' do
      ext_ref = "#{other_project.path_with_namespace}##{other_issue.iid}"

      allow(commit).to receive_messages(
        safe_message: "Fixes ##{issue.iid} and #{ext_ref}",
        committer_email: commiter.email
      )

      expect(commit.closes_issues).to include(issue)
      expect(commit.closes_issues).to include(other_issue)
    end
  end

  it_behaves_like 'a mentionable' do
    subject { create(:project).commit }

    let(:author) { create(:user, email: subject.author_email) }
    let(:backref_text) { "commit #{subject.id}" }
    let(:set_mentionable_text) do
      ->(txt) { allow(subject).to receive(:safe_message).and_return(txt) }
    end

    # Include the subject in the repository stub.
    let(:extra_commits) { [subject] }
  end

  describe '#hook_attrs' do
    let(:data) { commit.hook_attrs(with_changed_files: true) }

    it { expect(data).to be_a(Hash) }
    it { expect(data[:message]).to include('Add submodule from gitlab.com') }
    it { expect(data[:timestamp]).to eq('2014-02-27T11:01:38+02:00') }
    it { expect(data[:added]).to eq(["gitlab-grack"]) }
    it { expect(data[:modified]).to eq([".gitmodules"]) }
    it { expect(data[:removed]).to eq([]) }
  end

  describe '#reverts_commit?' do
    let(:another_commit) { double(:commit, revert_description: "This reverts commit #{commit.sha}") }

    it { expect(commit.reverts_commit?(another_commit)).to be_falsy }

    context 'commit has no description' do
      before { allow(commit).to receive(:description?).and_return(false) }

      it { expect(commit.reverts_commit?(another_commit)).to be_falsy }
    end

    context "another_commit's description does not revert commit" do
      before { allow(commit).to receive(:description).and_return("Foo Bar") }

      it { expect(commit.reverts_commit?(another_commit)).to be_falsy }
    end

    context "another_commit's description reverts commit" do
      before { allow(commit).to receive(:description).and_return("Foo #{another_commit.revert_description} Bar") }

      it { expect(commit.reverts_commit?(another_commit)).to be_truthy }
    end

    context "another_commit's description reverts merged merge request" do
      before do
        revert_description = "This reverts merge request !foo123"
        allow(another_commit).to receive(:revert_description).and_return(revert_description)
        allow(commit).to receive(:description).and_return("Foo #{another_commit.revert_description} Bar")
      end

      it { expect(commit.reverts_commit?(another_commit)).to be_truthy }
    end
  end

  describe '#ci_commits' do
    # TODO: kamil
  end

  describe '#status' do
    # TODO: kamil
  end

  describe '#participants' do
    let(:user1) { build(:user) }
    let(:user2) { build(:user) }

    let!(:note1) do
      create(:note_on_commit,
             commit_id: commit.id,
             project: project,
             note: 'foo')
    end

    let!(:note2) do
      create(:note_on_commit,
             commit_id: commit.id,
             project: project,
             note: 'bar')
    end

    before do
      allow(commit).to receive(:author).and_return(user1)
      allow(commit).to receive(:committer).and_return(user2)
    end

    it 'includes the commit author' do
      expect(commit.participants).to include(commit.author)
    end

    it 'includes the committer' do
      expect(commit.participants).to include(commit.committer)
    end

    it 'includes the authors of the commit notes' do
      expect(commit.participants).to include(note1.author, note2.author)
    end
  end

  describe '#uri_type' do
    it 'returns the URI type at the given path' do
      expect(commit.uri_type('files/html')).to be(:tree)
      expect(commit.uri_type('files/images/logo-black.png')).to be(:raw)
      expect(project.commit('video').uri_type('files/videos/intro.mp4')).to be(:raw)
      expect(commit.uri_type('files/js/application.js')).to be(:blob)
    end

    it "returns nil if the path doesn't exists" do
      expect(commit.uri_type('this/path/doesnt/exist')).to be_nil
    end
  end
end
