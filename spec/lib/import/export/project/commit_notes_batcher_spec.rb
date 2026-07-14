# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Export::Project::CommitNotesBatcher, feature_category: :importers do
  let_it_be(:project) { create(:project, :repository) }

  subject(:batcher) { described_class.new(project) }

  describe '#each_batch' do
    context 'when no block is given' do
      it 'returns an enumerator' do
        expect(batcher.each_batch).to be_a(Enumerator)
      end
    end

    context 'when the repository does not exist' do
      let_it_be(:project) { create(:project) }

      it 'yields nothing' do
        expect { |b| batcher.each_batch(&b) }.not_to yield_control
      end
    end

    context 'when the repository has commits' do
      it 'yields batches of commit SHAs' do
        yielded = []
        batcher.each_batch { |shas| yielded << shas }

        flat = yielded.flatten
        expect(flat).not_to be_empty
        expect(flat).to all(match(/\A[0-9a-f]{40}\z/))
      end

      it 'yields the same SHAs git rev-list --all would' do
        yielded = []
        batcher.each_batch { |shas| yielded.concat(shas) }

        gitaly_shas = project.repository.raw_repository
          .gitaly_commit_client
          .list_commits(['--all'], pagination_params: { limit: 1000 })
          .map(&:id)

        expect(yielded).to match_array(gitaly_shas)
      end

      context 'with a custom batch_size' do
        subject(:batcher) { described_class.new(project, batch_size: 2) }

        it 'yields batches of at most batch_size SHAs' do
          batcher.each_batch do |shas|
            expect(shas.size).to be <= 2
          end
        end

        it 'paginates through Gitaly using the provided batch_size as the page limit' do
          expect(project.repository.raw_repository.gitaly_commit_client)
            .to receive(:list_commits)
            .at_least(:once)
            .with(['--all'], hash_including(pagination_params: hash_including(limit: 2)))
            .and_call_original

          batcher.each_batch { |_shas| next }
        end
      end
    end

    context 'when Gitaly raises a transient error during pagination' do
      let(:raw_repository) { project.repository.raw_repository }
      let(:gitaly_client) { raw_repository.gitaly_commit_client }

      before do
        allow(project.repository).to receive(:raw_repository).and_return(raw_repository)
        allow(raw_repository).to receive(:gitaly_commit_client).and_return(gitaly_client)
      end

      it 'retries the page fetch and completes the walk' do
        call_count = 0
        allow(gitaly_client).to receive(:list_commits).and_wrap_original do |original, *args|
          call_count += 1
          raise GRPC::Unavailable if call_count == 1

          original.call(*args)
        end

        yielded = []
        batcher.each_batch { |shas| yielded.concat(shas) }

        expect(call_count).to be > 1
        expect(yielded).not_to be_empty
        expect(yielded).to all(match(/\A[0-9a-f]{40}\z/))
      end

      it 'gives up and re-raises after exhausting retries' do
        allow(gitaly_client).to receive(:list_commits).and_raise(GRPC::Unavailable)

        expect { batcher.each_batch { |_shas| next } }.to raise_error(GRPC::Unavailable)
      end
    end
  end

  describe '#each_commit_note_id_batch' do
    let_it_be(:commit_sha) { project.repository.commit.id }

    it 'returns an enumerator when no block is given' do
      expect(batcher.each_commit_note_id_batch).to be_a(Enumerator)
    end

    it "yields this project's commit note ids" do
      note = create(:note_on_commit, project: project, commit_id: commit_sha)

      yielded = []
      batcher.each_commit_note_id_batch { |ids| yielded.concat(ids) }

      expect(yielded).to contain_exactly(note.id)
    end

    it 'excludes notes on the same SHA that belong to another project' do
      own_note = create(:note_on_commit, project: project, commit_id: commit_sha)
      other_project = create(:project, :repository)
      create(:note_on_commit, project: other_project, commit_id: commit_sha)

      yielded = []
      batcher.each_commit_note_id_batch { |ids| yielded.concat(ids) }

      expect(yielded).to contain_exactly(own_note.id)
    end

    it 'accumulates ids into full batches of at most batch_size, with no empty batches' do
      create_list(:note_on_commit, 5, project: project, commit_id: commit_sha)

      sized_batcher = described_class.new(project, batch_size: 2)
      allow(sized_batcher).to receive(:each_batch).and_yield([commit_sha])

      sizes = []
      sized_batcher.each_commit_note_id_batch { |ids| sizes << ids.size }

      expect(sizes.sum).to eq(5)
      expect(sizes).to all(be <= 2)
      expect(sizes).not_to include(0)
    end
  end

  describe 'DEFAULT_BATCH_SIZE' do
    it 'is 500' do
      expect(described_class::DEFAULT_BATCH_SIZE).to eq(500)
    end
  end
end
