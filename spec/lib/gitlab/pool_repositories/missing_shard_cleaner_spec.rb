# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PoolRepositories::MissingShardCleaner, feature_category: :source_code_management do
  let_it_be(:missing_shard) { Shard.by_name('decommissioned-shard') }
  let_it_be(:other_missing_shard) { Shard.by_name('other-decommissioned-shard') }

  let(:logger) { instance_double(Logger, info: nil, warn: nil) }
  let(:csv_writer) { instance_double(Gitlab::PoolRepositories::CsvWriter, write_row: nil, flush: nil, close: nil) }
  let(:deleted_csv_writer) { instance_double(Gitlab::PoolRepositories::CsvWriter, write_row: nil, flush: nil, close: nil) }
  let(:shard_names) { [missing_shard.name] }
  let(:dry_run) { false }

  subject(:cleaner) do
    described_class.new(
      shard_names: shard_names, csv_writer: csv_writer, deleted_csv_writer: deleted_csv_writer,
      logger: logger, dry_run: dry_run
    )
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
    %i[output_file deleted_output_file].each do |invalid_output|
      context "when the parent directory of #{invalid_output} is missing" do
        it 'raises a validation error without creating files or deleting pools' do
          pool = create_orphaned_pool(missing_shard)

          Dir.mktmpdir do |directory|
            paths = {
              output_file: File.join(directory, 'recovery.csv'),
              deleted_output_file: File.join(directory, 'deleted.csv')
            }
            paths[invalid_output] = File.join(directory, 'missing', 'output.csv')
            cleaner = described_class.new(shard_names: shard_names, logger: logger, dry_run: false, **paths)

            expect { cleaner.run! }.to raise_error(
              described_class::ValidationError,
              /Cannot resolve output directory for #{Regexp.escape(paths[invalid_output])}:.*No such file or directory/
            )

            expect(File.exist?(paths[:output_file])).to be(false)
            expect(File.exist?(paths[:deleted_output_file])).to be(false)
            expect(pool.reload).to be_persisted
          end
        end
      end
    end

    it 'requires a destination for deleted IDs before opening the recovery file' do
      cleaner = described_class.new(shard_names: shard_names, logger: logger, csv_writer: csv_writer, dry_run: false)

      expect { cleaner.run! }.to raise_error(described_class::ValidationError, /DELETED_IDS_FILE is required/)

      expect(csv_writer).not_to have_received(:write_row)
    end

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

    context 'when output file paths are given' do
      subject(:cleaner) do
        described_class.new(
          shard_names: shard_names, output_file: output_file, deleted_output_file: deleted_output_file,
          logger: logger, dry_run: dry_run
        )
      end

      let(:output_file) { File.join(Dir.mktmpdir, 'orphaned_pools.csv') }
      let(:deleted_output_file) { File.join(File.dirname(output_file), 'deleted_ids.csv') }

      after do
        FileUtils.rm_rf(File.dirname(output_file))
      end

      it 'creates the CSV file after validation, even when nothing matches' do
        cleaner.run!

        expect(CSV.read(output_file)).to eq([described_class::CSV_COLUMNS.pluck(:header)])
        expect(CSV.read(deleted_output_file)).to eq([['Pool ID']])
        expect(logger).to have_received(:info).with('Recovery CSV: 0 pool records written.')
        expect(logger).to have_received(:info).with('Deleted IDs CSV: 0 IDs written.')
      end

      it 'writes recovery records and actual deleted IDs and reports totals across batches' do
        pools = Array.new(3) { create_orphaned_pool(missing_shard) }
        stub_const("#{described_class}::BATCH_SIZE", 2)

        expect { cleaner.run! }.to change { PoolRepository.count }.by(-3)

        recovery = CSV.read(output_file, headers: true)
        deleted = CSV.read(deleted_output_file, headers: true)
        expect(recovery['Pool ID'].map(&:to_i)).to match_array(pools.map(&:id))
        expect(deleted['Pool ID'].map(&:to_i)).to match_array(pools.map(&:id))
        expect(cleaner.csv_count).to eq(3)
        expect(cleaner.deleted_count).to eq(3)
        expect(logger).to have_received(:info).with('Recovery CSV: 3 pool records written.')
        expect(logger).to have_received(:info).with('Deleted IDs CSV: 3 IDs written.')
        expect(logger).to have_received(:info).with("Recovery CSV saved to #{output_file}")
        expect(logger).to have_received(:info).with("Deleted IDs CSV saved to #{deleted_output_file}")
      end

      it 'refuses to overwrite an existing deleted IDs file before creating the recovery file' do
        File.write(deleted_output_file, 'previous deleted IDs')
        pool = create_orphaned_pool(missing_shard)

        expect { cleaner.run! }.to raise_error(described_class::ValidationError, /already exists/)

        expect(File.exist?(output_file)).to be(false)
        expect(File.read(deleted_output_file)).to eq('previous deleted IDs')
        expect(pool.reload).to be_persisted
      end

      context 'when both paths refer to the same file' do
        let(:deleted_output_file) { File.join(File.dirname(output_file), '.', File.basename(output_file)) }

        it 'rejects the paths before creating either file' do
          expect { cleaner.run! }.to raise_error(described_class::ValidationError, /must be different paths/)

          expect(File.exist?(output_file)).to be(false)
        end
      end

      context 'when a symlinked directory points to the recovery destination' do
        let(:deleted_output_file) { File.join(File.dirname(output_file), 'alias', File.basename(output_file)) }

        it 'rejects the paths before creating either file' do
          File.symlink(File.dirname(output_file), File.join(File.dirname(output_file), 'alias'))

          expect { cleaner.run! }.to raise_error(described_class::ValidationError, /must be different paths/)

          expect(File.exist?(output_file)).to be(false)
        end
      end

      context 'when dry_run is true' do
        let(:dry_run) { true }

        it 'creates only the recovery file and reports its total' do
          pool = create_orphaned_pool(missing_shard)

          expect { cleaner.run! }.not_to change { PoolRepository.count }

          expect(CSV.read(output_file, headers: true)['Pool ID']).to eq([pool.id.to_s])
          expect(File.exist?(deleted_output_file)).to be(false)
          expect(logger).to have_received(:info).with('Recovery CSV: 1 pool records written.')
        end
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
        expect(deleted_csv_writer).to have_received(:close)
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

      it 'writes and flushes the actual deleted IDs after deletion' do
        allow(deleted_csv_writer).to receive(:write_row) do |row|
          expect(PoolRepository.find_by_id(row[:pool_id])).to be_nil
        end

        cleaner.run!

        expect(deleted_csv_writer).to have_received(:write_row).with(pool_id: orphaned_pool.id).once
        expect(deleted_csv_writer).to have_received(:flush)
      end

      it 'does not delete anything if the recovery CSV cannot be flushed' do
        allow(csv_writer).to receive(:flush).and_raise(IOError)

        expect { cleaner.run! }.to raise_error(IOError)

        expect(orphaned_pool.reload).to be_persisted
        expect(deleted_csv_writer).not_to have_received(:write_row)
        expect(csv_writer).to have_received(:close)
        expect(deleted_csv_writer).to have_received(:close)
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
          expect(deleted_csv_writer).not_to have_received(:write_row)
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
          allow(csv_writer).to receive(:write_row) do |row|
            create(:project, pool_repository_id: row[:pool_id])
          end

          expect { cleaner.run! }.not_to change { PoolRepository.count }

          expect(cleaner.deleted_count).to eq(0)
          expect(deleted_csv_writer).not_to have_received(:write_row)
          expect(logger).to have_received(:warn).with(/mismatch/i)
        end
      end

      context 'when a pool gains a source project between the read and the delete' do
        it 'keeps the backed-up pool and excludes it from the deleted IDs' do
          source_project = create(:project)
          allow(csv_writer).to receive(:flush) do
            orphaned_pool.update_column(:source_project_id, source_project.id)
          end

          expect { cleaner.run! }.not_to change { PoolRepository.count }

          expect(csv_writer).to have_received(:write_row).with(hash_including(pool_id: orphaned_pool.id))
          expect(deleted_csv_writer).not_to have_received(:write_row)
          expect(logger).to have_received(:warn).with(/mismatch/i)
        end
      end

      context 'when a pool loses its last member between the read and the delete' do
        let_it_be(:later_orphaned_pool) { create_orphaned_pool(missing_shard) }

        it 'leaves the newly eligible pool for a later run because it was not backed up' do
          allow(csv_writer).to receive(:flush) do
            Project.where(pool_repository_id: pool_with_member.id).update_all(pool_repository_id: nil)
          end

          expect { cleaner.run! }.to change { PoolRepository.count }.by(-2)

          expect(pool_with_member.reload).to be_persisted
          expect(csv_writer).not_to have_received(:write_row).with(hash_including(pool_id: pool_with_member.id))
          expect(deleted_csv_writer).not_to have_received(:write_row).with(pool_id: pool_with_member.id)
          expect(deleted_csv_writer).to have_received(:write_row).with(pool_id: orphaned_pool.id)
          expect(deleted_csv_writer).to have_received(:write_row).with(pool_id: later_orphaned_pool.id)
          expect(logger).not_to have_received(:warn)
        end

        it 'does not substitute an unbacked pool when a backed-up pool gains a member' do
          allow(csv_writer).to receive(:flush) do
            Project.where(pool_repository_id: pool_with_member.id).update_all(pool_repository_id: orphaned_pool.id)
          end

          expect { cleaner.run! }.to change { PoolRepository.count }.by(-1)

          expect(pool_with_member.reload).to be_persisted
          expect(orphaned_pool.reload).to be_persisted
          expect(deleted_csv_writer).to have_received(:write_row).with(pool_id: later_orphaned_pool.id).once
          expect(deleted_csv_writer).not_to have_received(:write_row).with(pool_id: pool_with_member.id)
          expect(deleted_csv_writer).not_to have_received(:write_row).with(pool_id: orphaned_pool.id)
          expect(logger).to have_received(:warn).with(/mismatch/i)
        end
      end
    end
  end
end
