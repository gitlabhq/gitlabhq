# frozen_string_literal: true

require 'fileutils'

require 'spec_helper'

RSpec.describe GitGarbageCollectWorker do
  include GitHelpers

  let_it_be(:project) { create(:project, :repository) }
  let(:shell) { Gitlab::Shell.new }
  let!(:lease_uuid) { SecureRandom.uuid }
  let!(:lease_key) { "project_housekeeping:#{project.id}" }
  let(:params) { [project.id, task, lease_key, lease_uuid] }

  subject { described_class.new }

  shared_examples 'it calls Gitaly' do
    specify do
      expect_any_instance_of(Gitlab::GitalyClient::RepositoryService).to receive(gitaly_task)
        .and_return(nil)

      subject.perform(*params)
    end
  end

  shared_examples 'it updates the project statistics' do
    it 'updates the project statistics' do
      expect_next_instance_of(Projects::UpdateStatisticsService, project, nil, statistics: [:repository_size, :lfs_objects_size]) do |service|
        expect(service).to receive(:execute).and_call_original
      end

      subject.perform(*params)
    end

    it 'does nothing if the database is read-only' do
      allow(Gitlab::Database).to receive(:read_only?) { true }

      expect_any_instance_of(Projects::UpdateStatisticsService).not_to receive(:execute)

      subject.perform(*params)
    end
  end

  describe "#perform" do
    let(:gitaly_task) { :garbage_collect }
    let(:task) { :gc }

    context 'with active lease_uuid' do
      before do
        allow(subject).to receive(:get_lease_uuid).and_return(lease_uuid)
      end

      it_behaves_like 'it calls Gitaly'
      it_behaves_like 'it updates the project statistics'

      it "flushes ref caches when the task if 'gc'" do
        expect(subject).to receive(:renew_lease).with(lease_key, lease_uuid).and_call_original
        expect_any_instance_of(Repository).to receive(:expire_branches_cache).and_call_original
        expect_any_instance_of(Repository).to receive(:branch_names).and_call_original
        expect_any_instance_of(Repository).to receive(:has_visible_content?).and_call_original
        expect_any_instance_of(Gitlab::Git::Repository).to receive(:has_visible_content?).and_call_original

        subject.perform(*params)
      end

      it 'handles gRPC errors' do
        expect_any_instance_of(Gitlab::GitalyClient::RepositoryService).to receive(:garbage_collect).and_raise(GRPC::NotFound)

        expect { subject.perform(*params) }.to raise_exception(Gitlab::Git::Repository::NoRepository)
      end
    end

    context 'with different lease than the active one' do
      before do
        allow(subject).to receive(:get_lease_uuid).and_return(SecureRandom.uuid)
      end

      it 'returns silently' do
        expect_any_instance_of(Repository).not_to receive(:expire_branches_cache).and_call_original
        expect_any_instance_of(Repository).not_to receive(:branch_names).and_call_original
        expect_any_instance_of(Repository).not_to receive(:has_visible_content?).and_call_original

        subject.perform(*params)
      end
    end

    context 'with no active lease' do
      let(:params) { [project.id] }

      before do
        allow(subject).to receive(:get_lease_uuid).and_return(false)
      end

      context 'when is able to get the lease' do
        before do
          allow(subject).to receive(:try_obtain_lease).and_return(SecureRandom.uuid)
        end

        it_behaves_like 'it calls Gitaly'
        it_behaves_like 'it updates the project statistics'

        it "flushes ref caches when the task if 'gc'" do
          expect(subject).to receive(:get_lease_uuid).with("git_gc:#{task}:#{project.id}").and_return(false)
          expect_any_instance_of(Repository).to receive(:expire_branches_cache).and_call_original
          expect_any_instance_of(Repository).to receive(:branch_names).and_call_original
          expect_any_instance_of(Repository).to receive(:has_visible_content?).and_call_original
          expect_any_instance_of(Gitlab::Git::Repository).to receive(:has_visible_content?).and_call_original

          subject.perform(*params)
        end

        context 'when the repository has joined a pool' do
          let!(:pool) { create(:pool_repository, :ready) }
          let(:project) { pool.source_project }

          it 'ensures the repositories are linked' do
            expect_any_instance_of(PoolRepository).to receive(:link_repository).once

            subject.perform(*params)
          end
        end

        context 'LFS object garbage collection' do
          before do
            stub_lfs_setting(enabled: true)
          end

          let_it_be(:lfs_reference) { create(:lfs_objects_project, project: project) }
          let(:lfs_object) { lfs_reference.lfs_object }

          it 'cleans up unreferenced LFS objects' do
            expect_next_instance_of(Gitlab::Cleanup::OrphanLfsFileReferences) do |svc|
              expect(svc.project).to eq(project)
              expect(svc.dry_run).to be_falsy
              expect(svc).to receive(:run!).and_call_original
            end

            subject.perform(*params)

            expect(project.lfs_objects.reload).not_to include(lfs_object)
          end

          it 'catches and logs exceptions' do
            expect_any_instance_of(Gitlab::Cleanup::OrphanLfsFileReferences)
              .to receive(:run!)
              .and_raise(/Failed/)

            expect(Gitlab::GitLogger).to receive(:warn)
            expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)

            subject.perform(*params)
          end

          it 'does nothing if the database is read-only' do
            allow(Gitlab::Database).to receive(:read_only?) { true }
            expect_any_instance_of(Gitlab::Cleanup::OrphanLfsFileReferences).not_to receive(:run!)

            subject.perform(*params)

            expect(project.lfs_objects.reload).to include(lfs_object)
          end
        end
      end

      context 'when no lease can be obtained' do
        before do
          expect(subject).to receive(:try_obtain_lease).and_return(false)
        end

        it 'returns silently' do
          expect(subject).not_to receive(:command)
          expect_any_instance_of(Repository).not_to receive(:expire_branches_cache).and_call_original
          expect_any_instance_of(Repository).not_to receive(:branch_names).and_call_original
          expect_any_instance_of(Repository).not_to receive(:has_visible_content?).and_call_original

          subject.perform(*params)
        end
      end
    end

    context "repack_full" do
      let(:task) { :full_repack }
      let(:gitaly_task) { :repack_full }

      before do
        expect(subject).to receive(:get_lease_uuid).and_return(lease_uuid)
      end

      it_behaves_like 'it calls Gitaly'
      it_behaves_like 'it updates the project statistics'
    end

    context "pack_refs" do
      let(:task) { :pack_refs }
      let(:gitaly_task) { :pack_refs }

      before do
        expect(subject).to receive(:get_lease_uuid).and_return(lease_uuid)
      end

      it "calls Gitaly" do
        expect_any_instance_of(Gitlab::GitalyClient::RefService).to receive(task)
          .and_return(nil)

        subject.perform(*params)
      end

      it 'does not update the project statistics' do
        expect(Projects::UpdateStatisticsService).not_to receive(:new)

        subject.perform(*params)
      end
    end

    context "repack_incremental" do
      let(:task) { :incremental_repack }
      let(:gitaly_task) { :repack_incremental }

      before do
        expect(subject).to receive(:get_lease_uuid).and_return(lease_uuid)
      end

      it_behaves_like 'it calls Gitaly'
      it_behaves_like 'it updates the project statistics'
    end

    shared_examples 'gc tasks' do
      before do
        allow(subject).to receive(:get_lease_uuid).and_return(lease_uuid)
        allow(subject).to receive(:bitmaps_enabled?).and_return(bitmaps_enabled)
      end

      it 'incremental repack adds a new packfile' do
        create_objects(project)
        before_packs = packs(project)

        expect(before_packs.count).to be >= 1

        subject.perform(project.id, 'incremental_repack', lease_key, lease_uuid)
        after_packs = packs(project)

        # Exactly one new pack should have been created
        expect(after_packs.count).to eq(before_packs.count + 1)

        # Previously existing packs are still around
        expect(before_packs & after_packs).to eq(before_packs)
      end

      it 'full repack consolidates into 1 packfile' do
        create_objects(project)
        subject.perform(project.id, 'incremental_repack', lease_key, lease_uuid)
        before_packs = packs(project)

        expect(before_packs.count).to be >= 2

        subject.perform(project.id, 'full_repack', lease_key, lease_uuid)
        after_packs = packs(project)

        expect(after_packs.count).to eq(1)

        # Previously existing packs should be gone now
        expect(after_packs - before_packs).to eq(after_packs)

        expect(File.exist?(bitmap_path(after_packs.first))).to eq(bitmaps_enabled)
      end

      it 'gc consolidates into 1 packfile and updates packed-refs' do
        create_objects(project)
        before_packs = packs(project)
        before_packed_refs = packed_refs(project)

        expect(before_packs.count).to be >= 1

        expect_any_instance_of(Gitlab::GitalyClient::RepositoryService)
          .to receive(:garbage_collect)
          .with(bitmaps_enabled, prune: false)
          .and_call_original

        subject.perform(project.id, 'gc', lease_key, lease_uuid)
        after_packed_refs = packed_refs(project)
        after_packs = packs(project)

        expect(after_packs.count).to eq(1)

        # Previously existing packs should be gone now
        expect(after_packs - before_packs).to eq(after_packs)

        # The packed-refs file should have been updated during 'git gc'
        expect(before_packed_refs).not_to eq(after_packed_refs)

        expect(File.exist?(bitmap_path(after_packs.first))).to eq(bitmaps_enabled)
      end

      it 'cleans up repository after finishing' do
        expect_any_instance_of(Project).to receive(:cleanup).and_call_original

        subject.perform(project.id, 'gc', lease_key, lease_uuid)
      end

      it 'prune calls garbage_collect with the option prune: true' do
        expect_any_instance_of(Gitlab::GitalyClient::RepositoryService)
          .to receive(:garbage_collect)
          .with(bitmaps_enabled, prune: true)
          .and_return(nil)

        subject.perform(project.id, 'prune', lease_key, lease_uuid)
      end
    end

    context 'with bitmaps enabled' do
      let(:bitmaps_enabled) { true }

      include_examples 'gc tasks'
    end

    context 'with bitmaps disabled' do
      let(:bitmaps_enabled) { false }

      include_examples 'gc tasks'
    end
  end

  # Create a new commit on a random new branch
  def create_objects(project)
    rugged = rugged_repo(project.repository)
    old_commit = rugged.branches.first.target
    new_commit_sha = Rugged::Commit.create(
      rugged,
      message: "hello world #{SecureRandom.hex(6)}",
      author: { email: 'foo@bar', name: 'baz' },
      committer: { email: 'foo@bar', name: 'baz' },
      tree: old_commit.tree,
      parents: [old_commit]
    )
    rugged.references.create("refs/heads/#{SecureRandom.hex(6)}", new_commit_sha)
  end

  def packs(project)
    Gitlab::GitalyClient::StorageSettings.allow_disk_access do
      Dir["#{project.repository.path_to_repo}/objects/pack/*.pack"]
    end
  end

  def packed_refs(project)
    path = "#{project.repository.path_to_repo}/packed-refs"
    FileUtils.touch(path)
    File.read(path)
  end

  def bitmap_path(pack)
    pack.sub(/\.pack\z/, '.bitmap')
  end
end
