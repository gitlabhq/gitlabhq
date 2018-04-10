require 'fileutils'

require 'spec_helper'

describe GitGarbageCollectWorker do
  let(:project) { create(:project, :repository) }
  let(:shell) { Gitlab::Shell.new }
  let!(:lease_uuid) { SecureRandom.uuid }
  let!(:lease_key) { "project_housekeeping:#{project.id}" }

  subject { described_class.new }

  describe "#perform" do
    shared_examples 'flushing ref caches' do |gitaly|
      context 'with active lease_uuid' do
        before do
          allow(subject).to receive(:get_lease_uuid).and_return(lease_uuid)
        end

        it "flushes ref caches when the task if 'gc'" do
          expect(subject).to receive(:renew_lease).with(lease_key, lease_uuid).and_call_original
          expect(subject).to receive(:command).with(:gc).and_return([:the, :command])

          if gitaly
            expect_any_instance_of(Gitlab::GitalyClient::RepositoryService).to receive(:garbage_collect)
              .and_return(nil)
          else
            expect(Gitlab::Popen).to receive(:popen)
              .with([:the, :command], project.repository.path_to_repo).and_return(["", 0])
          end

          expect_any_instance_of(Repository).to receive(:after_create_branch).and_call_original
          expect_any_instance_of(Repository).to receive(:branch_names).and_call_original
          expect_any_instance_of(Repository).to receive(:has_visible_content?).and_call_original
          expect_any_instance_of(Gitlab::Git::Repository).to receive(:has_visible_content?).and_call_original

          subject.perform(project.id, :gc, lease_key, lease_uuid)
        end
      end

      context 'with different lease than the active one' do
        before do
          allow(subject).to receive(:get_lease_uuid).and_return(SecureRandom.uuid)
        end

        it 'returns silently' do
          expect(subject).not_to receive(:command)
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
            expect(subject).to receive(:command).with(:gc).and_return([:the, :command])

            if gitaly
              expect_any_instance_of(Gitlab::GitalyClient::RepositoryService).to receive(:garbage_collect)
                .and_return(nil)
            else
              expect(Gitlab::Popen).to receive(:popen)
                .with([:the, :command], project.repository.path_to_repo).and_return(["", 0])
            end

            expect_any_instance_of(Repository).to receive(:after_create_branch).and_call_original
            expect_any_instance_of(Repository).to receive(:branch_names).and_call_original
            expect_any_instance_of(Repository).to receive(:has_visible_content?).and_call_original
            expect_any_instance_of(Gitlab::Git::Repository).to receive(:has_visible_content?).and_call_original

            subject.perform(project.id)
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
    end

    context "with Gitaly turned on" do
      it_should_behave_like 'flushing ref caches', true
    end

    context "with Gitaly turned off", :skip_gitaly_mock do
      it_should_behave_like 'flushing ref caches', false
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
    rugged = project.repository.rugged
    old_commit = rugged.branches.first.target
    new_commit_sha = Rugged::Commit.create(
      rugged,
      message: "hello world #{SecureRandom.hex(6)}",
      author: Gitlab::Git.committer_hash(email: 'foo@bar', name: 'baz'),
      committer: Gitlab::Git.committer_hash(email: 'foo@bar', name: 'baz'),
      tree: old_commit.tree,
      parents: [old_commit]
    )
    Gitlab::Git::OperationService.new(nil, project.repository.raw_repository).send(
      :update_ref,
      "refs/heads/#{SecureRandom.hex(6)}",
      new_commit_sha,
      Gitlab::Git::BLANK_SHA
    )
  end

  def packs(project)
    Dir["#{project.repository.path_to_repo}/objects/pack/*.pack"]
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
