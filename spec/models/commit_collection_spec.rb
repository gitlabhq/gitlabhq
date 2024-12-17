# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CommitCollection, feature_category: :source_code_management do
  let(:project) { create(:project, :repository) }
  let(:commit) { project.commit("c1c67abbaf91f624347bb3ae96eabe3a1b742478") }

  describe '#each' do
    it 'yields every commit' do
      collection = described_class.new(project, [commit])

      expect { |b| collection.each(&b) }.to yield_with_args(commit)
    end
  end

  describe '.committers' do
    subject(:collection) { described_class.new(project, [commit]) }

    it 'returns a relation of users when users are found' do
      user = create(:user, email: commit.committer_email.upcase)

      expect(collection.committers).to contain_exactly(user)
    end

    it 'returns empty array when committers cannot be found' do
      expect(collection.committers).to be_empty
    end

    context 'when is with_merge_commits false' do
      let(:commit) { project.commit("60ecb67744cb56576c30214ff52294f8ce2def98") }

      it 'excludes authors of merge commits' do
        create(:user, email: commit.committer_email.upcase)

        expect(collection.committers).to be_empty
      end
    end

    context 'when is with_merge_commits true' do
      let(:commit) { project.commit("60ecb67744cb56576c30214ff52294f8ce2def98") }

      it 'does not exclude authors of merge commits' do
        user = create(:user, email: commit.committer_email.upcase)

        expect(collection.committers(with_merge_commits: true)).to contain_exactly(user)
      end
    end

    context 'when committer email is nil' do
      before do
        allow(commit).to receive(:committer_email).and_return(nil)
      end

      it 'returns empty array when committers cannot be found' do
        expect(collection.committers).to be_empty
      end
    end

    context 'when a commit is signed by GitLab' do
      let(:author_email) { 'author@gitlab.com' }
      let(:committer_email) { 'committer@gitlab.com' }
      let(:author) { create(:user, email: author_email.upcase) }
      let(:committer) { create(:user, email: committer_email.upcase) }

      before do
        allow(commit).to receive_message_chain(:signature, :verified_system?).and_return(true)
        allow(commit).to receive(:author_email).and_return(author_email)
        allow(commit).to receive(:committer_email).and_return(committer_email)
      end

      it 'users committer email to identify committers' do
        expect(collection.committers).to eq([committer])
      end

      context 'when include_author_when_signed is true' do
        it 'uses author email to identify committers' do
          expect(collection.committers(include_author_when_signed: true)).to eq([author])
        end
      end
    end
  end

  describe '#committer_user_ids' do
    subject(:collection) { described_class.new(project, [commit]) }

    it 'returns an array of committer user IDs' do
      user = create(:user, email: commit.committer_email)

      expect(collection.committer_user_ids).to contain_exactly(user.id)
    end

    context 'when there are no committers' do
      subject(:collection) { described_class.new(project, []) }

      it 'returns an empty array' do
        expect(collection.committer_user_ids).to be_empty
      end
    end
  end

  describe '#without_merge_commits' do
    it 'returns all commits except merge commits' do
      merge_commit = project.commit("60ecb67744cb56576c30214ff52294f8ce2def98")
      expect(merge_commit).to receive(:merge_commit?).and_return(true)

      collection = described_class.new(project, [commit, merge_commit])

      expect(collection.without_merge_commits).to contain_exactly(commit)
    end
  end

  describe '#with_latest_pipeline' do
    let(:another_commit) { project.commit("60ecb67744cb56576c30214ff52294f8ce2def98") }

    let!(:pipeline) do
      create(:ci_empty_pipeline, ref: 'master', sha: commit.id, status: 'success', project: project)
    end

    let!(:another_pipeline) do
      create(:ci_empty_pipeline, ref: 'master', sha: another_commit.id, status: 'success', project: project)
    end

    let(:collection) { described_class.new(project, [commit, another_commit]) }

    it 'sets the latest pipeline for every commit so no additional queries are necessary' do
      commits = collection.with_latest_pipeline('master')

      recorder = ActiveRecord::QueryRecorder.new do
        expect(commits.map { |c| c.latest_pipeline('master') })
          .to eq([pipeline, another_pipeline])
      end

      expect(recorder.count).to be_zero
    end

    it 'performs a single query to fetch pipeline warnings' do
      recorder = ActiveRecord::QueryRecorder.new do
        collection.with_latest_pipeline('master').each do |c|
          c.latest_pipeline('master').number_of_warnings.itself
        end
      end

      expect(recorder.count).to eq(2) # 1 for pipelines, 1 for warnings counts
    end
  end

  describe '#with_markdown_cache' do
    let(:commits) { [commit] }
    let(:collection) { described_class.new(project, commits) }

    it 'preloads commits cache markdown' do
      aggregate_failures do
        expect(Commit).to receive(:preload_markdown_cache!).with(commits)
        expect(collection.with_markdown_cache).to eq(collection)
      end
    end
  end

  describe 'enrichment methods' do
    let(:gitaly_commit) { commit }
    let(:hash_commit) { Commit.from_hash(gitaly_commit.to_hash, project) }

    describe '#unenriched' do
      it 'returns all commits that are not backed by gitaly data' do
        collection = described_class.new(project, [gitaly_commit, hash_commit])

        expect(collection.unenriched).to contain_exactly(hash_commit)
      end
    end

    describe '#fully_enriched?' do
      it 'returns true when all commits are backed by gitaly data' do
        collection = described_class.new(project, [gitaly_commit, gitaly_commit])

        expect(collection.fully_enriched?).to eq(true)
      end

      it 'returns false when any commits are not backed by gitaly data' do
        collection = described_class.new(project, [gitaly_commit, hash_commit])

        expect(collection.fully_enriched?).to eq(false)
      end

      it 'returns true when the collection is empty' do
        collection = described_class.new(project, [])

        expect(collection.fully_enriched?).to eq(true)
      end
    end

    describe '#enrich!' do
      it 'replaces commits in the collection with those backed by gitaly data' do
        collection = described_class.new(project, [hash_commit])

        collection.enrich!

        new_commit = collection.commits.first
        expect(new_commit.id).to eq(hash_commit.id)
        expect(hash_commit.gitaly_commit?).to eq(false)
        expect(new_commit.gitaly_commit?).to eq(true)
      end

      it 'maintains the original order of the commits' do
        gitaly_commits = [gitaly_commit] * 3
        hash_commits = [hash_commit] * 3
        # Interleave the gitaly and hash commits together
        original_commits = gitaly_commits.zip(hash_commits).flatten
        collection = described_class.new(project, original_commits)

        collection.enrich!

        original_commits.each_with_index do |original_commit, i|
          new_commit = collection.commits[i]
          expect(original_commit.id).to eq(new_commit.id)
        end
      end

      it 'fetches data if there are unenriched commits' do
        collection = described_class.new(project, [hash_commit])

        expect(Commit).to receive(:lazy).exactly(:once)

        collection.enrich!
      end

      it 'does not fetch data if all commits are enriched' do
        collection = described_class.new(project, [gitaly_commit])

        expect(Commit).not_to receive(:lazy)

        collection.enrich!
      end

      it 'returns the original commit if the commit could not be lazy loaded' do
        collection = described_class.new(project, [hash_commit])
        unexisting_lazy_commit = Commit.lazy(project, Gitlab::Git::SHA1_BLANK_SHA)

        expect(Commit).to receive(:lazy).with(project, hash_commit.id).and_return(unexisting_lazy_commit)

        collection.enrich!

        expect(collection.commits).to contain_exactly(hash_commit)
      end
    end
  end

  describe '#load_tags' do
    let(:gitaly_commit_with_tags) { project.commit('5937ac0a7beb003549fc5fd26fc247adbce4a52e') }
    let(:collection) { described_class.new(project, [gitaly_commit_with_tags]) }

    subject { collection.load_tags }

    it 'loads tags' do
      subject

      expect(collection.commits[0].referenced_by).to contain_exactly('refs/tags/v1.1.0')
    end
  end

  describe '#respond_to_missing?' do
    it 'returns true when the underlying Array responds to the message' do
      collection = described_class.new(project, [])

      expect(collection.respond_to?(:last)).to eq(true)
    end

    it 'returns false when the underlying Array does not respond to the message' do
      collection = described_class.new(project, [])

      expect(collection.respond_to?(:foo)).to eq(false)
    end
  end

  describe '#method_missing' do
    it 'delegates undefined methods to the underlying Array' do
      collection = described_class.new(project, [commit])

      expect(collection.length).to eq(1)
      expect(collection.last).to eq(commit)
      expect(collection).not_to be_empty
    end
  end
end
