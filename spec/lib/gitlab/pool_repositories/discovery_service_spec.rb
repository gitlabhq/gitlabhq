# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PoolRepositories::DiscoveryService, feature_category: :source_code_management do
  let(:logger) { instance_double(Logger) }
  let(:verbose) { false }
  let(:discovery_service) { described_class.new(logger, verbose) }
  let(:storage_name) { 'default' }

  before do
    allow(logger).to receive(:info)
    allow(logger).to receive(:error)
    allow(logger).to receive(:debug)
  end

  shared_examples 'error handling with verbose toggle' do |expected_default, log_pattern|
    context 'when verbose' do
      let(:verbose) { true }

      it 'returns the safe default and logs the error' do
        expect(subject).to eq(expected_default)
        expect(logger).to have_received(:debug).with(log_pattern)
      end
    end

    context 'when not verbose' do
      it 'returns the safe default without logging' do
        expect(subject).to eq(expected_default)
        expect(logger).not_to have_received(:debug)
      end
    end
  end

  def build_scan_pool_metadata_response(relative_path:, pool_disk_path: nil)
    Gitaly::ScanPoolMetadataResponse.new(relative_path: relative_path, pool_disk_path: pool_disk_path)
  end

  describe '#initialize' do
    it 'loads all pool disk paths into cache' do
      create(:pool_repository, disk_path: '@pools/path1')
      create(:pool_repository, disk_path: '@pools/path2')

      client = described_class.new(logger, verbose)

      expect(client.pool_disk_path_exists?('@pools/path1')).to be true
      expect(client.pool_disk_path_exists?('@pools/path2')).to be true
    end
  end

  describe '#pool_disk_path_exists?' do
    subject { discovery_service.pool_disk_path_exists?(path) }

    context 'when the path exists in cache' do
      before do
        create(:pool_repository, disk_path: '@pools/test')
      end

      let(:discovery_service) { described_class.new(logger, verbose) }
      let(:path) { '@pools/test' }

      it { is_expected.to be true }
    end

    context 'when the path does not exist in cache' do
      let(:path) { '@pools/other' }

      it { is_expected.to be false }
    end
  end

  describe '#scan_pool_metadata' do
    subject(:scan_result) { discovery_service.scan_pool_metadata(storage_name) }

    context 'when repositories with pools are returned' do
      before do
        messages = [
          build_scan_pool_metadata_response(relative_path: 'repo1.git', pool_disk_path: '@pools/pool1.git'),
          build_scan_pool_metadata_response(relative_path: 'repo2.git', pool_disk_path: '@pools/pool2.git')
        ]
        allow(Gitlab::GitalyClient).to receive(:call).and_return(messages)
      end

      it 'returns relative paths with their pool disk paths' do
        expect(scan_result).to match_array([
          { relative_path: 'repo1.git', pool_disk_path: '@pools/pool1.git' },
          { relative_path: 'repo2.git', pool_disk_path: '@pools/pool2.git' }
        ])
      end
    end

    context 'when some repositories have no pools' do
      before do
        messages = [
          build_scan_pool_metadata_response(relative_path: 'repo1.git', pool_disk_path: '@pools/pool1.git'),
          build_scan_pool_metadata_response(relative_path: 'repo2.git', pool_disk_path: '')
        ]
        allow(Gitlab::GitalyClient).to receive(:call).and_return(messages)
      end

      it 'returns nil for pool_disk_path when empty' do
        expect(scan_result).to match_array([
          { relative_path: 'repo1.git', pool_disk_path: '@pools/pool1.git' },
          { relative_path: 'repo2.git', pool_disk_path: nil }
        ])
      end
    end

    context 'when the Gitaly call raises an error' do
      before do
        allow(Gitlab::GitalyClient).to receive(:call).and_raise(StandardError, 'Scan failed')
      end

      include_examples 'error handling with verbose toggle', [], /Failed to scan pool metadata/
    end
  end
end
