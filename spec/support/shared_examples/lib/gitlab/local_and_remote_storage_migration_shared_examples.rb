# frozen_string_literal: true

RSpec.shared_examples 'local and remote storage migration' do
  let(:logger) { Logger.new("/dev/null") }
  let(:migrater) { described_class.new(logger) }

  using RSpec::Parameterized::TableSyntax

  where(:start_store, :end_store, :method) do
    ObjectStorage::Store::LOCAL  | ObjectStorage::Store::REMOTE | :migrate_to_remote_storage
    ObjectStorage::Store::REMOTE | ObjectStorage::Store::REMOTE | :migrate_to_remote_storage
    ObjectStorage::Store::REMOTE | ObjectStorage::Store::LOCAL  | :migrate_to_local_storage
    ObjectStorage::Store::LOCAL  | ObjectStorage::Store::LOCAL  | :migrate_to_local_storage
  end

  with_them do
    let(:storage_name) { end_store == ObjectStorage::Store::REMOTE ? 'object' : 'local' }

    it 'successfully migrates' do
      expect(logger).to receive(:info).with("Starting transfer to #{storage_name} storage")

      if start_store != end_store
        expect(logger).to receive(:info).with("Transferred #{item.class.name} ID #{item.id} with size #{item.size} to #{storage_name} storage")
      end

      expect(item.file_store).to eq(start_store)

      migrater.send(method)

      expect(item.reload.file_store).to eq(end_store)
    end
  end

  context 'when migration fails' do
    let(:start_store) { ObjectStorage::Store::LOCAL }

    it 'prints error' do
      expect_next_instance_of(item.file.class) do |file|
        expect(file).to receive(:migrate!).and_raise("error message")
      end

      expect(logger).to receive(:info).with("Starting transfer to object storage")

      expect(logger).to receive(:warn).with("Failed to transfer #{item.class.name} ID #{item.id} with error: error message")

      expect(item.file_store).to eq(start_store)

      migrater.migrate_to_remote_storage

      expect(item.reload.file_store).to eq(start_store)
    end
  end
end
