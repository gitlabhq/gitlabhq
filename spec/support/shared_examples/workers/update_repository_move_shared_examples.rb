# frozen_string_literal: true

RSpec.shared_examples 'an update storage move worker' do
  let(:worker) { described_class.new }

  it 'has the `until_executed` deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
  end

  describe '#perform(repository_storage_move_id)', :clean_gitlab_redis_shared_state do
    let(:service) { double(:update_repository_storage_service) }

    subject { worker.perform(repository_storage_move.id) }

    before do
      allow(Gitlab.config.repositories.storages).to receive(:keys).and_return(%w[default test_second_storage])
      allow(service_klass).to receive(:new).and_return(service)
    end

    it 'calls the update repository storage service' do
      expect(service).to receive(:execute)

      expect do
        subject
      end.not_to change { repository_storage_move_klass.count }
    end

    context 'when repository storage move raises an exception' do
      let(:exception) { RuntimeError.new('boom') }

      it 'releases the exclusive lock' do
        expect(service).to receive(:execute).and_raise(exception)

        allow_next_instance_of(Gitlab::ExclusiveLease) do |lease|
          expect(lease).to receive(:cancel)
        end

        expect { subject }.to raise_error(exception)
      end
    end

    context 'when exclusive lease already set' do
      let(:lease_key) { [described_class.name.underscore, repository_storage_move.container_id].join(':') }
      let(:exclusive_lease) { Gitlab::ExclusiveLease.new(lease_key, uuid: uuid, timeout: 1.minute) }
      let(:uuid) { 'other_worker_jid' }

      it 'does not call the update repository storage service' do
        expect(exclusive_lease.try_obtain).to eq(uuid)
        expect(service).not_to receive(:execute)

        subject

        expect(repository_storage_move.reload).to be_failed
      end

      context 'when exclusive lease was taken by the current worker' do
        let(:uuid) { 'existing_worker_jid' }

        before do
          allow(worker).to receive(:jid).and_return(uuid)
        end

        it 'marks storage migration as failed' do
          expect(exclusive_lease.try_obtain).to eq(worker.jid)
          expect(service).not_to receive(:execute)

          subject

          expect(repository_storage_move.reload).to be_failed
        end
      end
    end
  end
end
