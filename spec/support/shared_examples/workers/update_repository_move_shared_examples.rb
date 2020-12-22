# frozen_string_literal: true

RSpec.shared_examples 'an update storage move worker' do
  describe '#perform' do
    let(:service) { double(:update_repository_storage_service) }

    before do
      allow(Gitlab.config.repositories.storages).to receive(:keys).and_return(%w[default test_second_storage])
    end

    context 'without repository storage move' do
      it 'calls the update repository storage service' do
        expect(service_klass).to receive(:new).and_return(service)
        expect(service).to receive(:execute)

        expect do
          subject.perform(container.id, 'test_second_storage')
        end.to change(repository_storage_move_klass, :count).by(1)

        storage_move = container.repository_storage_moves.last
        expect(storage_move).to have_attributes(
          source_storage_name: 'default',
          destination_storage_name: 'test_second_storage'
        )
      end
    end

    context 'with repository storage move' do
      it 'calls the update repository storage service' do
        expect(service_klass).to receive(:new).and_return(service)
        expect(service).to receive(:execute)

        expect do
          subject.perform(nil, nil, repository_storage_move.id)
        end.not_to change(repository_storage_move_klass, :count)
      end
    end
  end
end
