require 'spec_helper'

describe Gitlab::HealthChecks::FsShardsCheck do
  let(:metric_class) { Gitlab::HealthChecks::Metric }
  let(:result_class) { Gitlab::HealthChecks::Result }
  let(:repository_storages) { [:default] }
  let(:tmp_dir) { Dir.mktmpdir }

  let(:storages_paths) do
    {
      default: { path: tmp_dir }
    }.with_indifferent_access
  end

  before do
    allow(described_class).to receive(:repository_storages) { repository_storages }
    allow(described_class).to receive(:storages_paths) { storages_paths }
  end

  after do
    FileUtils.remove_entry_secure(tmp_dir) if Dir.exist?(tmp_dir)
  end

  shared_examples 'filesystem checks' do
    describe '#readiness' do
      subject { described_class.readiness }

      context 'storage points to not existing folder' do
        let(:storages_paths) do
          {
            default: { path: 'tmp/this/path/doesnt/exist' }
          }.with_indifferent_access
        end

        it { is_expected.to include(result_class.new(false, 'cannot stat storage', shard: :default)) }
      end

      context 'storage points to directory that has both read and write rights' do
        before do
          FileUtils.chmod_R(0755, tmp_dir)
        end

        it { is_expected.to include(result_class.new(true, nil, shard: :default)) }

        it 'cleans up files used for testing' do
          expect(described_class).to receive(:storage_write_test).with(any_args).and_call_original

          subject

          expect(Dir.entries(tmp_dir).count).to eq(2)
        end

        context 'read test fails' do
          before do
            allow(described_class).to receive(:storage_read_test).with(any_args).and_return(false)
          end

          it { is_expected.to include(result_class.new(false, 'cannot read from storage', shard: :default)) }
        end

        context 'write test fails' do
          before do
            allow(described_class).to receive(:storage_write_test).with(any_args).and_return(false)
          end

          it { is_expected.to include(result_class.new(false, 'cannot write to storage', shard: :default)) }
        end
      end
    end

    describe '#metrics' do
      subject { described_class.metrics }

      context 'storage points to not existing folder' do
        let(:storages_paths) do
          {
            default: { path: 'tmp/this/path/doesnt/exist' }
          }.with_indifferent_access
        end

        it { is_expected.to include(metric_class.new(:filesystem_accessible, 0, shard: :default)) }
        it { is_expected.to include(metric_class.new(:filesystem_readable, 0, shard: :default)) }
        it { is_expected.to include(metric_class.new(:filesystem_writable, 0, shard: :default)) }

        it { is_expected.to include(have_attributes(name: :filesystem_access_latency, value: be >= 0, labels: { shard: :default })) }
        it { is_expected.to include(have_attributes(name: :filesystem_read_latency, value: be >= 0, labels: { shard: :default })) }
        it { is_expected.to include(have_attributes(name: :filesystem_write_latency, value: be >= 0, labels: { shard: :default })) }
      end

      context 'storage points to directory that has both read and write rights' do
        before do
          FileUtils.chmod_R(0755, tmp_dir)
        end

        it { is_expected.to include(metric_class.new(:filesystem_accessible, 1, shard: :default)) }
        it { is_expected.to include(metric_class.new(:filesystem_readable, 1, shard: :default)) }
        it { is_expected.to include(metric_class.new(:filesystem_writable, 1, shard: :default)) }

        it { is_expected.to include(have_attributes(name: :filesystem_access_latency, value: be >= 0, labels: { shard: :default })) }
        it { is_expected.to include(have_attributes(name: :filesystem_read_latency, value: be >= 0, labels: { shard: :default })) }
        it { is_expected.to include(have_attributes(name: :filesystem_write_latency, value: be >= 0, labels: { shard: :default })) }
      end
    end
  end

  context 'when popen always finds required binaries' do
    before do
      allow(Gitlab::Popen).to receive(:popen).and_wrap_original do |method, *args, &block|
        begin
          method.call(*args, &block)
        rescue RuntimeError
          raise 'expected not to happen'
        end
      end
    end

    it_behaves_like 'filesystem checks'
  end

  context 'when popen never finds required binaries' do
    before do
      allow(Gitlab::Popen).to receive(:popen).and_raise(Errno::ENOENT)
    end

    it_behaves_like 'filesystem checks'
  end
end
