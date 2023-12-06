# frozen_string_literal: true

RSpec.shared_examples 'an update storage move worker' do
  let(:worker) { described_class.new }

  it 'has the `until_executed` deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
  end

  describe '#perform', :clean_gitlab_redis_shared_state do
    let(:service) { double(:update_repository_storage_service) }

    before do
      allow(Gitlab.config.repositories.storages).to receive(:keys).and_return(%w[default test_second_storage])
    end

    describe 'deprecated method signature' do
      # perform(container_id, new_repository_storage_key, repository_storage_move_id = nil)
      subject { worker.perform(container.id, 'test_second_storage', repository_storage_move_id) }

      context 'without repository storage move' do
        let(:repository_storage_move_id) { nil }

        it 'calls the update repository storage service' do
          expect(service_klass).to receive(:new).and_return(service)
          expect(service).to receive(:execute)

          expect do
            worker.perform(container.id, 'test_second_storage')
          end.to change { repository_storage_move_klass.count }.by(1)

          storage_move = container.repository_storage_moves.last
          expect(storage_move).to have_attributes(
            source_storage_name: 'default',
            destination_storage_name: 'test_second_storage'
          )
        end
      end

      context 'with repository storage move' do
        let(:repository_storage_move_id) { repository_storage_move.id }

        before do
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
          let(:lease_key) { [described_class.name.underscore, container.id].join(':') }
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

    describe 'new method signature' do
      # perform(repository_storage_move_id)
      subject { worker.perform(repository_storage_move.id) }

      before do
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
end
