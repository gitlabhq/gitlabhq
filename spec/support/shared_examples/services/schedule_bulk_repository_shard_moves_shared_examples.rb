# frozen_string_literal: true

RSpec.shared_examples 'moves repository shard in bulk' do
  let(:source_storage_name) { 'default' }
  let(:destination_storage_name) { 'test_second_storage' }

  before do
    stub_storage_settings(destination_storage_name => {})
  end

  describe '#execute' do
    it 'schedules container repository storage moves' do
      expect { subject.execute(source_storage_name, destination_storage_name) }
        .to change { move_service_klass.count }.by(1)

      storage_move = container.repository_storage_moves.last!

      expect(storage_move).to have_attributes(
        source_storage_name: source_storage_name,
        destination_storage_name: destination_storage_name,
        state_name: :scheduled
      )
    end

    context 'read-only repository' do
      it 'does not get scheduled' do
        container.set_repository_read_only!

        expect(subject).to receive(:log_info)
          .with(/Container #{container.full_path} \(#{container.id}\) was skipped: #{expected_class} is read-only/)
        expect { subject.execute(source_storage_name, destination_storage_name) }
          .to change { move_service_klass.count }.by(0)
      end
    end
  end

  describe '.enqueue' do
    it 'defers to the worker' do
      expect(bulk_worker_klass).to receive(:perform_async).with(source_storage_name, destination_storage_name)

      described_class.enqueue(source_storage_name, destination_storage_name)
    end
  end
end
