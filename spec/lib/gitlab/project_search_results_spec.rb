# coding: utf-8
require 'spec_helper'

describe Gitlab::ProjectSearchResults do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:query) { 'hello world' }

  describe 'initialize with empty ref' do
    let(:results) { described_class.new(user, project, query, '') }

    it { expect(results.project).to eq(project) }
    it { expect(results.query).to eq('hello world') }
  end

  describe 'initialize with ref' do
    let(:ref) { 'refs/heads/test' }
    let(:results) { described_class.new(user, project, query, ref) }

    it { expect(results.project).to eq(project) }
    it { expect(results.repository_ref).to eq(ref) }
    it { expect(results.query).to eq('hello world') }
  end

  describe 'blob search' do
    let(:project) { create(:project, :public, :repository) }

    subject(:results) { described_class.new(user, project, 'files').objects('blobs') }

    context 'when repository is disabled' do
      let(:project) { create(:project, :public, :repository, :repository_disabled) }

      it 'hides blobs from members' do
        project.add_reporter(user)

        is_expected.to be_empty
      end

      it 'hides blobs from non-members' do
        is_expected.to be_empty
      end
    end

    context 'when repository is internal' do
      let(:project) { create(:project, :public, :repository, :repository_private) }

      it 'finds blobs for members' do
        project.add_reporter(user)

        is_expected.not_to be_empty
      end

      it 'hides blobs from non-members' do
        is_expected.to be_empty
      end
    end

    it 'finds by name' do
      expect(results.map(&:first)).to include('files/images/wm.svg')
    end

    it 'finds by content' do
      blob = results.select { |result| result.first == "CHANGELOG" }.flatten.last

      expect(blob.filename).to eq("CHANGELOG")
    end

    describe 'parsing results' do
      let(:results) { project.repository.search_files_by_content('feature', 'master') }
      let(:search_result) { results.first }

      subject { described_class.parse_search_result(search_result) }

      it "returns a valid FoundBlob" do
        is_expected.to be_an Gitlab::SearchResults::FoundBlob
        expect(subject.id).to be_nil
        expect(subject.path).to eq('CHANGELOG')
        expect(subject.filename).to eq('CHANGELOG')
        expect(subject.basename).to eq('CHANGELOG')
        expect(subject.ref).to eq('master')
        expect(subject.startline).to eq(188)
        expect(subject.data.lines[2]).to eq("  - Feature: Replace teams with group membership\n")
      end

      context 'when the matching filename contains a colon' do
        let(:search_result) { "master:testdata/project::function1.yaml\x001\x00---\n" }

        it 'returns a valid FoundBlob' do
          expect(subject.filename).to eq('testdata/project::function1.yaml')
          expect(subject.basename).to eq('testdata/project::function1')
          expect(subject.ref).to eq('master')
          expect(subject.startline).to eq(1)
          expect(subject.data).to eq("---\n")
        end
      end

      context 'when the matching content contains a number surrounded by colons' do
        let(:search_result) { "master:testdata/foo.txt\x001\x00blah:9:blah" }

        it 'returns a valid FoundBlob' do
          expect(subject.filename).to eq('testdata/foo.txt')
          expect(subject.basename).to eq('testdata/foo')
          expect(subject.ref).to eq('master')
          expect(subject.startline).to eq(1)
          expect(subject.data).to eq('blah:9:blah')
        end
      end

      context 'when the search result ends with an empty line' do
        let(:results) { project.repository.search_files_by_content('Role models', 'master') }

        it 'returns a valid FoundBlob that ends with an empty line' do
          expect(subject.filename).to eq('files/markdown/ruby-style-guide.md')
          expect(subject.basename).to eq('files/markdown/ruby-style-guide')
          expect(subject.ref).to eq('master')
          expect(subject.startline).to eq(1)
          expect(subject.data).to eq("# Prelude\n\n> Role models are important. <br/>\n> -- Officer Alex J. Murphy / RoboCop\n\n")
        end
      end

      context 'when the search returns non-ASCII data' do
        context 'with UTF-8' do
          let(:results) { project.repository.search_files_by_content('файл', 'master') }

          it 'returns results as UTF-8' do
            expect(subject.filename).to eq('encoding/russian.rb')
            expect(subject.basename).to eq('encoding/russian')
            expect(subject.ref).to eq('master')
            expect(subject.startline).to eq(1)
            expect(subject.data).to eq("Хороший файл\n")
          end
        end

        context 'with UTF-8 in the filename' do
          let(:results) { project.repository.search_files_by_content('webhook', 'master') }

          it 'returns results as UTF-8' do
            expect(subject.filename).to eq('encoding/テスト.txt')
            expect(subject.basename).to eq('encoding/テスト')
            expect(subject.ref).to eq('master')
            expect(subject.startline).to eq(3)
            expect(subject.data).to include('WebHookの確認')
          end
        end

        context 'with ISO-8859-1' do
          let(:search_result) { "master:encoding/iso8859.txt\x001\x00\xC4\xFC\nmaster:encoding/iso8859.txt\x002\x00\nmaster:encoding/iso8859.txt\x003\x00foo\n".force_encoding(Encoding::ASCII_8BIT) }

          it 'returns results as UTF-8' do
            expect(subject.filename).to eq('encoding/iso8859.txt')
            expect(subject.basename).to eq('encoding/iso8859')
            expect(subject.ref).to eq('master')
            expect(subject.startline).to eq(1)
            expect(subject.data).to eq("Äü\n\nfoo\n")
          end
        end
      end

      context "when filename has extension" do
        let(:search_result) { "master:CONTRIBUTE.md\x005\x00- [Contribute to GitLab](#contribute-to-gitlab)\n" }

        it { expect(subject.path).to eq('CONTRIBUTE.md') }
        it { expect(subject.filename).to eq('CONTRIBUTE.md') }
        it { expect(subject.basename).to eq('CONTRIBUTE') }
      end

      context "when file under directory" do
        let(:search_result) { "master:a/b/c.md\x005\x00a b c\n" }

        it { expect(subject.path).to eq('a/b/c.md') }
        it { expect(subject.filename).to eq('a/b/c.md') }
        it { expect(subject.basename).to eq('a/b/c') }
      end
    end
  end

  describe 'wiki search' do
    let(:project) { create(:project, :public) }
    let(:wiki) { build(:project_wiki, project: project) }
    let!(:wiki_page) { wiki.create_page('Title', 'Content') }

    subject(:results) { described_class.new(user, project, 'Content').objects('wiki_blobs') }

    context 'when wiki is disabled' do
      let(:project) { create(:project, :public, :wiki_disabled) }

      it 'hides wiki blobs from members' do
        project.add_reporter(user)

        is_expected.to be_empty
      end

      it 'hides wiki blobs from non-members' do
        is_expected.to be_empty
      end
    end

    context 'when wiki is internal' do
      let(:project) { create(:project, :public, :wiki_private) }

      it 'finds wiki blobs for guest' do
        project.add_guest(user)

        is_expected.not_to be_empty
      end

      it 'hides wiki blobs from non-members' do
        is_expected.to be_empty
      end
    end

    it 'finds by content' do
      expect(results).to include("master:Title.md\x001\x00Content\n")
    end
  end

  it 'does not list issues on private projects' do
    issue = create(:issue, project: project)

    results = described_class.new(user, project, issue.title)

    expect(results.objects('issues')).not_to include issue
  end

  describe 'confidential issues' do
    let(:query) { 'issue' }
    let(:author) { create(:user) }
    let(:assignee) { create(:user) }
    let(:non_member) { create(:user) }
    let(:member) { create(:user) }
    let(:admin) { create(:admin) }
    let(:project) { create(:project, :internal) }
    let!(:issue) { create(:issue, project: project, title: 'Issue 1') }
    let!(:security_issue_1) { create(:issue, :confidential, project: project, title: 'Security issue 1', author: author) }
    let!(:security_issue_2) { create(:issue, :confidential, title: 'Security issue 2', project: project, assignees: [assignee]) }

    it 'does not list project confidential issues for non project members' do
      results = described_class.new(non_member, project, query)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).not_to include security_issue_1
      expect(issues).not_to include security_issue_2
      expect(results.limited_issues_count).to eq 1
    end

    it 'does not list project confidential issues for project members with guest role' do
      project.add_guest(member)

      results = described_class.new(member, project, query)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).not_to include security_issue_1
      expect(issues).not_to include security_issue_2
      expect(results.limited_issues_count).to eq 1
    end

    it 'lists project confidential issues for author' do
      results = described_class.new(author, project, query)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).to include security_issue_1
      expect(issues).not_to include security_issue_2
      expect(results.limited_issues_count).to eq 2
    end

    it 'lists project confidential issues for assignee' do
      results = described_class.new(assignee, project, query)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).not_to include security_issue_1
      expect(issues).to include security_issue_2
      expect(results.limited_issues_count).to eq 2
    end

    it 'lists project confidential issues for project members' do
      project.add_developer(member)

      results = described_class.new(member, project, query)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).to include security_issue_1
      expect(issues).to include security_issue_2
      expect(results.limited_issues_count).to eq 3
    end

    it 'lists all project issues for admin' do
      results = described_class.new(admin, project, query)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).to include security_issue_1
      expect(issues).to include security_issue_2
      expect(results.limited_issues_count).to eq 3
    end
  end

  describe 'notes search' do
    it 'lists notes' do
      project = create(:project, :public)
      note = create(:note, project: project)

      results = described_class.new(user, project, note.note)

      expect(results.objects('notes')).to include note
    end

    it "doesn't list issue notes when access is restricted" do
      project = create(:project, :public, :issues_private)
      note = create(:note_on_issue, project: project)

      results = described_class.new(user, project, note.note)

      expect(results.objects('notes')).not_to include note
    end

    it "doesn't list merge_request notes when access is restricted" do
      project = create(:project, :public, :merge_requests_private)
      note = create(:note_on_merge_request, project: project)

      results = described_class.new(user, project, note.note)

      expect(results.objects('notes')).not_to include note
    end
  end

  describe '#limited_notes_count' do
    let(:project) { create(:project, :public) }
    let(:note) { create(:note_on_issue, project: project) }
    let(:results) { described_class.new(user, project, note.note) }

    context 'when count_limit is lower than total amount' do
      before do
        allow(results).to receive(:count_limit).and_return(1)
      end

      it 'calls note finder once to get the limited amount of notes' do
        expect(results).to receive(:notes_finder).once.and_call_original
        expect(results.limited_notes_count).to eq(1)
      end
    end

    context 'when count_limit is higher than total amount' do
      it 'calls note finder multiple times to get the limited amount of notes' do
        project = create(:project, :public)
        note = create(:note_on_issue, project: project)

        results = described_class.new(user, project, note.note)

        expect(results).to receive(:notes_finder).exactly(4).times.and_call_original
        expect(results.limited_notes_count).to eq(1)
      end
    end
  end

  # Examples for commit access level test
  #
  # params:
  # * search_phrase
  # * commit
  #
  shared_examples 'access restricted commits' do
    context 'when project is internal' do
      let(:project) { create(:project, :internal, :repository) }

      it 'does not search if user is not authenticated' do
        commits = described_class.new(nil, project, search_phrase).objects('commits')

        expect(commits).to be_empty
      end

      it 'searches if user is authenticated' do
        commits = described_class.new(user, project, search_phrase).objects('commits')

        expect(commits).to contain_exactly commit
      end
    end

    context 'when project is private' do
      let!(:creator) { create(:user, username: 'private-project-author') }
      let!(:private_project) { create(:project, :private, :repository, creator: creator, namespace: creator.namespace) }
      let(:team_master) do
        user = create(:user, username: 'private-project-master')
        private_project.add_master(user)
        user
      end
      let(:team_reporter) do
        user = create(:user, username: 'private-project-reporter')
        private_project.add_reporter(user)
        user
      end

      it 'does not show commit to stranger' do
        commits = described_class.new(nil, private_project, search_phrase).objects('commits')

        expect(commits).to be_empty
      end

      context 'team access' do
        it 'shows commit to creator' do
          commits = described_class.new(creator, private_project, search_phrase).objects('commits')

          expect(commits).to contain_exactly commit
        end

        it 'shows commit to master' do
          commits = described_class.new(team_master, private_project, search_phrase).objects('commits')

          expect(commits).to contain_exactly commit
        end

        it 'shows commit to reporter' do
          commits = described_class.new(team_reporter, private_project, search_phrase).objects('commits')

          expect(commits).to contain_exactly commit
        end
      end
    end
  end

  describe 'commit search' do
    context 'by commit message' do
      let(:project) { create(:project, :public, :repository) }
      let(:commit) { project.repository.commit('59e29889be61e6e0e5e223bfa9ac2721d31605b8') }
      let(:message) { 'Sorry, I did a mistake' }

      it 'finds commit by message' do
        commits = described_class.new(user, project, message).objects('commits')

        expect(commits).to contain_exactly commit
      end

      it 'handles when no commit match' do
        commits = described_class.new(user, project, 'not really an existing description').objects('commits')

        expect(commits).to be_empty
      end

      it_behaves_like 'access restricted commits' do
        let(:search_phrase) { message }
        let(:commit) { project.repository.commit('59e29889be61e6e0e5e223bfa9ac2721d31605b8') }
      end
    end

    context 'by commit hash' do
      let(:project) { create(:project, :public, :repository) }
      let(:commit) { project.repository.commit('0b4bc9a') }

      commit_hashes = { short: '0b4bc9a', full: '0b4bc9a49b562e85de7cc9e834518ea6828729b9' }

      commit_hashes.each do |type, commit_hash|
        it "shows commit by #{type} hash id" do
          commits = described_class.new(user, project, commit_hash).objects('commits')

          expect(commits).to contain_exactly commit
        end
      end

      it 'handles not existing commit hash correctly' do
        commits = described_class.new(user, project, 'deadbeef').objects('commits')

        expect(commits).to be_empty
      end

      it_behaves_like 'access restricted commits' do
        let(:search_phrase) { '0b4bc9a49' }
        let(:commit) { project.repository.commit('0b4bc9a') }
      end
    end
  end
end
