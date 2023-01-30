# frozen_string_literal: true

RSpec.shared_examples 'can collect git garbage' do |update_statistics: true|
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
    let(:repository_service) { instance_double(Gitlab::GitalyClient::RepositoryService) }

    specify do
      expect_next_instance_of(Gitlab::GitalyClient::RepositoryService, repository.raw_repository) do |instance|
        expect(instance).to receive(:optimize_repository).and_call_original
      end

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
      allow(Gitlab::Database).to receive(:read_only?) { true }

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
        repository_service = instance_double(Gitlab::GitalyClient::RepositoryService)

        allow_next_instance_of(Projects::GitDeduplicationService) do |instance|
          allow(instance).to receive(:execute)
        end

        allow(repository.raw_repository).to receive(:gitaly_repository_client).and_return(repository_service)
        allow(repository_service).to receive(:optimize_repository).and_raise(GRPC::NotFound)

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

    context 'prune' do
      before do
        expect(subject).to receive(:get_lease_uuid).and_return(lease_uuid)
      end

      specify do
        expect_next_instance_of(Gitlab::GitalyClient::RepositoryService, repository.raw_repository) do |instance|
          expect(instance).to receive(:prune_unreachable_objects).and_call_original
        end

        subject.perform(resource.id, 'prune', lease_key, lease_uuid)
      end
    end

    context 'eager' do
      before do
        expect(subject).to receive(:get_lease_uuid).and_return(lease_uuid)
      end

      specify do
        expect_next_instance_of(Gitlab::GitalyClient::RepositoryService, repository.raw_repository) do |instance|
          expect(instance).to receive(:optimize_repository).with(eager: true).and_call_original
        end

        subject.perform(resource.id, 'eager', lease_key, lease_uuid)
      end
    end
  end
end
