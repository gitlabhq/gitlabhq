# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::PoolRepositories::StorageScanner, feature_category: :source_code_management do
  let(:logger) { instance_double(Logger) }
  let(:discovery_service) { instance_double(Gitlab::PoolRepositories::DiscoveryService) }
  let(:csv_writer) { instance_double(Gitlab::PoolRepositories::CsvWriter) }
  let(:verbose) { false }
  let(:scanner) { described_class.new(logger, verbose, discovery_service, csv_writer) }
  let(:storages) { { 'default' => {} } }
  let(:pool_metadata) { [] }

  before do
    allow(logger).to receive(:info)
    allow(logger).to receive(:error)
    allow(logger).to receive(:debug)
    allow(Gitlab.config.repositories).to receive(:storages).and_return(storages)
    allow(discovery_service).to receive(:scan_pool_metadata).and_return(pool_metadata)
  end

  shared_examples 'verbose error backtrace logging' do
    context 'when verbose' do
      let(:verbose) { true }

      it 'logs the backtrace via debug' do
        scan
        expect(logger).to have_received(:debug).with("line1\nline2")
      end
    end

    context 'when not verbose' do
      it 'does not log the backtrace' do
        scan
        expect(logger).not_to have_received(:debug)
      end
    end
  end

  describe '#scan_all_storages' do
    subject(:scan) { scanner.scan_all_storages }

    context 'when scanning multiple storages' do
      let(:storages) { { 'default' => {}, 'backup' => {} } }

      it 'scans all configured storages' do
        scan
        expect(discovery_service).to have_received(:scan_pool_metadata).twice
      end
    end

    context 'when scan_storage raises for one storage' do
      let(:storages) { { 'default' => {}, 'backup' => {} } }

      before do
        call_count = 0
        allow(scanner).to receive(:scan_storage).and_wrap_original do |method, *args|
          call_count += 1
          raise StandardError, 'Storage error' if call_count == 1

          method.call(*args)
        end
      end

      it 'logs error and continues scanning remaining storages' do
        expect { scan }.not_to raise_error
        expect(logger).to have_received(:error).with(/Error scanning storage default/)
      end
    end

    context 'when an error with backtrace occurs' do
      let(:error) { StandardError.new('Storage error').tap { |e| e.set_backtrace(%w[line1 line2]) } }

      before do
        allow(scanner).to receive(:scan_storage).and_raise(error)
      end

      include_examples 'verbose error backtrace logging'
    end

    context 'when pool is not in database' do
      let(:pool_metadata) { [{ relative_path: 'repo1.git', pool_disk_path: '@pools/orphan.git' }] }

      before do
        allow(discovery_service).to receive(:pool_disk_path_exists?).with('@pools/orphan').and_return(false)
        allow(csv_writer).to receive(:write_row)
      end

      it 'records an orphaned pool and writes CSV row' do
        scan

        expect(scanner.orphaned_pools.size).to eq(1)
        expect(scanner.orphaned_pools.first[:disk_path]).to eq('@pools/orphan')
        expect(csv_writer).to have_received(:write_row).with(
          hash_including(
            pool_id: 'N/A',
            disk_path: '@pools/orphan',
            reason_codes: 'pool_on_gitaly_missing_db',
            shard_name: 'default'
          )
        )
      end

      context 'when verbose' do
        let(:verbose) { true }

        it 'logs orphan info message' do
          scan
          expect(logger).to have_received(:info).with(/Found orphaned pool on Gitaly/)
        end
      end

      context 'when not verbose' do
        it 'does not log orphan info message' do
          scan
          expect(logger).not_to have_received(:info).with(/Found orphaned pool on Gitaly/)
        end
      end
    end

    context 'when two repos point to the same orphaned pool' do
      let(:pool_metadata) do
        [
          { relative_path: 'repo1.git', pool_disk_path: '@pools/orphan.git' },
          { relative_path: 'repo2.git', pool_disk_path: '@pools/orphan.git' }
        ]
      end

      before do
        allow(discovery_service).to receive(:pool_disk_path_exists?).with('@pools/orphan').and_return(false)
        allow(csv_writer).to receive(:write_row)
      end

      it 'deduplicates and records the orphaned pool only once' do
        scan

        expect(scanner.orphaned_pools.size).to eq(1)
        expect(csv_writer).to have_received(:write_row).once
      end
    end

    context 'when pool exists in database' do
      let(:pool_metadata) { [{ relative_path: 'repo1.git', pool_disk_path: '@pools/exists.git' }] }

      before do
        allow(discovery_service).to receive(:pool_disk_path_exists?).with('@pools/exists').and_return(true)
      end

      it 'does not record an orphaned pool' do
        scan
        expect(scanner.orphaned_pools).to be_empty
      end
    end

    context 'when pool_disk_path is blank' do
      let(:pool_metadata) { [{ relative_path: 'repo1.git', pool_disk_path: nil }] }

      before do
        allow(discovery_service).to receive(:pool_disk_path_exists?)
      end

      it 'skips the blank pool path and does not check if it exists' do
        scan
        expect(discovery_service).not_to have_received(:pool_disk_path_exists?)
        expect(scanner.orphaned_pools).to be_empty
      end
    end

    context 'when pool_disk_path is an empty string' do
      let(:pool_metadata) { [{ relative_path: 'repo1.git', pool_disk_path: '' }] }

      before do
        allow(discovery_service).to receive(:pool_disk_path_exists?)
      end

      it 'skips the empty pool path and does not check if it exists' do
        scan
        expect(discovery_service).not_to have_received(:pool_disk_path_exists?)
        expect(scanner.orphaned_pools).to be_empty
      end
    end

    context 'when check_pools_for_orphans raises an error' do
      let(:pool_metadata) { [{ relative_path: 'repo1.git', pool_disk_path: '@pools/pool.git' }] }
      let(:error) { StandardError.new('Check error').tap { |e| e.set_backtrace(%w[line1 line2]) } }

      before do
        allow(discovery_service).to receive(:pool_disk_path_exists?).and_raise(error)
      end

      it 'logs the error message' do
        scan
        expect(logger).to have_received(:error).with('Error checking pools on storage default: Check error')
      end

      context 'when verbose' do
        let(:verbose) { true }

        it 'logs the backtrace via debug' do
          scan
          expect(logger).to have_received(:debug).with("line1\nline2")
        end
      end

      context 'when not verbose' do
        it 'does not log the backtrace' do
          scan
          expect(logger).not_to have_received(:debug)
        end
      end
    end
  end

  describe '#orphaned_pools' do
    subject(:orphaned_pools) { scanner.orphaned_pools }

    it 'returns an empty array initially' do
      expect(orphaned_pools).to be_an(Array)
      expect(orphaned_pools).to be_empty
    end
  end
end
