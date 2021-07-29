# frozen_string_literal: true

require 'fileutils'

RSpec.shared_examples 'can collect git garbage' do |update_statistics: true|
  include GitHelpers

  let!(:lease_uuid) { SecureRandom.uuid }
  let!(:lease_key) { "resource_housekeeping:#{resource.id}" }
  let(:params) { [resource.id, task, lease_key, lease_uuid] }
  let(:shell) { Gitlab::Shell.new }
  let(:repository) { resource.repository }
  let(:statistics_service_klass) { nil }

  subject { described_class.new }

  before do
    allow(subject).to receive(:find_resource).and_return(resource)
  end

  shared_examples 'it calls Gitaly' do
    specify do
      repository_service = instance_double(Gitlab::GitalyClient::RepositoryService)

      expect(subject).to receive(:get_gitaly_client).with(task, repository.raw_repository).and_return(repository_service)
      expect(repository_service).to receive(gitaly_task)

      subject.perform(*params)
    end
  end

  shared_examples 'it updates the resource statistics' do
    it 'updates the resource statistics' do
      expect_next_instance_of(statistics_service_klass, anything, nil, statistics: statistics_keys) do |service|
        expect(service).to receive(:execute)
      end

      subject.perform(*params)
    end

    it 'does nothing if the database is read-only' do
      allow(Gitlab::Database.main).to receive(:read_only?) { true }

      expect(statistics_service_klass).not_to receive(:new)

      subject.perform(*params)
    end
  end

  describe '#perform', :aggregate_failures do
    let(:gitaly_task) { :garbage_collect }
    let(:task) { :gc }

    context 'with active lease_uuid' do
      before do
        allow(subject).to receive(:get_lease_uuid).and_return(lease_uuid)
      end

      it_behaves_like 'it calls Gitaly'
      it_behaves_like 'it updates the resource statistics' if update_statistics

      it "flushes ref caches when the task if 'gc'" do
        expect(subject).to receive(:renew_lease).with(lease_key, lease_uuid).and_call_original
        expect(repository).to receive(:expire_branches_cache).and_call_original
        expect(repository).to receive(:branch_names).and_call_original
        expect(repository).to receive(:has_visible_content?).and_call_original
        expect(repository.raw_repository).to receive(:has_visible_content?).and_call_original

        subject.perform(*params)
      end

      it 'handles gRPC errors' do
        allow_next_instance_of(Gitlab::GitalyClient::RepositoryService, repository.raw_repository) do |instance|
          allow(instance).to receive(:garbage_collect).and_raise(GRPC::NotFound)
        end

        expect { subject.perform(*params) }.to raise_exception(Gitlab::Git::Repository::NoRepository)
      end
    end

    context 'with different lease than the active one' do
      before do
        allow(subject).to receive(:get_lease_uuid).and_return(SecureRandom.uuid)
      end

      it 'returns silently' do
        expect(repository).not_to receive(:expire_branches_cache).and_call_original
        expect(repository).not_to receive(:branch_names).and_call_original
        expect(repository).not_to receive(:has_visible_content?).and_call_original

        subject.perform(*params)
      end
    end

    context 'with no active lease' do
      let(:params) { [resource.id] }

      before do
        allow(subject).to receive(:get_lease_uuid).and_return(false)
      end

      context 'when is able to get the lease' do
        before do
          allow(subject).to receive(:try_obtain_lease).and_return(SecureRandom.uuid)
        end

        it_behaves_like 'it calls Gitaly'
        it_behaves_like 'it updates the resource statistics' if update_statistics

        it "flushes ref caches when the task if 'gc'" do
          expect(subject).to receive(:get_lease_uuid).with("git_gc:#{task}:#{expected_default_lease}").and_return(false)
          expect(repository).to receive(:expire_branches_cache).and_call_original
          expect(repository).to receive(:branch_names).and_call_original
          expect(repository).to receive(:has_visible_content?).and_call_original
          expect(repository.raw_repository).to receive(:has_visible_content?).and_call_original

          subject.perform(*params)
        end
      end

      context 'when no lease can be obtained' do
        it 'returns silently' do
          expect(subject).to receive(:try_obtain_lease).and_return(false)

          expect(subject).not_to receive(:command)
          expect(repository).not_to receive(:expire_branches_cache).and_call_original
          expect(repository).not_to receive(:branch_names).and_call_original
          expect(repository).not_to receive(:has_visible_content?).and_call_original

          subject.perform(*params)
        end
      end
    end

    context 'repack_full' do
      let(:task) { :full_repack }
      let(:gitaly_task) { :repack_full }

      before do
        expect(subject).to receive(:get_lease_uuid).and_return(lease_uuid)
      end

      it_behaves_like 'it calls Gitaly'
      it_behaves_like 'it updates the resource statistics' if update_statistics
    end

    context 'pack_refs' do
      let(:task) { :pack_refs }
      let(:gitaly_task) { :pack_refs }

      before do
        expect(subject).to receive(:get_lease_uuid).and_return(lease_uuid)
      end

      it 'calls Gitaly' do
        repository_service = instance_double(Gitlab::GitalyClient::RefService)

        expect(subject).to receive(:get_gitaly_client).with(task, repository.raw_repository).and_return(repository_service)
        expect(repository_service).to receive(gitaly_task)

        subject.perform(*params)
      end

      it 'does not update the resource statistics' do
        expect(statistics_service_klass).not_to receive(:new)

        subject.perform(*params)
      end
    end

    context 'repack_incremental' do
      let(:task) { :incremental_repack }
      let(:gitaly_task) { :repack_incremental }

      before do
        expect(subject).to receive(:get_lease_uuid).and_return(lease_uuid)
      end

      it_behaves_like 'it calls Gitaly'
      it_behaves_like 'it updates the resource statistics' if update_statistics
    end

    shared_examples 'gc tasks' do
      before do
        allow(subject).to receive(:get_lease_uuid).and_return(lease_uuid)
        allow(subject).to receive(:bitmaps_enabled?).and_return(bitmaps_enabled)
      end

      it 'incremental repack adds a new packfile' do
        create_objects(resource)
        before_packs = packs(resource)

        expect(before_packs.count).to be >= 1

        subject.perform(resource.id, 'incremental_repack', lease_key, lease_uuid)
        after_packs = packs(resource)

        # Exactly one new pack should have been created
        expect(after_packs.count).to eq(before_packs.count + 1)

        # Previously existing packs are still around
        expect(before_packs & after_packs).to eq(before_packs)
      end

      it 'full repack consolidates into 1 packfile' do
        create_objects(resource)
        subject.perform(resource.id, 'incremental_repack', lease_key, lease_uuid)
        before_packs = packs(resource)

        expect(before_packs.count).to be >= 2

        subject.perform(resource.id, 'full_repack', lease_key, lease_uuid)
        after_packs = packs(resource)

        expect(after_packs.count).to eq(1)

        # Previously existing packs should be gone now
        expect(after_packs - before_packs).to eq(after_packs)

        expect(File.exist?(bitmap_path(after_packs.first))).to eq(bitmaps_enabled)
      end

      it 'gc consolidates into 1 packfile and updates packed-refs' do
        create_objects(resource)
        before_packs = packs(resource)
        before_packed_refs = packed_refs(resource)

        expect(before_packs.count).to be >= 1

        # It's quite difficult to use `expect_next_instance_of` in this place
        # because the RepositoryService is instantiated several times to do
        # some repository calls like `exists?`, `create_repository`, ... .
        # Therefore, since we're instantiating the object several times,
        # RSpec has troubles figuring out which instance is the next and which
        # one we want to mock.
        # Besides, at this point, we actually want to perform the call to Gitaly,
        # otherwise we would just use `instance_double` like in other parts of the
        # spec file.
        expect_any_instance_of(Gitlab::GitalyClient::RepositoryService) # rubocop:disable RSpec/AnyInstanceOf
          .to receive(:garbage_collect)
          .with(bitmaps_enabled, prune: false)
          .and_call_original

        subject.perform(resource.id, 'gc', lease_key, lease_uuid)
        after_packed_refs = packed_refs(resource)
        after_packs = packs(resource)

        expect(after_packs.count).to eq(1)

        # Previously existing packs should be gone now
        expect(after_packs - before_packs).to eq(after_packs)

        # The packed-refs file should have been updated during 'git gc'
        expect(before_packed_refs).not_to eq(after_packed_refs)

        expect(File.exist?(bitmap_path(after_packs.first))).to eq(bitmaps_enabled)
      end

      it 'cleans up repository after finishing' do
        expect(resource).to receive(:cleanup).and_call_original

        subject.perform(resource.id, 'gc', lease_key, lease_uuid)
      end

      it 'prune calls garbage_collect with the option prune: true' do
        repository_service = instance_double(Gitlab::GitalyClient::RepositoryService)

        expect(subject).to receive(:get_gitaly_client).with(:prune, repository.raw_repository).and_return(repository_service)
        expect(repository_service).to receive(:garbage_collect).with(bitmaps_enabled, prune: true)

        subject.perform(resource.id, 'prune', lease_key, lease_uuid)
      end

      # Create a new commit on a random new branch
      def create_objects(resource)
        rugged = rugged_repo(resource.repository)
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

      def packs(resource)
        Dir["#{path_to_repo}/objects/pack/*.pack"]
      end

      def packed_refs(resource)
        path = File.join(path_to_repo, 'packed-refs')
        FileUtils.touch(path)
        File.read(path)
      end

      def path_to_repo
        @path_to_repo ||= File.join(TestEnv.repos_path, resource.repository.relative_path)
      end

      def bitmap_path(pack)
        pack.sub(/\.pack\z/, '.bitmap')
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
end
