# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::CleanupService, feature_category: :source_code_management do
  subject(:service) { described_class.new(project) }

  describe '.enqueue' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user) { create(:user) }

    let(:object_map_file) { fixture_file_upload('spec/fixtures/bfg_object_map.txt') }

    subject(:enqueue) { described_class.enqueue(project, user, object_map_file) }

    it 'makes the repository read-only' do
      expect { enqueue }
        .to change(project, :repository_read_only?)
        .from(false)
        .to(true)
    end

    it 'sets the bfg_object_map of the project' do
      enqueue

      expect(project.bfg_object_map.read).to eq(object_map_file.read)
    end

    it 'enqueues a RepositoryCleanupWorker' do
      enqueue

      expect(RepositoryCleanupWorker.jobs.count).to eq(1)
    end

    it 'returns success' do
      expect(enqueue[:status]).to eq(:success)
    end

    it 'returns an error if making the repository read-only fails' do
      project.set_repository_read_only!

      expect(enqueue[:status]).to eq(:error)
    end

    it 'returns an error if updating the project fails' do
      expect_next_instance_of(Projects::UpdateService) do |service|
        expect(service).to receive(:execute).and_return(status: :error)
      end

      expect(enqueue[:status]).to eq(:error)
      expect(project.reload.repository_read_only?).to be_falsy
    end
  end

  describe '.cleanup_after' do
    let(:project) { create(:project, :repository, bfg_object_map: fixture_file_upload('spec/fixtures/bfg_object_map.txt')) }

    subject(:cleanup_after) { described_class.cleanup_after(project) }

    before do
      project.set_repository_read_only!
    end

    it 'sets the repository read-write' do
      expect { cleanup_after }.to change(project, :repository_read_only?).from(true).to(false)
    end

    it 'removes the BFG object map' do
      cleanup_after

      expect(project.bfg_object_map).not_to be_exist
    end
  end

  describe '#execute' do
    let(:project) { create(:project, :repository, bfg_object_map: fixture_file_upload('spec/fixtures/bfg_object_map.txt')) }
    let(:object_map) { project.bfg_object_map }
    let(:cleaner) { service.__send__(:repository_cleaner) }

    before do
      project.set_repository_read_only!
    end

    it 'runs the apply_bfg_object_map_stream gitaly RPC' do
      expect(cleaner).to receive(:apply_bfg_object_map_stream).with(kind_of(IO))

      service.execute
    end

    it 'runs garbage collection on the repository' do
      expect_next_instance_of(Projects::GitGarbageCollectWorker) do |worker|
        expect(worker).to receive(:perform).with(project.id, :prune, "project_cleanup:gc:#{project.id}")
      end

      service.execute
    end

    it 'clears the repository cache' do
      expect(project.repository).to receive(:expire_all_method_caches)

      service.execute
    end

    it 'removes the object map file' do
      service.execute

      expect(object_map.exists?).to be_falsy
    end

    it 'makes the repository read-write again' do
      expect { service.execute }
        .to change(project, :repository_read_only?)
        .from(true)
        .to(false)
    end

    context 'with a tainted merge request diff' do
      let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
      let(:diff) { merge_request.merge_request_diff }
      let(:entry) { build_entry(diff.commits.first.id) }

      before do
        allow(cleaner)
          .to receive(:apply_bfg_object_map_stream)
          .and_yield(Gitaly::ApplyBfgObjectMapStreamResponse.new(entries: [entry]))
      end

      it 'removes the tainted commit from the database' do
        service.execute

        expect(MergeRequestDiff.exists?(diff.id)).to be_falsy
      end

      it 'ignores non-commit responses from Gitaly' do
        entry.type = :UNKNOWN

        service.execute

        expect(MergeRequestDiff.exists?(diff.id)).to be_truthy
      end
    end

    context 'with a tainted diff note' do
      let(:diff_note) { create(:diff_note_on_commit, project: project) }
      let(:note_diff_file) { diff_note.note_diff_file }
      let(:entry) { build_entry(diff_note.commit_id) }

      let(:highlight_cache) { Gitlab::DiscussionsDiff::HighlightCache }
      let(:cache_id) { note_diff_file.id }

      before do
        allow(cleaner)
          .to receive(:apply_bfg_object_map_stream)
          .and_yield(Gitaly::ApplyBfgObjectMapStreamResponse.new(entries: [entry]))
      end

      it 'removes the tainted commit from the database' do
        service.execute

        expect(NoteDiffFile.exists?(note_diff_file.id)).to be_falsy
      end

      it 'removes the highlight cache from redis' do
        write_cache(highlight_cache, cache_id, [{}])

        expect(read_cache(highlight_cache, cache_id)).not_to be_nil

        service.execute

        expect(read_cache(highlight_cache, cache_id)).to be_nil
      end

      it 'ignores non-commit responses from Gitaly' do
        entry.type = :UNKNOWN

        service.execute

        expect(NoteDiffFile.exists?(note_diff_file.id)).to be_truthy
      end
    end

    it 'raises an error if no object map can be found' do
      object_map.remove!

      expect { service.execute }.to raise_error(described_class::NoUploadError)
    end
  end

  def build_entry(old_oid)
    Gitaly::ApplyBfgObjectMapStreamResponse::Entry.new(
      type: :COMMIT,
      old_oid: old_oid,
      new_oid: Gitlab::Git::SHA1_BLANK_SHA
    )
  end

  def read_cache(cache, key)
    cache.read_multiple([key]).first
  end

  def write_cache(cache, key, value)
    cache.write_multiple(key => value)
  end
end
