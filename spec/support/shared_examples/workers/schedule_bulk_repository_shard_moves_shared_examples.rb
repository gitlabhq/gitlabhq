# frozen_string_literal: true

RSpec.shared_examples 'schedules bulk repository shard moves' do
  let(:source_storage_name) { 'default' }
  let(:destination_storage_name) { 'test_second_storage' }

  describe "#perform" do
    before do
      stub_storage_settings(destination_storage_name => {})

      allow(worker_klass).to receive(:perform_async)
    end

    include_examples 'an idempotent worker' do
      let(:job_args) { [source_storage_name, destination_storage_name] }

      it 'schedules container repository storage moves' do
        expect { subject }.to change { move_service_klass.count }.by(1)

        storage_move = container.repository_storage_moves.last!

        expect(storage_move).to have_attributes(
          source_storage_name: source_storage_name,
          destination_storage_name: destination_storage_name,
          state_name: :scheduled
        )
      end
    end
  end
end
