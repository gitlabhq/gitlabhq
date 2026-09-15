# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PoolRepositories::MissingShardCleaner, feature_category: :source_code_management do
  let_it_be(:missing_shard) { Shard.by_name('decommissioned-shard') }
  let_it_be(:other_missing_shard) { Shard.by_name('other-decommissioned-shard') }

  let(:logger) { instance_double(Logger, info: nil, warn: nil) }
  let(:csv_writer) { instance_double(Gitlab::PoolRepositories::CsvWriter, write_row: nil, flush: nil, close: nil) }
  let(:shard_names) { [missing_shard.name] }
  let(:dry_run) { false }

  subject(:cleaner) do
    described_class.new(shard_names: shard_names, csv_writer: csv_writer, logger: logger, dry_run: dry_run)
  end

  def create_orphaned_pool(shard)
    create(:pool_repository, :without_project, shard: shard, organization: create(:organization))
  end

  describe '#initialize' do
    it 'raises an error when neither output_file nor csv_writer is given' do
      expect { described_class.new(shard_names: shard_names, logger: logger) }
        .to raise_error(ArgumentError, /output_file or csv_writer/)
    end
  end

  describe '#run!' do
    context 'when shard_names is empty' do
      let(:shard_names) { [] }

      it 'raises a validation error' do
        expect { cleaner.run! }.to raise_error(described_class::ValidationError, /cannot be empty/)
      end
    end

    context 'when a shard name is present in the current Gitaly configuration' do
      let(:shard_names) { [missing_shard.name, 'default'] }

      let_it_be(:orphaned_pool) { create_orphaned_pool(missing_shard) }

      it 'aborts without deleting anything' do
        expect { cleaner.run! }.to raise_error(described_class::ValidationError, /default/)

        expect(orphaned_pool.reload).to be_persisted
      end

      it 'does not create the output file' do
        output_file = File.join(Dir.mktmpdir, 'output.csv')
        cleaner = described_class.new(shard_names: shard_names, output_file: output_file, logger: logger)
        allow(Gitlab::PoolRepositories::CsvWriter).to receive(:new)

        expect { cleaner.run! }.to raise_error(described_class::ValidationError, /default/)

        expect(Gitlab::PoolRepositories::CsvWriter).not_to have_received(:new)
      ensure
        FileUtils.rm_rf(File.dirname(output_file))
      end
    end

    context 'when the output file already exists' do
      subject(:cleaner) do
        described_class.new(shard_names: shard_names, output_file: output_file.path, logger: logger)
      end

      let(:output_file) { Tempfile.new('existing.csv') }

      after do
        output_file.close!
      end

      it 'aborts without touching the file' do
        output_file.write('previous audit data')
        output_file.flush

        expect { cleaner.run! }.to raise_error(described_class::ValidationError, /already exists/)

        expect(File.read(output_file.path)).to eq('previous audit data')
      end
    end

    context 'when a shard name has no shards record' do
      let(:shard_names) { ['never-existed'] }

      it 'warns, deletes nothing and closes the CSV writer' do
        expect { cleaner.run! }.not_to change { PoolRepository.count }

        expect(logger).to have_received(:warn).with(/never-existed/)
        expect(logger).to have_received(:info).with(/Nothing to clean up/)
        expect(csv_writer).to have_received(:close)
      end
    end

    context 'when only output_file is given' do
      subject(:cleaner) do
        described_class.new(shard_names: shard_names, output_file: output_file, logger: logger, dry_run: dry_run)
      end

      let(:output_file) { File.join(Dir.mktmpdir, 'orphaned_pools.csv') }

      after do
        FileUtils.rm_rf(File.dirname(output_file))
      end

      it 'creates the CSV file after validation, even when nothing matches' do
        cleaner.run!

        expect(File.exist?(output_file)).to be(true)
      end
    end

    context 'with orphaned pools on the given missing shard' do
      let_it_be(:orphaned_pool) { create_orphaned_pool(missing_shard) }
      let_it_be(:orphaned_pool_other_shard) { create_orphaned_pool(other_missing_shard) }
      let_it_be(:pool_with_source) do
        create(:pool_repository, shard: missing_shard)
      end

      let_it_be(:pool_with_member) do
        create_orphaned_pool(missing_shard).tap do |pool|
          create(:project, pool_repository: pool)
        end
      end

      it 'deletes only fully orphaned pools on the given shards' do
        expect { cleaner.run! }.to change { PoolRepository.count }.by(-1)

        expect(PoolRepository.find_by_id(orphaned_pool.id)).to be_nil
        expect(orphaned_pool_other_shard.reload).to be_persisted
        expect(pool_with_source.reload).to be_persisted
        expect(pool_with_member.reload).to be_persisted
      end

      it 'closes the CSV writer' do
        cleaner.run!

        expect(csv_writer).to have_received(:close)
      end

      it 'writes deleted rows to the CSV before deleting' do
        cleaner.run!

        expect(csv_writer).to have_received(:write_row).with(
          hash_including(
            pool_id: orphaned_pool.id,
            shard_name: missing_shard.name,
            disk_path: orphaned_pool.disk_path,
            state: orphaned_pool.state,
            organization_id: orphaned_pool.organization_id
          )
        )
      end

      it 'flushes the CSV to disk before each batch delete' do
        allow(csv_writer).to receive(:flush) do
          expect(PoolRepository.find_by_id(orphaned_pool.id)).to be_present
        end

        cleaner.run!

        expect(csv_writer).to have_received(:flush)
        expect(PoolRepository.find_by_id(orphaned_pool.id)).to be_nil
      end

      it 'does not enqueue ObjectPool::DestroyWorker' do
        expect(ObjectPool::DestroyWorker).not_to receive(:perform_async)

        cleaner.run!
      end

      it 'logs the count of excluded pools still referenced by projects' do
        cleaner.run!

        expect(cleaner.skipped_members_count).to eq(1)
        expect(logger).to have_received(:info).with(/excluded\): 1/)
      end

      it 'tracks the deleted count' do
        cleaner.run!

        expect(cleaner.deleted_count).to eq(1)
      end

      context 'when dry_run is true' do
        let(:dry_run) { true }

        it 'writes the CSV but deletes nothing' do
          expect { cleaner.run! }.not_to change { PoolRepository.count }

          expect(csv_writer).to have_received(:write_row).with(hash_including(pool_id: orphaned_pool.id))
          expect(logger).to have_received(:info).with(/Dry run complete/)
        end
      end

      context 'when a pool with a member sits between orphaned pools in the same batch' do
        let_it_be(:later_orphaned_pool) { create_orphaned_pool(missing_shard) }

        it 'deletes and writes to CSV only the orphaned pools around it' do
          expect(pool_with_member.id).to be_between(orphaned_pool.id, later_orphaned_pool.id).exclusive

          expect { cleaner.run! }.to change { PoolRepository.count }.by(-2)

          expect(pool_with_member.reload).to be_persisted
          expect(csv_writer).to have_received(:write_row).with(hash_including(pool_id: orphaned_pool.id))
          expect(csv_writer).to have_received(:write_row).with(hash_including(pool_id: later_orphaned_pool.id))
          expect(csv_writer).not_to have_received(:write_row).with(hash_including(pool_id: pool_with_member.id))
          expect(logger).not_to have_received(:warn)
        end
      end

      context 'when a pool gains a member between the read and the delete' do
        it 'skips the row and warns about the mismatch' do
          # The CSV write happens after the batch is read but before
          # delete_all, so linking a project here simulates the race.
          allow(csv_writer).to receive(:write_row) do |row|
            create(:project, pool_repository_id: row[:pool_id])
          end

          expect { cleaner.run! }.not_to change { PoolRepository.count }

          expect(cleaner.deleted_count).to eq(0)
          expect(logger).to have_received(:warn).with(/mismatch/i)
        end
      end
    end
  end
end
