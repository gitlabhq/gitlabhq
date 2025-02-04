# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Commit, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:personal_snippet) { create(:personal_snippet, :repository) }
  let_it_be(:project_snippet) { create(:project_snippet, :repository) }

  let(:commit) { project.commit }

  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(Mentionable) }
    it { is_expected.to include_module(Participable) }
    it { is_expected.to include_module(Referable) }
    it { is_expected.to include_module(StaticModel) }
    it { is_expected.to include_module(Presentable) }
    it { is_expected.to include_module(GlobalID::Identification) }
  end

  describe '.lazy' do
    shared_examples '.lazy checks' do
      context 'when the commits are found' do
        let(:oids) do
          %w[
            498214de67004b1da3d820901307bed2a68a8ef6
            c642fe9b8b9f28f9225d7ea953fe14e74748d53b
            6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9
            048721d90c449b244b7b4c53a9186b04330174ec
            281d3a76f31c812dbf48abce82ccf6860adedd81
          ]
        end

        subject { oids.map { |oid| described_class.lazy(container, oid) } }

        it 'batches requests for commits' do
          expect(container.repository).to receive(:commits_by).once.and_call_original

          subject.first.title
          subject.last.title
        end

        it 'maintains ordering' do
          subject.each_with_index do |commit, i|
            expect(commit.id).to eq(oids[i])
          end
        end

        it 'does not attempt to replace methods via BatchLoader' do
          subject.each do |commit|
            expect(commit).to receive(:method_missing).and_call_original

            commit.id
          end
        end
      end

      context 'when not found' do
        it 'returns nil as commit' do
          commit = described_class.lazy(container, 'deadbeef').__sync

          expect(commit).to be_nil
        end
      end
    end

    context 'with project' do
      let(:container) { project }

      it_behaves_like '.lazy checks'
    end

    context 'with personal snippet' do
      let(:container) { personal_snippet }

      it_behaves_like '.lazy checks'
    end

    context 'with project snippet' do
      let(:container) { project_snippet }

      it_behaves_like '.lazy checks'
    end
  end

  describe '.build_from_sidekiq_hash' do
    it 'returns a Commit' do
      commit = described_class.build_from_sidekiq_hash(project, id: '123')

      expect(commit).to be_an_instance_of(described_class)
    end

    it 'parses date strings into Time instances' do
      commit = described_class.build_from_sidekiq_hash(
        project,
        id: '123',
        authored_date: Time.current.to_s
      )

      expect(commit.authored_date).to be_a_kind_of(Time)
    end
  end

  describe '#diff_refs' do
    it 'is equal to itself' do
      expect(commit.diff_refs).to eq(commit.diff_refs)
    end

    context 'from a factory' do
      let(:commit) { create(:commit) }

      it 'is equal to itself' do
        expect(commit.diff_refs).to eq(commit.diff_refs)
      end
    end
  end

  describe '#author', :request_store do
    it 'looks up the author in a case-insensitive way' do
      user = create(:user, email: commit.author_email.upcase)
      expect(commit.author).to eq(user)
    end

    it 'caches the author' do
      user = create(:user, email: commit.author_email)

      expect(commit.author).to eq(user)

      key = "Commit:author:#{commit.author_email.downcase}"

      expect(Gitlab::SafeRequestStore[key]).to eq(user)
      expect(commit.author).to eq(user)
    end

    context 'with a user with an unconfirmed e-mail' do
      before do
        user = create(:user)
        create(:email, user: user, email: commit.author_email)
      end

      it 'returns no user' do
        expect(commit.author).to be_nil
      end
    end

    context 'using eager loading' do
      let!(:alice) { create(:user, email: 'alice@example.com') }
      let!(:bob) { create(:user, email: 'hunter2@example.com') }
      let!(:jeff) { create(:user) }

      let(:alice_commit) do
        described_class.new(RepoHelpers.sample_commit, project).tap do |c|
          c.author_email = 'alice@example.com'
        end
      end

      let(:bob_commit) do
        # The commit for Bob uses one of his alternative Emails, instead of the
        # primary one.
        described_class.new(RepoHelpers.sample_commit, project).tap do |c|
          c.author_email = 'bob@example.com'
        end
      end

      let(:eve_commit) do
        described_class.new(RepoHelpers.sample_commit, project).tap do |c|
          c.author_email = 'eve@example.com'
        end
      end

      let(:jeff_commit) do
        # The commit for Jeff uses his private commit email
        described_class.new(RepoHelpers.sample_commit, project).tap do |c|
          c.author_email = jeff.private_commit_email
        end
      end

      let!(:commits) { [alice_commit, bob_commit, eve_commit, jeff_commit] }

      before do
        create(:email, :confirmed, user: bob, email: 'bob@example.com')
      end

      it 'executes only two SQL queries' do
        recorder = ActiveRecord::QueryRecorder.new do
          # Running this first ensures we don't run one query for every
          # commit.
          commits.each(&:lazy_author)

          # This forces the execution of the SQL queries necessary to load the
          # data.
          commits.each { |c| c.author.try(:id) }
        end

        expect(recorder.count).to eq(2)
      end

      it "preloads the authors for Commits matching a user's primary Email" do
        commits.each(&:lazy_author)

        expect(alice_commit.author).to eq(alice)
      end

      it "preloads the authors for Commits using a User's alternative Email" do
        commits.each(&:lazy_author)

        expect(bob_commit.author).to eq(bob)
      end

      it "preloads the authors for Commits using a User's private commit Email" do
        commits.each(&:lazy_author)

        expect(jeff_commit.author).to eq(jeff)
      end

      it "preloads the authors for Commits using a User's outdated private commit Email" do
        jeff.update!(username: 'new-username')

        commits.each(&:lazy_author)

        expect(jeff_commit.author).to eq(jeff)
      end

      it 'sets the author to Nil if an author could not be found for a Commit' do
        commits.each(&:lazy_author)

        expect(eve_commit.author).to be_nil
      end

      it 'does not execute SQL queries once the authors are preloaded' do
        commits.each(&:lazy_author)
        commits.each { |c| c.author.try(:id) }

        recorder = ActiveRecord::QueryRecorder.new do
          alice_commit.author
          bob_commit.author
          eve_commit.author
        end

        expect(recorder.count).to be_zero
      end
    end

    context 'when author_email is nil' do
      let(:git_commit) { RepoHelpers.sample_commit.tap { |c| c.author_email = nil } }
      let(:commit) { described_class.new(git_commit, build(:project)) }

      it 'returns nil' do
        expect(commit.author).to be_nil
      end
    end
  end

  describe '#committer' do
    context "when committer_email is the user's primary email" do
      context 'when the user email is confirmed' do
        let!(:user) { create(:user, email: commit.committer_email) }

        it 'returns the user' do
          expect(commit.committer).to eq(user)
          expect(commit.committer(confirmed: false)).to eq(user)
        end
      end

      context 'when the user email is unconfirmed' do
        let!(:user) { create(:user, :unconfirmed, email: commit.committer_email) }

        it 'returns the user according to confirmed argument' do
          expect(commit.committer).to be_nil
          expect(commit.committer(confirmed: false)).to eq(user)
        end
      end
    end

    context "when committer_email is the user's secondary email" do
      let!(:user) { create(:user) }

      context 'when the user email is confirmed' do
        let!(:email) { create(:email, :confirmed, user: user, email: commit.committer_email) }

        it 'returns the user' do
          expect(commit.committer).to eq(user)
          expect(commit.committer(confirmed: false)).to eq(user)
        end
      end

      context 'when the user email is unconfirmed' do
        let!(:email) { create(:email, user: user, email: commit.committer_email) }

        it 'does not return the user' do
          expect(commit.committer).to be_nil
          expect(commit.committer(confirmed: false)).to be_nil
        end
      end
    end
  end

  describe '#to_reference' do
    context 'with project' do
      let(:project) { create(:project, :repository, path: 'sample-project') }

      it 'returns a String reference to the object' do
        expect(commit.to_reference).to eq commit.id
      end

      it 'supports a cross-project reference' do
        another_project = build(:project, :repository, name: 'another-project', namespace: project.namespace)
        expect(commit.to_reference(another_project)).to eq "sample-project@#{commit.id}"
      end
    end

    context 'with personal snippet' do
      let(:commit) { personal_snippet.commit }

      it 'returns a String reference to the object' do
        expect(commit.to_reference).to eq "$#{personal_snippet.id}@#{commit.id}"
      end

      it 'supports a cross-snippet reference' do
        another_snippet = build(:personal_snippet)
        expect(commit.to_reference(another_snippet)).to eq "$#{personal_snippet.id}@#{commit.id}"
      end
    end

    context 'with project snippet' do
      let(:commit) { project_snippet.commit }

      it 'returns a String reference to the object' do
        expect(commit.to_reference).to eq "$#{project_snippet.id}@#{commit.id}"
      end

      it 'supports a cross-snippet project reference' do
        another_snippet = build(:personal_snippet)
        expect(commit.to_reference(another_snippet)).to eq "#{project_snippet.project.path}$#{project_snippet.id}@#{commit.id}"
      end
    end
  end

  describe '.reference_valid?' do
    using RSpec::Parameterized::TableSyntax

    where(:ref, :result) do
      '1234567' | true
      '123456' | false
      '1' | false
      ('0' * 40) | true
      'c1acaa58bbcbc3eafe538cb8274ba387047b69f8' | true
      'H1acaa58bbcbc3eafe538cb8274ba387047b69f8' | false
      nil | false
    end

    with_them do
      it { expect(described_class.reference_valid?(ref)).to eq(result) }
    end
  end

  describe '#reference_link_text' do
    let(:project) { create(:project, :repository, path: 'sample-project') }

    context 'with project' do
      it 'returns a String reference to the object' do
        expect(commit.reference_link_text).to eq commit.short_id
      end

      it 'supports a cross-project reference' do
        another_project = build(:project, :repository, name: 'another-project', namespace: project.namespace)
        expect(commit.reference_link_text(another_project)).to eq "sample-project@#{commit.short_id}"
      end
    end

    context 'with personal snippet' do
      let(:commit) { personal_snippet.commit }

      it 'returns a String reference to the object' do
        expect(commit.reference_link_text).to eq "$#{personal_snippet.id}@#{commit.short_id}"
      end

      it 'supports a cross-snippet reference' do
        another_snippet = build(:personal_snippet, :repository)
        expect(commit.reference_link_text(another_snippet)).to eq "$#{personal_snippet.id}@#{commit.short_id}"
      end
    end

    context 'with project snippet' do
      let(:commit) { project_snippet.commit }

      it 'returns a String reference to the object' do
        expect(commit.reference_link_text).to eq "$#{project_snippet.id}@#{commit.short_id}"
      end

      it 'supports a cross-snippet project reference' do
        another_snippet = build(:project_snippet, :repository)
        expect(commit.reference_link_text(another_snippet)).to eq "#{project_snippet.project.path}$#{project_snippet.id}@#{commit.short_id}"
      end
    end
  end

  describe '#title' do
    it "returns no_commit_message when safe_message is blank" do
      allow(commit).to receive(:safe_message).and_return('')
      expect(commit.title).to eq("No commit message")
    end

    it 'truncates a message without a newline at natural break to 80 characters' do
      message = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec sodales id felis id blandit. Vivamus egestas lacinia lacus, sed rutrum mauris.'

      allow(commit).to receive(:safe_message).and_return(message)
      expect(commit.title).to eq('Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec sodales id...')
    end

    it "truncates a message with a newline before 80 characters at the newline" do
      message = commit.safe_message.split(" ").first

      allow(commit).to receive(:safe_message).and_return(message + "\n" + message)
      expect(commit.title).to eq(message)
    end

    it "does not truncates a message with a newline after 80 but less 100 characters" do
      message = <<EOS
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec sodales id felis id blandit.
Vivamus egestas lacinia lacus, sed rutrum mauris.
EOS

      allow(commit).to receive(:safe_message).and_return(message)
      expect(commit.title).to eq(message.split("\n").first)
    end
  end

  describe '#full_title' do
    it "returns no_commit_message when safe_message is blank" do
      allow(commit).to receive(:safe_message).and_return('')
      expect(commit.full_title).to eq("No commit message")
    end

    it "returns entire message if there is no newline" do
      message = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec sodales id felis id blandit. Vivamus egestas lacinia lacus, sed rutrum mauris.'

      allow(commit).to receive(:safe_message).and_return(message)
      expect(commit.full_title).to eq(message)
    end

    it "returns first line of message if there is a newLine" do
      message = commit.safe_message.split(" ").first

      allow(commit).to receive(:safe_message).and_return(message + "\n" + message)
      expect(commit.full_title).to eq(message)
    end

    it 'truncates html representation if more than 1KiB' do
      # Commit title is over 2KiB on a single line
      huge_commit_title = ('panic ' * 350) + 'trailing text'

      allow(commit).to receive(:safe_message).and_return(huge_commit_title)

      commit.refresh_markdown_cache
      full_title_html = commit.full_title_html

      expect(full_title_html.bytesize).to be < 2.kilobytes
      expect(full_title_html).not_to include('trailing text')
    end
  end

  describe 'description' do
    it 'returns no_commit_message when safe_message is blank' do
      allow(commit).to receive(:safe_message).and_return(nil)

      expect(commit.description).to eq('No commit message')
    end

    it 'returns description of commit message if title less than 100 characters' do
      message = <<EOS
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec sodales id felis id blandit.
Vivamus egestas lacinia lacus, sed rutrum mauris.
EOS

      allow(commit).to receive(:safe_message).and_return(message)
      expect(commit.description).to eq('Vivamus egestas lacinia lacus, sed rutrum mauris.')
    end

    it 'returns full commit message if commit title more than 100 characters' do
      message = <<EOS
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec sodales id felis id blandit. Vivamus egestas lacinia lacus, sed rutrum mauris.
Vivamus egestas lacinia lacus, sed rutrum mauris.
EOS

      allow(commit).to receive(:safe_message).and_return(message)
      expect(commit.description).to eq(message)
    end

    it 'truncates html representation if more than 1Mib' do
      # Commit message is over 2MiB
      huge_commit_message = ['panic', ('panic ' * 350000), 'trailing text'].join("\n")

      allow(commit).to receive(:safe_message).and_return(huge_commit_message)

      commit.refresh_markdown_cache
      description_html = commit.description_html

      expect(description_html.bytesize).to be < 2.megabytes
      expect(description_html).not_to include('trailing text')
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
    it { is_expected.to respond_to(:id) }
  end

  it_behaves_like 'a mentionable' do
    subject(:commit) { create(:project, :repository).commit }

    let(:author) { create(:user, email: subject.author_email) }
    let(:backref_text) { "commit #{subject.id}" }
    let(:set_mentionable_text) do
      ->(txt) { allow(commit).to receive(:safe_message).and_return(txt) }
    end

    # Include the subject in the repository stub.
    let(:extra_commits) { [commit] }

    it 'uses the CachedMarkdownField cache instead of the Mentionable cache', :use_clean_rails_redis_caching do
      expect(commit.title_html).not_to be_present

      commit.all_references(project.first_owner).all

      expect(commit.title_html).to be_present
      expect(Rails.cache.read("banzai/commit:#{commit.id}/safe_message/single_line")).to be_nil
    end
  end

  describe '#hook_attrs' do
    let(:data) { commit.hook_attrs(with_changed_files: true) }

    it { expect(data).to be_a(Hash) }
    it { expect(data[:message]).to include('adds bar folder and branch-test text file to check Repository merged_to_root_ref method') }
    it { expect(data[:timestamp]).to eq('2016-09-27T14:37:46+00:00') }
    it { expect(data[:added]).to contain_exactly("bar/branch-test.txt") }
    it { expect(data[:modified]).to eq([]) }
    it { expect(data[:removed]).to eq([]) }
  end

  describe '#cherry_pick_message' do
    let(:user) { create(:user) }

    context 'of a regular commit' do
      let(:commit) { project.commit('video') }

      it { expect(commit.cherry_pick_message(user)).to include("\n\n(cherry-picked from commit 88790590ed1337ab189bccaa355f068481c90bec)") }
    end

    context 'of a merge commit' do
      let(:repository) { project.repository }

      let(:merge_request) do
        create(
          :merge_request,
          source_branch: 'video',
          target_branch: 'master',
          source_project: project,
          author: user
        )
      end

      let(:merge_commit) do
        merge_commit_id = repository.merge(
          user,
          merge_request.diff_head_sha,
          merge_request,
          'Test message'
        )

        repository.commit(merge_commit_id)
      end

      context 'that is found' do
        before do
          # Artificially mark as completed.
          merge_request.update!(merge_commit_sha: merge_commit.id)
        end

        it do
          expected_appended_text = <<~STR.rstrip

            (cherry-picked from commit #{merge_commit.sha})

            467dc98f Add new 'videos' directory
            88790590 Upload new video file
          STR

          expect(merge_commit.cherry_pick_message(user)).to include(expected_appended_text)
        end
      end

      context "that is existing but not found" do
        it 'does not include details of the merged commits' do
          expect(merge_commit.cherry_pick_message(user)).to end_with("(cherry-picked from commit #{merge_commit.sha})")
        end
      end
    end
  end

  describe '#parents' do
    subject(:parents) { commit.parents }

    it 'loads commits for parents' do
      expect(parents).to all be_kind_of(described_class)
      expect(parents.map(&:id)).to match_array(commit.parent_ids)
    end

    context 'when parent id cannot be loaded' do
      before do
        allow(commit).to receive(:parent_ids).and_return(["invalid"])
      end

      it 'returns an empty array' do
        expect(parents).to eq([])
      end
    end
  end

  describe '#reverts_commit?' do
    let(:another_commit) { double(:commit, revert_description: "This reverts commit #{commit.sha}") }
    let(:user) { commit.author }

    it { expect(commit.reverts_commit?(another_commit, user)).to be_falsy }

    context 'commit has no description' do
      before do
        allow(commit).to receive(:description?).and_return(false)
      end

      it { expect(commit.reverts_commit?(another_commit, user)).to be_falsy }
    end

    context "another_commit's description does not revert commit" do
      before do
        allow(commit).to receive(:description).and_return("Foo Bar")
      end

      it { expect(commit.reverts_commit?(another_commit, user)).to be_falsy }
    end

    context "another_commit's description reverts commit" do
      before do
        allow(commit).to receive(:description).and_return("Foo #{another_commit.revert_description} Bar")
      end

      it { expect(commit.reverts_commit?(another_commit, user)).to be_truthy }
    end

    context "another_commit's description reverts merged merge request" do
      before do
        revert_description = "This reverts merge request !foo123"
        allow(another_commit).to receive(:revert_description).and_return(revert_description)
        allow(commit).to receive(:description).and_return("Foo #{another_commit.revert_description} Bar")
      end

      it { expect(commit.reverts_commit?(another_commit, user)).to be_truthy }
    end
  end

  describe '#participants' do
    let(:user1) { build(:user) }
    let(:user2) { build(:user) }

    let!(:note1) do
      create(
        :note_on_commit,
        commit_id: commit.id,
        project: project,
        note: 'foo'
      )
    end

    let!(:note2) do
      create(
        :note_on_commit,
        commit_id: commit.id,
        project: project,
        note: 'bar'
      )
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

  shared_examples '#uri_type' do
    it 'returns the URI type at the given path' do
      expect(commit.uri_type('files/html')).to be(:tree)
      expect(commit.uri_type('files/images/logo-black.png')).to be(:raw)
      expect(commit.uri_type('files/images/wm.svg')).to be(:raw)
      expect(project.commit('audio').uri_type('files/audio/clip.mp3')).to be(:raw)
      expect(project.commit('audio').uri_type('files/audio/sample.wav')).to be(:raw)
      expect(project.commit('video').uri_type('files/videos/intro.mp4')).to be(:raw)
      expect(commit.uri_type('files/js/application.js')).to be(:blob)
    end

    it "returns nil if the path doesn't exists" do
      expect(commit.uri_type('this/path/doesnt/exist')).to be_nil
      expect(commit.uri_type('../path/doesnt/exist')).to be_nil
    end

    it 'is nil if the path is nil or empty' do
      expect(commit.uri_type(nil)).to be_nil
      expect(commit.uri_type("")).to be_nil
    end
  end

  describe '#uri_type with Gitaly enabled' do
    it_behaves_like "#uri_type"
  end

  describe '.diff_max_files' do
    subject(:diff_max_files) { described_class.diff_max_files }

    it 'returns the current settings' do
      Gitlab::CurrentSettings.update!(diff_max_files: 1234)
      expect(diff_max_files).to eq(1234)
    end
  end

  describe '.diff_max_lines' do
    subject(:diff_max_lines) { described_class.diff_max_lines }

    it 'returns the current settings' do
      Gitlab::CurrentSettings.update!(diff_max_lines: 65321)
      expect(diff_max_lines).to eq(65321)
    end
  end

  describe '.diff_safe_max_files' do
    subject(:diff_safe_max_files) { described_class.diff_safe_max_files }

    it 'returns the commit diff max divided by the limit factor of 10' do
      expect(::Commit).to receive(:diff_max_files).and_return(10)
      expect(diff_safe_max_files).to eq(1)
    end
  end

  describe '.diff_safe_max_lines' do
    subject(:diff_safe_max_lines) { described_class.diff_safe_max_lines }

    it 'returns the commit diff max divided by the limit factor of 10' do
      expect(::Commit).to receive(:diff_max_lines).and_return(100)
      expect(diff_safe_max_lines).to eq(10)
    end
  end

  describe '.from_hash' do
    subject { described_class.from_hash(commit.to_hash, container) }

    shared_examples 'returns Commit' do
      it 'returns a Commit' do
        expect(subject).to be_an_instance_of(described_class)
      end

      it 'wraps a Gitlab::Git::Commit' do
        expect(subject.raw).to be_an_instance_of(Gitlab::Git::Commit)
      end

      it 'stores the correct commit fields' do
        expect(subject.id).to eq(commit.id)
        expect(subject.message).to eq(commit.message)
      end
    end

    context 'with project' do
      let(:container) { project }

      it_behaves_like 'returns Commit'
    end

    context 'with personal snippet' do
      let(:container) { personal_snippet }

      it_behaves_like 'returns Commit'
    end

    context 'with project snippet' do
      let(:container) { project_snippet }

      it_behaves_like 'returns Commit'
    end
  end

  describe '#draft?' do
    [
      'squash! ', 'fixup! ',
      'draft: ', '[Draft] ', '(draft) ', 'Draft: '
    ].each do |draft_prefix|
      it "detects the '#{draft_prefix}' prefix" do
        commit.message = "#{draft_prefix}#{commit.message}"

        expect(commit).to be_draft
      end
    end

    it "does not detect a commit just saying 'draft' as draft? == true" do
      commit.message = "draft"

      expect(commit).not_to be_draft
    end

    ["FIXUP!", "Draft - ", "Wipeout", "WIP: ", "[WIP] ", "wip: "].each do |draft_prefix|
      it "doesn't detect '#{draft_prefix}' at the start of the title as a draft" do
        commit.message = "#{draft_prefix} #{commit.message}"

        expect(commit).not_to be_draft
      end
    end
  end

  describe '.valid_hash?' do
    it 'checks hash contents' do
      expect(described_class.valid_hash?('abcdef01239ABCDEF')).to be true
      expect(described_class.valid_hash?("abcdef01239ABCD\nEF")).to be false
      expect(described_class.valid_hash?(' abcdef01239ABCDEF ')).to be false
      expect(described_class.valid_hash?('Gabcdef01239ABCDEF')).to be false
      expect(described_class.valid_hash?('gabcdef01239ABCDEF')).to be false
      expect(described_class.valid_hash?('-abcdef01239ABCDEF')).to be false
    end

    it 'checks hash length' do
      expect(described_class.valid_hash?('a' * 6)).to be false
      expect(described_class.valid_hash?('a' * 7)).to be true
      expect(described_class.valid_hash?('a' * 40)).to be true
      expect(described_class.valid_hash?('a' * 64)).to be true
      expect(described_class.valid_hash?('a' * 65)).to be false
    end
  end

  describe 'signed commits' do
    let(:gpg_signed_commit) { project.commit_by(oid: '0b4bc9a49b562e85de7cc9e834518ea6828729b9') }
    let(:x509_signed_commit) { project.commit_by(oid: '189a6c924013fc3fe40d6f1ec1dc20214183bc97') }
    let(:ssh_signed_commit) { project.commit_by(oid: '7b5160f9bb23a3d58a0accdbe89da13b96b1ece9') }
    let(:unsigned_commit) { project.commit_by(oid: '54fcc214b94e78d7a41a9a8fe6d87a5e59500e51') }
    let!(:commit) { create(:commit, project: project) }

    it 'returns signature_type properly' do
      expect(gpg_signed_commit.signature_type).to eq(:PGP)
      expect(x509_signed_commit.signature_type).to eq(:X509)
      expect(ssh_signed_commit.signature_type).to eq(:SSH)
      expect(unsigned_commit.signature_type).to eq(:NONE)
      expect(commit.signature_type).to eq(:NONE)
    end

    it 'returns has_signature? properly' do
      expect(gpg_signed_commit.has_signature?).to be_truthy
      expect(x509_signed_commit.has_signature?).to be_truthy
      expect(ssh_signed_commit.has_signature?).to be_truthy
      expect(unsigned_commit.has_signature?).to be_falsey
      expect(commit.has_signature?).to be_falsey
    end
  end

  describe '#has_been_reverted?' do
    let(:user) { create(:user) }
    let(:issue) { create(:issue, author: user, project: project) }

    it 'returns true if the commit has been reverted' do
      create(
        :note_on_issue,
        noteable: issue,
        system: true,
        note: commit.revert_description(user),
        project: issue.project
      )

      expect_next_instance_of(Commit) do |revert_commit|
        expect(revert_commit).to receive(:reverts_commit?)
          .with(commit, user)
          .and_return(true)
      end

      expect(commit.has_been_reverted?(user, issue.notes_with_associations)).to eq(true)
    end

    it 'returns false if the commit has not been reverted' do
      expect(commit.has_been_reverted?(user, issue.notes_with_associations)).to eq(false)
    end
  end

  describe '#merged_merge_request' do
    subject { commit.merged_merge_request(user) }

    let(:user) { project.first_owner }

    before do
      allow(commit).to receive(:parent_ids).and_return(parent_ids)
    end

    context 'when commit is a merge commit' do
      let!(:merge_request) { create(:merge_request, source_project: project, merge_commit_sha: commit.id) }
      let(:parent_ids) { [1, 2] }

      it { is_expected.to eq(merge_request) }
    end

    context 'when commit is a squash commit' do
      let!(:merge_request) { create(:merge_request, source_project: project, squash_commit_sha: commit.id) }
      let(:parent_ids) { [1] }

      it { is_expected.to eq(merge_request) }
    end

    context 'when commit does not belong to the merge request' do
      let!(:merge_request) { create(:merge_request, source_project: project) }
      let(:parent_ids) { [1] }

      it { is_expected.to be_nil }
    end
  end

  describe '#tipping_refs' do
    let_it_be(:tag_name) { 'v1.1.0' }
    let_it_be(:branch_names) { %w[master not-merged-branch v1.1.0] }

    shared_examples 'tipping ref names' do
      context 'when called without limits' do
        it 'return tipping refs names' do
          expect(called_method.call).to eq(expected)
        end
      end

      context 'when called with limits' do
        it 'return tipping refs names' do
          limit = 1
          expect(called_method.call(limit).size).to be <= limit
        end
      end

      describe '#tipping_branches' do
        let(:called_method) { ->(limit = 0) { commit.tipping_branches(limit: limit) } }
        let(:expected) { branch_names }

        it_behaves_like 'with tipping ref names'
      end

      describe '#tipping_tags' do
        let(:called_method) { ->(limit = 0) { commit.tipping_tags(limit: limit) } }
        let(:expected) { [tag_name] }

        it_behaves_like 'with tipping ref names'
      end
    end
  end

  context 'containing refs' do
    shared_examples 'containing ref names' do
      context 'without arguments' do
        it 'returns branch names containing the commit' do
          expect(ref_containing.call).to eq(containing_refs)
        end
      end

      context 'with limit argument' do
        it 'returns the appropriate amount branch names' do
          limit = 2
          expect(ref_containing.call(limit: limit).size).to be <= limit
        end
      end

      context 'with tipping refs excluded' do
        let(:excluded_refs) do
          project.repository.refs_by_oid(oid: commit_sha, ref_patterns: [ref_prefix]).map { |n| n.delete_prefix(ref_prefix) }
        end

        it 'returns branch names containing the commit without the one with the commit at tip' do
          expect(ref_containing.call(excluded_tipped: true)).to eq(containing_refs - excluded_refs)
        end

        it 'returns the appropriate amount branch names with limit argument' do
          limit = 2
          expect(ref_containing.call(limit: limit, excluded_tipped: true).size).to be <= limit
        end
      end
    end

    describe '#branches_containing' do
      let_it_be(:commit_sha) { project.commit.sha }
      let_it_be(:containing_refs) { project.repository.branch_names_contains(commit_sha) }

      let(:ref_prefix) { Gitlab::Git::BRANCH_REF_PREFIX }

      let(:ref_containing) { ->(limit: 0, excluded_tipped: false) { commit.branches_containing(exclude_tipped: excluded_tipped, limit: limit) } }

      it_behaves_like 'containing ref names'
    end

    describe '#tags_containing' do
      let_it_be(:tag_name) { 'v1.1.0' }
      let_it_be(:commit_sha) { project.repository.find_tag(tag_name).target_commit.sha }
      let_it_be(:containing_refs) { %w[v1.1.0 v1.1.1] }

      let(:ref_prefix) { Gitlab::Git::TAG_REF_PREFIX }

      let(:commit) { project.repository.commit(commit_sha) }
      let(:ref_containing) { ->(limit: 0, excluded_tipped: false) { commit.tags_containing(exclude_tipped: excluded_tipped, limit: limit) } }

      it_behaves_like 'containing ref names'
    end
  end

  describe '#has_encoded_file_paths?' do
    before do
      allow(commit).to receive(:raw_diffs).and_return(raw_diffs)
    end

    context 'when there are diffs with encoded_file_path as true' do
      let(:raw_diffs) do
        [
          instance_double(Gitlab::Git::Diff, encoded_file_path: true),
          instance_double(Gitlab::Git::Diff, encoded_file_path: false)
        ]
      end

      it 'returns true' do
        expect(commit.has_encoded_file_paths?).to eq(true)
      end
    end

    context 'when there are no diffs with encoded_file_path as true' do
      let(:raw_diffs) do
        [
          instance_double(Gitlab::Git::Diff, encoded_file_path: false),
          instance_double(Gitlab::Git::Diff, encoded_file_path: false)
        ]
      end

      it 'returns false' do
        expect(commit.has_encoded_file_paths?).to eq(false)
      end
    end
  end

  describe '#valid_full_sha' do
    before do
      allow(commit).to receive(:id).and_return(value)
    end

    let(:sha) { '5716ca5987cbf97d6bb54920bea6adde242d87e6' }

    context 'when commit id does not match the full sha pattern' do
      let(:value) { sha[0, Gitlab::Git::Commit::SHA1_LENGTH - 1] } # doesn't match Gitlab::Git::Commit::FULL_SHA_PATTERN because length is less than 40

      it 'returns nil' do
        expect(commit.valid_full_sha).to be_empty
      end
    end

    context 'when commit id matches the full sha pattern' do
      let(:value) { sha }

      it 'returns the sha as a string' do
        expect(commit.valid_full_sha).to eq(sha)
      end
    end
  end

  describe '#first_diffs_slice' do
    let_it_be(:sha) { "913c66a37b4a45b9769037c55c2d238bd0942d2e" }
    let_it_be(:commit) { project.commit_by(oid: sha) }
    let_it_be(:limit) { 5 }

    subject(:first_diffs_slice) { commit.first_diffs_slice(limit) }

    it 'returns limited diffs' do
      expect(first_diffs_slice.count).to eq(limit)
    end
  end

  describe '#diffs_for_streaming' do
    it 'returns a diff file collection commit' do
      expect(commit.diffs_for_streaming).to be_a_kind_of(Gitlab::Diff::FileCollection::Commit)
    end

    it_behaves_like 'diffs for streaming' do
      let(:repository) { commit.repository }
      let(:resource) { commit }
    end
  end
end
