# frozen_string_literal: true

require 'fileutils'

require 'spec_helper'

describe GitGarbageCollectWorker do
  include GitHelpers

  let(:project) { create(:project, :repository) }
  let(:shell) { Gitlab::Shell.new }
  let!(:lease_uuid) { SecureRandom.uuid }
  let!(:lease_key) { "project_housekeeping:#{project.id}" }

  subject { described_class.new }

  describe "#perform" do
    context 'with active lease_uuid' do
      before do
        allow(subject).to receive(:get_lease_uuid).and_return(lease_uuid)
      end

      it "flushes ref caches when the task if 'gc'" do
        expect(subject).to receive(:renew_lease).with(lease_key, lease_uuid).and_call_original
        expect_any_instance_of(Gitlab::GitalyClient::RepositoryService).to receive(:garbage_collect)
          .and_return(nil)
        expect_any_instance_of(Repository).to receive(:after_create_branch).and_call_original
        expect_any_instance_of(Repository).to receive(:branch_names).and_call_original
        expect_any_instance_of(Repository).to receive(:has_visible_content?).and_call_original
        expect_any_instance_of(Gitlab::Git::Repository).to receive(:has_visible_content?).and_call_original

        subject.perform(project.id, :gc, lease_key, lease_uuid)
      end

      it 'handles gRPC errors' do
        expect_any_instance_of(Gitlab::GitalyClient::RepositoryService).to receive(:garbage_collect).and_raise(GRPC::NotFound)

        expect { subject.perform(project.id, :gc, lease_key, lease_uuid) }.to raise_exception(Gitlab::Git::Repository::NoRepository)
      end
    end

    context 'with different lease than the active one' do
      before do
        allow(subject).to receive(:get_lease_uuid).and_return(SecureRandom.uuid)
      end

      it 'returns silently' do
        expect_any_instance_of(Repository).not_to receive(:after_create_branch).and_call_original
        expect_any_instance_of(Repository).not_to receive(:branch_names).and_call_original
        expect_any_instance_of(Repository).not_to receive(:has_visible_content?).and_call_original

        subject.perform(project.id, :gc, lease_key, lease_uuid)
      end
    end

    context 'with no active lease' do
      before do
        allow(subject).to receive(:get_lease_uuid).and_return(false)
      end

      context 'when is able to get the lease' do
        before do
          allow(subject).to receive(:try_obtain_lease).and_return(SecureRandom.uuid)
        end

        it "flushes ref caches when the task if 'gc'" do
          expect_any_instance_of(Gitlab::GitalyClient::RepositoryService).to receive(:garbage_collect)
            .and_return(nil)
          expect_any_instance_of(Repository).to receive(:after_create_branch).and_call_original
          expect_any_instance_of(Repository).to receive(:branch_names).and_call_original
          expect_any_instance_of(Repository).to receive(:has_visible_content?).and_call_original
          expect_any_instance_of(Gitlab::Git::Repository).to receive(:has_visible_content?).and_call_original

          subject.perform(project.id)
        end

        context 'when the repository has joined a pool' do
          let!(:pool) { create(:pool_repository, :ready) }
          let(:project) { pool.source_project }

          it 'ensures the repositories are linked' do
            expect_any_instance_of(PoolRepository).to receive(:link_repository).once

            subject.perform(project.id)
          end
        end
      end

      context 'when no lease can be obtained' do
        before do
          expect(subject).to receive(:try_obtain_lease).and_return(false)
        end

        it 'returns silently' do
          expect(subject).not_to receive(:command)
          expect_any_instance_of(Repository).not_to receive(:after_create_branch).and_call_original
          expect_any_instance_of(Repository).not_to receive(:branch_names).and_call_original
          expect_any_instance_of(Repository).not_to receive(:has_visible_content?).and_call_original

          subject.perform(project.id)
        end
      end
    end

    context "repack_full" do
      before do
        expect(subject).to receive(:get_lease_uuid).and_return(lease_uuid)
      end

      it "calls Gitaly" do
        expect_any_instance_of(Gitlab::GitalyClient::RepositoryService).to receive(:repack_full)
          .and_return(nil)

        subject.perform(project.id, :full_repack, lease_key, lease_uuid)
      end
    end

    context "pack_refs" do
      before do
        expect(subject).to receive(:get_lease_uuid).and_return(lease_uuid)
      end

      it "calls Gitaly" do
        expect_any_instance_of(Gitlab::GitalyClient::RefService).to receive(:pack_refs)
          .and_return(nil)

        subject.perform(project.id, :pack_refs, lease_key, lease_uuid)
      end
    end

    context "repack_incremental" do
      before do
        expect(subject).to receive(:get_lease_uuid).and_return(lease_uuid)
      end

      it "calls Gitaly" do
        expect_any_instance_of(Gitlab::GitalyClient::RepositoryService).to receive(:repack_incremental)
          .and_return(nil)

        subject.perform(project.id, :incremental_repack, lease_key, lease_uuid)
      end
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
